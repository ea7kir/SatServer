# SatServer

## Description

SatServer, together with [SatController](https://github.com/ea7kir/SatController), will be a system for controlling and Digital Amateur Television (DATV) equipment over a wired local area network.

## Platform

- Raspberry Pi 4 (mine has 8 GB of memory)
- Raspberry Pi OS Lite Arm 64 (Bullseye)
- Swift 5.5


## Implementation

Both Controller and Server are written in Swift, with Swift-NIO for the networking.  The server runs as a service on the latest 64-bit version of Raspberry Pi OS Lite.  The controller is a desktop application with a SwiftUI user interface on an Apple iMac.  Transmitted audio & video is sourced internally from the Mac version of OBS. Received audio & video can be monitored with VNC on the iMac or an Apple TV and HDMI television. All other equipment (transmitter, power amplifier, receiver, power supplies, peripherals and ancillaries) are situated outdoors - weather protected and close to the antennas.

## Supported Devices

- Power Supplies
- Cooling Fans
- Various Sensors
- ADALM-Pluto Transmitter
- RF Power Amplifier
- BATC Advanced Receiver
- Etc, etc.

NOTE: Hardware.swift contains more information, includng which Pi pin numbers are used.

## Current Status

- Fetching the status is taking to long for the response handler.
- Raspberry Pi interupts (used to measure fan speed) maybe causing segmention errors.
- Need to implement better and more concurrency.

**THIS IS WORK IN PROGRESS AND SOME HARDWARE HAS NOT BEEN BUILT OR TESTED**

NOTE: Returned data will be diplayed as question marks or random numbers when hardware devices are not connected.

## Futher Reading

- INSTALLING.md - how to configure the Raspberry Pi
- CONNECTING.md - how to connect the relays and sensors

## Acknowledgements

- Swift-Arm [swift-arm.com)](https://swift-arm.com)
- Swift-NIO [github.com/apple/swift-nio](https://github.com/apple/swift-nio)
- SwiftyGPIO [github.com/uraimo/SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO)
- Swift Community [swift.org](https://swift.org)

## License

Copyright (C) 2021 Michael Naylor EA7KIR http://michaelnaylor.es

SatServer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

SatServer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with SatServer.  If not, see <https://www.gnu.org/licenses/>.
