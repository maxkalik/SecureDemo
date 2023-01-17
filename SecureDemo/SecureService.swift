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

typealias SecureCompletion = (SecureError?, SecureResponse?) -> Void

class SecureService {
    
    private let dependencies: Dependencies
    
    private var currentRandom: Int?

    private var requestCompletions: [(request: any SecureRequest, completion: SecureCompletion?)] = []  {
        didSet {
            print("+++", requestCompletions.map { $0.request.path })
        }
    }
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func call<R: SecureRequest>(request: R, completion: @escaping (SecureError?, SecureResponse?) -> Void) {
        requestCompletions.append((request, completion))
        executeFromQueue()
    }
    
    func executeFromQueue() {
        Task {
            guard let requestCompletion = requestCompletions.first else {
                return
            }

            // let userRandom1 = await dependencies.session.user?.random
            // print("=== Start executing from queue | USER RANDOM: \(userRandom1) | CUR RANDOM: \(currentRandom)")
            
            // CASE 1 - USER RANDOM: nil | CURRENT RANDOM: nil
            // CASE 2 - USER RANDOM: 123 | CURRENT RANDOM: nil
            // CASE 3 - USER RANDOM: 123 | CURRENT RANDOM: 123
            // CASE 4 - USER RANDOM: 321 | CURRENT RANDOM: 123
            // CASE 4 - USER RANDOM: nil | CURRENT RANDOM: 321 -> ?
            
            guard let userRandom = await dependencies.session.user?.random, currentRandom != userRandom else {
                return
            }
            
            currentRandom = userRandom

            requestCompletions.removeAll { $0.request.path == requestCompletion.request.path }
            
            do {
                let response = try await execute(request: requestCompletion.request, random: userRandom)
                requestCompletion.completion?(nil, response)
            } catch {
                requestCompletion.completion?(.error("SECURE ERROR: Server error"), nil)
            }
        }
    }
    
    func execute<R: SecureRequest>(request: R, random: Int) async throws -> R.Output? {
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
