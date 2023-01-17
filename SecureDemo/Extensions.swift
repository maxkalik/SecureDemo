//
//  Extensions.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/17/23.
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    func toJSON() -> Data? {
        do {
            let dict = self.mapValues { ($0 as? Double)?.isNaN == true ? nil : $0 }
            return try JSONSerialization.data(withJSONObject: dict)
        } catch {
            return nil
        }
    }
}
