//
//  ViewController.swift
//  LocationDemo
//
//  Created by ted.liu on 2022/4/6.
//

import UIKit

class ViewController: UIViewController {
    
    /// 当前坐标
    let currPolyline = LocationModel(lat: "31.22629", lon: "121.63948")
    
    /// 当前数据文件路径
    var resourcePath: String {
        Bundle.main.path(forResource: "polyline", ofType: "gpx") ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        Task {
            do {
                let nearPoint = try await LocationManager.manager.startParser(resourcePath: resourcePath, location: currPolyline)
                print("最短距离坐标===\(nearPoint)")
            } catch let error as LocationError {
                switch error{
                case .showTipsError(reason: let msg) :
                    print("===转换错误：\(msg ?? "")")
                }
            }
        }
    }
}
