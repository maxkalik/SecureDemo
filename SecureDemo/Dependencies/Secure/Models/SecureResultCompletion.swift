//
//  SecureResultCompletion.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

typealias SecureResultCompletion = (Result<SecureResponse?, SecureError>) -> Void
