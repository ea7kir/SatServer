//  -------------------------------------------------------------------
//  File: FAN.swift
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

final class FAN {
    private let gpio: GPIO
    private var localSpeed: Int = 0
    private var configured = false

    actor Cached {
        private var localValue = Int(0)
        var value: Int { localValue }
        func update(_ v: Int) { localValue = v }
    }
    
    private let cached = Cached()
    
    init(gpio: GPIO) {
        self.gpio = gpio
    }
    
    var speed: Int {
        if !configured {
            configure()
        }
        Task { self.localSpeed = await cached.value }
        return localSpeed
    }
    
    private func configure() {
        gpio.direction = .IN
        // TODO: Try .up and .down
//         gpio.pull = .up
        readSpeed()
        configured = true
    }
    
    private func readSpeed() {
        Task { //}(priority: .low) {
            var curTime = UInt64(0)
            var endTime = UInt64(0)
            var onState = false
            var rpm = 0
            while true {
                await Task.yield()
                curTime = DispatchTime.now().uptimeNanoseconds
                endTime = curTime + 1_000_000_000
                onState = false
                rpm = 0
                while curTime < endTime {
                    if gpio.value == 0 {
                        // SwiftGPIO interupts don't work for me
                        if onState == false {
                            onState = true
                            // this is equivalent to increment by 1 and then
                            // dividing the tototal by 2 and multipying by 60
                            // i.e. total = (total / 2) * 60
                            rpm += 30
                        }
                    } else {
                        onState = false
                    }
                    curTime = DispatchTime.now().uptimeNanoseconds
                }
                await cached.update(rpm)
                try await Task.sleep(seconds: 1.0)
            }
        }
    }
}
