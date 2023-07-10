//
//  Session.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation
import Combine

class Session {

    let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // Requests for Button One
    let request1x1 = Request1x1()
    let request1x2 = Request1x2()
    let request1x3 = Request1x3()
    
    // Requests for Button Two
    let request2x1 = Request2x1()
    let request2x2 = Request2x2()
    
    // Requests for Button Three
    let request3x1 = Request3x1()
}

// MARK: - Requests With Completions

extension Session {
    
    // MARK: Requests Button One
    func postRequestOne(completion: @escaping () -> Void) {
        executeSecureRequest(request1x1) { _ in
            self.executeSecureRequest(self.request1x2) { _ in
                self.executeSecureRequest(self.request1x3) { _ in
                    completion()
                }
            }
        }
    }
    
    // MARK: Requests Button Two
    func postRequestTwo(completion: @escaping (Response2x2?) -> Void) {
        executeSecureRequest(request2x1) { _ in
            self.executeSecureRequest(self.request2x2, completion: completion)
        }
    }
    
    // MARK: Requests Button Three
    func postRequestThree(completion: @escaping () -> Void) {
        executeSecureRequest(request3x1) { _ in
            completion()
        }
    }
}

// MARK: - Requests With Combine

extension Session {
    
    // MARK: Requests Button One
    func postRequestOne() -> AnyPublisher<(), SessionError> {
        executeSecureRequest(request1x1)
            .flatMap { _ in self.executeSecureRequest(self.request1x2) }
            .flatMap { _ in self.executeSecureRequest(self.request1x3) }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // MARK: Requests Button Two
    func postRequestTwo() -> AnyPublisher<Response2x2, SessionError> {
        executeSecureRequest(request2x1)
            .flatMap { _ in self.executeSecureRequest(self.request2x2) }
            .eraseToAnyPublisher()
    }
    
    // MARK: Requests Button Three
    func postRequestThree() -> AnyPublisher<(), SessionError> {
        executeSecureRequest(request3x1)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
