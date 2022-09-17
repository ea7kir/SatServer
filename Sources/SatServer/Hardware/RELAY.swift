//  -------------------------------------------------------------------
//  File: RELAY.swift
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

final class RELAY {
    private let gpio: GPIO
    // the 8-way relay card uses invertetd logica levesl, so 1 == off and 0 = on
    private let OFF = 1
    private let ON  = 0

    init(gpio: GPIO) {
        self.gpio = gpio
        gpio.direction = .OUT
        gpio.value = OFF
    }

    var isOn: Bool {
        gpio.value == ON
    }

//    func turn(_ to: Bool) {
//        gpio.value = to ? ON : OFF
//    }
    
    func turnOn() {
        gpio.value = ON
    }
    
    func turnOff() {
        gpio.value = OFF
    }
    
    func reset() {
        gpio.direction = .IN
    }
}
