//  -------------------------------------------------------------------
//  File: Receiver.swift
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

final class Receiver {


    private let symbolRatesToScan: [[String]] = [
        [SR1500],
        [SR33,SR66,SR125], // MiniTiouner minimum is SR33
        [SR250,SR333,SR500],
        [SR1000,SR1500]]
    private var currentSrIndex = 0 // fix in start()
    private var savedSRindexesForBand: [Int]

    private let receiverPort: Int
    private var satReceiverServer: NIO_Cory_Server?
    private var serverHasStarted = false
    
    private var dataToSend = Data()
    private var flagDataToSend = false // wait for longmynd to be running

    private var rx = RxStatusAPI() // local copy

    private var rxBand = 0 // fix in start()
    private var rxChannel = 0 // fix in start()
    
    private var maxSrIndexForBand = [0,0,0,0] // fix in start()

    // TODO: move these to YANL as Int
    private let defaultSrForBand_0 = 0 // SR1500
    private let defaultSrForBand_1 = 2 // SR125
    private let defaultSrForBand_2 = 1 // SR333
    private let defaultSrForBand_3 = 0 // SR1000
    

    init(config: YAMLConfig) {
        self.receiverPort = config.satReceiverPort
        // TODO: get these from YAML
        self.savedSRindexesForBand = [defaultSrForBand_0,
                                      defaultSrForBand_1,
                                      defaultSrForBand_2,
                                      defaultSrForBand_3]
        for i in 0..<symbolRatesToScan.endIndex {
            maxSrIndexForBand[i] = symbolRatesToScan[i].endIndex - 1
        }
        currentSrIndex = savedSRindexesForBand[0]
        startQueuingRequestsToSendToSatReceiver()
        setRxBandChannel(band: 0, channel: 0)
        startTcpSatReceiverServer()
    }
        
    func shutdown() {
        logProgress("Receiver.\(#function) : shutting down")
        queueActionToSend(action: .Shutdown) // TODO: Note: SatReceiver wil respond with state = ShuttingDown
    }
    
    // Start a server to communicate with SatReceiver
    private func startTcpSatReceiverServer() {
        Task {
            logProgress("Receiver.\(#function) : waiting for SatReceiver client")
            do {
                try ServerFactory.listen(host: "0.0.0.0", port: receiverPort, { (server: NIO_Cory_Server) in
                    self.satReceiverServer = server
                    self.satReceiverServer?.dataCallback = self.callbackFromSatReceiver
                    // everything has to be done in here!
                    logProgress("Receiver.\(#function) : active on port \(self.receiverPort)")
                    self.serverHasStarted = true
                })
            } catch {
                logError("Receiver.\(#function) in Receiver failed to listen: \(error)")
            }
            logError("Receiver.\(#function) : SHOULD NOT REACH HERE")
        }
    }
    
    private func rxIsConnected() -> Bool {
        return satReceiverServer?.isConnected ?? false
//        return satReceiverServer?.isConnected != nil // TODO: rename to satReceiverServer?.isActive
    }
    
//    private func rxDisconnect() {
////        satReceiverServer?.disconnect() // TODO: REALLY?
//    }
    
