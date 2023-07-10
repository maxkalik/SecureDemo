//
//  SecureCombineRequestCompletion.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation
import Combine

struct SecureCombineRequestCompletion {
    var request: any SecureRequest
    var status: SecureRequestStatus
    var completion: PassthroughSubject<SecureResponse?, SecureError>
}
