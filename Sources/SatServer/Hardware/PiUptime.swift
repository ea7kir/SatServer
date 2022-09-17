//  -------------------------------------------------------------------
//  File: PiUptime.swift
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

actor PiUptime {
    private var isRunning = false
    private var cache: String

    init() {
        self.cache = "ERROR"
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
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
                    process.arguments = ["uptime","--pretty"]
                    let pipe = Pipe()
                    process.standardOutput = pipe
                    process.standardError = pipe
                    process.standardInput = nil
                    
                    try process.run()
                    //logProgress("PiUptime.\(#function) just before waitUntilExit()")
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)
                    process.waitUntilExit()

                    let str = output
                    
                    let uptime_pretty = str!
                    let start = uptime_pretty.index(uptime_pretty.startIndex, offsetBy: 3)
                    let end = uptime_pretty.index(uptime_pretty.endIndex, offsetBy: -1)
                    let range = start..<end
                    cache = String(uptime_pretty[range])
                } catch {
                    logError("PiUptime.\(#function) : reading Pi uptime")
                    cache = "ERROR" //strTemperature()
                }
                await Task.yield()
                try await Task.sleep(seconds: 60.0)
            }
        }
        isRunning = true
    }
}
