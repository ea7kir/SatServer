//  -------------------------------------------------------------------
//  File: SystemControl.swift
//
//  This file is part of the SatController 'Suite'. It's purpose is
//  to remotely control and monitor a QO-100 DATV station over a LAN.
//
//  Copyright (C) 2021 Michael Naylor EA7KIR http://michaelnaylor.es
//
//  The 'Suite' is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  The 'Suite' is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General License for more details.
//
//  You should have received a copy of the GNU General License
//  along with  SatServer.  If not, see <https://www.gnu.org/licenses/>.
//  -------------------------------------------------------------------

import Foundation

final class SystemControl {
    private var current = BbStatusAPI()
    private var previous = BbStatusAPI()
    private var store = BbStatusAPI()
    private var response = ServerStatusAPI()
    private let hardware = Hardware()
    private let transmitter: Transmitter
    private let receiver: Receiver
    private var lastBoot: String
    private var previousState: BbStateType = .Simplex
    private var satControllerPort: Int
    private var satControllerServer: NIO_Cory_Server?
    
    init(with config: YAMLConfig) {
        self.satControllerPort = config.satControllerPort
        self.lastBoot = piLastBoot()
        
        switch config.state {
        case "simplex":
            current.state = .Simplex
            current.rxBand = config.simplexBand
            current.rxChannel = config.simplexChannel
            current.txBand = config.simplexBand
            current.txChannel = config.simplexChannel
        case "duplexRx":
            current.state = .DuplexRx
            current.rxBand = config.duplexRXBand
            current.rxChannel = config.duplexRXChannel
            current.txBand = config.duplexTXBand
            current.txChannel = config.duplexTXChannel
        case "duplexTx":
            current.state = .DuplexTx
            current.rxBand = config.duplexRXBand
            current.rxChannel = config.duplexRXChannel
            current.txBand = config.duplexTXBand
            current.txChannel = config.duplexTXChannel
        default:
            break
        }
        
        previous = current
        store = current
        
        if config.beacon {
            current.state = .Beacon
            current.rxBand = 0
            current.rxChannel = 0
        }
        
        self.receiver = Receiver(config: config)
        self.transmitter = Transmitter(config: config)
        receiver.setRxBandChannel(band: current.rxBand, channel: current.rxChannel)
        transmitter.setTxBandChannel(band: current.txBand, channel: current.txChannel)
        startTcpSatControllerServer()
    }
    
    func cleanup() {
        logProgress("SystemControll.\(#function) : reseting known states and closing network")
        //                transmitter.cleanup()
        //                receiver.cleanup()
        if ((satControllerServer?.isConnected) != nil) {
            logProgress("SystemControll.\(#function) : disconnecting SatContoller Server")
            satControllerServer?.disconnect()
        }
        switchBothPSUs_Off()
        if satControllerServer?.isConnected != nil {
            satControllerServer?.disconnect()
        }
        hardware.resetGPIOs()
    }
    
    private func startTcpSatControllerServer() {
        Task {
            logProgress("SystemControll.\(#function) : waiting for SatController client")
            do {
                try ServerFactory.listen(host: "0.0.0.0", port: satControllerPort, { (server: NIO_Cory_Server) in
                    self.satControllerServer = server
                    self.satControllerServer?.dataCallback = self.callbackFromSatController
                    // everything has to be done in here!
                    logProgress("SystemControll.\(#function) : active on port \(self.satControllerPort)")
                    self.sendPeriodicStatusToSatController()
                })
            } catch {
                logError("SystemControll.\(#function) : failed to listen: \(error)")
                exit(1)
            }
            logError("SystemControll.\(#function) : SHOULD NOT REACH HERE")
        }
    }
    
    // incomming commands from SatController
    func callbackFromSatController(data: Data) {
        do {
            let request = try JSONDecoder().decode(ServerCommandAPI.self, from: data)
            //            logProgress("SystemControll.\(#function) : got (request)")
            switchOnRequest(request: request)
        } catch {
            logError("SystemControll.\(#function) : failed to decode: \(error)")
            return
        }
    }
    
    // MARK: return response to SatController
    
    func sendPeriodicStatusToSatController() {
        Task {
            while true {
                await Task.yield()
                if (satControllerServer?.isConnected ?? false) {
                    let status = readCurrentStatus()
                    do {
                        let data =  try JSONEncoder().encode(status)
                        // logProgress("SystemControll.\(#function) : SEND -> SatController: \(status)")
                        satControllerServer?.send(data)
                    } catch {
                        logError("\(#function) : failed to send: \(error)")
                        return
                    }
                }
                try await Task.sleep(seconds: 0.5)
            }
        }
    }
    
