//
//  ServerMock.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation
import Combine

enum ServerError: Error {
    case expiredRandom
    case badRequest
}

class ServerSimulator {

    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    private var currentRandom: Int {
        Int.random(in: 1000000...9000000)
    }
    
    private lazy var user: User = User(random: currentRandom) {
        didSet {
            userUpdatedClosure?(user)
        }
    }
    
    private var userUpdatedClosure: ((User?) -> Void)?
    
    private var expiredRandoms: [Int] = []
    
    private func updateRandom() {
        expiredRandoms.append(user.random)
        Task {
            let randomSec = UInt64.random(in: 3_000_000_000...5_000_000_000)
            try await Task.sleep(nanoseconds: randomSec)
            user.random = currentRandom
        }
    }
    
    func fetchMockedUser(completion: @escaping (User?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(self.user)
        }
    }
    
    func middleware(body: [String: String], completion: (String, ServerError?) -> Void) {
        guard let randomStr = body["random"],
              let random = Int(randomStr),
              !expiredRandoms.contains(random) else {
            completion("", .expiredRandom)
            return
        }
        
        updateRandom()
        
        guard let path = body["path"] else {
            completion("", .badRequest)
            return
        }
        
        completion(path, nil)
    }
    
    func postRequest(body: [String: String], completion: (Data?, ServerError?) -> Void) {

        middleware(body: body) { path, error in
            if let error {
                completion(nil, error)
            } else {
                completion(["data": "Some server data for request \(path)"].toJSON(), nil)
            }
        }
    }
    
    func postRequest(body: [String: String]) -> Future<Data?, ServerError> {
        Future { promise in
            self.postRequest(body: body) { data, error in
                if let data {
                    promise(.success(data))
                } else if let error {
                    promise(.failure(error))
                } else {
                    promise(.failure(.badRequest))
                }
            }
        }
    }
    
    func observeUser(completion: @escaping (User?) -> Void) {
        self.userUpdatedClosure = completion
    }
}
