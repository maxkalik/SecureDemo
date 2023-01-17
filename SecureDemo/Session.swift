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
    
    func postRequestOne(completion: @escaping () -> Void) {
        
        // MARK: - Request 1 / 1
        
        let request1 = Request1x1()
        dependencies.secure.call(request: request1) { error, response in
            self.debugResponse(request: request1, error: error, response: response)
            
            // MARK: - Request 1 / 2
            
            let request2 = Request1x2()
            self.dependencies.secure.call(request: request2) { error, response in
                self.debugResponse(request: request2, error: error, response: response)
                
                // MARK: - Request 1 / 3
                
                let request3 = Request1x3()
                self.dependencies.secure.call(request: request3) { error, response in
                    self.debugResponse(request: request3, error: error, response: response)
                    
                    completion()
                }
            }
        }
    }
    
    func postRequestTwo(completion: @escaping (Response2x2) -> Void) {
        let request = Request2x1()
        self.dependencies.secure.call(request: request) { error, response in
            self.debugResponse(request: request, error: error, response: response)
            
            let request = Request2x2()
            self.dependencies.secure.call(request: request) { error, response in
                self.debugResponse(request: request, error: error, response: response)
                if let response = response as? Response2x2 {
                    completion(response)
                }
            }
        }
    }
    
    func postRequestThree(completion: @escaping () -> Void) {
        let request = Request3x1()
        self.dependencies.secure.call(request: request) { error, response in
            self.debugResponse(request: request, error: error, response: response)
            
            completion()
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
