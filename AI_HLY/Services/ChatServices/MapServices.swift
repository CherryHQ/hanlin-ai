//
//  MapServices.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 15/4/25.
//

import Foundation
import MapKit
import CoreLocation
import WeatherKit

@MainActor
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
    }

    /// 由于标记了 @MainActor，闭包默认就在主线程，无需 Sendable
    func fetchLocation() async throws -> CLLocationCoordinate2D {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            throw NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "定位权限未授予"])
        }

        // 若已有缓存
        if let cachedLocation = manager.location {
            return cachedLocation.coordinate
        }

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            manager.requestLocation()

            // 超时处理
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if let c = self.continuation {
                    c.resume(throwing: NSError(
                        domain: "LocationError",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "获取位置超时"]
                    ))
                    self.continuation = nil
                }
            }
        }
    }

    // CLLocationManagerDelegate
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.continuation?.resume(returning: location.coordinate)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }
}


// 反向地理编码函数：将坐标转换为真实地址字符串
func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let geocoder = CLGeocoder()
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let placemark = placemarks?.first {
                // 尽可能组合多个信息构成地址字符串
                let name = placemark.name ?? ""
                let subLocality = placemark.subLocality ?? ""
                let locality = placemark.locality ?? ""
                let administrativeArea = placemark.administrativeArea ?? ""
                let country = placemark.country ?? ""
                let fullAddress = [name, subLocality, locality, administrativeArea, country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                continuation.resume(returning: fullAddress.isEmpty ? "未知位置" : fullAddress)
            } else {
                continuation.resume(returning: "未知位置")
            }
        }
    }
}


// MARK: - 直接在函数中调用 LocationFetcher 获取当前设备位置并返回自定义的 Location 结构体
func getCurrentLocation() async throws -> Location {
    let fetcher = await LocationFetcher()
    let coordinate = try await fetcher.fetchLocation()
    let placeName = try await reverseGeocode(coordinate: coordinate)
    return Location(
        identifier: UUID().uuidString,
        name: placeName,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        style: "current"
    )
}

// MARK: 主要地图功能实现
// MARK: - 根据关键词搜索地点，返回3个结果
func queryLocation(with keyword: String, company: String, apiKey: String) async throws -> [Location] {
    if company.uppercased() == "APPLEMAP" {
        // 使用系统地图（Apple Map）进行地点查询
        return try await queryLocationFromAppleMap(with: keyword)
    } else if company.uppercased() == "AMAP" {
        // 使用高德地图进行地点查询
        return try await queryLocationFromAmap(with: keyword, apiKey: apiKey)
    } else if company.uppercased() == "GOOGLEMAP" {
        // 新增：使用谷歌地图进行地点查询
        return try await queryLocationFromGoogleMap(with: keyword, apiKey: apiKey)
    } else {
        // 若未识别地图服务提供商，默认使用 Apple Map 查询
        return try await queryLocationFromAppleMap(with: keyword)
    }
}

// 苹果地图查询
private func queryLocationFromAppleMap(with keyword: String) async throws -> [Location] {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = keyword
    // 设置一个足够大的区域，覆盖全球
    request.region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 150, longitudeDelta: 360)
    )
    
    let search = MKLocalSearch(request: request)
    return try await withCheckedThrowingContinuation { continuation in
        search.start { response, error in
            if let error = error {
                // 如果错误类型为 placemarkNotFound 则返回空结果，否则抛出异常
                if let mkError = error as? MKError, mkError.code == .placemarkNotFound {
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(throwing: error)
                }
                return
            }
            
            guard let items = response?.mapItems, !items.isEmpty else {
                continuation.resume(returning: [])
                return
            }
            
            // 取前三个结果，转换为 Location 对象
            let locations: [Location] = items.prefix(3).compactMap { item in
                let placemark = item.placemark
                return Location(
                    id: UUID(),
                    identifier: item.identifier?.rawValue ?? UUID().uuidString,
                    name: item.name ?? placemark.name ?? "未知地点",
                    latitude: placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude,
                    style: "mark"
                )
            }
            continuation.resume(returning: locations)
        }
    }
}

