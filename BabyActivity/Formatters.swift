//
//  Formatters.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//

import Foundation

struct Formatters {
    public static let dateFormatter: DateFormatter = {
//        let df = DateFormatter()
//        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
//        return df
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    public static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
 }
