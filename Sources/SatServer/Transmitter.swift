//  -------------------------------------------------------------------
//  File: Transmitter.swift
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

// For General Use
fileprivate let NONE = "-" // This allow compatability with the Receiver.swift

final class Transmitter {

    private let symbolRateArray: [[String]] = [
        [NONE],
        [NONE,SR25,SR33,SR66,SR125],
        [NONE,SR250,SR333,SR500],
        [NONE,SR1000,SR1500]]
    private var symbolRateIndex: [Int]
    
    private let modeArray: [[String]] = [
        [NONE],
        [NONE, DVB_S, DVB_S2],
        [NONE, DVB_S, DVB_S2],
        [NONE, DVB_S, DVB_S2]]
    private var modeIndex = [Int]()
    
    private let constellationArray: [[String]] = [
        [NONE], // TODO: Limit to custom & prctice
        [NONE,sQPSK,s8PSK,s16PSK,s32PSK],
        [NONE,sQPSK,s8PSK,s16PSK,s32PSK],
        [NONE,sQPSK,s8PSK,s16PSK,s32PSK]]
    private var constellationIndex: [Int]
    
    private let fecArray: [[String]] = [
        [NONE], // TODO: Limit to custom & prctice
        [NONE,FEC12,FEC23,FEC34,FEC45,FEC56,FEC67,FEC78,FEC89],
        [NONE,FEC12,FEC23,FEC34,FEC45,FEC56,FEC67,FEC78,FEC89],
        [NONE,FEC12,FEC23,FEC34,FEC45,FEC56,FEC67,FEC78,FEC89]]
    private var fecIndex: [Int]
    
    private let codecsArray: [[String]] = [
        [NONE], // TODO: Link these to OBS
        [NONE,H264_ACC,H265_ACC],
        [NONE,H264_ACC,H265_ACC],
        [NONE,H264_ACC,H265_ACC]]
    private var codecsIndex: [Int]
    
    private let driveArray: [[String]] = [
        [NONE], // TODO: increase range to "0"..."-71"
        [NONE,"-10","-9","-8","-7","-6","-5","-4","-3","-2","-1","0"],
        [NONE,"-10","-9","-8","-7","-6","-5","-4","-3","-2","-1","0"],
        [NONE,"-10","-9","-8","-7","-6","-5","-4","-3","-2","-1","0"]]
    // [NONE,"0","-1","-2","-3","-4","-5","-6","-7","-8","-9","-10","-11","-12","-13","-14","-15","-16","-17","-18","-19","-20"],
    //[NONE,"0","-1","-2","-3","-4","-5","-6","-7","-8","-9","-10","-11","-12","-13","-14","-15","-16","-17","-18","-19","-20"],
    //        [NONE,"0","-1","-2","-3","-4","-5","-6","-7","-8","-9","-10","-11","-12","-13","-14","-15","-16","-17","-18","-19","-20"]]
    private var driveIndex: [Int]
    
    private let obsClient: NIO_OBS_Client
    
    private var tx = TxStatusAPI()
    
    private var txBand = 0 // fix in start()
    private var txChannel = 0 // fix in start()

    // TODO: move these to YANL as Int
    private let defaultSrForBand_0 = 0
    private let defaultSrForBand_1 = 4 // SR125
    private let defaultSrForBand_2 = 2 // SR333
    private let defaultSrForBand_3 = 1 // SR1000

    private let defaultModeForBand_0 = 0
    private let defaultModeForBand_1 = 2 // DVB_S2
    private let defaultModeForBand_2 = 2 // DVB_S2
    private let defaultModeForBand_3 = 2 // DVB_S2

    private let defaultConstellationForBand_0 = 0
    private let defaultConstellationForBand_1 = 1 // QPSK
    private let defaultConstellationForBand_2 = 1 // QPSK
    private let defaultConstellationForBand_3 = 1 // QPSK

    private let defaultFecForBand_0 = 0
    private let defaultFecForBand_1 = 2 // FEC23
    private let defaultFecForBand_2 = 2 // FEC23
    private let defaultFecForBand_3 = 2 // FEC323

    private let defaultCodecsForBand_0 = 0
    private let defaultCodecsForBand_1 = 1 // H264_ACC
    private let defaultCodecsForBand_2 = 1 // H264_ACC
    private let defaultCodecsForBand_3 = 1 // H264_ACC

    private let defaultDriveForBand_0 = 0
    private let defaultDriveForBand_1 = 11 // -10
    private let defaultDriveForBand_2 = 11 // -10
    private let defaultDriveForBand_3 = 11 // -10
    