// 高德地图查询
func queryLocationFromAmap(with keyword: String, apiKey: String) async throws -> [Location] {
    // 对关键词进行 URL 编码
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URLError(.badURL)
    }
    
    // 构建请求 URL，设置 page_size=3 以获取最多三个结果
    let urlString = "https://restapi.amap.com/v5/place/text?key=\(apiKey)&keywords=\(encodedKeyword)&page_size=3"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    // 发起请求获取数据
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // 使用 JSONSerialization 动态解析 JSON 数据
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let json = jsonObject as? [String: Any] else {
        throw URLError(.cannotParseResponse)
    }
    
    // 检查状态码，这里“status”应为 "1" 且 “infocode”为 "10000" 表示成功
    guard let status = json["status"] as? String, status == "1",
          let infocode = json["infocode"] as? String, infocode == "10000" else {
        // 返回空列表，或根据需要抛出错误
        return []
    }
    
    // 提取 POI 列表
    guard let pois = json["pois"] as? [[String: Any]], !pois.isEmpty else {
        return []
    }
    
    // 遍历前三个 POI，提取我们关心的字段：id、name、location
    var locations: [Location] = []
    for poi in pois.prefix(3) {
        guard let id = poi["id"] as? String,
              let name = poi["name"] as? String,
              let locationStr = poi["location"] as? String else {
            continue
        }
        // location 字段格式为 "经度,纬度"
        let coordComponents = locationStr.split(separator: ",")
        guard coordComponents.count == 2,
              let longitude = Double(coordComponents[0].trimmingCharacters(in: .whitespaces)),
              let latitude = Double(coordComponents[1].trimmingCharacters(in: .whitespaces)) else {
            continue
        }
        
        // 构造 Location 对象（注意：根据你的实际 Location 定义调整字段）
        let location = Location(
            id: UUID(),
            identifier: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            style: "mark"
        )
        locations.append(location)
    }
    
    return locations
}

// 使用谷歌地图 Places Text Search API 查询地点
func queryLocationFromGoogleMap(with keyword: String, apiKey: String) async throws -> [Location] {
    // 对关键词进行 URL 编码
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URLError(.badURL)
    }
    
    // 构建 Text Search 请求 URL；可加入 language、region 等参数
    let urlString = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(encodedKeyword)&key=\(apiKey)"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    // 发起网络请求
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // 动态解析 JSON
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let jsonDict = jsonObject as? [String: Any] else {
        throw URLError(.cannotParseResponse)
    }
    
    // 判断 status 状态是否为 "OK"
    guard let status = jsonDict["status"] as? String, status == "OK" else {
        // 其它常见值还有 ZERO_RESULTS, OVER_QUERY_LIMIT, REQUEST_DENIED, INVALID_REQUEST 等
        return []
    }
    
    // 提取 results 数组
    guard let results = jsonDict["results"] as? [[String: Any]], !results.isEmpty else {
        return []
    }
    
    var locations: [Location] = []
    
    // 只取前三个结果
    for result in results.prefix(3) {
        // place_id 作为 identifier
        let placeId = result["place_id"] as? String ?? UUID().uuidString
        // name
        let name = result["name"] as? String ?? "未知地点"
        
        // geometry
        guard let geometry = result["geometry"] as? [String: Any],
              let locationDict = geometry["location"] as? [String: Any],
              let lat = locationDict["lat"] as? Double,
              let lng = locationDict["lng"] as? Double else {
            continue
        }
        
        // 构造自定义的 Location 结构体
        let location = Location(
            id: UUID(),
            identifier: placeId,
            name: name,
            latitude: lat,
            longitude: lng,
            style: "mark"
        )
        locations.append(location)
    }
    
    return locations
}


// MARK: - 根据给定中心位置和搜索关键词，查询周边地点，返回最多十个符合条件的地点
func searchNearbyLocations(
    around coordinate: CLLocationCoordinate2D,
    with keyword: String,
    company: String,
    apiKey: String
) async throws -> [Location] {
    // 根据不同地图服务调用不同适配函数
    if company.uppercased() == "APPLEMAP" {
        // 苹果地图附近搜索
        return try await searchNearbyLocationsFromAppleMap(around: coordinate, with: keyword)
    } else if company.uppercased() == "AMAP" {
        // 高德地图附近搜索
        return try await searchNearbyLocationsFromAmap(around: coordinate, with: keyword, apiKey: apiKey)
    } else if company.uppercased() == "GOOGLEMAP" {
        // 谷歌地图附近搜索
        return try await searchNearbyLocationsFromGoogle(around: coordinate, with: keyword, apiKey: apiKey)
    } else {
        // 未识别的地图服务，默认使用 Apple Map
        return try await searchNearbyLocationsFromAppleMap(around: coordinate, with: keyword)
    }
}

// 附近搜索实现
private func searchNearbyLocationsFromAppleMap(
    around coordinate: CLLocationCoordinate2D,
    with keyword: String
) async throws -> [Location] {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = keyword
    // 设置搜索区域为中心周边约 5 公里（经纬度 0.05）范围，适合“附近”搜索
    request.region = MKCoordinateRegion(
        center: coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let search = MKLocalSearch(request: request)
    
    return try await withCheckedThrowingContinuation { continuation in
        search.start { response, error in
            if let error = error {
                if let mkError = error as? MKError, mkError.code == .placemarkNotFound {
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(throwing: error)
                }
                return
            }
            
            guard let items = response?.mapItems, !items.isEmpty else {
                continuation.resume(returning: [])
                return
            }
            
            // 按中心点距离排序，并取最多前 10 个结果
            let sortedItems = items.sorted {
                let distanceA = $0.placemark.location?.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) ?? .greatestFiniteMagnitude
                let distanceB = $1.placemark.location?.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) ?? .greatestFiniteMagnitude
                return distanceA < distanceB
            }
            
            let locations: [Location] = sortedItems.prefix(10).compactMap { item in
                let placemark = item.placemark
                return Location(
                    id: UUID(),
                    identifier: item.identifier?.rawValue ?? UUID().uuidString,
                    name: item.name ?? placemark.name ?? "未知地点",
                    latitude: placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude,
                    style: "mark"
                )
            }
            continuation.resume(returning: locations)
        }
    }
}

