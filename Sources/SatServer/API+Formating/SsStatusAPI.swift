//  -------------------------------------------------------------------
//  File: SsStatusAPI.swift
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

struct SsStatusAPI: Codable {
    var url = "-"
    var temperature = BlankTemperature
    var fanSpeed = BlankRPM
    var encClimate = BlankClimate
    var encFanSpeeds = Blank2RPM
    var supply5v = BlankSupply
    var supply12v = BlankSupply
    var supply28v = BlankSupply
    var psu12vIsOn = false
    var psu28vIsOn = false
    var lastBoot = BlankLastBoot
    var upTime = BlankUpTime
}
