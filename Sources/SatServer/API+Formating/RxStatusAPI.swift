//  -------------------------------------------------------------------
//  File: RxStatusAPI.swift
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

enum RxStateType : String, Codable {
    case OffLine,
         Intializing,
         Searching,
         FoundHeaders,
         LockedS,
         LockedS2,
         ShuttingDown
}

struct RxStatusAPI: Codable {
    var state: RxStateType = .OffLine // TODO: not used here
    var freq = BlankFrequency
    var bandChanDisplay: String = BlankBandChannel
    var temperature = BlankTemperature
    var fanSpeed = BlankRPM
    var isScan = false
    var sr = BlankSR
    var mode = BlankMode
    var constellation = BlankConstellation
    var fec = BlankFEC
    var codecs = BlankCodecs
    var mer = ZeroMER
    var margin = BlankDMargin
    var power = BlankPower
    var provider = BlankProvider
    var service = BlankService
    var tunedFreq = BlankFrequency
    var tunedSr = BlankSR
    var tunedError = BlankTunedError
}

