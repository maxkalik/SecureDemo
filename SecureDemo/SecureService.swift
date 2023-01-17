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
    private var currentRandom: Int?
    private var queue: [SecureRequestCompletion] = []
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    // This method just append `SecureRequestCompletion` to the queue
    // And emmidiately runs queue becase random num can be already in a user object
    func call<R: SecureRequest>(request: R, completion: @escaping SecureCompletion) {
        queue.append((request, completion))
        executeFromQueue()
    }
    
    // Call this method if random num has changed (for example from session user didSet)
    func executeFromQueue() {
        Task {
            // Check if we have something to execute in the queue
            guard let requestCompletion = queue.first else {
                return
            }
            
            // Possible cases to handle
            // CASE 1 - USER RANDOM: nil | CURRENT RANDOM: nil
            // CASE 2 - USER RANDOM: 123 | CURRENT RANDOM: nil
            // CASE 3 - USER RANDOM: 123 | CURRENT RANDOM: 123
            // CASE 4 - USER RANDOM: 321 | CURRENT RANDOM: 123
            // CASE 4 - USER RANDOM: nil | CURRENT RANDOM: 321 -> ?
            
            // Check if current random is not the same
            guard let userRandom = await dependencies.session.user?.random, currentRandom != userRandom else {
                return
            }
            
            // Update current random with that what was updated in user object
            currentRandom = userRandom

            // Remove all request with the same body or path from queue
            // I know it's questionable to remove all requests with the same body
            // Instead of array we can use Set but for PoC I think that's enough
            queue.removeAll { $0.request.path == requestCompletion.request.path }
            
            do {
                let response = try await execute(request: requestCompletion.request, random: userRandom)
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
