//
//  ExperimantalServer.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 7/10/23.
//

import Foundation

struct Specific: Codable {
    let prop: String
}

struct SpecificQuery: Codable {
    let bodyQeury: String
}

class ExperimentalServer {
    
    init() {
        
    }
    
    func request1() {
        guard let url = URL(string: "http://localhost:3000/secure/1x1") else {
            return
        }

        Task {
            let parameters = ["name": "maxpro", "password": "123456"]
            var urlRequest = URLRequest(url: url)
            urlRequest.allHTTPHeaderFields = [
                "Content-Type": "application/json; charset=utf-8",
                "Signature": "123324349829345"
            ]

            urlRequest.httpBody = parameters.stringify()?.data(using: .utf8)
            urlRequest.httpMethod = "POST"

            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            print(data, response)
            let res = try JSONDecoder().decode(Specific.self, from: data)
            print(res)
        }
    }
}
