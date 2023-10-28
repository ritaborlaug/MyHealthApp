//
//  Extensions.swift
//  MyHealthApp
//
//  Created by Rita Borlaug on 16/10/2023.
//

import Foundation


extension DateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
