//
//  Session.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation
import Combine

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
                // dependencies.secure2.executeFromQueue(newRandom)
                dependencies.secureCombine.executeFromQueue(newRandom)
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
    
    nonisolated func executeSecureRequest<R: SecureRequest>(_ request: R, completion: @escaping (R.Output?) -> Void) {
        Task {
            guard let random = await user?.random else {
                completion(nil)
                print("=== 🔴 user random nil")
                return
            }
            
            var request = request
            request.random = random
            
            debugResponse(request: request, completion: completion)
        }
    }
    
    nonisolated func executeSecureRequest<R: SecureRequest>(_ request: R) -> AnyPublisher<R.Output, SessionError> {

        guard let random = dependencies.user.userSubject.value?.random else {
            return Fail(error: .secureError(.userRandom)).eraseToAnyPublisher()
        }
        
        var request = request
        request.random = random
        
        return dependencies.secureCombine.call(request: request)
            .mapError {
                print("=== request: \(request.path) - 🔴", $0)
                return SessionError.secureError($0)
            }
            .map {
                print("=== request: \(request.path) - 🟢", $0)
                return $0
            }
            .first()
            .eraseToAnyPublisher()
    }
}

// MARK: - Requests

extension Session {
    // MARK: Request One
    
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

// MARK: - With Completions

extension Session {
    
    nonisolated func postRequestOne(completion: @escaping () -> Void) {

        let request1x1 = Request1x1()
        executeSecureRequest(request1x1) { _ in
            
            let request1x2 = Request1x2()
            self.executeSecureRequest(request1x2) { _ in

                let request1x3 = Request1x3()
                self.executeSecureRequest(request1x3) { _ in
                    completion()
                }
            }
        }
    }
    
    // MARK: Request Two
    
    nonisolated func postRequestTwo(completion: @escaping (Response2x2?) -> Void) {
        
        let request2x1 = Request2x1()
        executeSecureRequest(request2x1) { _ in
            
            let request2x2 = Request2x2()
            self.executeSecureRequest(request2x2, completion: completion)
        }
    }
    
    // MARK: Request Three

    nonisolated func postRequestThree(completion: @escaping () -> Void) {

        let request3x1 = Request3x1()
        executeSecureRequest(request3x1) { _ in
            completion()
        }
    }
}

// MARK: - Combine

extension Session {
    
    nonisolated func postRequestOne() -> AnyPublisher<(), SessionError> {
        
        let request1x1 = Request1x1()
        let request1x2 = Request1x2()
        let request1x3 = Request1x3()
        
        return executeSecureRequest(request1x1)
            .flatMap { _ in self.executeSecureRequest(request1x2) }
            .flatMap { _ in self.executeSecureRequest(request1x3) }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    nonisolated func postRequestTwo() -> AnyPublisher<Response2x2, SessionError> {
        
        let request2x1 = Request2x1()
        let request2x2 = Request2x2()
        
        return executeSecureRequest(request2x1)
            .flatMap { _ in self.executeSecureRequest(request2x2) }
            .eraseToAnyPublisher()
    }
    
    nonisolated func postRequestThree() -> AnyPublisher<(), SessionError> {
        
        let request3x1 = Request3x1()
        
        return executeSecureRequest(request3x1)
            .map { _ in () }
            .eraseToAnyPublisher()
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

    nonisolated private func debugResponse<R: SecureRequest>(request: R, completion: @escaping (R.Output?) -> Void) {
        dependencies.secure2.call(request: request) { result in
            switch result {
            case .success(let response):
                completion(response as? R.Output)
                if let response {
                    print("=== request: \(request.path) - 🟢", response)
                } else {
                    print("=== request: \(request.path) - 🔴 response is nil")
                }
            case .failure(let error):
                print("=== request: \(request.path) - 🔴", error)
                completion(nil)
            }
        }
    }
}
