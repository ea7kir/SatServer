//  -------------------------------------------------------------------
//  File: NIO_Cory_Server.swift
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

struct ServerFactory {
    static func listen(host: String, port: Int, _ connectionCallback: @escaping (NIO_Cory_Server) -> Void) throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            try! group.syncShutdownGracefully()
        }
        
        let bootstrap = ServerBootstrap(group: group)
            .childChannelInitializer { channel in
                // channel.pipeline.syncOperations.addHandler(Server.ServerHandler())
                try! channel.pipeline.syncOperations.addHandler(NIO_Cory_Server.ServerHandler())
                let server = NIO_Cory_Server(channel: channel)
                connectionCallback(server)
                return channel.eventLoop.makeSucceededVoidFuture()
            }
        let channel = try bootstrap.bind(host: host, port: port).wait()
        
        // Park the main thread here.
        try channel.closeFuture.wait()
    }
}

final class NIO_Cory_Server {
    typealias DataCallback = (Data) -> Void
    
    // private final class ServerHandler: ChannelInboundHandler {
    internal final class ServerHandler: ChannelInboundHandler {
        typealias InboundIn = ByteBuffer
        
        fileprivate var dataCallback: DataCallback?
        
        init() {
            self.dataCallback = nil
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let buffer = self.unwrapInboundIn(data)
            self.dataCallback?(Data(buffer: buffer))
        }
    }
    
    private let channel: Channel
    
    // This hides the existence of the `ServerHandler` class but allows us to expose the property we want to let the user set.
    // We use `preconditionInEventLoop` here because this operation is not thread-safe: you must only set this from the event
    // loop thread.
    var dataCallback: DataCallback? {
        get {
            self.channel.eventLoop.preconditionInEventLoop()
            return try! self.channel.pipeline.syncOperations.handler(type: ServerHandler.self).dataCallback
        }
        set {
            self.channel.eventLoop.preconditionInEventLoop()
            try! self.channel.pipeline.syncOperations.handler(type: ServerHandler.self).dataCallback = newValue
        }
    }
    
    init(channel: Channel) {
        self.channel = channel
    }
    
    var isConnected: Bool {
        return self.channel.isActive
    }
    
    func send(_ data: Data) {
        self.channel.writeAndFlush(ByteBuffer(data: data), promise: nil)
    }
    
    func disconnect() {
        self.channel.close(promise: nil)
    }
}

