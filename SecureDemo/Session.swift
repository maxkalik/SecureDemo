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
                let oldRandomNum = (old?.random ?? -1)
                let oldRandom = oldRandomNum < 1 ? "nil" : "\(oldRandomNum)"
                print("=== ⚠️ SESSION: User random updated! Old: \(oldRandom) | New: \(newRandom)")
                dependencies.secure.executeFromQueue()
            }
        }
    }
    
    func prepareSession() async {
        await fetchUser()
    }
    
    func fetchUser() async {
        do {
            self.user = try await dependencies.server.fetchUser()
            if let user = self.user {
                print("session == fetched user", user)
            }
        } catch {
            print(error)
        }
    }
    
    func observeUser() {
        dependencies.server.observeUser { user in
            self.user = user
        }
    }
    
    func postRequestOne() {
        
        let request = RequestOneOfOne()
        dependencies.secure.call(request: request) { error, response in
            if let error = error {
                print("=== request: \(request.path) - 🔴", error)
                return
            }
            
            if let response = response {
                print("=== request: \(request.path) - 🟢", response)
            }
            
            let request = RequestTwoOfOne()
            self.dependencies.secure.call(request: request) { error, response in
                if let error = error {
                    print("=== request: \(request.path) - 🔴", error)
                    return
                }
                
                if let response = response {
                    print("=== request: \(request.path) - 🟢", response)
                }
                
                let request = RequestThreeOfOne()
                self.dependencies.secure.call(request: request) { error, response in
                    if let error = error {
                        print("=== request: \(request.path) - 🔴", error)
                        return
                    }
                    
                    if let response = response {
                        print("=== request: \(request.path) - 🟢", response)
                    }
                }
            }
        }
    }
    
    func postRequestTwo() async throws {
        
    }
}

struct RequestOneOfOne: SecureRequest {
    var path: String = "secure/1/1"
}

struct RequestTwoOfOne: SecureRequest {
    var path: String = "secure/1/2"
}

struct RequestThreeOfOne: SecureRequest {
    var path: String = "secure/1/3"
}

struct RequestOneOfTwo: SecureRequest {
    var path: String = "secure/2/1"
}

struct RequestTwoOfTwo: SecureRequest {
    var path: String = "secure/2/2"
}

struct RequestThreeOfTwo: SecureRequest {
    var path: String = "secure/2/3"
}