    init(config: YAMLConfig) {
        tx.provider = config.provider
        tx.service = config.service

        self.symbolRateIndex = [defaultSrForBand_0,
                                defaultSrForBand_1,
                                defaultSrForBand_2,
                                defaultSrForBand_3]
        self.modeIndex = [defaultModeForBand_0,
                          defaultModeForBand_1,
                          defaultModeForBand_2,
                          defaultModeForBand_3]
        self.constellationIndex = [defaultConstellationForBand_0,
                                   defaultConstellationForBand_1,
                                   defaultConstellationForBand_2,
                                   defaultConstellationForBand_3]
        self.fecIndex = [defaultFecForBand_0,
                         defaultFecForBand_1,
                         defaultFecForBand_2,
                         defaultFecForBand_3]
        self.codecsIndex = [defaultCodecsForBand_0,
                            defaultCodecsForBand_1,
                            defaultCodecsForBand_2,
                            defaultCodecsForBand_3]
        self.driveIndex = [defaultDriveForBand_0,
                           defaultDriveForBand_1,
                           defaultDriveForBand_2,
                           defaultDriveForBand_3]
        
        self.obsClient = NIO_OBS_Client()
    }
    
    func connect(host: String, port: Int) { // TODO: currently called when 28v is switched
        // TODO: add delays
        // TODO: figure out if we're talking to Pluto or OBS or both ????????????????
        // TODO: maybe we need ipFromString() and pingOnce.sh
        obsClient.connect(host: host, port: port) // or "rtmp://192.168.2.1:7272")
    }
    
    private func send(cmd: String) {
        obsClient.send(cmd: cmd)
    }
    
    func shutdown() {
        // TODO: this where we should dispbale PTT
        Task {
            send(cmd: "sudo poweroff")
            try await Task.sleep(seconds: 1.0)
            obsClient.disconnect()
        }
    }
    
    func CALLBACKFROM_TransmitterServer(data: Data) {
        // TODO: Read Pluto temperatures amd put this code somewhere else
        // actor
        //        send(cmd: "get temperature")
        // hoping to read a sys file on the Pluto
        // https://wiki.analog.com/university/tools/pluto/users/temp
        // https://github.com/analogdevicesinc/plutosdr_scripts/blob/master/pluto_temp.sh
        // send(command: "./pluto_temp.sh PLUTO_IP")
        // returns 'pluto: 40.4 °C      zynq: 55.4 °C'
        let pluto = 0.0 // Double.random(in: 40.0...45.0)
        let zynq = 0.0 // Double.random(in: 50.0...55.0)
        tx.plutoTemperatures = strTwoTemperatures(pluto, zynq)
    }
    
    func readTxStatus() -> TxStatusAPI {
        CALLBACKFROM_TransmitterServer(data: Data()) // TODO: ONLY FOR TESTING
        return tx
    }
    
    func setTxBandChannel(band: Int, channel: Int) {
        txBand = band
        txChannel = channel
        tx.frequency = strTxFrequency(band: band, channel: channel)
        tx.bandChanDisplay = strBandChannel(band: band, channel: channel)
        tx.sr = symbolRateArray[band][symbolRateIndex[band]]
        tx.mode = modeArray[band][modeIndex[band]]
        tx.constellation = constellationArray[band][constellationIndex[band]]
        tx.fec = fecArray[band][fecIndex[band]]
        tx.codecs = codecsArray[band][codecsIndex[band]]
        tx.drive = driveArray[band][driveIndex[band]]
    }
    
    func setTxSymbolRate(direction: String) {
//        cancelPttIfEngaged()
        if direction == "+" && symbolRateIndex[txBand] < symbolRateArray[txBand].endIndex - 1 {
            symbolRateIndex[txBand] = symbolRateIndex[txBand] + 1
        }
        if direction == "-" && symbolRateIndex[txBand] > 1 {
            symbolRateIndex[txBand] = symbolRateIndex[txBand] - 1
        }
        tx.sr = symbolRateArray[txBand][symbolRateIndex[txBand]]
    }
    
    func setTxMode(direction: String) {
//        cancelPttIfEngaged()
        if direction == "+" && modeIndex[txBand] < modeArray[txBand].endIndex - 1 {
            modeIndex[txBand] = modeIndex[txBand] + 1
        }
        if direction == "-" && modeIndex[txBand] > 1 {
            modeIndex[txBand] = modeIndex[txBand] - 1
        }
        tx.mode = modeArray[txBand][modeIndex[txBand]]
    }
    