    func readCurrentStatus() -> ServerStatusAPI {
        Task {
            response.bb = current
            
            response.ss.temperature = await hardware.piTemperature.value
            
            response.ss.fanSpeed = strFanSpeed(hardware.rpiFan.speed)
            response.ss.encClimate = hardware.enclosure.climate
            
            response.ss.encFanSpeeds = strTwoFanSpeeds(hardware.encIntakeFan.speed, hardware.encExtractFan.speed)
            response.ss.psu12vIsOn = hardware.relay_supply12v.isOn
            response.ss.psu28vIsOn = hardware.relay_supply28v.isOn
            
            response.ss.supply5v = hardware.supply5v.supply
            response.ss.supply12v = hardware.supply12v.supply
            response.ss.supply28v = hardware.supply28v.supply
            
            response.ss.lastBoot = lastBoot
            response.ss.upTime = await hardware.piUptime.value
            
            response.rx = receiver.readRxStatus()
            response.rx.fanSpeed = strFanSpeed(hardware.reveiverFan.speed)
            
            response.tx = transmitter.readTxStatus()
            response.tx.fanSpeed = strFanSpeed(hardware.plutoFan.speed)
            
            response.tx.driveFanSpeed = strFanSpeed(hardware.paDriverFan.speed)
            response.tx.paFanSpeeds = strTwoFanSpeeds(hardware.paIntakeFan.speed, hardware.paExtractFan.speed)
            
            // TODO: Stop thess two from flashing on/off
            response.tx.driveTemperature = await hardware.paDriver.temperature
            response.tx.paTemperature = await hardware.finalPa.temperature

            response.tx.driveIsOn = hardware.relay_PaDriver.isOn
            response.tx.paIsOn = hardware.relay_PaBias.isOn
        }
        return response
    }
    
    // MARK: act on incoming network request from SatController - called from satControllerCallback()
    
    func switchOnRequest(request: ServerCommandAPI) {
        //        logProgress("SystemControll.\(#function) : \(request)")  // TODO: TESTING
        switch request.action {
        case .Standby:
            // SatController sends .Standby when it closes.
            // If the 12v and 28v PSU are on, switch them off.
            logProgress("SystemControll.\(#function) : \(request.action)")
            switchBothPSUs_Off()
        case .Reboot:
            logProgress("SystemControll.\(#function) : \(request.action)")
            runState = .rebooting
        case .Shutdown:
            logProgress("SystemControll.\(#function) : \(request.action)")
            runState = .shuttingdown
        case .Toggle12v:
            toggle12vPSU()
        case .Toggle28v:
            toggle28vPSU()
            
            // MARK: Transmitter Actions
            
        case .TxTogglePtt:
            togglePTT()
        case .TxSetMode:
            if transmitter.isBusy() { break }
            transmitter.setTxMode(direction: request.param)
        case .TxSetConstellation:
            if transmitter.isBusy() { break }
            transmitter.setTxConstellation(direction: request.param)
        case .TxSetSR:
            if transmitter.isBusy() { break }
            transmitter.setTxSymbolRate(direction: request.param)
        case .TxSetFEC:
            if transmitter.isBusy() { break }
            transmitter.setTxFec(direction: request.param)
        case .TxSetCodecs:
            if transmitter.isBusy() { break }
            transmitter.setTxCodecs(direction: request.param)
        case .TxDrive:
            if transmitter.isBusy() { break }
            transmitter.setTxDrive(direction: request.param)
            
            // MARK: Receiver Actions
            
        case .RxScan:
            receiver.startScan()
        case .RxSetSR:
            receiver.setRxSymbolRate(direction: request.param)
        case .RxCalibrate:
            receiver.calibate()
            
            // MARK: BEGIN STATE SWITCHING
            
        case .SetBeacon:
            if current.state == .Beacon {
                return
            }
            previous = current
            current.state = .Beacon
            current.rxBand = 0
            current.rxChannel = 0
            receiver.setRxBandChannel(band: current.rxBand, channel: current.rxChannel)
            // transmitter - no change
        case .SetRecall:        // RECALL STATUS FOM MEMORY STORE
            current = store
            receiver.setRxBandChannel(band: current.rxBand, channel: current.rxChannel)
            transmitter.setTxBandChannel(band: current.txBand, channel: current.txChannel)
        case .SetStore:         // SAVE CURRENT STATUS TO MEMORY STORE
            if current.state == .Beacon {
                return
            }
            store = current
        case .SetRxSelect:
            switch current.state {
            case .Beacon:
                current = previous
            case .DuplexRx:
                current.state = .Simplex
                // change tx freq to match rx freq
                current.txBand = current.rxBand
                current.txChannel = current.rxChannel
//                transmitter.setTxBandChannel(band: current.txBand, channel: current.txChannel)
            case .DuplexTx:
                current.state = .DuplexRx
            case .Simplex:
                current.state = .DuplexRx
            }
            receiver.setRxBandChannel(band: current.rxBand, channel: current.rxChannel)
            transmitter.setTxBandChannel(band: current.txBand, channel: current.txChannel)
        case .SetTxSelect:
            switch current.state {
            case .Beacon:
                current = previous
            case .DuplexRx:
                current.state = .DuplexTx
            case .DuplexTx:
                current.state = .Simplex
            case .Simplex:
                current.state = .DuplexRx
            }
            receiver.setRxBandChannel(band: current.rxBand, channel: current.rxChannel)
            transmitter.setTxBandChannel(band: current.txBand, channel: current.txChannel)

            // MARK: END STATE SWITCHING
            
        case .SetVeryNarrow, .SetNarrow, .SetWide:
            var band = 0
            let channel = Int(request.param)!
            switch request.action {
            case .SetVeryNarrow:
                band = 1
            case .SetNarrow:
                band = 2
            case .SetWide:
                band = 3
            default:
                print("CODE error")
                exit(0)
            }
            switch current.state {
            case .Beacon:
                current = previous
                if current.state == .Simplex {
                    current.rxBand = band
                    current.rxChannel = channel
                    current.txBand = band
                    current.txChannel = channel
                } else {
                    current.rxBand = band
                    current.rxChannel = channel
                }
            case .Simplex:
                current.rxBand = band
                current.rxChannel = channel
                current.txBand = band
                current.txChannel = channel
            case .DuplexRx:
                current.rxBand = band
                current.rxChannel = channel
                if channel == current.txChannel { current.state = .Simplex }
            case .DuplexTx:
                current.txBand = band
                current.txChannel = channel
                if channel == current.rxChannel { current.state = .Simplex }
            }
            receiver.setRxBandChannel(band: current.rxBand, channel: current.rxChannel)
            transmitter.setTxBandChannel(band: current.txBand, channel: current.txChannel)
        }
    }
    
