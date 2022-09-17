//  -------------------------------------------------------------------
//  File: BandPlan.swift
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

// The 2021 version 3 Qatar-OSCAR 100 Wide Band Plan.
// https://wiki.batc.org.uk/QO-100_WB_Bandplan
// https://wiki.batc.org.uk/images/a/a2/QO-100_WB_Bandplan_V3.pdf

import Foundation

// Transmit/Receive Frequency Band                    1   2   3   Beacon
//let TCH00 = "----.---"; let RCH00 = "10491.500" //                0
//let TCH01 = "2403.250"; let RCH01 = "10492.750" //    1   2
//let TCH02 = "2403.500"; let RCH02 = "10493.000" //    1
//let TCH03 = "2403.750"; let RCH03 = "10493.250" //    1   2   3
//let TCH04 = "2404.000"; let RCH04 = "10493.500" //    1
//let TCH05 = "2404.250"; let RCH05 = "10493.750" //    1   2
//let TCH06 = "2404.500"; let RCH06 = "10494.000" //    1
//let TCH07 = "2404.750"; let RCH07 = "10494.250" //    1   2
//let TCH08 = "2405.000"; let RCH08 = "10494.500" //    1
//let TCH09 = "2405.250"; let RCH09 = "10494.750" //    1   2   3
//let TCH10 = "2405.500"; let RCH10 = "10495.000" //    1
//let TCH11 = "2405.750"; let RCH11 = "10495.250" //    1   2
//let TCH12 = "2406.000"; let RCH12 = "10495.500" //    1
//let TCH13 = "2406.250"; let RCH13 = "10495.750" //    1   2
//let TCH14 = "2406.500"; let RCH14 = "10496.000" //    1
//let TCH15 = "2406.750"; let RCH15 = "10496.250" //    1   2   3
//let TCH16 = "2407.000"; let RCH16 = "10496.500" //    1
//let TCH17 = "2407.250"; let RCH17 = "10496.750" //    1   2
//let TCH18 = "2407.500"; let RCH18 = "10497.000" //    1
//let TCH19 = "2407.750"; let RCH19 = "10497.250" //    1   2
//let TCH20 = "2408.000"; let RCH20 = "10497.500" //    1
//let TCH21 = "2408.250"; let RCH21 = "10497.750" //    1   2
//let TCH22 = "2408.500"; let RCH22 = "10498.000" //    1
//let TCH23 = "2408.750"; let RCH23 = "10498.250" //    1   2
//let TCH24 = "2409.000"; let RCH24 = "10498.250" //    1
//let TCH25 = "2409.250"; let RCH25 = "10498.750" //    1   2
//let TCH26 = "2409.500"; let RCH26 = "10499.000" //    1
//let TCH27 = "2409.750"; let RCH27 = "10499.250" //    1   2

let bandName = ["Beacon", "VeryNarrow", "Narrow", "Wide"]
let rxFrequency: [[Int]] = [
    [10491500],
    
    [0, 10492750, 10493000, 10493250, 10493500, 10493750, 10494000 ,10494250, 10494500, 10494750,
        10495000, 10495250, 10495500, 10495750, 10496000, 10496250, 10496500, 10496750, 10497000,
        10497250, 10497500, 10497750, 10498000, 10498250, 10498250, 10498750, 10499000, 10499250],
    
    [0, 10492750,           10493250,           10493750,           10494250,           10494750,
        10495250,           10495750,           10496250,           10496750,           10497250,
        10497750,           10498250,           10498750,           10499250],
    
    [0,                     10493250,                                                   10494750,
                                                          10496250]
]
let txFrequency: [[Int]] = [
    [0],
    
    [0, 2403250,  2403500,  2403750,  2404000,  2404250,  2404500,  2404750,  2405000,  2405250,
        2405500,  2405750,  2406000,  2406250,  2406500,  2406750,  2407000,  2407250,  2407500,
        2407750,  2408000,  2408250,  2408500,  2408750,  2409000,  2409250,  2409500,  2409750],
    
    [0, 2403250,            2403750,            2404250,            2404750,            2405250,
        2405750,            2406250,            2406750,            2407250,            2407750,
        2408250,            2408750,            2409250,            2409750],
    
    [0,                     2403750,                                                    2405250,
                                                          2406750]
]

func strBandChannel(band: Int = -1, channel: Int = -1) -> String {
    return band >= 0 ? "\(bandName[band]) Channel \(channel)" : BlankBandChannel
}

func strRxFrequency(band: Int = -1, channel: Int = -1) -> String {
    if band >= 0 {
        let f = rxFrequency[band][channel]
        return "\(f / 1000).\(f % 1000)"
    }
    return BlankFrequency
}

func strTxFrequency(band: Int = -1, channel: Int = -1) -> String {
    if band >= 0 {
        let f = txFrequency[band][channel]
        return "\(f / 1000).\(f % 1000)"
    }
    return BlankFrequency
}

// Symbol Rate
let SR25 = "25"
let SR33 = "33"
let SR66 = "66"
let SR125 = "125"
let SR250 = "250"
let SR333 = "333"
let SR500 = "500"
let SR1000 = "1000"
let SR1500 = "1500"

// Forward Error Correction
let FEC12 = "1/2"
let FEC23 = "2/3"
let FEC34 = "3/4"
let FEC45 = "4/5"
let FEC56 = "5/6"
let FEC67 = "6/7"
let FEC78 = "7/8"
let FEC89 = "8/9"

// Mode
let DVB_S    = "DVB-S"
let DVB_S2   = "DVB-S2"

// Codecs
let H264_ACC = "H264 ACC"
let H265_ACC = "H265 ACC"

// Constellations
let sQPSK  = "QPSK"
let s8PSK  = "8PSK"
let s16PSK = "16PSK"
let s32PSK = "32PSK"

//// Band Names
//let sBeacon     = "Beacon"
//let sVeryNarrow = "VeryNarrow"
//let sNarrow     = "Narrow"
//let sWide       = "Wide"

// valid band and channel numbers
// band 0 = Beacon, channel 0 (receive only)
// band 1 = VeryNarrow, channels 1 through 27
// band 2 = Narrow, channels 1 3 5 7 9 11 13 15 17 19 21 23 25 27
// band 3 = Wide, channels 3 9 15

// band 0 SR and FEC

//struct BeaconChannel {
//    let sr = [SR1500]
//    let fec = [FEC45]
//}
//
//// band 1 SR and FEC
//
//struct VeryNarrorChannel_1_27 {
//    let sr = [SR33,SR66,SR125]
//    let fec = [FEC12,FEC23,FEC34,FEC45,FEC56,FEC67,FEC78,FEC89]
//}
//
//// band 2a SR and FEC
//
//struct NarrowChannel_1_9 {
//    let sr = [SR250,SR333,SR500]
//    let fec = [FEC12,FEC23,FEC34,FEC45,FEC56,FEC67,FEC78,FEC89]
//}
//
//// band 2b  SR and FEC
//
//struct NarrowChannel_10_14 {
//    let sr = [SR250,SR333]
//    let fec = [FEC12,FEC23,FEC34,FEC45,FEC56,FEC67,FEC78,FEC89]
//}
//
//// band 3  SR and FEC
//
//struct WideChannel_1_3 {
//    let sr = [SR1000,SR1500]
//    let fec = [FEC12,FEC23,FEC34,FEC45,FEC56,FEC67,FEC78,FEC89]
//}
