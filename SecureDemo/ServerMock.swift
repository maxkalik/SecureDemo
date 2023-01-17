//
//  ServerMock.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

struct User {
    let username: String = "maxpro"
    var random: Int?
}

enum ServerError: Error {
    case expiredRandom
}

class ServerMock {

    let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        
        updateRandom()
    }

    private var user: User = User() {
        didSet {
            userUpdatedClosure?(user)
        }
    }
    
    private var userUpdatedClosure: ((User?) -> Void)?
    
    private var expiredRandoms: [Int] = []
    
    private func updateRandom() {
        if let random = user.random {
            expiredRandoms.append(random)
        }
        Task {
            let randomSec = UInt64.random(in: 3_000_000_000...5_000_000_000)
            try await Task.sleep(nanoseconds: randomSec)
            let random = Int.random(in: 1000000...9000000)
            user.random = random
            print("=== SERVER ==> user random updated", user)
        }
    }
    
    func fetchUser() async throws -> User? {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return self.user
    }
    
    func postRequest(random: Int) async throws {
        guard !expiredRandoms.contains(random) else {
            throw ServerError.expiredRandom
        }
        
        // TODO: execute request if random is different
        
        updateRandom()
    }
    
    func observeUser(completion: @escaping (User?) -> Void) {
        self.userUpdatedClosure = completion
    }
}
