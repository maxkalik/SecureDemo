//
//  Session.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

enum SessionError: Error {
    case secureError(SecureError)
}

actor Session {

    let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    var user: User? {
        didSet(old) {
            if let newRandom = user?.random, old?.random != newRandom {
                dependencies.secure.executeFromQueue(newRandom)
            }
        }
    }
    
    func prepareSession() async {
        await fetchUser()
    }
    
    func fetchUser() async {
        do {
            self.user = try await dependencies.server.fetchMockedUser()
        } catch {
            print("=== 🔴 fetching user error")
        }
    }
    
    func observeUser() {
        dependencies.server.observeUser { user in
            self.user = user
        }
    }
    
    @discardableResult
    func executeSecureRequest<R: SecureRequest>(_ request: R) async throws -> R.Output? {
        guard let random = user?.random else {
            throw SessionError.secureError(.userRandom)
        }
        
        var request = request
        request.random = random
        return await debugResponse(request: request)
    }
}

// MARK: - Requests

extension Session {
    // MARK: Request One
    
    private func userRandom() throws -> Int {
        guard let random = user?.random else {
            throw SessionError.secureError(.userRandom)
        }
        
        return random
    }
    
    func postRequestOne() async throws {

        let request1x1 = Request1x1()
        try await executeSecureRequest(request1x1)

        let request1x2 = Request1x2()
        try await executeSecureRequest(request1x2)
        
        let request1x3 = Request1x3()
        try await executeSecureRequest(request1x3)
    }
    
    // MARK: Request Two
    
    func postRequestTwo() async throws -> Response2x2? {
        
        let request2x1 = Request2x1()
        try await executeSecureRequest(request2x1)
        
        let request2x2 = Request2x2()
        let response2x2 = try await executeSecureRequest(request2x2)
        
        return response2x2
    }
    
    // MARK: Request Three

    func postRequestThree() async throws {

        let request3x1 = Request3x1()
        try await executeSecureRequest(request3x1)
    }
}

// MARK: - Debug pring

extension Session {
    @discardableResult
    private func debugResponse<R: SecureRequest>(request: R) async -> R.Output? {
        do {
            guard let response = try await dependencies.secure.call(request: request) else {
                print("=== request: \(request.path) - 🔴 response is nil")
                return nil
            }
            print("=== request: \(request.path) - 🟢", response)
            return response
        } catch {
            print("=== request: \(request.path) - 🔴", error)
            return nil
        }
    }
}