    private func callbackFromSatReceiver(data: Data) {
        do {
            let rxStatusAPI = try JSONDecoder().decode(RxStatusAPI.self, from: data)
            switch rxStatusAPI.state {
            case .OffLine:
                ()
            case .Intializing:
                ()
            case .Searching:
                ()
            case .FoundHeaders:
                ()
            case .LockedS:
                ()
            case .LockedS2:
                ()
            case .ShuttingDown:
                ()
            }
            rx.state = rxStatusAPI.state
//            rx.freq = 
//            rx.bandChanDisplay =
            rx.temperature = rxStatusAPI.temperature
//            rx.fanSpeed = hardware.readReceiverFanSpeed()
//            rx.isScan =
//            rx.sr =
            rx.mode = rxStatusAPI.mode
            rx.constellation = rxStatusAPI.constellation
            rx.fec = rxStatusAPI.fec
            rx.codecs = rxStatusAPI.codecs
            rx.mer = rxStatusAPI.mer
            rx.margin = rxStatusAPI.margin
            rx.power = rxStatusAPI.power
            rx.provider = rxStatusAPI.provider
            rx.service = rxStatusAPI.service
            rx.tunedFreq = rxStatusAPI.tunedFreq
            rx.tunedSr = rxStatusAPI.tunedSr
            rx.tunedError = rxStatusAPI.tunedError
           
//            rx.isScan = rx.actualSr != strSr() // TODO: I'm not too sure about this
            logProgress("Receiver.\(#function) : received state = \(rxStatusAPI.state)")
        } catch {
            logError("Receiver.\(#function) : failed to decode data from SatReceiver")
        }
    }
    
    // TODO: This could be moved into startTcpSatReceiverServer(), as with the other server
    private func startQueuingRequestsToSendToSatReceiver() { // TODO: prime candidate to be an actor
        logProgress("Receiver.\(#function) : starting")
        // the idea here is to poll for when a command needs to be sent
        Task {
            while true {
                if flagDataToSend && rxIsConnected() {
                    satReceiverServer?.send(dataToSend)
                    flagDataToSend = false
                    logProgress("Receiver.\(#function) : sent data to SatReceiver")
                }
                try await Task.sleep(seconds: 0.5)
            }
        }
    }
        
    private func queueActionToSend(action: RxCommandType, freq: String = "", srs: [String] = [""]) {
        logProgress("Receiver.\(#function) : queing \(action) \(freq) \(srs) == \(freq) \(srs)")
        do {
            let request = RxCommandAPI(action: action, freq: freq, srs: srs)
            let data = try JSONEncoder().encode(request)
            // inform let sendRequestsToSatReceiver() know there is a request waiting to be sent
            dataToSend = data
            flagDataToSend = true
        } catch {
            logError("Receiver.\(#function) : failed to encode requestData")
        }
    }
    
    // most reads are read from func readLongmyd()
    func readRxStatus() -> RxStatusAPI {
        return rx
    }
    
    func setRxBandChannel(band: Int, channel: Int) {
        logProgress("Receiver.\(#function) : to \(band):\(channel)")
        if rxBand != band {
            currentSrIndex = savedSRindexesForBand[band]
            savedSRindexesForBand[band] = currentSrIndex
        }
        rxBand = band
        rxChannel = channel
        rx.freq = strRxFrequency(band: band, channel: channel)
        rx.bandChanDisplay = strBandChannel(band: band, channel: channel)
        rx.sr = symbolRatesToScan[band][currentSrIndex]
        if rx.isScan {
            queueActionToSend(action: .Configure, freq: rx.freq, srs: symbolRatesToScan[band])
        } else {
            queueActionToSend(action: .Configure, freq: rx.freq, srs: [symbolRatesToScan[band][currentSrIndex]])
        }
    }
    
    func setRxSymbolRate(direction: String = "") {
        rx.isScan = false
        currentSrIndex = savedSRindexesForBand[rxBand]
        if direction == "+" && currentSrIndex < maxSrIndexForBand[rxBand] {
            currentSrIndex += 1
        }
        if direction == "-" && currentSrIndex > 0 {
            currentSrIndex -= 1
        }
        savedSRindexesForBand[rxBand] = currentSrIndex
        setRxBandChannel(band: rxBand, channel: rxChannel)
    }
    
    func startScan() { // on the current band channel
        rx.isScan = true
        setRxBandChannel(band: rxBand, channel: rxChannel)
//        rx.isScan = false // TODO: TESTING to see if this is better, then have SatReceiver return the current sr being used
    }
    
    func calibate() {
        queueActionToSend(action: .Calibrate)
    }

}
