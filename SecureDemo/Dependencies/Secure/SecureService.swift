//
//  SecureService2.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/9/23.
//

import Foundation

enum SecureRequestStatus: Equatable {
    case unprocessed
    case processing
    case processed
    case error(SecureError)
}

struct SecureRequestCompletion {
    var request: any SecureRequest
    var status: SecureRequestStatus
    var completion: SecureResultCompletion
}

class SecureService {
    
    private let dependencies: Dependencies
    private var expiredRandom: [Int] = []
    private var requestsQueue: [SecureRequestCompletion] = []
    private let accessQueue = DispatchQueue(label: "secureService.accessQueue")
    private var pendingRequests: [String: SecureRequestCompletion] = [:]
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // This method just append `SecureRequestCompletion` to the queue
    // And emmidiately runs queue becase random num can be already in a user object
    public func call<R: SecureRequest>(request: R, completion: @escaping SecureResultCompletion) {
        guard let random = request.random else {
            completion(.failure(.userRandom))
            return
        }
        
        let requestCompletion = SecureRequestCompletion(
            request: request,
            status: .unprocessed,
            completion: completion
        )
        
        accessQueue.async {
            self.requestsQueue.append(requestCompletion)
            self.pendingRequests[request.path] = requestCompletion
            self.executeFromQueue(random)
        }
    }
    
    // Call this method if random num has changed (for example from session user didSet)
    public func executeFromQueue(_ random: Int) {
        accessQueue.async {
            self._executeFromQueue(random)
        }
    }
    
    private func _executeFromQueue(_ random: Int) {
        guard let requestCompletion = self.requestsQueue.first(where: { $0.status == .unprocessed }) else {
            self.expiredRandom.removeAll()
            return
        }
        
        // Possible cases to handle
        // CASE 1 - USER RANDOM: nil | CURRENT RANDOM: nil
        // CASE 2 - USER RANDOM: 123 | CURRENT RANDOM: nil
        // CASE 3 - USER RANDOM: 123 | CURRENT RANDOM: 123
        // CASE 4 - USER RANDOM: 321 | CURRENT RANDOM: 123
        // CASE 4 - USER RANDOM: nil | CURRENT RANDOM: 321 -> ?
        
        // Check if current random is not the same
        guard !self.expiredRandom.contains(random) else {
            print("=== QUIT:", requestsQueue.map { $0.request.path })
            return
        }
        
        // Update current random with that what was updated in user object
        self.expiredRandom.append(random)
        
        // Remove all request with the same body or path from queue
        // I know it's questionable to remove all requests with the same body
        // Instead of array we can use Set but for PoC I think that's enough
        requestsQueue.removeAll { $0.request.path == requestCompletion.request.path }
        
        
        var mutableRequestCompletion = requestCompletion
        mutableRequestCompletion.status = .processing
        execute(request: mutableRequestCompletion.request, random: random) { result in
            switch result {
            case .success(let response):
                mutableRequestCompletion.completion(.success(response))
                mutableRequestCompletion.status = .processed
            case .failure(let error):
                mutableRequestCompletion.completion(.failure(.error("SECURE ERROR: \(error)")))
                mutableRequestCompletion.status = .error(.error("SECURE ERROR: \(error)"))
            }
            self.pendingRequests[mutableRequestCompletion.request.path] = nil
        }
    }
    
    // Simulate executing request with random num
    private func execute<R: SecureRequest>(request: R, random: Int, completion: @escaping SecureResultCompletion) {
        let requestBody = [
            "random": String(random),
            "path": request.path
        ]
        
        dependencies.server.postRequest(body: requestBody) { data, error in
            if let data {
                do {
                    let response = try JSONDecoder().decode(R.Output.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(.error("JSON DECODING ERROR: \(error)")))
                }
            } else if let error {
                completion(.failure(.error("SERVER ERROR: \(error)")))
            } else {
                completion(.failure(.error("SERVER UNKNOWN ERROR")))
            }
        }
    }
}
