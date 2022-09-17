//  -------------------------------------------------------------------
//  File: SHT31.swift
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

// MARK: Syncronous version

final class SHT31 {
    private let i2c: I2CInterface
    private let address: Int
    private var reachable: Bool
    private enum SHT31Error: Error {
        case invalidDataLength
        case invalidTemperatureChecksum
        case invalidHumidityChecksum
    }
    private var configured = false

    init(i2c: I2CInterface, address: Int) {
        self.i2c = i2c
        self.address = address
        self.reachable = false
    }
    
    var climate: String {
        if !configured {
            configure()
        }
        var t: Double = 0
        var h: Double = 0
        if i2c.isReachable(address) {
            do {
                (t, h) = try measuredTandRH()
                configured = true
            } catch {
                logError("SHT31.\(#function) : \(error)")
            }
        }
        return strClimate(h, t)
    }
    
    private func configure() {
        reachable = i2c.isReachable(address)
        if reachable {
            // soft reset
            i2c.writeByte(address, command: 0x30, value: 0xA2)
        }
    }
    
    private func measuredTandRH() throws -> (temperature: Double, humidity: Double) {
        // Single Shot Medium Stretch 0x2C 0x0D
        let data: [UInt8] = i2c.writeAndRead(address, write: [0x2C, 0x0D], readLength: 6)
        guard data.count == 6 else {
            throw SHT31Error.invalidDataLength
        }
        guard crc8(data: data, range: 0...1) == data[2] else {
            throw SHT31Error.invalidTemperatureChecksum
        }
        guard crc8(data: data, range: 3...4) == data[5] else {
            throw SHT31Error.invalidHumidityChecksum
        }
        let t16: UInt16 = (UInt16(data[0]) << 8) + UInt16(data[1])
        let h16: UInt16 = (UInt16(data[3]) << 8) + UInt16(data[5])
        let temperature: Double = -45 + 175 * ( Double(t16) / 0xFFFF )
        let humidity: Double = 100 * ( Double(h16) / 0xFFFF )
        return (temperature, humidity)
    }
    
    private func crc8(data: [UInt8], range: ClosedRange<Int>) -> UInt8 {
        let Polynomial: UInt8 = 0x31
        var crc: UInt8 = 0xFF
        
        for i in range {
            crc ^= data[i]
            for _ in 0...7 {
                crc = (crc & 0x80 == 0x80) ? (crc << 1) ^ Polynomial : (crc << 1)
            }
        }
        return crc
    }
}
