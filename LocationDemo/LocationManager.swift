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

enum DistanceMethod {
    /// 根据CLLocation计算
    case firstVersion
    /// 根据坐标点计算
    case secondVersion
    /// 根据公式计算
    case thirdVersion
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
    func startParser(method: DistanceMethod,
                     resourcePath: String,
                     location: LocationModel? = nil) async throws -> LocationModel {
        
        if let location = location {
            currLocation = location
        }
        
        //初始化parser
        let parser = XMLParser(contentsOf: NSURL(fileURLWithPath: resourcePath) as URL)
        //设置delegate
        parser?.delegate = self
        //开始解析
        parser?.parse()

        return try await getNearestPoint(method)
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
    
    /// 获取比对后的最近点
    /// - Returns: 最近点model
    func getNearestPoint(_ method: DistanceMethod) async throws -> LocationModel {
        guard let meterModel = locationList.first else {
            throw LocationError.showTipsError(reason: "解析异常，坐标集合为空")
        }
        switch method {
        case .firstVersion:
            return getDistanceWithFirstVersion(distancePoint: meterModel)
        case .secondVersion:
            return getDistanceWithSecondVersion(distancePoint: meterModel)
        case .thirdVersion:
            return getDistanceWithThirdVersion(distancePoint: meterModel)
        }
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

//MARK: - 直接根据经纬度计算两点直线距离
extension LocationManager {
    
    /// 根据 CLLocation获取两个经纬度直线距离
    /// - Parameter distancePoint:
    /// - Returns: 距离值
    private func getLocationDifference(distancePoint: LocationModel) -> Double {
        //第一个坐标
        let current = CLLocation(latitude: currLocation.useLat, longitude: currLocation.useLon)
        //第二个坐标
        let before = CLLocation(latitude: distancePoint.useLat, longitude: distancePoint.useLon)
        // 计算距离
        return current.distance(from: before)
    }
    
    /// 计算出与指定坐标直线最近的坐标
    /// - Parameter distancePoint: 当前起始坐标
    /// - Returns: 最近坐标
    func getDistanceWithFirstVersion(distancePoint: LocationModel) -> LocationModel {
        var distanceNum = getLocationDifference(distancePoint: distancePoint)
        var coordinateModel = distancePoint
        locationList.forEach { polylineModel in
            let meter = getLocationDifference(distancePoint: polylineModel)
            if meter < distanceNum {
                distanceNum = meter
                coordinateModel = polylineModel
            }
        }
        return coordinateModel
    }
}

//MARK: - 根据两点经纬度计算两点距离
extension LocationManager {
    //根据角度计算弧度
    private func radian(d: Double) -> Double {
        return d * Double.pi / 180.0
    }
    
    private func getDistanceDifference(distancePoint: LocationModel) -> Double {
        let EARTH_RADIUS: Double = 6378137.0
        
        let radLat1: Double = self.radian(d: currLocation.useLat)
        let radLat2: Double = self.radian(d: distancePoint.useLat)
          
        let radLng1: Double = self.radian(d: currLocation.useLon)
        let radLng2: Double = self.radian(d: distancePoint.useLon)
          
        let a: Double = radLat1 - radLat2
        let b: Double = radLng1 - radLng2
          
        var s: Double = 2 * asin(sqrt(pow(sin(a/2), 2) + cos(radLat1) * cos(radLat2) * pow(sin(b/2), 2)))
        s = s * EARTH_RADIUS
        
        return s
    }
    
    //根据两点经纬度计算两点距离
    func getDistanceWithSecondVersion(distancePoint: LocationModel) -> LocationModel {
        var distanceNum = getDistanceDifference(distancePoint: distancePoint)
        var coordinateModel = distancePoint
        locationList.forEach { polylineModel in
            let meter = getDistanceDifference(distancePoint: polylineModel)
            if meter < distanceNum {
                distanceNum = meter
                coordinateModel = polylineModel
            }
        }
        return coordinateModel
    }
}
//MARK: - 数学公式计算
extension LocationManager {
    
    func getDistanceWithThirdVersion(distancePoint: LocationModel) -> LocationModel {
        var distanceNum = 0.0;
        var coordinateModel = distancePoint
        for (index, element) in locationList.enumerated(){
            let tmpDistance = fabs(sqrt(pow(element.useLat - currLocation.useLat, 2) + pow(element.useLon - currLocation.useLon, 2)))
            if index == 0 || tmpDistance < distanceNum {
                distanceNum = tmpDistance
                coordinateModel = element
            }
        }
        return coordinateModel
    }
}
