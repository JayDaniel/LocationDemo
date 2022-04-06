//
//  PolylineModel.swift
//  LocationDemo
//
//  Created by ted.liu on 2022/4/6.
//

import UIKit

/// 坐标点model
struct LocationModel: Codable {
    var lat: String
    var lon: String
    
    var useLat: Double {
        return Double(lat) ?? 0.0
    }
    var useLon: Double {
        return Double(lon) ?? 0.0
    }
}