    func setTxConstellation(direction: String) {
//        cancelPttIfEngaged()
        if direction == "+" && constellationIndex[txBand] < constellationArray[txBand].endIndex - 1 {
            constellationIndex[txBand] = constellationIndex[txBand] + 1
        }
        if direction == "-" && constellationIndex[txBand] > 1 {
            constellationIndex[txBand] = constellationIndex[txBand] - 1
        }
        tx.constellation = constellationArray[txBand][constellationIndex[txBand]]
    }
    
    func setTxFec(direction: String) {
//        cancelPttIfEngaged()
        if direction == "+" && fecIndex[txBand] < fecArray[txBand].endIndex - 1 {
            fecIndex[txBand] = fecIndex[txBand] + 1
        }
        if direction == "-" && fecIndex[txBand] > 1 {
            fecIndex[txBand] = fecIndex[txBand] - 1
        }
        tx.fec = fecArray[txBand][fecIndex[txBand]]
    }
    
    func setTxCodecs(direction: String) {
//        cancelPttIfEngaged()
        if direction == "+" && codecsIndex[txBand] < codecsArray[txBand].endIndex - 1 {
            codecsIndex[txBand] = codecsIndex[txBand] + 1
        }
        if direction == "-" && codecsIndex[txBand] > 1 {
            codecsIndex[txBand] = codecsIndex[txBand] - 1
        }
        tx.codecs = codecsArray[txBand][codecsIndex[txBand]]
    }
    
    func setTxDrive(direction: String) {
        // TODO: is it possible to adjust the Pluto drive during PTT ?
        if direction == "+" && driveIndex[txBand] < driveArray[txBand].endIndex - 1 {
            driveIndex[txBand] = driveIndex[txBand] + 1
        }
        if direction == "-" && driveIndex[txBand] > 1 {
            driveIndex[txBand] = driveIndex[txBand] - 1
        }
        tx.drive = driveArray[txBand][driveIndex[txBand]]
    }
    
    // MARK: prepare pluto for PTT
    
    func isBusy() -> Bool {
        return tx.ptt
    }
    
    func lockParametersIntoPluto() {
        tx.ptt = true
        let PLUTO_IP = ipFromString("pluto.local")
        let PLUTO_Port = "7272"
        /*
         The order and type of events (and possoble time delays) are currently unknown.
         
         PLUTO Configuration from BATC Wiki
         https://wiki.batc.org.uk/Custom_DATV_Firmware_for_the_Pluto
         
         Example stream to Pluto
         URL : rtmp://192.168.2.1:7272/,437,DVBS2,QPSK,333,23,Pass : ,EA7KIR,
         
         example...
         Frequency:  in MHz: 437
         Mode:  (DVBS/DVBS2): DVBS2
         Constellation:  (QPSK,8PSK,16APSK): QPSK (only QPSK is valid in DVBS)
         SymbolRate:  in KS (33-2000): 333
         FEC: (12,23,34,67,78...): 23
         CALLSIGN: EA7KIR
         */
        func formatFec(_ fec: String) -> String {
            let component = fec.components(separatedBy: "/")
            return component[0] + component[1]
        }
        
        // Frequency in Mhz
        let frequency: String       = tx.frequency
        // Mode [ DVBS | DVBS2 ]
        let mode: String            = tx.mode
        // Constelation: [ QPSK | 8PSK | 16APSK ] only QPSK in valid in DVBS
        let constellation: String   = tx.constellation
        // SymbolRate in KS [ 33...2000 ]
        let synbolRate: String      = tx.sr
        // FEC [ 12 | 23 | 34 | 67 | 78... ]
        let fec: String             = formatFec(tx.fec)
        // Gain in dB [ -71...0 ]
        let gain: String            = tx.drive
        
        // Advanced parameters
        
        // CalibrationMode: [ calib | nocalib ] force a calibration process (high spike) with calib
        let calibrationMode: String = "nocalib"
        // PCR/PTS delay [ 100...2000 ] default 600. If encoding suffers from underflow, increase this
        let pcrPtsDelay: String     = "800"
        // Audio transcoding bitrate. Audio bitrate from OBS could not go down below 64kbit, this is used to workaround that
        let audioBitRate: String    = "32"
        // Callsign
        let provider = tx.provider
        // let service = tx.service
        
        // Eg: "rtmp://192.168.1.40:7272/,2409.75,DVBS2,QPSK,333,23,-2,nocalib,800,32,/,EA7KIR,"
        let cmdStr = "\(PLUTO_IP):\(PLUTO_Port)/,\(frequency),\(mode),\(constellation),\(synbolRate),\(fec),\(gain),\(calibrationMode),\(pcrPtsDelay),\(audioBitRate),/,\(provider),"
        send(cmd: cmdStr)
    }
    
    func unlockPlutoParameters() {
        send(cmd: "standdown")
        tx.ptt = false
    }
    
}
