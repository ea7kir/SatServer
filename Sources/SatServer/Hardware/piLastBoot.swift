//  -------------------------------------------------------------------
//  File: piLastBoot.swift
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

func piLastBoot() -> String {
    do {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["uptime","--since"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.standardInput = nil
        
        try process.run()
        // logProgress("PiLastBoot.\(#function) just before waitUntilExit()")
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        process.waitUntilExit()
        
        let str = output
        
        // "2022-04-18 12:22:19\n"
        let uptime_since = str!
        let start = uptime_since.index(uptime_since.startIndex, offsetBy: 0)
        let end = uptime_since.index(uptime_since.endIndex, offsetBy: -4)
        let range = start..<end
        let upSince = uptime_since[range]
        return String(upSince)
    } catch {
        logError("PiLastBoot.\(#function) : reading uptime --since")
        return "ERROR"
    }
}
