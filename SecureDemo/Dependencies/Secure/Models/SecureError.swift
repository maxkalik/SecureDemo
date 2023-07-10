//
//  SecureError.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

enum SecureError: Error, Equatable {
    case userRandom
    case requestNotFound
    case error(String)
}
