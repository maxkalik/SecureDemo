//
//  SecureRequestStatus.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

enum SecureRequestStatus: Equatable {
    case unprocessed
    case processing
    case processed
    case error(SecureError)
}
