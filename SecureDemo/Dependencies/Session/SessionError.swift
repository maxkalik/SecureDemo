//
//  SessionError.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

enum SessionError: Error {
    case secureError(SecureError)
}
