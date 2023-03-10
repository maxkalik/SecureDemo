//
//  SecureService.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/16/23.
//

import Foundation

protocol SecureRequest: Codable {
    associatedtype Output: SecureResponse
    var path: String { get }
    var random: Int? { get set }
}

protocol SecureResponse: Codable {
    var data: String { get }
}

enum SecureError: Error {
    case userRandom
    case requestNotFound
    case error(String)
}

typealias SecureCompletion = (Result<SecureResponse?, SecureError>) -> Void
typealias SecureRequestCompletion = (request: any SecureRequest, completion: SecureCompletion?)

class SecureService {
    
    private let dependencies: Dependencies
    private var expiredRandom: [Int] = []
    private var queue: [SecureRequestCompletion] = []
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    // This method just append `SecureRequestCompletion` to the queue
    // And emmidiately runs queue becase random num can be already in a user object
    func call<R: SecureRequest>(request: R, completion: @escaping (Result<SecureResponse?, SecureError>) -> Void) {
        guard let random = request.random else {
            completion(.failure(.userRandom))
            return
        }
        queue.append((request, completion))
        executeFromQueue(random)
    }
    
    @discardableResult
    func call<R: SecureRequest>(request: R) async throws -> R.Output? {
        try await withCheckedThrowingContinuation { continuation in
            call(request: request) { result in
                continuation.resume(with: result)
            }
        } as? R.Output
    }
    
    // Call this method if random num has changed (for example from session user didSet)
    func executeFromQueue(_ random: Int) {
        Task {
            // Check if we have something to execute in the queue
            guard let requestCompletion = queue.first else {
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
            guard !expiredRandom.contains(random) else {
                print("=== QUIT:", queue.map { $0.request.path })
                return
            }

            // Update current random with that what was updated in user object
            expiredRandom.append(random)
            

            // Remove all request with the same body or path from queue
            // I know it's questionable to remove all requests with the same body
            // Instead of array we can use Set but for PoC I think that's enough
            queue.removeAll { $0.request.path == requestCompletion.request.path }
            
            do {
                let response = try await execute(
                    request: requestCompletion.request,
                    random: random
                )
                requestCompletion.completion?(.success(response))
            } catch {
                requestCompletion.completion?(.failure(.error("SECURE ERROR: Server error")))
            }
        }
    }
    
    // Simulate executing request with random num
    private func execute<R: SecureRequest>(request: R, random: Int) async throws -> R.Output? {
        let requestBody = [
            "random": String(random),
            "path": request.path
        ]
        
        guard let data = try await dependencies.server.postRequest(body: requestBody) else {
            return nil
        }
        
        return try JSONDecoder().decode(R.Output.self, from: data)
    }
}
