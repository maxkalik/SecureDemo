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
                print("--------------------------------------------------------------------------")
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
        
        let request1 = Request1of1()
        dependencies.secure.call(request: request1) { error, response in
            self.debugResponse(request: request1, error: error, response: response)
            
            // MARK: - Request 1 / 2
            
            let request2 = Request2of1()
            self.dependencies.secure.call(request: request2) { error, response in
                self.debugResponse(request: request2, error: error, response: response)
                
                // MARK: - Request 1 / 3
                
                let request3 = Request3of1()
                self.dependencies.secure.call(request: request3) { error, response in
                    self.debugResponse(request: request3, error: error, response: response)
                }
            }
        }
    }
    
    func postRequestTwo() {
        let request = Request1of2()
        self.dependencies.secure.call(request: request) { error, response in
            self.debugResponse(request: request, error: error, response: response)
            
            let request = Request2of2()
            self.dependencies.secure.call(request: request) { error, response in
                self.debugResponse(request: request, error: error, response: response)
            }
        }
    }
    
    func postRequestThree() {
        let request = Request1of3()
        self.dependencies.secure.call(request: request) { error, response in
            self.debugResponse(request: request, error: error, response: response)
        }
    }
    
    private func debugResponse<R: SecureRequest>(request: R, error: SecureError?, response: SecureResponse?) {
        if let error = error {
            print("=== request: \(request.path) - 🔴", error)
            return
        }
        
        if let response = response {
            print("=== request: \(request.path) - 🟢", response)
        }
    }
}

// MARK: - secure/1/1

struct Request1of1: SecureRequest {
    typealias Output = Response1of1
    var path: String = "secure/1/1"
}

struct Response1of1: SecureResponse {
    var data: String
}

// MARK: - secure/1/2

struct Request2of1: SecureRequest {
    typealias Output = Response2of1
    var path: String = "secure/1/2"
}

struct Response2of1: SecureResponse {
    var data: String
}

// MARK: - secure/1/3

struct Request3of1: SecureRequest {
    typealias Output = Response3of1
    var path: String = "secure/1/3"
}

struct Response3of1: SecureResponse {
    var data: String
}



// MARK: - secure/2/1

struct Request1of2: SecureRequest {
    typealias Output = Response1of2
    var path: String = "secure/2/1"
}

struct Response1of2: SecureResponse {
    var data: String
}

// MARK: - secure/2/2

struct Request2of2: SecureRequest {
    typealias Output = Response2of2
    var path: String = "secure/2/2"
}

struct Response2of2: SecureResponse {
    var data: String
}




// MARK: - secure/3/1

struct Request1of3: SecureRequest {
    typealias Output = Response1of3
    var path: String = "secure/3/1"
}

struct Response1of3: SecureResponse {
    var data: String
}
