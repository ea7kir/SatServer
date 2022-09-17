//  -------------------------------------------------------------------
//  File: Hardware.swift
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

// See SCHEMATICS.md for pin allocations

import Foundation
import SwiftyGPIO

struct Hardware {
    
    let piTemperature = PiTemperature()
    let piUptime = PiUptime()
    
    // GPIO Relays
    let relay_supply12v:    RELAY // 24v AC to 12v Contactor
    let relay_supply28v:    RELAY // 24v AC to 28v Contactor
    let relay_RxPi:         RELAY // 5v to RX Pi Vcc
    let relay_AllTxFans:    RELAY // 12v to Pluto Fan, Driver Fan, PA Fans, PA
    let relay_Pluto:        RELAY // 5v to TX Pluto Vcc
    let relay_PaDriver:     RELAY // 5v to TX Driver Vcc (PTT)
    let relay_PaBias:       RELAY // 28v to PA Bias (PTT)
    let relay_Reserved:     RELAY // reserved
    
    // GPIO Fans
    let rpiFan:             FAN // RPi Server
    let encIntakeFan:       FAN // Enclosure Intake
    let encExtractFan:      FAN // Enclosure Extract
    let reveiverFan:        FAN // MinTiouner & Pi
    let plutoFan:           FAN // Pluto
    let paDriverFan:        FAN // PA Driver
    let paIntakeFan:        FAN // PA Intake
    let paExtractFan:       FAN // PA Extract
    
    // 1-Wire Temperature Sensors
    let paDriver:           DS18820 // PA Driver
    let finalPa:            DS18820 // PA
    
    // I2C Voltage/Current Sensors
    let supply5v:           INA226 // 5v PSU
    let supply12v:          INA226 // 12v PSU
    let supply28v:          INA226 // 28v PSU
    
    // I2C Humidity/Temperature
    let enclosure:          SHT31 // Enclosure Climate
    
    
    init() {
        // get GPIOs
        let gpios =                 SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        // get 1-WIRE
        let ones =                  SwiftyGPIO.hardware1Wires(for:.RaspberryPi4)!
        // get I2Cs
        let i2cs =                  SwiftyGPIO.hardwareI2Cs(for:.RaspberryPi4)!
        
        // MARK: init GPIO Relays
        self.relay_supply12v =      RELAY(gpio: gpios[.P17]!) // pin 11 - Relay 0 - AC to Psu12v Contactor
        self.relay_supply28v =      RELAY(gpio: gpios[.P27]!) // pin 13 - Relay 1 - AC to Psu28v Contactor
        self.relay_RxPi =           RELAY(gpio: gpios[.P22]!) // pin 15 - Relay 2 - 5v to RX Pi
        self.relay_AllTxFans =      RELAY(gpio: gpios[.P10]!) // pin 19 - Relay 3 - 12v to Pluto Fan, Driver Fan, PA LH Fan, PA RH Fan
        self.relay_Pluto =          RELAY(gpio: gpios[.P9 ]!) // pin 21 - Relay 4 - 5v to Pluto Vcc
        self.relay_PaDriver =       RELAY(gpio: gpios[.P11]!) // pin 23 - Relay 5 - 5v to Driver Vcc (PTT)
        self.relay_PaBias =         RELAY(gpio: gpios[.P5 ]!) // pin 29 - Relay 6 - 28v to PA Bias (PTT)
        self.relay_Reserved =       RELAY(gpio: gpios[.P6 ]!) // pin 31 - Relay 7 - Relay7 reserved
        
        // MARK: init GPIO Fan Speeds
        self.rpiFan =               FAN(gpio: gpios[.P14]!) // pin 8  - RPi Server
        self.encIntakeFan =         FAN(gpio: gpios[.P15]!) // pin 10 - Enclosure Intake
        self.encExtractFan =        FAN(gpio: gpios[.P18]!) // pin 12 - Enclosure Extract
        self.reveiverFan =          FAN(gpio: gpios[.P23]!) // pin 16 - Receiver
        self.plutoFan =             FAN(gpio: gpios[.P24]!) // pin 18 - Pluto
        self.paDriverFan =          FAN(gpio: gpios[.P25]!) // pin 22 - PA Driver
        self.paIntakeFan =          FAN(gpio: gpios[.P8 ]!) // pin 24 - PA Intake
        self.paExtractFan =         FAN(gpio: gpios[.P7]!)  // pin 26 - PA Extract
        
        // MARK: init 1-Wire DS18B20 Temperature Sensors using default pin 7
        // Sset the slave ID for each DS18B20 TO-92 device
        // To find those available, type: cd /sys/bus/w1/devices/
        // and look for directors named like: 28-3c01d607d440
        // these are the names to enter here
        // % /sys/bus/w1/devices/
        self.paDriver =             DS18820(onewire: ones[0], slaveId: "28-3c01d607d440") // pin 7 - PA Driver
        self.finalPa =              DS18820(onewire: ones[0], slaveId: "28-3c01d607e348") // pin 7 - PA
        
        // MARK: init I2C INA226 Voltage Current Sensors
        // To discover I2C devices
        // % sudo i2cdetect -y 1
        self.supply5v =             INA226(i2c: i2cs[1], address: 0x40, shuntOhm: 0.002, maxAmp: 5)  // 5v
        self.supply12v =            INA226(i2c: i2cs[1], address: 0x41, shuntOhm: 0.002, maxAmp: 5)  // 12v
        self.supply28v =            INA226(i2c: i2cs[1], address: 0x42, shuntOhm: 0.002, maxAmp: 10) // 28v
        
        // MARK: init I2C SHT31 Enclosure Humidity & Temperature Sensor
        self.enclosure =            SHT31(i2c: i2cs[1], address: 0x44) // Enclosure Climate
    }
    
    func resetGPIOs() {
        logError("Hardware.\(#function) : NOT FULLY IMPLEMENTED")
        relay_supply12v.reset()
        relay_supply28v.reset()
        relay_RxPi.reset()
        relay_AllTxFans.reset()
        relay_Pluto.reset()
        relay_PaDriver.reset()
        relay_PaBias.reset()
        relay_Reserved.reset()
    }
}