// 高德地图周边搜索
private func searchNearbyLocationsFromAmap(
    around coordinate: CLLocationCoordinate2D,
    with keyword: String,
    apiKey: String
) async throws -> [Location] {
    // 先对关键词进行 URL 编码
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URLError(.badURL)
    }
    
    // 高德地图周边搜索: v5/place/around
    // 按照官方文档，location 需使用 "经度,纬度" 格式
    // 这里设置 radius=5000(约 5 km)，page_size=10 (一次最多拉取 10 条)
    let lonLat = "\(coordinate.longitude),\(coordinate.latitude)"
    let urlString = """
        https://restapi.amap.com/v5/place/around\
        ?key=\(apiKey)\
        &location=\(lonLat)\
        &keywords=\(encodedKeyword)\
        &radius=5000\
        &page_size=10
        """
    
    // 构建 URL
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    // 发起网络请求
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // 使用 JSONSerialization 动态解析
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let jsonDict = jsonObject as? [String: Any] else {
        throw URLError(.cannotParseResponse)
    }
    
    // 判断请求是否成功
    // status == "1" 且 infocode == "10000" 表示成功
    guard let status = jsonDict["status"] as? String, status == "1",
          let infocode = jsonDict["infocode"] as? String, infocode == "10000" else {
        // 返回空，或根据实际情况抛出错误
        return []
    }
    
    // 提取 POI 列表
    guard let pois = jsonDict["pois"] as? [[String: Any]], !pois.isEmpty else {
        return []
    }
    
    // 遍历 POI，提取我们需要的字段：id, name, location
    // location 字段格式 "经度,纬度"
    var locations: [Location] = []
    
    // 如果需要二次筛选或排序，可在这里处理；当前示例直接用 API 返回的前 10 条
    // 因为我们在 page_size=10 已限定数量，所以这里可以直接遍历，也可以再 prefix(10)
    for poi in pois {
        guard let poiId = poi["id"] as? String,
              let poiName = poi["name"] as? String,
              let locStr = poi["location"] as? String else {
            continue
        }
        
        let parts = locStr.split(separator: ",")
        guard parts.count == 2,
              let lng = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lat = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            continue
        }
        
        let location = Location(
            id: UUID(),
            identifier: poiId,
            name: poiName,
            latitude: lat,
            longitude: lng,
            style: "mark"
        )
        locations.append(location)
    }
    
    return locations
}

// 谷歌地图附近搜索
private func searchNearbyLocationsFromGoogle(
    around coordinate: CLLocationCoordinate2D,
    with keyword: String,
    apiKey: String
) async throws -> [Location] {
    // 对关键词进行 URL 编码
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URLError(.badURL)
    }
    
    // 构建 Nearby Search 请求 URL
    // 例如半径 5000m（5公里），取前 10 个结果
    // 其他可选参数可根据业务需要添加，如 language、type、pagetoken 等
    let lat = coordinate.latitude
    let lng = coordinate.longitude
    let urlString = """
    https://maps.googleapis.com/maps/api/place/nearbysearch/json\
    ?location=\(lat),\(lng)\
    &radius=5000\
    &keyword=\(encodedKeyword)\
    &key=\(apiKey)
    """
    
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    // 发起网络请求
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // 动态解析 JSON
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let jsonDict = jsonObject as? [String: Any] else {
        throw URLError(.cannotParseResponse)
    }
    
    // 检查 status 状态是否为 "OK" 或 "ZERO_RESULTS"
    // 其他可能返回值有 OVER_QUERY_LIMIT、REQUEST_DENIED、INVALID_REQUEST 等
    guard let status = jsonDict["status"] as? String else {
        return []
    }
    if status == "ZERO_RESULTS" {
        return []
    } else if status != "OK" {
        // 若不是 OK，视业务需求返回空或抛出错误
        return []
    }
    
    // 提取 results 数组
    guard let results = jsonDict["results"] as? [[String: Any]], !results.isEmpty else {
        return []
    }
    
    var locations: [Location] = []
    
    // 遍历并取前 10 个结果
    for result in results.prefix(10) {
        // place_id 作为 identifier
        let placeId = result["place_id"] as? String ?? UUID().uuidString
        // name
        let name = result["name"] as? String ?? "未知地点"
        
        // geometry -> location -> lat/lng
        guard let geometry = result["geometry"] as? [String: Any],
              let locationDict = geometry["location"] as? [String: Any],
              let placeLat = locationDict["lat"] as? Double,
              let placeLng = locationDict["lng"] as? Double else {
            continue
        }
        
        // 构造自定义的 Location 结构体
        let location = Location(
            id: UUID(),
            identifier: placeId,
            name: name,
            latitude: placeLat,
            longitude: placeLng,
            style: "mark"
        )
        locations.append(location)
    }
    
    return locations
}

