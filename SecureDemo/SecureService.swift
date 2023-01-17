//
//  SecureService.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

protocol SecureRequest {
    var path: String { get }
}

struct SecureResponse {
    var status: Int
}

enum SecureError: Error {
    case userRandom
    case requestNotFound
    case error(String)
}

class SecureService {
    
    private let dependencies: Dependencies
    
    private var currentRandom: Int?
    private var requests: [SecureRequest] = [] {
        didSet {
            print("+++", requests.map { $0.path })
            // self.executeFromQueue()
        }
    }
    
    var requestCompletion: ((SecureError?, SecureResponse?) -> Void)?
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func call<R: SecureRequest>(request: R, completion: @escaping (SecureError?, SecureResponse?) -> Void) {
        requests.append(request)
        requestCompletion = completion
        executeFromQueue()
    }
    
    func executeFromQueue() {
        Task {
            guard let request = requests.first else {
                return
            }
            
//            let userRandom1 = await dependencies.session.user?.random
//            print("=== Start executing from queue | USER RANDOM: \(userRandom1) | CUR RANDOM: \(currentRandom)")
            
            // CASE 1 - USER RANDOM: nil | CURRENT RANDOM: nil
            // CASE 2 - USER RANDOM: 123 | CURRENT RANDOM: nil
            // CASE 3 - USER RANDOM: 123 | CURRENT RANDOM: 123
            // CASE 4 - USER RANDOM: 321 | CURRENT RANDOM: 123
            
            guard let userRandom = await dependencies.session.user?.random, currentRandom != userRandom else {
                requestCompletion?(nil, nil)
                // TODO: wait more?
                return
            }
            
            currentRandom = userRandom
            
            requests.removeAll { $0.path == request.path }
            
            do {
                try await dependencies.server.postRequest(random: userRandom)
                requestCompletion?(nil, SecureResponse(status: 200))
            } catch {
                requestCompletion?(.error("SECURE ERROR: Server error"), nil)
            }
        }
    }
}
