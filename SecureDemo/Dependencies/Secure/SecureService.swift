//
//  SecureService2.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/9/23.
//

import Foundation

fileprivate let maxRetries = 3

class SecureService {
    
    // This queue serves as a synchronization mechanism for the requestsQueue and expiredRandom
    // Because they could be changed from different threads using call and executeFromQueue methods
    private let accessQueue = DispatchQueue(label: "secureService.accessQueue")
    private let dependencies: Dependencies
    private var expiredRandom: [Int] = []
    private var requestsQueue: [SecureRequestCompletion] = []
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // This method just append `SecureRequestCompletion` to the queue
    // And emmidiately runs queue becase random num can be already in a user object
    public func call<R: SecureRequest>(request: R, completion: @escaping SecureRequestResult) {
        guard let random = request.random else {
            completion(.failure(.userRandom))
            return
        }
        
        let requestCompletion = SecureRequestCompletion(
            request: request,
            retries: 0,
            status: .unprocessed,
            result: completion
        )
        
        accessQueue.async {
            self.requestsQueue.append(requestCompletion)
            self.executeFromQueue(random)
        }
    }
    
    // Call this method if random num has changed (for example from session user didSet)
    public func executeFromQueue(_ random: Int) {
        accessQueue.async {
            self._executeFromQueue(random)
        }
    }
    
    // Should be called only in `accessQueue`
    private func _executeFromQueue(_ random: Int) {
        // We need only unprocessed request completions from the queue
        guard let requestCompletion = requestsQueue.first(where: { $0.status == .unprocessed }) else {
            expiredRandom.removeAll()
            return
        }
        
        // Possible cases to handle
        // CASE 1 - USER RANDOM: nil | CURRENT RANDOM: nil
        // CASE 2 - USER RANDOM: 123 | CURRENT RANDOM: nil
        // CASE 3 - USER RANDOM: 123 | CURRENT RANDOM: 123
        // CASE 4 - USER RANDOM: 321 | CURRENT RANDOM: 123
        // CASE 4 - USER RANDOM: nil | CURRENT RANDOM: 321 -> ?
        
        // Check if current random is not the same
        // If it's still the same random number then we need just quit silently
        // and wait for another call of `executeFromQueue`
        guard !expiredRandom.contains(random) else { return }
        
        // Update current random with that what was updated in user object
        self.expiredRandom.append(random)
        
        // Remove all request with the same body or path from queue
        // I know it's questionable to remove all requests with the same body
        // Instead of array we can use Set but for PoC I think that's enough
        requestsQueue.removeAll { $0.request.path == requestCompletion.request.path }

        // It captures a copy of the mutableRequestCompletion object
        // ensuring the completion block does not affect other threads
        // that may be manipulating the requestsQueue
        var mutableRequestCompletion = requestCompletion
        mutableRequestCompletion.status = .processing
        execute(request: mutableRequestCompletion.request, random: random) { result in
            switch result {
            case .success(let response):
                mutableRequestCompletion.result(.success(response))
                mutableRequestCompletion.status = .processed
            case .failure(let error):
                if mutableRequestCompletion.retries < maxRetries {
                    mutableRequestCompletion.retries += 1
                    mutableRequestCompletion.status = .unprocessed
                    self.requestsQueue.append(mutableRequestCompletion)
                    self._executeFromQueue(random)
                } else {
                    mutableRequestCompletion.result(.failure(.error("SECURE ERROR: \(error)")))
                    mutableRequestCompletion.status = .error(.error("SECURE ERROR: \(error)"))
                }
            }
        }
    }
    
    // Simulate executing request with random num
    private func execute<R: SecureRequest>(request: R, random: Int, completion: @escaping SecureRequestResult) {
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
