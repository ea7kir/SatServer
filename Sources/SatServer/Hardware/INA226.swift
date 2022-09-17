//  -------------------------------------------------------------------
//  File: INA226.swift
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

final class INA226 {
    //    private let INA226_REG_CONFIGURATION: UInt8         = 0x00
    //    private let INA226_REG_SHUNT_VOLTAGE: UInt8         = 0x01
    //    private let INA226_REG_BUS_VOLTAGE: UInt8           = 0x02
    //    private let INA226_REG_POWER: UInt8                 = 0x03
    //    private let INA226_REG_CURRENT: UInt8               = 0x04
    //    private let INA226_REG_CALIBRATION: UInt8           = 0x05
    //    private let INA226_REG_MASK_ENABLE: UInt8           = 0x06
    //    private let INA226_REG_ALERT_LIMIT: UInt8           = 0x07
    //    private let INA226_REG_MANUFACTURER: UInt8          = 0xFE
    //    private let INA226_REG_DIE_ID: UInt8                = 0xFF
    //
    //    private let INA226_RESET: UInt16                    = 0x8000
    //    private let INA226_MASK_ENABLE_CVRF: UInt16         = 0x0008
    //
    //    private let INA226_BIT_SHUNT                        = 0
    //    private let INA226_BIT_BUS                          = 1
    //    private let INA226_BIT_MODE                         = 2
    //
    //    private let INA226_MODE_SHUNT: UInt8                = 1
    //    private let INA226_MODE_BUS: UInt8                  = 2
    //    private let INA226_MODE_TRIGGERED: UInt8            = 0
    //    private let INA226_MODE_CONTINUOUS: UInt8           = 4
    //
    //    private let INA226_MODE_OFF: UInt16                 = 0
    //    private let INA226_MODE_SHUNT_TRIGGERED: UInt16     = 1
    //    private let INA226_MODE_BUS_TRIGGERED: UInt16       = 2
    //    private let INA226_MODE_SHUNT_BUS_TRIGGERED: UInt16 = 3
    //    private let INA226_MODE_OFF2: UInt16                = 4
    //    private let INA226_MODE_SHUNT_CONTINUOUS: UInt16    = 5
    //    private let INA226_MODE_BUS_CONTINUOUS: UInt16      = 6
    //    private let INA226_MODE_SHUNT_BUS_CONTINUOUS: UInt8 = 7
    //
    //    private let INA226_TIME_01MS: UInt8                 = 0 /* 140us */
    //    private let INA226_TIME_02MS: UInt8                 = 1 /* 204us */
    //    private let INA226_TIME_03MS: UInt8                 = 2 /* 332us */
    //    private let INA226_TIME_05MS: UInt8                 = 3 /* 588us */
    //    private let INA226_TIME_1MS: UInt8                  = 4 /* 1.1ms */
    //    private let INA226_TIME_2MS: UInt8                  = 5 /* 2.115ms */
    //    private let INA226_TIME_4MS: UInt8                  = 6 /* 4.156ms */
    //    private let INA226_TIME_8MS: UInt8                  = 7 /* 8.244ms */
    //
    //    private let INA226_AVERAGES_1: UInt8                = 0
    //    private let INA226_AVERAGES_4: UInt8                = 1
    //    private let INA226_AVERAGES_16: UInt8               = 2
    //    private let INA226_AVERAGES_64: UInt8               = 3
    //    private let INA226_AVERAGES_128: UInt8              = 4
    //    private let INA226_AVERAGES_256: UInt8              = 5
    //    private let INA226_AVERAGES_512: UInt8              = 6
    //    private let INA226_AVERAGES_1024: UInt8             = 7
    
    private let i2c: I2CInterface
    private let address: Int
    private let shuntOhm: Double
    private let maxAmp: Double
    private var reachable = false
    private var currentLSBs: Double = 0
    private var configured = false
    
