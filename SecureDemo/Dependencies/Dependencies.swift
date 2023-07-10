//
//  Dependencies.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

protocol Dependencies:
    HasSession,
    HasUser,
    HasServer,
    HasSecure2,
    HasSecureCombine
{ }

class AppDependencies: Dependencies {
    
    init() {
        user.start()
    }
    
    lazy var session: Session = .init(dependencies: self)
    lazy var user: UserService = .init(dependencies: self)
    lazy var server: ServerSimulator = .init(dependencies: self)
    lazy var secure2: SecureService = .init(dependencies: self)
    lazy var secureCombine: SecureServiceCombine = .init(dependencies: self)
}

protocol HasSession {
    var session: Session { get set }
}

protocol HasUser {
    var user: UserService { get set }
}

protocol HasServer {
    var server: ServerSimulator { get set }
}

protocol HasSecure2 {
    var secure2: SecureService { get set }
}

protocol HasSecureCombine {
    var secureCombine: SecureServiceCombine { get set }
}
