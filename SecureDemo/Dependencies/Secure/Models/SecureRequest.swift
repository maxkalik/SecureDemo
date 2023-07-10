//
//  SecureRequest.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

protocol SecureRequest: Codable {
    associatedtype Output: SecureResponse
    var path: String { get }
    var random: Int? { get set }
}
