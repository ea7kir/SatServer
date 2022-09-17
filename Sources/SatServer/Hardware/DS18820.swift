//  -------------------------------------------------------------------
//  File: DS18820.swift
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
import SwiftyGPIO

actor DS18820 {
    private var isRunning = false
    private let onewire: OneWireInterface
    private let slaveId: String
    private let pathname: String
    private var cache: String

    init(onewire: OneWireInterface, slaveId: String) {
        self.onewire = onewire
        self.slaveId = slaveId
        self.pathname = "/sys/bus/w1/devices/" + slaveId + "/w1_slave"
        self.cache = strTemperature()
    }
    
    var temperature: String {
        if !isRunning {
            startReading()
        }
        return cache
    }
        
    private func startReading() {
        if !isReachable() {
            logError("DS1820.\(#function) : Unable to reach \(slaveId)")
            return
        }
        Task(priority: .background) {
            while true {
                await Task.yield()
                for line in onewire.readData(slaveId) {
                    //Only 2 lines expected, the 2nd one has the temp value
                    guard !line.contains("YES") else {
                        continue
                    }
                    let words = line.split{$0 == " "}.map(String.init)
                    var word = words[words.count-1]
                    word = String(word[word.index(word.startIndex, offsetBy: 2)...])
                    let t = (Double(word) ?? -273150) / 1000
                    cache = strTemperature(t)
                }
                try await Task.sleep(seconds: 5.0)
            }
        }
        isRunning = true
    }
    
    private func isReachable() -> Bool {
        let fd = open(pathname, O_RDONLY | O_SYNC)
        if fd > 0 {
            close(fd)
            return true
        }
        return false
    }
}

//final class PREV_DS18820 {
//    private let onewire: OneWireInterface
//    private let slaveId: String
//    private let pathname: String
//    private var configured = false
//
//    private var celsius = ""
//
//    init(onewire: OneWireInterface, slaveId: String) {
//        self.onewire = onewire
//        self.slaveId = slaveId
//        self.pathname = "/sys/bus/w1/devices/" + slaveId + "/w1_slave"
//    }
//
//    var temperature: String {
//        if !configured {
//            configure()
//        }
//        if configured {
//            for line in onewire.readData(slaveId) {
//                //Only 2 lines expected, the 2nd one has the temp value
//                guard !line.contains("YES") else {
//                    continue
//                }
//                let words = line.split{$0 == " "}.map(String.init)
//                var word = words[words.count-1]
//                word = String(word[word.index(word.startIndex, offsetBy: 2)...])
//                let t = (Double(word) ?? -273150) / 1000
//                celsius = strTemperature(t)
//            }
//        } else {
//            celsius = strTemperature()
//        }
//        return celsius
//    }
//
//    func configure() {
//        let fd = open(pathname, O_RDONLY | O_SYNC)
//        if fd > 0 {
//            configured = true
//            close(fd)
//        }
//    }
//}