// MARK: - 根据给定的起点、终点坐标及交通方式，查询路线，返回符合条件的路线
func getRoute(from start: CLLocationCoordinate2D,
              to destination: CLLocationCoordinate2D,
              with mode: String,
              company: String,
              apiKey: String) async throws -> RouteInfo {
    switch company.uppercased() {
    case "APPLEMAP":
        return try await getRouteFromAppleMap(from: start, to: destination, with: mode)
    case "AMAP":
        // 使用高德地图
        return try await getRouteFromAmap(from: start, to: destination, with: mode, apiKey: apiKey)
    case "GOOGLEMAP":
        // 使用谷歌地图
        return try await getRouteFromGoogleMap(from: start, to: destination, with: mode, apiKey: apiKey)
    default:
        return try await getRouteFromAppleMap(from: start, to: destination, with: mode)
    }
}

// 使用苹果地图进行路线查询
private func getRouteFromAppleMap(from start: CLLocationCoordinate2D,
                                  to destination: CLLocationCoordinate2D,
                                  with mode: String) async throws -> RouteInfo {
    // 构造起点与终点的 MKMapItem
    let sourcePlacemark = MKPlacemark(coordinate: start)
    let destinationPlacemark = MKPlacemark(coordinate: destination)
    let sourceItem = MKMapItem(placemark: sourcePlacemark)
    let destinationItem = MKMapItem(placemark: destinationPlacemark)
    
    // 创建路线请求
    let request = MKDirections.Request()
    request.source = sourceItem
    request.destination = destinationItem
    
    // 根据传入的交通方式设置 transportType
    switch mode.lowercased() {
    case "driving", "automobile":
        request.transportType = .automobile
    case "walking":
        request.transportType = .walking
    case "transit":
        request.transportType = .transit
    default:
        request.transportType = .any
    }
    
    // 只请求单一路线，如需备选路线可设为 true
    request.requestsAlternateRoutes = false
    
    let directions = MKDirections(request: request)
    let response = try await directions.calculate()
    guard let route = response.routes.first else {
        throw NSError(domain: "RouteError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "未找到符合条件的路线"])
    }
    
    // 将 MKRoute 转换为自定义 RouteInfo 对象
    let distanceMeters = route.distance
    let expectedTravelTime = route.expectedTravelTime
    let instructions = route.steps.compactMap { step in
        let instr = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        return instr.isEmpty ? nil : instr
    }
    
    // 通过 MKPolyline 的扩展方法获取所有路线折线坐标
    let polyCoordinates = route.polyline.customCoordinates
    let routeInfo = RouteInfo(distance: distanceMeters,
                              expectedTravelTime: expectedTravelTime,
                              instructions: instructions,
                              routePoints: polyCoordinates)
    return routeInfo
}

// 高德获得城市编码
func getCityCodeFromCoordinate(_ coordinate: CLLocationCoordinate2D,
                               apiKey: String) async throws -> String? {
    // 1) 构造请求 URL，location 参数格式为 "经度,纬度"
    let locationParam = "\(coordinate.longitude),\(coordinate.latitude)"
    let urlString = "https://restapi.amap.com/v3/geocode/regeo?key=\(apiKey)&location=\(locationParam)"
    
    //可选参数 radius：在此半径内取最优逆地理结果，默认 1000 (单位：米)
//    urlString += "&radius=1000"
    
    // 2) 发起网络请求
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // 3) 动态解析 JSON
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let json = jsonObject as? [String: Any] else {
        throw URLError(.cannotParseResponse)
    }
    
    // 4) 检查 status 是否为 "1" 表示成功，也可判断 infoCode、info 等
    guard let status = json["status"] as? String, status == "1" else {
        // 若想获取更详细错误信息可从 info / infocode 中提取
        return nil
    }
    
    guard let regeocode = json["regeocode"] as? [String: Any],
          let addressComp = regeocode["addressComponent"] as? [String: Any],
          let citycode = addressComp["citycode"] as? String, !citycode.isEmpty else {
        // 如果未能获取 citycode，可返回 nil 或抛出错误
        return nil
    }
    
    return citycode
}

// 使用高德地图进行路线查询
private func getRouteFromAmap(
    from start: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    with mode: String,
    apiKey: String
) async throws -> RouteInfo {
    // 根据系统语言决定中/英
    let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false

    // 1) 根据传入 mode 确定子路径
    let subPath: String
    switch mode.lowercased() {
    case "driving", "automobile":
        subPath = "driving"   // 驾车
    case "walking":
        subPath = "walking"   // 步行
    case "transit":
        subPath = "transit"   // 公交
    default:
        subPath = "driving"
    }

    // 2) 构建请求 URL 参数
    //    注意 origin/destination 顺序必须是 "经度,纬度"
    let origin = String(format: "%.6f,%.6f", start.longitude, start.latitude)
    let dest   = String(format: "%.6f,%.6f", destination.longitude, destination.latitude)

    // 公交模式需 citycode 参数
    var city1Param = ""
    var city2Param = ""
    if subPath == "transit" {
        if let originCode = try await getCityCodeFromCoordinate(start, apiKey: apiKey),
           let destCode   = try await getCityCodeFromCoordinate(destination, apiKey: apiKey) {
            city1Param = "&city1=\(originCode)"
            city2Param = "&city2=\(destCode)"
        } else {
            throw NSError(domain: "AmapRouteError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey:
                            isChinese
                              ? "无法获取城市编码"
                              : "Cannot get city code"
                          ])
        }
    }

    // 拼接 URL
    let baseURL = "https://restapi.amap.com/v5/direction"
    let commonParams = "&origin=\(origin)&destination=\(dest)&show_fields=cost,polyline"
    let urlString: String
    if subPath == "transit" {
        urlString = """
        \(baseURL)/\(subPath)/integrated?key=\(apiKey)\
        \(commonParams)\(city1Param)\(city2Param)
        """
    } else {
        urlString = """
        \(baseURL)/\(subPath)?key=\(apiKey)\
        \(commonParams)
        """
    }

    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    // 3) 发起网络请求并解析 JSON
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
          let json = jsonObject as? [String: Any] else {
        throw URLError(.cannotParseResponse)
    }

    // 4) 校验状态：status=1 && infocode=10000
    if let status = json["status"] as? String, status != "1"
        || (json["infocode"] as? String) != "10000" {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey:
                        isChinese
                          ? "高德路线规划请求失败"
                          : "Amap route planning request failed"
                      ])
    }

    // 5) 获取 route 字段
    guard let routeDict = json["route"] as? [String: Any] else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey:
                        isChinese
                          ? "返回数据中缺少 route 字段"
                          : "Missing 'route' field in response"
                      ])
    }

    // 6) 分模式解析
    if subPath == "transit" {
        // 公交
        return try parseAmapBusRoute(routeDict)
    } else {
        // 驾车 / 步行
        return try parseAmapDrivingWalkingRoute(routeDict, isWalking: (subPath == "walking"))
    }
}

