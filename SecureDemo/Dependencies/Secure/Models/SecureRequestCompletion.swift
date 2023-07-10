//
//  SecureCombineRequestCompletion.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation
import Combine

struct SecureRequestCompletion {
    var request: any SecureRequest
    var retries: Int
    var status: SecureRequestStatus
    var completion: SecureResultCompletion
}

struct SecureCombineRequestCompletion {
    var request: any SecureRequest
    var status: SecureRequestStatus
    var completion: PassthroughSubject<SecureResponse?, SecureError>
}
