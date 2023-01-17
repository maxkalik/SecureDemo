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
            print(error)
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
    func postRequestOne(completion: @escaping () -> Void) {
        let request1 = Request1x1()
        dependencies.secure.call(request: request1) { result in
            self.debugResponse(request: request1, result: result)
            
            let request2 = Request1x2()
            self.dependencies.secure.call(request: request2) { result in
                self.debugResponse(request: request2, result: result)
                
                let request3 = Request1x3()
                self.dependencies.secure.call(request: request3) { result in
                    self.debugResponse(request: request3, result: result)
                    
                    completion()
                }
            }
        }
    }
    
    func postRequestTwo(completion: @escaping (Response2x2) -> Void) {
        let request = Request2x1()
        self.dependencies.secure.call(request: request) { result in
            self.debugResponse(request: request, result: result)
            
            let request = Request2x2()
            self.dependencies.secure.call(request: request) { result in
                self.debugResponse(request: request, result: result)
                
                switch result {
                case .success(let response):
                    if let response = response as? Response2x2 {
                        completion(response)
                    }
                case .failure:
                    return
                }
            }
        }
    }
    
    func postRequestThree(completion: @escaping () -> Void) {
        let request = Request3x1()
        self.dependencies.secure.call(request: request) { result in
            self.debugResponse(request: request, result: result)
            
            completion()
        }
    }
}

// MARK: - Debug pring

extension Session {
    private func debugResponse<R: SecureRequest>(request: R, result: Result<SecureResponse?, SecureError>) {
        switch result {
        case .success(let response):
            guard let response = response else { return }
            print("=== request: \(request.path) - 🟢", response)
        case .failure(let error):
            print("=== request: \(request.path) - 🔴", error)
        }
    }
}