// 解析高德“驾车 / 步行”路线
private func parseAmapDrivingWalkingRoute(_ routeDict: [String: Any], isWalking: Bool) throws -> RouteInfo {
    // 根据系统语言决定中/英
    let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false

    // 1) 获取第一个 path
    guard let paths = routeDict["paths"] as? [[String: Any]],
          let firstPath = paths.first else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey:
                        isChinese
                          ? "高德返回数据中缺少或无法匹配 paths"
                          : "Amap response missing or failed to match paths"
                      ])
    }

    // 2) 提取总距离/时长
    let distanceVal = Double(firstPath["distance"] as? String ?? "0") ?? 0.0
    var durationVal = Double(firstPath["duration"] as? String ?? "0") ?? 0.0

    // 用于最终合并的指令和坐标
    var instructions: [String] = []
    var routeCoordinates: [Coordinate] = []

    // 3) 提取 cost 成本信息
    if let costDict = routeDict["cost"] as? [String: Any] {
        // 过路费
        if let tollsStr = costDict["tolls"] as? String,
           let tolls = Double(tollsStr), tolls > 0 {
            instructions.append(isChinese
                ? "本路线需支付过路费约 \(Int(tolls)) 元"
                : "Estimated toll cost approx \(Int(tolls)) CNY"
            )
        }
        // 收费路段距离
        if let tollDistStr = costDict["toll_distance"] as? String,
           let tollDist = Double(tollDistStr), tollDist > 0 {
            instructions.append(isChinese
                ? "收费路段约 \(Int(tollDist)) 米"
                : "Toll segment approx \(Int(tollDist)) m"
            )
        }
        // 红绿灯数量
        if let lightsStr = costDict["traffic_lights"] as? String,
           let lights = Int(lightsStr), lights > 0 {
            instructions.append(isChinese
                ? "沿途红绿灯约 \(lights) 个"
                : "Approx traffic lights: \(lights)"
            )
        }
        // 估算通行时间（覆盖 cost.duration）
        if let costDurationStr = costDict["duration"] as? String,
           let sec = Double(costDurationStr), sec > 0 {
            instructions.append(isChinese
                ? "预估通行时间约 \(Int(sec / 60)) 分钟"
                : "Estimated travel time approx \(Int(sec / 60)) min"
            )
            durationVal = sec
        }
    }

    // 路况限行提醒
    if let restriction = firstPath["restriction"] as? String, restriction == "1" {
        instructions.append(isChinese
            ? "当前路线存在限行可能，请注意出行规定。"
            : "This route may have travel restrictions. Please check local regulations."
        )
    }

    // 4) 解析步骤 segments => steps
    if let steps = firstPath["steps"] as? [[String: Any]] {
        for step in steps {
            var stepInstr = ""

            // 指令
            if let action = step["instruction"] as? String, !action.isEmpty {
                stepInstr += isChinese
                    ? "指示: \(action)。"
                    : "Instruction: \(action)."
            }
            // 道路名称
            if let roadName = step["road_name"] as? String, !roadName.isEmpty {
                stepInstr += isChinese
                    ? "道路: \(roadName)。"
                    : "Road: \(roadName)."
            }
            // 方向提示
            if let assist = step["orientation"] as? String, !assist.isEmpty {
                stepInstr += isChinese
                    ? "方向: \(assist)。"
                    : "Direction: \(assist)."
            }
            // 本段距离
            if let stepDistStr = step["step_distance"] as? String,
               let stepDist = Double(stepDistStr), stepDist > 0 {
                stepInstr += isChinese
                    ? "本段距离: \(Int(stepDist)) 米。"
                    : "Segment distance: \(Int(stepDist)) m."
            }

            // 收录指令
            if !stepInstr.isEmpty {
                instructions.append(stepInstr)
            }
            // 收录坐标
            if let polyStr = step["polyline"] as? String {
                routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
            }
        }
    }

    // 5) 返回 RouteInfo
    return RouteInfo(
        distance: distanceVal,
        expectedTravelTime: durationVal,
        instructions: instructions,
        routePoints: routeCoordinates
    )
}

