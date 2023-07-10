//
//  SecureResultCompletion.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

typealias SecureRequestResult = (Result<SecureResponse?, SecureError>) -> Void
