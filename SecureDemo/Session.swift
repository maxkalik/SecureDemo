//
//  Session.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

actor Session {

    let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    var user: User? {
        didSet(old) {
            if let newRandom = user?.random, old?.random != newRandom {
                // It can be implemented with Notification
                dependencies.secure.executeFromQueue()
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
}

// MARK: - Requests

extension Session {
    // MARK: Request One
    
    func postRequestOne() async {
        let request1x1 = Request1x1()
        await debugResponse(request: request1x1)
        
        let request1x2 = Request1x2()
        await debugResponse(request: request1x2)
        
        let request1x3 = Request1x3()
        await debugResponse(request: request1x3)
    }
    
    // MARK: Request Two
    
    func postRequestTwo() async -> Response2x2? {
        let request2x1 = Request2x1()
        await debugResponse(request: request2x1)
        
        let request2x2 = Request2x2()
        let response2x2 = await debugResponse(request: request2x2)
        return response2x2 as? Response2x2
    }
    
    // MARK: Request Three

    func postRequestThree() async {
        let request3x1 = Request3x1()
        await debugResponse(request: request3x1)
    }
}

// MARK: - Debug pring

extension Session {
    @discardableResult
    private func debugResponse<R: SecureRequest>(request: R) async -> SecureResponse? {
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
