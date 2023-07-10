//
//  SecureService2.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/9/23.
//

import Foundation
import Combine

enum SecureRequestStatus: Equatable {
    case unprocessed
    case processing
    case processed
    case error(SecureError)
}

struct Secure2RequestCompletion {
    var request: any SecureRequest
    var status: SecureRequestStatus
    var completion: SecureResultCompletion
}

class Secure2Service {
    
    private let dependencies: Dependencies
    private var expiredRandom: [Int] = []
    private var queue: [Secure2RequestCompletion] = []
    private var pendingRequests: [String: Secure2RequestCompletion] = [:]
    private let accessQueue = DispatchQueue(label: "SecureService.queueAccessQueue")
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func call<R: SecureRequest>(request: R, completion: @escaping SecureResultCompletion) {
        guard let random = request.random else {
            completion(.failure(.userRandom))
            return
        }
        
        let requestCompletion = Secure2RequestCompletion(
            request: request,
            status: .unprocessed,
            completion: completion
        )
        
        accessQueue.async {
            self.queue.append(requestCompletion)
            self.pendingRequests[request.path] = requestCompletion
            self.executeFromQueue(random)
        }
    }
    
    public func executeFromQueue(_ random: Int) {
        accessQueue.async {
            self._executeFromQueue(random)
        }
    }
    
    private func _executeFromQueue(_ random: Int) {
        guard let requestCompletion = self.queue.first(where: { $0.status == .unprocessed }) else {
            self.expiredRandom.removeAll()
            return
        }
        
        guard !self.expiredRandom.contains(random) else { return }
        
        self.expiredRandom.append(random)
        queue.removeAll { $0.request.path == requestCompletion.request.path }
        
        
        var mutableRequestCompletion = requestCompletion
        mutableRequestCompletion.status = .processing
        self.execute(request: mutableRequestCompletion.request, random: random) { result in
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
