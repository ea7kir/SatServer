//  -------------------------------------------------------------------
//  File: PiTemperature.swift
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

actor PiTemperature {
    private let pathToThermalFile = "/sys/class/thermal/thermal_zone0/temp"
    private var isRunning = false
    private var cache: String
    
    init() {
        cache = strTemperature()
    }
    
    
    var value: String {
        if !isRunning {
            startReading()
        }
        return cache
    }
    
    private func startReading() {
        Task {
            while true {
                do {
                    await Task.yield()
                    let string = try String.init(contentsOfFile: self.pathToThermalFile)
                    let double = (string as NSString).doubleValue / 1000.0
                    cache = strTemperature(double)
                } catch {
                    logError("PiTemperature.\(#function) : reading Pi temperature")
                    cache = "ERROR" //strTemperature()
                }
                try await Task.sleep(seconds: 60.0)
            }
        }
        isRunning = true
    }
}
