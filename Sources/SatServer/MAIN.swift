//  -------------------------------------------------------------------
//  File: MAIN.swift
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
import Yams

let logProgress = false
let logErrors = true

func logProgress(_ str: String) {
    if logProgress {
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = format.string(from: date)
        print("\(timestamp) - \(str)")
    }
}

func logError(_ str: String) {
    if logErrors {
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = format.string(from: date)
        print("\(timestamp) - ERROR: \(str)")
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

// YAML from https://github.com/jpsim/Yams
struct YAMLConfig: Codable {
    var satControllerPort = 8001
    var satReceiverPort = 8002
    var note = "set state to: simplex | duplexRx | duplexTx"
    var beacon = false
    var state = "simplex"
    var simplexBand = 2
    var simplexChannel = 14
    var duplexRXBand = 2
    var duplexRXChannel = 11
    var duplexTXBand = 2
    var duplexTXChannel = 13
    var provider = "EA7KIR"
    var service = "Malaga"
}

func readYAML() -> YAMLConfig {
    var config = YAMLConfig()
    let filename = "/home/pisat/configSatServer.yaml"
    
    do {
        // read configuration
        let yaml = try String(contentsOfFile: filename)
        let decoder = YAMLDecoder()
        config = try decoder.decode(YAMLConfig.self, from: yaml)
    } catch {
        // write default YAML configuration
        logProgress("MAIN.\(#function) : creating default configuration file")
        let defaultConfig = YAMLConfig()
        let encoder = YAMLEncoder()
        let encodedYAML = try! encoder.encode(defaultConfig)
        do {
            try encodedYAML.write(toFile: filename, atomically: true, encoding: .utf8)
        } catch {
            logError("MAIN.\(#function) : failed to write to: \(filename)")
            fatalError()
        }
    }
    return config
}

func invalidBandChannel(band: Int, channel: Int) -> Int {
    var invaild = 0
    switch band {
    case 1:
        if !(1...27).contains(channel) {
            print("ERROR: illegal channel \(channel) for band 1 in configSatServer.yaml")
            invaild += 1
        }
    case 2:
        if !(1...14).contains(channel) {
            print("ERROR: illegal channel \(channel) for band 2 in configSatServer.yaml")
            invaild += 1
        }
    case 3:
        if !(1...3).contains(channel) {
            print("ERROR: illegal channel \(channel) for band 3 in configSatServer.yaml")
            invaild += 1
        }
    default:
        print("ERROR: illegal band \(band) in configSatServer.yaml")
        invaild += 1
        
    }
    return invaild
}

func invalidState(state: String) -> Int {
    var invaild = 0
    if !(["simplex", "duplexRx", "duplexTx"].contains(state)) {
        print("ERROR: ilegal state: \"\(state)\" in configSatServer.yaml")
        invaild += 1
    }
    return invaild
}

var signalReceived: sig_atomic_t = 0

enum RunState {
    case running, rebooting, shuttingdown, interupted, stopped
}
var runState: RunState = .running

@main
struct MAIN {
    static func main() {
//#if os(Linux)
        let config = readYAML()
        let errCount = invalidBandChannel(band: config.simplexBand, channel: config.simplexChannel) +
            invalidBandChannel(band: config.duplexRXBand, channel: config.duplexRXChannel) +
            invalidBandChannel(band: config.duplexTXBand, channel: config.duplexTXChannel) +
            invalidState(state: config.state)
        if errCount > 0 {
            exit(0)
        }

        signal(SIGTERM) { signal in signalReceived = SIGTERM }
        signal(SIGINT) { signal in signalReceived = SIGINT }
        print("MAIN.\(#function) : starting as \(config.provider) @ \(config.service)")
        let systemControl = SystemControl(with: config)

        print("StaServer run state: \(runState)")
        
        while runState != .stopped {
            while runState == .running {
                switch signalReceived {
                case SIGINT:
                    runState = .interupted
                case SIGTERM:
                    runState = .shuttingdown
                default:
                    break // do nothing
                }
                
                switch runState {
                case .running:
                    break
                case .rebooting:
                    logProgress("MAIN.\(#function) : About to reboot")
                    systemControl.cleanup()
                    logProgress("MAIN.\(#function) : Will reboot")
                    piReboot()
                    runState = .stopped
                case .shuttingdown:
                    logProgress("MAIN.\(#function) : About to shutdown")
                    systemControl.cleanup()
                    logProgress("MAIN.\(#function) : Will shutdown")
                    piShutdown()
                    runState = .stopped
                case .interupted:
                    logProgress("MAIN.\(#function) : About to stop")
                    systemControl.cleanup()
                    logProgress("MAIN.\(#function) : Will stop")
                    runState = .stopped
                case .stopped:
                    break
                }
            }
            sleep(1)
        }
        print("MAIN.\(#function) : Has stopped with runState:\(runState)")
//#else
//        print("SatServer can only run on Linux")
//#endif
        sleep(1)
        exit(0)
    }
}