    private let INA226_TIME_8MS: UInt8 = 7 /* 8.244ms */
    private let INA226_AVERAGES_16: UInt8 = 2
    private let INA226_MODE_SHUNT_BUS_CONTINUOUS: UInt8 = 7
    private let INA226_REG_BUS_VOLTAGE: UInt8 = 0x02
    private let INA226_REG_CURRENT: UInt8 = 0x04
    
    private var volts: Double = 0.0
    private var amps: Double = 0.0
    
    public init(i2c: I2CInterface, address: Int, shuntOhm: Double, maxAmp:Double) {
        self.i2c = i2c
        self.address = address
        self.shuntOhm = shuntOhm
        self.maxAmp = maxAmp
    }
    
    var supply: String {
        if !configured {
            reachable = i2c.isReachable(address)
            if reachable {
                reset(i2c: i2c, address: address)
                configure(i2c: i2c, address: address, shuntOhm: shuntOhm, maxAmp: maxAmp,
                          bus: INA226_TIME_8MS,
                          shunt: INA226_TIME_8MS,
                          average: INA226_AVERAGES_16,
                          mode: INA226_MODE_SHUNT_BUS_CONTINUOUS)
                configured = true            }
        }
        if reachable && configured {
            let voltageReg = Int16( i2c.readWord(address, command: INA226_REG_BUS_VOLTAGE).byteSwapped )
            volts = Double(voltageReg) * 0.00125
            usleep(1_000)
            let currentReg: Int16 = Int16( i2c.readWord(address, command: INA226_REG_CURRENT).byteSwapped )
            amps = Double(currentReg) * currentLSBs
        } else {
            volts = 0
            amps = 0
        }
        return strSupply(volts, amps)
    }
    
    private func reset(i2c: I2CInterface, address: Int) {
        let INA226_REG_CONFIGURATION: UInt8 = 0x00
        let INA226_RESET: UInt16 = 0x8000
        i2c.writeWord(address, command: INA226_REG_CONFIGURATION, value: INA226_RESET.byteSwapped)
    }
    
    private func configure(i2c: I2CInterface, address: Int, shuntOhm: Double,
                           maxAmp: Double, bus: UInt8, shunt: UInt8, average: UInt8, mode: UInt8) {
        let INA226_REG_CALIBRATION: UInt8 = 0x05
        let INA226_REG_CONFIGURATION: UInt8 = 0x00
        // Calibrate
        currentLSBs = /* max_current / (1 << 15) */ maxAmp / Double(1 << 15)
        let calib: Double = 0.00512 / (currentLSBs * shuntOhm)
        let calibReg: UInt16 = UInt16(floor(calib))
        currentLSBs = /* 0.00512 / (r_shunt * calib_reg) */ 0.00512 / (shuntOhm * Double(calibReg))
        i2c.writeWord(address, command: INA226_REG_CALIBRATION, value: calibReg.byteSwapped)
        // Configure
        let configReg = (UInt16(average) << 9) | (UInt16(bus) << 6) | (UInt16(shunt) << 3) | UInt16(mode)
        i2c.writeWord(address, command: INA226_REG_CONFIGURATION, value: configReg.byteSwapped)
    }
    
    // MARK: Working, but not used
    
    //    private func disable() {
    //        let INA226_MODE_OFF: UInt16 = 0
    //        let INA226_REG_CONFIGURATION: UInt8 = 0x00
    //        i2c.writeWord(address, command: INA226_REG_CONFIGURATION, value: INA226_MODE_OFF.byteSwapped)
    //    }
    //    private func manID() -> UInt16 {
    //        let INA226_REG_MANUFACTURER: UInt8 = 0xFE
    //        return UInt16( i2c.readWord(address, command: INA226_REG_MANUFACTURER).byteSwapped )
    //    }
    //
    //    private func dieID() -> UInt16 {
    //        let INA226_REG_DIE_ID: UInt8 = 0xFF
    //        return UInt16( i2c.readWord(address, command: INA226_REG_DIE_ID).byteSwapped )
    //    }
}