    // MARK: Power Supplies and Press To Talk
    
    private func toggle12vPSU() {
        hardware.relay_supply12v.isOn ? switch12vPSU_Off() : switch12vPSU_On()
    }
    
    private func toggle28vPSU() {
        hardware.relay_supply28v.isOn ? switch28vPSU_Off() : switch28vPSU_On()
    }
    
    private func togglePTT() {
        if hardware.relay_supply28v.isOn {
            if hardware.relay_PaDriver.isOn {
                switchPTT_Off()
            } else {
                switchPTT_On()
            }
        }
    }
    
    private func switch12vPSU_On() {
        logProgress("SystemControll.\(#function) : should I be reseting Reeciver here?")
        hardware.relay_RxPi.turnOn() // Relay 2 5v to Receiver's Pi
        hardware.relay_supply12v.turnOn()
    }
    
    private func switch12vPSU_Off() {
        logProgress("SystemControll.\(#function) :")
        if hardware.relay_supply28v.isOn {
            switch28vPSU_Off()
        }
        Task {
            receiver.shutdown()
            try await Task.sleep(seconds: 5.0) // allow time to shutdown
            hardware.relay_RxPi.turnOff() // Relay 2 5v to Receiver's Pi
            hardware.relay_supply12v.turnOff()
        }
    }
    
    private func switch28vPSU_On() {
        logProgress("SystemControll.\(#function) :")
        if hardware.relay_supply12v.isOn {
            hardware.relay_AllTxFans.turnOn()
            hardware.relay_supply28v.turnOn()
            hardware.relay_Pluto.turnOn()
            transmitter.connect(host: "pluto.local", port: 7272)
        }
    }
    
    private func switch28vPSU_Off() {
        logProgress("SystemControll.\(#function) :")
        if hardware.relay_supply28v.isOn {
            if transmitter.isBusy() {
                switchPTT_Off()
            }
            transmitter.shutdown()
            //            Task { try await Task.sleep(seconds: 1.0) }
            hardware.relay_Pluto.turnOff()
            hardware.relay_supply28v.turnOff()
            hardware.relay_AllTxFans.turnOff()
        }
    }
    
    private func switchBothPSUs_Off() {
        logProgress("SystemControll.\(#function) :")
        if hardware.relay_supply28v.isOn {
            switch28vPSU_Off()
        }
        if hardware.relay_supply12v.isOn {
            switch12vPSU_Off()
        }
    }
    
    private func switchPTT_On() {
        // TODO: reduce delay time to a little more than 200ms
        Task {
            /* 1 */ transmitter.lockParametersIntoPluto()
            /* 2 */ try await Task.sleep(seconds: 0.2)
            /* 3 */ hardware.relay_PaBias.turnOn()
            /* 4 */ try await Task.sleep(seconds: 0.2)
            /* 5 */ hardware.relay_PaDriver.turnOn()
        }
    }
    
    private func switchPTT_Off() {
        // TODO: reduce delay time to a little more than 200ms
        Task {
            /* 1 */ hardware.relay_PaDriver.turnOff()
            /* 2 */ try await Task.sleep(seconds: 0.2)
            /* 5 */ hardware.relay_PaBias.turnOff()
            /* 4 */ try await Task.sleep(seconds: 0.2)
            /* 3 */ transmitter.unlockPlutoParameters()
        }
    }
}
