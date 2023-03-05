//
//  Requests.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/17/23.
//

import Foundation


// MARK: - secure/1x1

struct Request1x1: SecureRequest {
    typealias Output = Response1x1
    var path: String = "secure/1x1"
    var random: Int?
}

struct Response1x1: SecureResponse {
    var data: String
}

// MARK: - secure/1x2

struct Request1x2: SecureRequest {
    typealias Output = Response1x2
    var path: String = "secure/1x2"
    var random: Int?
}

struct Response1x2: SecureResponse {
    var data: String
}

// MARK: - secure/1x3

struct Request1x3: SecureRequest {
    typealias Output = Response1x3
    var path: String = "secure/1x3"
    var random: Int?
}

struct Response1x3: SecureResponse {
    var data: String
}

// MARK: - secure/2x1

struct Request2x1: SecureRequest {
    typealias Output = Response2x1
    var path: String = "secure/2x1"
    var random: Int?
}

struct Response2x1: SecureResponse {
    var data: String
}

// MARK: - secure/2x2

struct Request2x2: SecureRequest {
    typealias Output = Response2x2
    var path: String = "secure/2x2"
    var random: Int?
}

struct Response2x2: SecureResponse {
    var data: String
}


// MARK: - secure/3x1

struct Request3x1: SecureRequest {
    typealias Output = Response3x1
    var path: String = "secure/3x1"
    var random: Int?
}

struct Response3x1: SecureResponse {
    var data: String
}
