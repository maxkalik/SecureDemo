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
                print("--------------------------------------------------------------------------")
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
        
        // MARK: - Request 1 / 1
        
        let request1 = RequestOneOfOne()
        print("--- request 1 start \(request1.path)")
        dependencies.secure.call(request: request1) { error, response in
            if let error = error {
                print("=== request 1: \(request1.path) - 🔴", error)
                return
            }
            
            if let response = response {
                print("=== request 1: \(request1.path) - 🟢", response)
            }
            
            // MARK: - Request 1 / 2
            
            let request2 = RequestTwoOfOne()
            print("--- request 2 start \(request1.path)")
            self.dependencies.secure.call(request: request2) { error, response in
                if let error = error {
                    print("=== request 2: \(request2.path) - 🔴", error)
                    return
                }
                
                if let response = response {
                    print("=== request 2: \(request2.path) - 🟢", response)
                }
                
                // MARK: - Request 1 / 3
                
                let request3 = RequestThreeOfOne()
                print("--- request 3 start \(request1.path)")
                self.dependencies.secure.call(request: request3) { error, response in
                    if let error = error {
                        print("=== request 3: \(request3.path) - 🔴", error)
                        return
                    }
                    
                    if let response = response {
                        print("=== request 3: \(request3.path) - 🟢", response)
                    }
                }
            }
        }
    }
    
    func postRequestTwo() async throws {
        
    }
}

// MARK: - secure/1/1

struct RequestOneOfOne: SecureRequest {
    typealias Output = ResponseOneOfOne
    var path: String = "secure/1/1"
}

struct ResponseOneOfOne: SecureResponse {
    var data: String
}

// MARK: - secure/1/2

struct RequestTwoOfOne: SecureRequest {
    typealias Output = ResponseTwoOfOne
    var path: String = "secure/1/2"
}

struct ResponseTwoOfOne: SecureResponse {
    var data: String
}

// MARK: - secure/1/3

struct RequestThreeOfOne: SecureRequest {
    typealias Output = ResponseThreeOfOne
    var path: String = "secure/1/3"
}

struct ResponseThreeOfOne: SecureResponse {
    var data: String
}



// MARK: - secure/2/1

struct RequestOneOfTwo: SecureRequest {
    typealias Output = ResponseOneOfTwo
    var path: String = "secure/2/1"
}

struct ResponseOneOfTwo: SecureResponse {
    var data: String
}

// MARK: - secure/2/2

struct RequestTwoOfTwo: SecureRequest {
    typealias Output = ResponseTwoOfTwo
    var path: String = "secure/2/2"
}

struct ResponseTwoOfTwo: SecureResponse {
    var data: String
}

// MARK: - secure/2/3

struct RequestThreeOfTwo: SecureRequest {
    typealias Output = ResponseThreeOfTwo
    var path: String = "secure/2/3"
}

struct ResponseThreeOfTwo: SecureResponse {
    var data: String
}
