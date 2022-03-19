# SatController

![SatController](Images/Screenshot.png)

## Description

SatController, together with [SatServer](https://github.com/ea7kir/SatServer), will be a system for controlling and monitoring a Digital Amateur Television (DATV) equipment over a wired local area network.

## Platform

* Apple iMac
* macOS 12 (Monterery)
* Swift 5.5 (included with Xcode)

## Implementation

Both Controller and Server are written in Swift, with Swift-NIO for the networking.  The server runs as a service on the latest 64-bit version of raspOS.  The controller is a desktop application with a SwiftUI user interface on an Apple iMac.  Transmitted audio & video is sourced internally from the Mac version of OBS. Received audio & video can be monitored with VNC on the iMac or an Apple TV and HDMI television. All other equipment (transmitter, power amplifier, receiver, power supplies, peripherals and ancillaries) are situated outdoors - weather protected and close to the antennas.

## Supported Devices

- Power Supplies
- Cooling Fans
- Various Sensors
- ADALM-Pluto Transmitter
- RF Power Amplifier
- BATC-MiniTiouner Receiver
- Etc, etc.

## Current Status

**THIS IS WORK IN PROGRESS AND SOME OF MY HARDWARE IS WAITING FOR OUT OF STOCK COMPONENTS**

All the sensors, relays and fan speed detection is working.

Obviously, valid data will only be displayed if external hardware is connected.

Next major changes will include more concurrency and revising the network protocol.

## Acknowledgements

- Members of the BATC [batc.org.uk](https://batc.org.uk)
- Swift-NIO [github.com/apple/swift-nio](https://github.com/apple/swift-nio)
- Swift Community [swift.org](https://swift.org)

## License

Copyright (C) 2021 Michael Naylor EA7KIR https://michaelnaylor.es

SatController is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

SatController is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with SatController.  If not, see <https://www.gnu.org/licenses/>.
