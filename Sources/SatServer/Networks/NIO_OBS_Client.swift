//  -------------------------------------------------------------------
//  File: NIO_OBS_Client.swift
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
import NIOCore
import NIOPosix
import NIOFoundationCompat

final class NIO_OBS_Client {
    var connected = false
    
    init() {
    }
    
    func connect(host: String, port: Int) {
        connected = true
    }
    
    func isConnected() -> Bool {
        return connected
    }
    
    func disconnect() {
        connected = false
    }
    
    func send(cmd: String) {
        logProgress("NIO_OBS_Client.\(#function) : sent to OBS: \(cmd)")
        print("Sent to OBS: \(cmd)")
    }
        
}
