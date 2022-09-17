//  -------------------------------------------------------------------
//  File: Formating.swift
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

let BlankLastBoot = "-"
let BlankUpTime = "-"
let BlankFrequency = "-----.---"
let BlankBandChannel = "-------"
let ZeroTemperature = "--.-"
let BlankTemperature = "--.- °C"
let BlankTwinTemperature = "--.- --.- °C"
let BlankRH = "--"
let ZeroRPM = "----"
let BlankRPM = "---- RPM"
let Blank2RPM = "---- ---- RPM"
let ZeroVolts = "--.--"
let ZeroAmps = "--.--"
let BlankSupply = "--.-- V --.-- A"
let BlankClimate = "-- %RH --.- °C"
let BlankDrive = "-"
let ZeroMER = "-.-"
let BlankDMargin = "D -.-"
let BlankMargin = "-.-"
let BlankPower = " ---"
let BlankSR = "-"
let BlankMode = "-"
let BlankConstellation = "-"
let BlankFEC = "-/-"
let BlankCodec = "-"
let BlankCodecs = "- -"
let BlankProvider = "-"
let BlankService = "-"
let BlankTunedError = "ϵ ±0 kHz"

func strTemperature(_ t: Double = 0) -> String {
    "\(t > 0 ? String(format: "%4.1f", t) :  ZeroTemperature) °C"
}

func strTwoTemperatures(_ a: Double = 0, _ b: Double = 0) -> String {
    "\(a > 0 ? String(format: "%4.1f", a) :  ZeroTemperature) \(b > 0 ? String(format: "%4.1f", b) :  ZeroTemperature) °C"
}

func strClimate(_ h: Double = 0, _ t: Double = 0) -> String {
    "\(h > 0 ? String(format: "%4.0f", h) : BlankRH) %RH \(t > 0 ? String(format: "%4.1f", t) : ZeroTemperature) °C"
}

func strFanSpeed(_ v: Int = 0) -> String {
    "\(v > 0 ? String(format: "%04i", v) : ZeroRPM) RPM"
}

func strTwoFanSpeeds(_ a: Int = 0, _ b: Int = 0) -> String {
    "\(a > 0 ? String(format: "%04i", a) : ZeroRPM) \(b > 0 ? String(format: "%04i", b) : ZeroRPM) RPM"
}

func strSupply(_ v: Double = 0, _ a: Double = 0) -> String {
    "\(v > 0.005 ? String(format: "%05.2f", v) : ZeroVolts) V \(a > 0.005 ? String(format: "%05.2f", a) : ZeroAmps) A"
}

func strMer(_ m: Double = 0) -> String {
    "\(m > 0 ? String(format: "%3.1f", m) : ZeroMER)"
}

func strMargin(_ m: Double = 0) -> String {
    "D \(m > 0 ? String(format: "%3.1f", m) : BlankMargin)"
}

func strPower(_ p: Int = 0, over: Bool = false) -> String {
    "\(p < 0 ? String(format: over ? ">%3i" : "%3i", p) : BlankPower)"
}

func strSr(_ s: Double = 0) -> String {
    "\(s > 0 ? String(format: "%.1f", s) : BlankSR)"
}

func strMode(_ v: String = "") -> String { !v.isEmpty ? v : BlankMode }

func strConstellation(_ v: String = "") -> String { !v.isEmpty ? v : BlankConstellation }

func strFec(_ v: String = "") -> String { !v.isEmpty ? v : BlankFEC }

func strCodecs(_ v: String = "", _ a: String = "") -> String { "\(v.isEmpty ? BlankCodec : v) \(a.isEmpty ? BlankCodec : a)" }

func strProvider(_ v: String = "") -> String { !v.isEmpty ? v : BlankProvider }

func strService(_ v: String = "") -> String { !v.isEmpty ? v : BlankService }

func strTunedFrequency(_ f: Double = 0) -> String {
    return "\(f > 0 ? String(format: "%09.3f", f) : BlankFrequency)"
//    return f > 0 ? "\(f / 1000).\(f % 1000)" : BlankFrequency
}

func strTunedError(_ v: Double = 0) -> String {
    let i = Int(v)
    if i == 0 { return BlankTunedError }
    if i > 0 { return "ϵ +\(i) kHz" }
    return "ϵ -\(i) kHz"
}
