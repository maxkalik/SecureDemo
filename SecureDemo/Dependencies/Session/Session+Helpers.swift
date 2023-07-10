//
//  Session+Helpers.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation
import Combine

extension Session {

    // Completion version
    
    func executeSecureRequest<R: SecureRequest>(_ request: R, completion: @escaping (R.Output?) -> Void) {
//        guard let random = dependencies.user.userSubject.value?.random else {
//            completion(nil)
//            print("=== 🔴 user random nil")
//            return
//        }
//        
//        var request = request
//        request.random = random
        
        dependencies.secure.call(request: request) { result in
            switch result {
            case .success(let response):
                completion(response as? R.Output)
                if let response {
                    print("=== request: \(request.path) - 🟢", response)
                } else {
                    print("=== request: \(request.path) - 🔴 response is nil")
                }
            case .failure(let error):
                print("=== request: \(request.path) - 🔴", error)
                completion(nil)
            }
        }
    }
    
    // Combine version
    
    func executeSecureRequest<R: SecureRequest>(_ request: R) -> AnyPublisher<R.Output, SessionError> {

        guard let random = dependencies.user.userSubject.value?.random else {
            
            print("=== 🔴 user random nil")
            
            return Fail(error: .secureError(.userRandom)).eraseToAnyPublisher()
        }
        
        var request = request
        request.random = random
        
        return dependencies.secureCombine.call(request: request)
            .mapError {
                print("=== request: \(request.path) - 🔴", $0)
                return SessionError.secureError($0)
            }
            .map {
                print("=== request: \(request.path) - 🟢", $0)
                return $0
            }
            .first()
            .eraseToAnyPublisher()
    }
}
