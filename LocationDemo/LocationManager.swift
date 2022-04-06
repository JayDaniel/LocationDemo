//
//  LocationManager.swift
//  LocationDemo
//
//  Created by ted.liu on 2022/4/6.
//

import UIKit
import CoreLocation

enum LocationError: Error {
    /**显示自定义错误信息*/
    case showTipsError(reason: String? = nil)
}

class LocationManager: NSObject {
    
    static let manager = LocationManager()
    
    /// 默认比对gps坐标
    var currLocation = LocationModel(lat: "31.22629", lon: "121.63948")
    
    // gps数据源
    var locationList: [LocationModel] = []
    
    /// 创建xml解析器解析数据
    /// - Parameters:
    ///   - resourcePath: 资源路径
    ///   - polyline: 与资源文件做对比的坐标model
    func startParser(resourcePath: String, location: LocationModel? = nil) async throws -> LocationModel {
        
        if let location = location {
            currLocation = location
        }
        
        //初始化parser
        let parser = XMLParser(contentsOf: NSURL(fileURLWithPath: resourcePath) as URL)
        //设置delegate
        parser?.delegate = self
        //开始解析
        parser?.parse()

        return try await getNearestPoint()
    }
    
    /// 解析转换字典为model
    /// - Parameter attributeDict: 传入的字典数据
    /// - Returns: 解析后的model
    func getDictConvertModelData(_ attributeDict: [String : String]) -> LocationModel? {
        // 是否为可解析类型
        guard JSONSerialization.isValidJSONObject(attributeDict),
              let data = try? JSONSerialization.data(withJSONObject: attributeDict, options: []) else {
            return nil
        }
        // 解析当前数据为model
        do {
            let model = try JSONDecoder().decode(LocationModel.self, from: data)
            return model
        } catch  {
            return nil
        }
    }
    
    /// 计算当前两点距离
    /// - Parameters:
    ///   - firstPoint: 开始点位
    ///   - lastPoint: 结束点位
    func distanceBetweenOrderBy(distancePoint: LocationModel) -> Double {
        //第一个坐标
        let current = CLLocation(latitude: currLocation.useLat, longitude: currLocation.useLon)
        //第二个坐标
        let before = CLLocation(latitude: distancePoint.useLat, longitude: distancePoint.useLon)
        // 计算距离
        return current.distance(from: before)
    }
    
    /// 获取比对后的最近点
    /// - Returns: 最近点model
    func getNearestPoint() async throws -> LocationModel {
        guard var meterModel = locationList.first else {
            throw LocationError.showTipsError(reason: "解析异常，坐标集合为空")
        }
        var comparisonNum: Double = distanceBetweenOrderBy(distancePoint: meterModel)
        // 循环比对出最近点
        locationList.forEach { polylineModel in
            let meter = distanceBetweenOrderBy(distancePoint: polylineModel)
            if meter < comparisonNum {
                comparisonNum = meter
                meterModel = polylineModel
            }
        }
        print("两点之间最短距离===\(comparisonNum)")
        return meterModel
    }
}

//MARK: - XMLParserDelegate
extension LocationManager: XMLParserDelegate {
    /// 标签开始解析
    /// - Parameters:
    ///   - parser: 解析器
    ///   - elementName: 标签名
    ///   - namespaceURI:
    ///   - qName:
    ///   - attributeDict: 解析dic
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?, attributes
                attributeDict: [String : String] = [:]) {
        // 拿到标签开始点，进行解析
        if elementName == "trkpt" {
            if let parserModel = getDictConvertModelData(attributeDict) {
                locationList.append(parserModel)
            }
        }
    }
    
    /// 标签解析完成
    /// - Parameter parser:
    func parserDidEndDocument(_ parser: XMLParser) {
        print("标签已经解析完成===")
    }
}
