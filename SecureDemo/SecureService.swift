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
    private var requests: [any SecureRequest] = [] {
        didSet {
            print("+++", requests.map { $0.path })
        }
    }
    
    var requestCompletion: SecureCompletion?
    
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
                return
            }
            
            currentRandom = userRandom
            
            requests.removeAll { $0.path == request.path }
            
            do {
                let response = try await execute(request: request, random: userRandom)
                requestCompletion?(nil, response)
            } catch {
                requestCompletion?(.error("SECURE ERROR: Server error"), nil)
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

struct DummySecureResponse: SecureResponse {
    var data: String
    
    init(path: String) {
        self.data = "Dummy Response - \(path)"
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    func toJSON() -> Data? {
        do {
            let dict = self.mapValues { ($0 as? Double)?.isNaN == true ? nil : $0 }
            return try JSONSerialization.data(withJSONObject: dict)
        } catch {
            return nil
        }
    }
}
