//
//  Dependencies.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

protocol Dependencies: HasSession, HasServer, HasSecure {
    
}

class AppDependencies: Dependencies {
    lazy var session: Session = Session(dependencies: self)
    lazy var server: ServerMock = ServerMock(dependencies: self)
    lazy var secure: SecureService = SecureService(dependencies: self)
}

protocol HasSession {
    var session: Session { get set }
}

protocol HasServer {
    var server: ServerMock { get set }
}

protocol HasSecure {
    var secure: SecureService { get set }
}
