//
//  SecureResponse.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

protocol SecureResponse: Codable {
    var data: String { get }
}
