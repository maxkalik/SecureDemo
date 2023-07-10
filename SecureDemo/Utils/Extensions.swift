//
//  Extensions.swift
//  SecureDemo
//
//  Created by Maksim Kalik on 1/17/23.
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
//    var dictionary: [String: Any]? {
//        guard let data = try? JSONEncoder().encode(self) else { return nil }
//        return (
//            try? JSONSerialization.jsonObject(
//                with: data,
//                options: .allowFragments
//            )
//        ).flatMap { $0 as? [String: Any] }
//    }
    
    func toJSON() -> Data? {
        do {
            let dict = self.mapValues { ($0 as? Double)?.isNaN == true ? nil : $0 }
            return try JSONSerialization.data(withJSONObject: dict)
        } catch {
            return nil
        }
    }
    
    func stringify() -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self),
           let jsonText = String(data: jsonData, encoding: .utf8) {
            return jsonText
        } else {
            return nil
        }
    }
}
