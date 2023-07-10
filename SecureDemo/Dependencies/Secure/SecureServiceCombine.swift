//
//  SecureServiceCombine.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/9/23.
//

import Foundation
import Combine

class SecureServiceCombine {
    
    private let dependencies: Dependencies
    private var expiredRandom: [Int] = []
    private let accessQueue = DispatchQueue(label: "SecureService.queueAccessQueue")
    private var requestsQueue: [SecureCombineRequestCompletion] = []
    private var pendingRequests: [String: SecureCombineRequestCompletion] = [:]
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func call<R: SecureRequest>(request: R) -> AnyPublisher<R.Output, SecureError> {
        guard let random = request.random else {
            return Fail(error: .userRandom).eraseToAnyPublisher()
        }
        
        let completion = PassthroughSubject<SecureResponse?, SecureError>()
        let requestCompletion = SecureCombineRequestCompletion(
            request: request,
            status: .unprocessed,
            completion: completion
        )
        
        accessQueue.async {
            self.requestsQueue.append(requestCompletion)
            self.pendingRequests[request.path] = requestCompletion
            self.executeFromQueue(random)
        }
        
        return completion
            .tryMap { response in
                guard let response = response as? R.Output else {
                    throw SecureError.error("Wrong output type")
                }
                return response
            }
            .mapError { $0 as? SecureError ?? .error("SECURE ERROR: Server error") }
            .eraseToAnyPublisher()
    }
    
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
        
        guard !self.expiredRandom.contains(random) else { return }
        
        self.expiredRandom.append(random)
        requestsQueue.removeAll { $0.request.path == requestCompletion.request.path }
        
        var mutableRequestCompletion = requestCompletion
        mutableRequestCompletion.status = .processing
        self.execute(request: mutableRequestCompletion.request, random: random)
            .sink { result in
                switch result {
                case .finished:
                    mutableRequestCompletion.status = .processed
                case .failure(let error):
                    mutableRequestCompletion.status = .error(error)
                }
                self.pendingRequests[mutableRequestCompletion.request.path] = nil
            } receiveValue: { response in
                mutableRequestCompletion.completion.send(response)
            }
            .store(in: &cancellables)
    }
    
    private func execute<R: SecureRequest>(request: R, random: Int) -> AnyPublisher<SecureResponse?, SecureError> {
        let requestBody = [
            "random": String(random),
            "path": request.path
        ]
        
        return dependencies.server.postRequest(body: requestBody)
            .tryMap { data -> SecureResponse? in
                if let data = data {
                    let response = try JSONDecoder().decode(R.Output.self, from: data)
                    return response
                } else {
                    throw SecureError.error("No data")
                }
            }
            .mapError { $0 as? SecureError ?? .error("SECURE ERROR: Request error") }
            .eraseToAnyPublisher()
    }
}