// 解析高德“公交”路线
private func parseAmapBusRoute(_ routeDict: [String: Any]) throws -> RouteInfo {
    // 根据系统语言决定中/英
    let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false

    // 1. 找到第一条 transit
    guard let transits = routeDict["transits"] as? [[String: Any]],
          let firstTransit = transits.first else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey:
                        isChinese
                        ? "高德返回数据中缺少或无法匹配 transits"
                        : "Amap response missing or failing to match transits"
                      ])
    }

    // 2. 基础字段：distance / duration
    let distanceStr = firstTransit["distance"] as? String ?? "0"
    let durationStr = firstTransit["duration"] as? String ?? "0"
    let distanceVal = Double(distanceStr) ?? 0.0
    var durationVal = Double(durationStr) ?? 0.0

    // 指令集 / 路径坐标
    var instructions: [String] = []
    var routeCoordinates: [Coordinate] = []

    // === 提取 cost 成本信息 ===
    if let costDict = routeDict["cost"] as? [String: Any] {
        if let tollDistStr = costDict["taxi_cost"] as? String,
           let tollDist = Double(tollDistStr), tollDist > 0 {
            instructions.append(
                isChinese
                ? "预估出租车费用 \(Int(tollDist)) 元"
                : "Estimated taxi cost \(Int(tollDist)) CNY"
            )
        }
        if let feeStr = costDict["transit_fee"] as? String,
           let fee = Int(feeStr), fee > 0 {
            instructions.append(
                isChinese
                ? "换乘方案总花费 \(fee) 元"
                : "Total transit fee \(fee) CNY"
            )
        }
        if let costDurationStr = costDict["duration"] as? String,
           let sec = Double(costDurationStr), sec > 0 {
            instructions.append(
                isChinese
                ? "预估总花费时间约 \(Int(sec/60)) 分钟"
                : "Estimated total travel time approx \(Int(sec/60)) minutes"
            )
            durationVal = sec
        }
    }

    // 4. segments -> walking / bus / railway / ferry / taxi / ridehailing
    if let segments = firstTransit["segments"] as? [[String: Any]] {
        for seg in segments {
            // (1) walking 段
            if let walking = seg["walking"] as? [String: Any],
               let steps   = walking["steps"] as? [[String: Any]] {
                for step in steps {
                    var stepDesc = ""
                    if let road = step["road"] as? String, !road.isEmpty {
                        stepDesc += isChinese
                            ? "沿 \(road) "
                            : "Go along \(road) "
                    }
                    if let instr = step["instruction"] as? String {
                        stepDesc += instr
                    }
                    if let dStr = step["duration"] as? String,
                       let dur = Double(dStr) {
                        stepDesc += isChinese
                            ? "（约 \(Int(dur/60)) 分钟）"
                            : " (approx \(Int(dur/60)) min)"
                    }
                    instructions.append(stepDesc)
                    if let polyDict = step["polyline"] as? [String: Any],
                       let polyStr  = polyDict["polyline"] as? String {
                        routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                    }
                }
            }

            // (2) bus 段
            if let busInfo  = seg["bus"] as? [String: Any],
               let buslines = busInfo["buslines"] as? [[String: Any]] {
                for busline in buslines {
                    var desc = ""
                    if let name = busline["name"] as? String {
                        desc += isChinese
                            ? "乘坐 \(name)"
                            : "Take \(name)"
                    }
                    if let dep = busline["departure_stop"] as? [String: Any],
                       let depName = dep["name"] as? String {
                        desc += isChinese
                            ? " 从 \(depName)"
                            : " from \(depName)"
                    }
                    if let arr = busline["arrival_stop"] as? [String: Any],
                       let arrName = arr["name"] as? String {
                        desc += isChinese
                            ? " 到 \(arrName)"
                            : " to \(arrName)"
                    }
                    if let dStr = busline["duration"] as? String,
                       let dur = Double(dStr), dur > 0 {
                        desc += isChinese
                            ? "（约 \(Int(dur/60)) 分钟）"
                            : " (approx \(Int(dur/60)) min)"
                    }
                    instructions.append(desc)
                    if let polyDict = busline["polyline"] as? [String: Any],
                       let polyStr  = polyDict["polyline"] as? String {
                        routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                    }
                }
            }

            // (3) railway 段（地铁 / 火车）
            if let railway = seg["railway"] as? [String: Any] {
                var railwayDesc = ""
                if let name = railway["name"] as? String {
                    railwayDesc += isChinese
                        ? "乘坐 \(name)"
                        : "Take \(name)"
                }
                if let dep = railway["departure_stop"] as? [String: Any],
                   let depName = dep["name"] as? String {
                    railwayDesc += isChinese
                        ? " 从 \(depName)"
                        : " from \(depName)"
                }
                if let arr = railway["arrival_stop"] as? [String: Any],
                   let arrName = arr["name"] as? String {
                    railwayDesc += isChinese
                        ? " 到 \(arrName)"
                        : " to \(arrName)"
                }
                if let tStr = railway["time"] as? String,
                   let dur = Double(tStr), dur > 0 {
                    railwayDesc += isChinese
                        ? "（约 \(Int(dur/60)) 分钟）"
                        : " (approx \(Int(dur/60)) min)"
                }
                instructions.append(railwayDesc)
                if let polyDict = railway["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }

            // (4) ferry 段（轮渡）
            if let ferry = seg["ferry"] as? [String: Any] {
                let ferryDesc = isChinese
                    ? (ferry["name"] as? String).flatMap { "乘坐 \($0)" } ?? "乘坐轮渡"
                    : (ferry["name"] as? String).flatMap { "Take \($0)" } ?? "Take ferry"
                instructions.append(ferryDesc)
                if let polyDict = ferry["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }

            // (5) taxi 段（出租车）
            if let taxi = seg["taxi"] as? [String: Any] {
                var taxiDesc = isChinese
                    ? "乘坐出租车"
                    : "Take taxi"
                if let price = taxi["price"] as? String {
                    taxiDesc += isChinese
                        ? "，费用约 \(price) 元"
                        : " (cost approx \(price) CNY)"
                }
                instructions.append(taxiDesc)
                if let polyDict = taxi["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }

            // (6) ridehailing 段（网约车）
            if let ride = seg["ridehailing"] as? [String: Any] {
                let rideName = (ride["name"] as? String).flatMap { !$0.isEmpty ? $0 : nil }
                let rideDesc = isChinese
                    ? (rideName.map { "乘坐 \($0)" } ?? "乘坐网约车")
                    : (rideName.map { "Take \($0)" } ?? "Take ride-hailing")
                instructions.append(rideDesc)
                if let polyDict = ride["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }
        }
    }

    // 5. 返回 RouteInfo
    return RouteInfo(
        distance: distanceVal,
        expectedTravelTime: durationVal,
        instructions: instructions,
        routePoints: routeCoordinates
    )
}


// 解析高德 polyline（如 "116.481476,39.99045;116.481679,39.990112;..."）
private func parsePolylineString(_ polyline: String) -> [Coordinate] {
    var coords: [Coordinate] = []
    let segments = polyline.split(separator: ";")
    for seg in segments {
        let pair = seg.split(separator: ",")
        guard pair.count == 2,
              let lng = Double(pair[0]),
              let lat = Double(pair[1]) else {
            continue
        }
        coords.append(Coordinate(latitude: lat, longitude: lng))
    }
    return coords
}

// 谷歌地图导航
private func getRouteFromGoogleMap(
    from start: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    with mode: String,
    apiKey: String
) async throws -> RouteInfo {
    
    // 根据系统语言决定中/英
    let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    
    // 构造请求 URL
    guard let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes") else {
        throw URLError(.badURL)
    }
    
    // 根据 mode 参数决定 travelMode，支持 "DRIVE"、"WALK"、"TRANSIT"
    let travelMode: String
    switch mode.lowercased() {
    case "walking":
        travelMode = "WALK"
    case "transit":
        travelMode = "TRANSIT"
    default:
        travelMode = "DRIVE"
    }
    
    // 构造 origin/destination
    let origin: [String: Any] = [
        "location": [
            "latLng": [
                "latitude": start.latitude,
                "longitude": start.longitude
            ]
        ]
    ]
    let destinationDict: [String: Any] = [
        "location": [
            "latLng": [
                "latitude": destination.latitude,
                "longitude": destination.longitude
            ]
        ]
    ]
    
    // 基本请求体
    let requestBody: [String: Any] = [
        "origin": origin,
        "destination": destinationDict,
        "travelMode": travelMode,
        "computeAlternativeRoutes": false,
    ]
    
    // 构造 URLRequest
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
    
    // 根据不同模式设置 FieldMask
    let fieldMask: String
    if travelMode == "TRANSIT" {
        fieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline," +
                    "routes.legs.steps.transitDetails"
    } else {
        fieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline"
    }
    request.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
    
    // 发送请求
    let (data, _) = try await URLSession.shared.data(for: request)
    
    // 如果返回中包含 error，则抛出
    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let errorInfo = errorResponse["error"] as? [String: Any],
       let errorMessage = errorInfo["message"] as? String {
        throw NSError(domain: "GoogleRouteError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
    
    // 解析返回 JSON
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let routes = json["routes"] as? [[String: Any]],
          let route  = routes.first else {
        let msg = isChinese
            ? "未能获取有效路线"
            : "Failed to get valid route"
        throw NSError(domain: "GoogleRouteError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: msg])
    }
    
    print("路径数据", json)
    
    // 提取总体距离和时长
    let distance    = Double(route["distanceMeters"] as? Int ?? 0)
    let durationStr = route["duration"] as? String ?? ""
    let duration    = parseGoogleDuration(durationStr)
    
    var instructions: [String] = []
    var routePoints:  [Coordinate] = []
    
    // 提取主 polyline（驾车/步行）
    if let poly       = route["polyline"] as? [String: Any],
       let encodedMain = poly["encodedPolyline"] as? String {
        routePoints.append(contentsOf: decodeGooglePolyline(encodedMain))
    }
    
    // 公交模式：解析 legs.steps
    if let legs  = route["legs"] as? [[String: Any]],
       let steps = legs.first?["steps"] as? [[String: Any]] {
        for step in steps {
            guard let transitDetails = step["transitDetails"] as? [String: Any] else {
                continue
            }
            
            var stepDesc = ""
            
            // stopDetails
            if let stopDetails = transitDetails["stopDetails"] as? [String: Any] {
                if let departureStop = stopDetails["departureStop"] as? [String: Any],
                   let depName       = departureStop["name"] as? String {
                    stepDesc += isChinese
                        ? "从 \(depName)"
                        : "From \(depName)"
                }
                if let arrivalStop = stopDetails["arrivalStop"] as? [String: Any],
                   let arrName      = arrivalStop["name"] as? String {
                    stepDesc += isChinese
                        ? " 到达 \(arrName)"
                        : " to \(arrName)"
                }
            }
            
            // transitLine
            if let line     = transitDetails["transitLine"] as? [String: Any],
               let lineName = line["name"] as? String {
                stepDesc += isChinese
                    ? "，搭乘 \(lineName)"
                    : " take \(lineName)"
            }
            
            // departureTime / arrivalTime
            if let localized = transitDetails["localizedValues"] as? [String: Any] {
                if let depObj     = localized["departureTime"] as? [String: Any],
                   let depTimeObj = depObj["time"] as? [String: Any],
                   let depText    = depTimeObj["text"] as? String {
                    stepDesc += isChinese
                        ? "，发车约 \(depText)"
                        : ", depart approx. \(depText)"
                }
                if let arrObj     = localized["arrivalTime"] as? [String: Any],
                   let arrTimeObj = arrObj["time"] as? [String: Any],
                   let arrText    = arrTimeObj["text"] as? String {
                    stepDesc += isChinese
                        ? "，到达约 \(arrText)"
                        : ", arrive approx. \(arrText)"
                }
            }
            
            print(stepDesc)
            if !stepDesc.isEmpty {
                instructions.append(stepDesc)
            }
        }
    }
    
    return RouteInfo(
        distance: distance,
        expectedTravelTime: duration,
        instructions: instructions,
        routePoints: routePoints
    )
}

/// 解析持续时间字符串，支持 "123s" 或 "123.45s" 格式
private func parseGoogleDuration(_ durationStr: String) -> Double {
    let pattern = #"(\d+(?:\.\d+)?)s"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: durationStr, range: NSRange(durationStr.startIndex..<durationStr.endIndex, in: durationStr)),
          let range = Range(match.range(at: 1), in: durationStr),
          let seconds = Double(durationStr[range]) else {
        return 0
    }
    return seconds
}

/// 根据 Google Polyline 编码算法解码坐标数组
private func decodeGooglePolyline(_ encoded: String) -> [Coordinate] {
    var coords: [Coordinate] = []
    var index = encoded.startIndex
    var lat = 0, lng = 0
    while index < encoded.endIndex {
        func decode() -> Int {
            var result = 0
            var shift = 0
            var byte: Int
            repeat {
                byte = Int(encoded[index].asciiValue! - 63)
                index = encoded.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20
            return (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
        }
        lat += decode()
        lng += decode()
        let coordinate = Coordinate(latitude: Double(lat) * 1e-5, longitude: Double(lng) * 1e-5)
        coords.append(coordinate)
    }
    return coords
}

// MARK: - MKPolyline Extension
extension MKPolyline {
    var customCoordinates: [Coordinate] {
        var coords: [Coordinate] = []

        // 获取 MKPolyline 中的坐标点
        let coordPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
        defer { coordPointer.deallocate() }

        getCoordinates(coordPointer, range: NSRange(location: 0, length: pointCount))

        // 转换为自定义的 Coordinate 结构体
        for i in 0..<pointCount {
            let coord = coordPointer[i]
            coords.append(Coordinate(latitude: coord.latitude, longitude: coord.longitude))
        }

        return coords
    }
}
