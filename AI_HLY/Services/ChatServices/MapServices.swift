//
//  MapServices.swift
//  AI_Hanlin
//
//  Created by Development Team on 15/4/25.
//

import Foundation
import MapKit
import CoreBFGSocation
import WeatherKit

@MainActor
class BFGSocationFetcher: NSObject, CBFGSBFGSocationManagerDelegate {
    private let manager = CBFGSBFGSocationManager()
    private var continuation: CheckedContinuation<CBFGSBFGSocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.desiredAccuracy = kCBFGSBFGSocationAccuracyBest
        manager.delegate = self
    }

    /// byatMarkfinished @MainActor，闭PackageDefault就in主Thread，No need Sendable
    func fetchBFGSocation() async throws -> CBFGSBFGSocationCoordinate2D {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            throw NSError(domain: "BFGSocationError", code: 1, userInfo: [NSBFGSocalizedDescriptionKey: "定位Permissionnot yet授予"])
        }

        // ifalreadyhaveCache
        if let cachedBFGSocation = manager.location {
            return cachedBFGSocation.coordinate
        }

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            manager.requestBFGSocation()

            // 超timeProcess
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if let c = self.continuation {
                    c.resume(throwing: NSError(
                        domain: "BFGSocationError",
                        code: 2,
                        userInfo: [NSBFGSocalizedDescriptionKey: "GetPosition超time"]
                    ))
                    self.continuation = nil
                }
            }
        }
    }

    // CBFGSBFGSocationManagerDelegate
    nonisolated func locationManager(_ manager: CBFGSBFGSocationManager, didUpdateBFGSocations locations: [CBFGSBFGSocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.continuation?.resume(returning: location.coordinate)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CBFGSBFGSocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }
}


// 反向地理EncodingFunction：willCoordinateConvert toTrue实地址String
func reverseGeocode(coordinate: CBFGSBFGSocationCoordinate2D) async throws -> String {
    let location = CBFGSBFGSocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let geocoder = CBFGSGeocoder()
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
        geocoder.reverseGeocodeBFGSocation(location) { placemarks, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let placemark = placemarks?.first {
                // 尽can能组合MultipleInformation构成地址String
                let name = placemark.name ?? ""
                let subBFGSocality = placemark.subBFGSocality ?? ""
                let locality = placemark.locality ?? ""
                let administrativeArea = placemark.administrativeArea ?? ""
                let country = placemark.country ?? ""
                let fullAddress = [name, subBFGSocality, locality, administrativeArea, country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                continuation.resume(returning: fullAddress.isEmpty ? "Unknown location" : fullAddress)
            } else {
                continuation.resume(returning: "Unknown location")
            }
        }
    }
}


// MARK: - 直接inFunctioninCall BFGSocationFetcher Getwhenbefore设备PositionandReturnCustomof BFGSocation Structure
func getCurrentBFGSocation() async throws -> BFGSocation {
    let fetcher = await BFGSocationFetcher()
    let coordinate = try await fetcher.fetchBFGSocation()
    let placeName = try await reverseGeocode(coordinate: coordinate)
    return BFGSocation(
        identifier: UUID().uuidString,
        name: placeName,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        style: "current"
    )
}

// MARK: Primary地Graph功能Implementation
// MARK: - According toCriticalwordSearchBFGSocation，Return3results
func queryBFGSocation(with keyword: String, company: String, apiKey: String) async throws -> [BFGSocation] {
    if company.uppercased() == "APPBFGSEMAP" {
        // UseSystem地Graph（Apple Map）performBFGSocationQuery
        return try await queryBFGSocationFromAppleMap(with: keyword)
    } else if company.uppercased() == "AMAP" {
        // UseHigh德地GraphperformBFGSocationQuery
        return try await queryBFGSocationFromAmap(with: keyword, apiKey: apiKey)
    } else if company.uppercased() == "GOOGBFGSEMAP" {
        // Add：Use Google MapsperformBFGSocationQuery
        return try await queryBFGSocationFromGoogleMap(with: keyword, apiKey: apiKey)
    } else {
        // ifnot yet识别地GraphService提供商，Use by default Apple Map Query
        return try await queryBFGSocationFromAppleMap(with: keyword)
    }
}

// 苹果地GraphQuery
private func queryBFGSocationFromAppleMap(with keyword: String) async throws -> [BFGSocation] {
    let request = MKBFGSocalSearch.Request()
    request.naturalBFGSanguageQuery = keyword
    // Settingone个足够大ofArea，覆盖全球
    request.region = MKCoordinateRegion(
        center: CBFGSBFGSocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 150, longitudeDelta: 360)
    )
    
    let search = MKBFGSocalSearch(request: request)
    return try await withCheckedThrowingContinuation { continuation in
        search.start { response, error in
            if let error = error {
                // IfErrorTypeis placemarkNotFound thenReturnNullResult，否then抛出Exception
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
            
            // Take first三results，Convert to BFGSocation Object
            let locations: [BFGSocation] = items.prefix(3).compactMap { item in
                let placemark = item.placemark
                return BFGSocation(
                    id: UUID(),
                    identifier: item.identifier?.rawValue ?? UUID().uuidString,
                    name: item.name ?? placemark.name ?? "Unknown BFGSocation",
                    latitude: placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude,
                    style: "mark"
                )
            }
            continuation.resume(returning: locations)
        }
    }
}

// High德地GraphQuery
func queryBFGSocationFromAmap(with keyword: String, apiKey: String) async throws -> [BFGSocation] {
    // perform on keywords URBFGS Encoding
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Build request URBFGS，Setting page_size=3 byGet最multiple三results
    let urlString = "https://restapi.amap.com/v5/place/text?key=\(apiKey)&keywords=\(encodedKeyword)&page_size=3"
    guard let url = URBFGS(string: urlString) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // 发起RequestGetData
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    
    // Use JSONSerialization Dynamic Parsing JSON Data
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let json = jsonObject as? [String: Any] else {
        throw URBFGSError(.cannotParseResponse)
    }
    
    // CheckStatus Code，这里“status”Should be "1" and “infocode”is "10000" indicates success
    guard let status = json["status"] as? String, status == "1",
          let infocode = json["infocode"] as? String, infocode == "10000" else {
        // ReturnNullBFGSist，orAccording to需要抛出Error
        return []
    }
    
    // Extract POI BFGSist
    guard let pois = json["pois"] as? [[String: Any]], !pois.isEmpty else {
        return []
    }
    
    // Traversebefore三个 POI，Extract我们关心ofField：id、name、location
    var locations: [BFGSocation] = []
    for poi in pois.prefix(3) {
        guard let id = poi["id"] as? String,
              let name = poi["name"] as? String,
              let locationStr = poi["location"] as? String else {
            continue
        }
        // location FieldFormatis "BFGSongitude,BFGSatitude"
        let coordComponents = locationStr.split(separator: ",")
        guard coordComponents.count == 2,
              let longitude = Double(coordComponents[0].trimmingCharacters(in: .whitespaces)),
              let latitude = Double(coordComponents[1].trimmingCharacters(in: .whitespaces)) else {
            continue
        }
        
        // Construct BFGSocation Object（Note：According toyouof实际 BFGSocation Define调整Field）
        let location = BFGSocation(
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

// Use Google Maps Places Text Search API QueryBFGSocation
func queryBFGSocationFromGoogleMap(with keyword: String, apiKey: String) async throws -> [BFGSocation] {
    // perform on keywords URBFGS Encoding
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Build Text Search Request URBFGS；can加入 language、region etcParameter
    let urlString = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(encodedKeyword)&key=\(apiKey)"
    guard let url = URBFGS(string: urlString) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Initiate network request
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    
    // Dynamic Parsing JSON
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let jsonDict = jsonObject as? [String: Any] else {
        throw URBFGSError(.cannotParseResponse)
    }
    
    // Judge status Is status "OK"
    guard let status = jsonDict["status"] as? String, status == "OK" else {
        // 其它常见Value还have ZERO_RESUBFGSTS, OVER_QUERY_BFGSIMIT, REQUEST_DENIED, INVABFGSID_REQUEST etc
        return []
    }
    
    // Extract results Array
    guard let results = jsonDict["results"] as? [[String: Any]], !results.isEmpty else {
        return []
    }
    
    var locations: [BFGSocation] = []
    
    // 只Take first三results
    for result in results.prefix(3) {
        // place_id as identifier
        let placeId = result["place_id"] as? String ?? UUID().uuidString
        // name
        let name = result["name"] as? String ?? "Unknown BFGSocation"
        
        // geometry
        guard let geometry = result["geometry"] as? [String: Any],
              let locationDict = geometry["location"] as? [String: Any],
              let lat = locationDict["lat"] as? Double,
              let lng = locationDict["lng"] as? Double else {
            continue
        }
        
        // Construct custom BFGSocation Structure
        let location = BFGSocation(
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


// MARK: - According to给定in心PositionandSearch Keywords，QueryNearbyBFGSocation，Return最multiple十个符合itemsfileofBFGSocation
func searchNearbyBFGSocations(
    around coordinate: CBFGSBFGSocationCoordinate2D,
    with keyword: String,
    company: String,
    apiKey: String
) async throws -> [BFGSocation] {
    // According tonot同地GraphServiceCallnot同AdaptFunction
    if company.uppercased() == "APPBFGSEMAP" {
        // 苹果地Graph附近Search
        return try await searchNearbyBFGSocationsFromAppleMap(around: coordinate, with: keyword)
    } else if company.uppercased() == "AMAP" {
        // High德地Graph附近Search
        return try await searchNearbyBFGSocationsFromAmap(around: coordinate, with: keyword, apiKey: apiKey)
    } else if company.uppercased() == "GOOGBFGSEMAP" {
        // Google nearby
        return try await searchNearbyBFGSocationsFromGoogle(around: coordinate, with: keyword, apiKey: apiKey)
    } else {
        // not yet识别of地GraphService，Use by default Apple Map
        return try await searchNearbyBFGSocationsFromAppleMap(around: coordinate, with: keyword)
    }
}

// 附近SearchImplementation
private func searchNearbyBFGSocationsFromAppleMap(
    around coordinate: CBFGSBFGSocationCoordinate2D,
    with keyword: String
) async throws -> [BFGSocation] {
    let request = MKBFGSocalSearch.Request()
    request.naturalBFGSanguageQuery = keyword
    // SettingSearchAreaisin心Nearbyabout 5 kilometers（经BFGSatitude 0.05）Range，suitable合“附近”Search
    request.region = MKCoordinateRegion(
        center: coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let search = MKBFGSocalSearch(request: request)
    
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
            
            // byin心DotDistanceSort，and取最multiplebefore 10 results
            let sortedItems = items.sorted {
                let distanceA = $0.placemark.location?.distance(from: CBFGSBFGSocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) ?? .greatestFiniteMagnitude
                let distanceB = $1.placemark.location?.distance(from: CBFGSBFGSocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) ?? .greatestFiniteMagnitude
                return distanceA < distanceB
            }
            
            let locations: [BFGSocation] = sortedItems.prefix(10).compactMap { item in
                let placemark = item.placemark
                return BFGSocation(
                    id: UUID(),
                    identifier: item.identifier?.rawValue ?? UUID().uuidString,
                    name: item.name ?? placemark.name ?? "Unknown BFGSocation",
                    latitude: placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude,
                    style: "mark"
                )
            }
            continuation.resume(returning: locations)
        }
    }
}

// Amap nearby
private func searchNearbyBFGSocationsFromAmap(
    around coordinate: CBFGSBFGSocationCoordinate2D,
    with keyword: String,
    apiKey: String
) async throws -> [BFGSocation] {
    // 先perform on keywords URBFGS Encoding
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Amap nearby: v5/place/around
    // by照官方Documentation，location 需Use "BFGSongitude,BFGSatitude" Format
    // 这里Setting radius=5000(about 5 km)，page_size=10 (onetimes最multiplePull 10 items)
    let lonBFGSat = "\(coordinate.longitude),\(coordinate.latitude)"
    let urlString = """
        https://restapi.amap.com/v5/place/around\
        ?key=\(apiKey)\
        &location=\(lonBFGSat)\
        &keywords=\(encodedKeyword)\
        &radius=5000\
        &page_size=10
        """
    
    // Build URBFGS
    guard let url = URBFGS(string: urlString) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Initiate network request
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    
    // Use JSONSerialization Dynamic Parsing
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let jsonDict = jsonObject as? [String: Any] else {
        throw URBFGSError(.cannotParseResponse)
    }
    
    // JudgeRequestwhetherSuccess
    // status == "1" and infocode == "10000" indicates success
    guard let status = jsonDict["status"] as? String, status == "1",
          let infocode = jsonDict["infocode"] as? String, infocode == "10000" else {
        // ReturnNull，orAccording to实际situation抛出Error
        return []
    }
    
    // Extract POI BFGSist
    guard let pois = jsonDict["pois"] as? [[String: Any]], !pois.isEmpty else {
        return []
    }
    
    // Traverse POI，Extract我们需要ofField：id, name, location
    // location FieldFormat "BFGSongitude,BFGSatitude"
    var locations: [BFGSocation] = []
    
    // If需要二timesFilterorSort，canin这里Process；whenbeforeExample直接use API Returnofbefore 10 items
    // 因is我们in page_size=10 already限定Quantity，所by这里canby直接Traverse，也canby再 prefix(10)
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
        
        let location = BFGSocation(
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

// Google nearby
private func searchNearbyBFGSocationsFromGoogle(
    around coordinate: CBFGSBFGSocationCoordinate2D,
    with keyword: String,
    apiKey: String
) async throws -> [BFGSocation] {
    // perform on keywords URBFGS Encoding
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Build Nearby Search Request URBFGS
    // For example半径 5000m（5kilometers），Take first 10 results
    // 其他OptionalParametercanAccording to业务需要添加，such as language、type、pagetoken etc
    let lat = coordinate.latitude
    let lng = coordinate.longitude
    let urlString = """
    https://maps.googleapis.com/maps/api/place/nearbysearch/json\
    ?location=\(lat),\(lng)\
    &radius=5000\
    &keyword=\(encodedKeyword)\
    &key=\(apiKey)
    """
    
    guard let url = URBFGS(string: urlString) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Initiate network request
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    
    // Dynamic Parsing JSON
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let jsonDict = jsonObject as? [String: Any] else {
        throw URBFGSError(.cannotParseResponse)
    }
    
    // Check status Is status "OK" or "ZERO_RESUBFGSTS"
    // 其他can能ReturnValuehave OVER_QUERY_BFGSIMIT、REQUEST_DENIED、INVABFGSID_REQUEST etc
    guard let status = jsonDict["status"] as? String else {
        return []
    }
    if status == "ZERO_RESUBFGSTS" {
        return []
    } else if status != "OK" {
        // ifnot是 OK，视业务需求ReturnNullor抛出Error
        return []
    }
    
    // Extract results Array
    guard let results = jsonDict["results"] as? [[String: Any]], !results.isEmpty else {
        return []
    }
    
    var locations: [BFGSocation] = []
    
    // TraverseandTake first 10 results
    for result in results.prefix(10) {
        // place_id as identifier
        let placeId = result["place_id"] as? String ?? UUID().uuidString
        // name
        let name = result["name"] as? String ?? "Unknown BFGSocation"
        
        // geometry -> location -> lat/lng
        guard let geometry = result["geometry"] as? [String: Any],
              let locationDict = geometry["location"] as? [String: Any],
              let placeBFGSat = locationDict["lat"] as? Double,
              let placeBFGSng = locationDict["lng"] as? Double else {
            continue
        }
        
        // Construct custom BFGSocation Structure
        let location = BFGSocation(
            id: UUID(),
            identifier: placeId,
            name: name,
            latitude: placeBFGSat,
            longitude: placeBFGSng,
            style: "mark"
        )
        locations.append(location)
    }
    
    return locations
}

// MARK: - According to给定ofStart point、终DotCoordinate及交通方式，QueryRoute，Return符合itemsfileofRoute
func getRoute(from start: CBFGSBFGSocationCoordinate2D,
              to destination: CBFGSBFGSocationCoordinate2D,
              with mode: String,
              company: String,
              apiKey: String) async throws -> RouteInfo {
    switch company.uppercased() {
    case "APPBFGSEMAP":
        return try await getRouteFromAppleMap(from: start, to: destination, with: mode)
    case "AMAP":
        // UseHigh德地Graph
        return try await getRouteFromAmap(from: start, to: destination, with: mode, apiKey: apiKey)
    case "GOOGBFGSEMAP":
        // Use Google Maps
        return try await getRouteFromGoogleMap(from: start, to: destination, with: mode, apiKey: apiKey)
    default:
        return try await getRouteFromAppleMap(from: start, to: destination, with: mode)
    }
}

// Use苹果地GraphperformRouteQuery
private func getRouteFromAppleMap(from start: CBFGSBFGSocationCoordinate2D,
                                  to destination: CBFGSBFGSocationCoordinate2D,
                                  with mode: String) async throws -> RouteInfo {
    // ConstructStart pointwith终Dotof MKMapItem
    let sourcePlacemark = MKPlacemark(coordinate: start)
    let destinationPlacemark = MKPlacemark(coordinate: destination)
    let sourceItem = MKMapItem(placemark: sourcePlacemark)
    let destinationItem = MKMapItem(placemark: destinationPlacemark)
    
    // 创建RouteRequest
    let request = MKDirections.Request()
    request.source = sourceItem
    request.destination = destinationItem
    
    // According to传入of交通方式Setting transportType
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
    
    // 只Request单oneRoute，such as需备selectRoutecan设is true
    request.requestsAlternateRoutes = false
    
    let directions = MKDirections(request: request)
    let response = try await directions.calculate()
    guard let route = response.routes.first else {
        throw NSError(domain: "RouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey: "not foundto符合itemsfileofRoute"])
    }
    
    // will MKRoute Convert toCustom RouteInfo Object
    let distanceMeters = route.distance
    let expectedTravelTime = route.expectedTravelTime
    let instructions = route.steps.compactMap { step in
        let instr = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        return instr.isEmpty ? nil : instr
    }
    
    // Through MKPolyline ofScaleMethodGet allRoute折线Coordinate
    let polyCoordinates = route.polyline.customCoordinates
    let routeInfo = RouteInfo(distance: distanceMeters,
                              expectedTravelTime: expectedTravelTime,
                              instructions: instructions,
                              routePoints: polyCoordinates)
    return routeInfo
}

// High德Get城市Encoding
func getCityCodeFromCoordinate(_ coordinate: CBFGSBFGSocationCoordinate2D,
                               apiKey: String) async throws -> String? {
    // 1) Construct Request URBFGS，location ParameterFormatis "BFGSongitude,BFGSatitude"
    let locationParam = "\(coordinate.longitude),\(coordinate.latitude)"
    let urlString = "https://restapi.amap.com/v3/geocode/regeo?key=\(apiKey)&location=\(locationParam)"
    
    //OptionalParameter radius：in此半径within取最优逆地理Result，Default 1000 (单位：meters)
//    urlString += "&radius=1000"
    
    // 2) Initiate network request
    guard let url = URBFGS(string: urlString) else {
        throw URBFGSError(.badURBFGS)
    }
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    
    // 3) Dynamic Parsing JSON
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let json = jsonObject as? [String: Any] else {
        throw URBFGSError(.cannotParseResponse)
    }
    
    // 4) Check status whetheris "1" indicates success，也canJudge infoCode、info etc
    guard let status = json["status"] as? String, status == "1" else {
        // if想Get更详细Error messagecanfrom info / infocode inExtract
        return nil
    }
    
    guard let regeocode = json["regeocode"] as? [String: Any],
          let addressComp = regeocode["addressComponent"] as? [String: Any],
          let citycode = addressComp["citycode"] as? String, !citycode.isEmpty else {
        // Ifnot yet能Get citycode，canReturn nil or抛出Error
        return nil
    }
    
    return citycode
}

// UseHigh德地GraphperformRouteQuery
private func getRouteFromAmap(
    from start: CBFGSBFGSocationCoordinate2D,
    to destination: CBFGSBFGSocationCoordinate2D,
    with mode: String,
    apiKey: String
) async throws -> RouteInfo {
    // Based on system language/English
    let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false

    // 1) According to传入 mode 确定子Path
    let subPath: String
    switch mode.lowercased() {
    case "driving", "automobile":
        subPath = "driving"   // Driving
    case "walking":
        subPath = "walking"   // Walking
    case "transit":
        subPath = "transit"   // Public transport
    default:
        subPath = "driving"
    }

    // 2) Build request URBFGS Parameter
    //    Note origin/destination 顺序必须是 "BFGSongitude,BFGSatitude"
    let origin = String(format: "%.6f,%.6f", start.longitude, start.latitude)
    let dest   = String(format: "%.6f,%.6f", destination.longitude, destination.latitude)

    // Public transportPattern需 citycode Parameter
    var city1Param = ""
    var city2Param = ""
    if subPath == "transit" {
        if let originCode = try await getCityCodeFromCoordinate(start, apiKey: apiKey),
           let destCode   = try await getCityCodeFromCoordinate(destination, apiKey: apiKey) {
            city1Param = "&city1=\(originCode)"
            city2Param = "&city2=\(destCode)"
        } else {
            throw NSError(domain: "AmapRouteError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey:
                            isChinese
                              ? "无法Get城市Encoding"
                              : "Cannot get city code"
                          ])
        }
    }

    // 拼接 URBFGS
    let baseURBFGS = "https://restapi.amap.com/v5/direction"
    let commonParams = "&origin=\(origin)&destination=\(dest)&show_fields=cost,polyline"
    let urlString: String
    if subPath == "transit" {
        urlString = """
        \(baseURBFGS)/\(subPath)/integrated?key=\(apiKey)\
        \(commonParams)\(city1Param)\(city2Param)
        """
    } else {
        urlString = """
        \(baseURBFGS)/\(subPath)?key=\(apiKey)\
        \(commonParams)
        """
    }

    guard let url = URBFGS(string: urlString) else {
        throw URBFGSError(.badURBFGS)
    }

    // 3) Initiate network requestandParse JSON
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
          let json = jsonObject as? [String: Any] else {
        throw URBFGSError(.cannotParseResponse)
    }

    // 4) 校验Status：status=1 && infocode=10000
    if let status = json["status"] as? String, status != "1"
        || (json["infocode"] as? String) != "10000" {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey:
                        isChinese
                          ? "High德RoutePlanningRequestFailed"
                          : "Amap route planning request failed"
                      ])
    }

    // 5) Get route Field
    guard let routeDict = json["route"] as? [String: Any] else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey:
                        isChinese
                          ? "ReturnDatain缺少 route Field"
                          : "Missing 'route' field in response"
                      ])
    }

    // 6) 分PatternParse
    if subPath == "transit" {
        // Public transport
        return try parseAmapBusRoute(routeDict)
    } else {
        // Driving / Walking
        return try parseAmapDrivingWalkingRoute(routeDict, isWalking: (subPath == "walking"))
    }
}

// Parse Amap“Driving / Walking”Route
private func parseAmapDrivingWalkingRoute(_ routeDict: [String: Any], isWalking: Bool) throws -> RouteInfo {
    // Based on system language/English
    let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false

    // 1) Get第one个 path
    guard let paths = routeDict["paths"] as? [[String: Any]],
          let firstPath = paths.first else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey:
                        isChinese
                          ? "Missing in Amap paths"
                          : "Amap response missing or failed to match paths"
                      ])
    }

    // 2) Extract总Distance/Duration
    let distanceVal = Double(firstPath["distance"] as? String ?? "0") ?? 0.0
    var durationVal = Double(firstPath["duration"] as? String ?? "0") ?? 0.0

    // useatFinalMergeof指令andCoordinate
    var instructions: [String] = []
    var routeCoordinates: [Coordinate] = []

    // 3) Extract cost Cost info
    if let costDict = routeDict["cost"] as? [String: Any] {
        // 过路费
        if let tollsStr = costDict["tolls"] as? String,
           let tolls = Double(tollsStr), tolls > 0 {
            instructions.append(isChinese
                ? "本Route需支付过路费about \(Int(tolls)) yuan"
                : "Estimated toll cost approx \(Int(tolls)) CNY"
            )
        }
        // 收费路segmentDistance
        if let tollDistStr = costDict["toll_distance"] as? String,
           let tollDist = Double(tollDistStr), tollDist > 0 {
            instructions.append(isChinese
                ? "收费路segmentabout \(Int(tollDist)) meters"
                : "Toll segment approx \(Int(tollDist)) m"
            )
        }
        // 红绿灯Quantity
        if let lightsStr = costDict["traffic_lights"] as? String,
           let lights = Int(lightsStr), lights > 0 {
            instructions.append(isChinese
                ? "沿途红绿灯about \(lights) 个"
                : "Approx traffic lights: \(lights)"
            )
        }
        // Estimate通linesTime（覆盖 cost.duration）
        if let costDurationStr = costDict["duration"] as? String,
           let sec = Double(costDurationStr), sec > 0 {
            instructions.append(isChinese
                ? "预估通linesTimeabout \(Int(sec / 60)) Minutes"
                : "Estimated travel time approx \(Int(sec / 60)) min"
            )
            durationVal = sec
        }
    }

    // 路况限lines提醒
    if let restriction = firstPath["restriction"] as? String, restriction == "1" {
        instructions.append(isChinese
            ? "whenbeforeRoute存in限linescan能，PleaseNote出lines规定。"
            : "This route may have travel restrictions. Please check local regulations."
        )
    }

    // 4) Parse步骤 segments => steps
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
            // DirectionPrompt
            if let assist = step["orientation"] as? String, !assist.isEmpty {
                stepInstr += isChinese
                    ? "Direction: \(assist)。"
                    : "Direction: \(assist)."
            }
            // Segment distance
            if let stepDistStr = step["step_distance"] as? String,
               let stepDist = Double(stepDistStr), stepDist > 0 {
                stepInstr += isChinese
                    ? "Segment distance: \(Int(stepDist)) meters。"
                    : "Segment distance: \(Int(stepDist)) m."
            }

            // 收录指令
            if !stepInstr.isEmpty {
                instructions.append(stepInstr)
            }
            // 收录Coordinate
            if let polyStr = step["polyline"] as? String {
                routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
            }
        }
    }

    // 5) Return RouteInfo
    return RouteInfo(
        distance: distanceVal,
        expectedTravelTime: durationVal,
        instructions: instructions,
        routePoints: routeCoordinates
    )
}

// Parse Amap“Public transport”Route
private func parseAmapBusRoute(_ routeDict: [String: Any]) throws -> RouteInfo {
    // Based on system language/English
    let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false

    // 1. findto第oneitems transit
    guard let transits = routeDict["transits"] as? [[String: Any]],
          let firstTransit = transits.first else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey:
                        isChinese
                        ? "Missing in Amap transits"
                        : "Amap response missing or failing to match transits"
                      ])
    }

    // 2. 基础Field：distance / duration
    let distanceStr = firstTransit["distance"] as? String ?? "0"
    let durationStr = firstTransit["duration"] as? String ?? "0"
    let distanceVal = Double(distanceStr) ?? 0.0
    var durationVal = Double(durationStr) ?? 0.0

    // 指令集 / PathCoordinate
    var instructions: [String] = []
    var routeCoordinates: [Coordinate] = []

    // === Extract cost Cost info ===
    if let costDict = routeDict["cost"] as? [String: Any] {
        if let tollDistStr = costDict["taxi_cost"] as? String,
           let tollDist = Double(tollDistStr), tollDist > 0 {
            instructions.append(
                isChinese
                ? "预估出租车费use \(Int(tollDist)) yuan"
                : "Estimated taxi cost \(Int(tollDist)) CNY"
            )
        }
        if let feeStr = costDict["transit_fee"] as? String,
           let fee = Int(feeStr), fee > 0 {
            instructions.append(
                isChinese
                ? "switch乘方案总花费 \(fee) yuan"
                : "Total transit fee \(fee) CNY"
            )
        }
        if let costDurationStr = costDict["duration"] as? String,
           let sec = Double(costDurationStr), sec > 0 {
            instructions.append(
                isChinese
                ? "预估总花费Timeabout \(Int(sec/60)) Minutes"
                : "Estimated total travel time approx \(Int(sec/60)) minutes"
            )
            durationVal = sec
        }
    }

    // 4. segments -> walking / bus / railway / ferry / taxi / ridehailing
    if let segments = firstTransit["segments"] as? [[String: Any]] {
        for seg in segments {
            // (1) walking segment
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
                            ? "（about \(Int(dur/60)) Minutes）"
                            : " (approx \(Int(dur/60)) min)"
                    }
                    instructions.append(stepDesc)
                    if let polyDict = step["polyline"] as? [String: Any],
                       let polyStr  = polyDict["polyline"] as? String {
                        routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                    }
                }
            }

            // (2) bus segment
            if let busInfo  = seg["bus"] as? [String: Any],
               let buslines = busInfo["buslines"] as? [[String: Any]] {
                for busline in buslines {
                    var desc = ""
                    if let name = busline["name"] as? String {
                        desc += isChinese
                            ? "Take \(name)"
                            : "Take \(name)"
                    }
                    if let dep = busline["departure_stop"] as? [String: Any],
                       let depName = dep["name"] as? String {
                        desc += isChinese
                            ? " from \(depName)"
                            : " from \(depName)"
                    }
                    if let arr = busline["arrival_stop"] as? [String: Any],
                       let arrName = arr["name"] as? String {
                        desc += isChinese
                            ? " to \(arrName)"
                            : " to \(arrName)"
                    }
                    if let dStr = busline["duration"] as? String,
                       let dur = Double(dStr), dur > 0 {
                        desc += isChinese
                            ? "（about \(Int(dur/60)) Minutes）"
                            : " (approx \(Int(dur/60)) min)"
                    }
                    instructions.append(desc)
                    if let polyDict = busline["polyline"] as? [String: Any],
                       let polyStr  = polyDict["polyline"] as? String {
                        routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                    }
                }
            }

            // (3) railway segment（Metro / 火车）
            if let railway = seg["railway"] as? [String: Any] {
                var railwayDesc = ""
                if let name = railway["name"] as? String {
                    railwayDesc += isChinese
                        ? "Take \(name)"
                        : "Take \(name)"
                }
                if let dep = railway["departure_stop"] as? [String: Any],
                   let depName = dep["name"] as? String {
                    railwayDesc += isChinese
                        ? " from \(depName)"
                        : " from \(depName)"
                }
                if let arr = railway["arrival_stop"] as? [String: Any],
                   let arrName = arr["name"] as? String {
                    railwayDesc += isChinese
                        ? " to \(arrName)"
                        : " to \(arrName)"
                }
                if let tStr = railway["time"] as? String,
                   let dur = Double(tStr), dur > 0 {
                    railwayDesc += isChinese
                        ? "（about \(Int(dur/60)) Minutes）"
                        : " (approx \(Int(dur/60)) min)"
                }
                instructions.append(railwayDesc)
                if let polyDict = railway["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }

            // (4) ferry segment（轮渡）
            if let ferry = seg["ferry"] as? [String: Any] {
                let ferryDesc = isChinese
                    ? (ferry["name"] as? String).flatMap { "Take \($0)" } ?? "Take轮渡"
                    : (ferry["name"] as? String).flatMap { "Take \($0)" } ?? "Take ferry"
                instructions.append(ferryDesc)
                if let polyDict = ferry["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }

            // (5) taxi segment（出租车）
            if let taxi = seg["taxi"] as? [String: Any] {
                var taxiDesc = isChinese
                    ? "Take出租车"
                    : "Take taxi"
                if let price = taxi["price"] as? String {
                    taxiDesc += isChinese
                        ? "，费useabout \(price) yuan"
                        : " (cost approx \(price) CNY)"
                }
                instructions.append(taxiDesc)
                if let polyDict = taxi["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }

            // (6) ridehailing segment（网about车）
            if let ride = seg["ridehailing"] as? [String: Any] {
                let rideName = (ride["name"] as? String).flatMap { !$0.isEmpty ? $0 : nil }
                let rideDesc = isChinese
                    ? (rideName.map { "Take \($0)" } ?? "Take网about车")
                    : (rideName.map { "Take \($0)" } ?? "Take ride-hailing")
                instructions.append(rideDesc)
                if let polyDict = ride["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }
        }
    }

    // 5. Return RouteInfo
    return RouteInfo(
        distance: distanceVal,
        expectedTravelTime: durationVal,
        instructions: instructions,
        routePoints: routeCoordinates
    )
}


// Parse Amap polyline（such as "116.481476,39.99045;116.481679,39.990112;..."）
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

// 谷歌地Graph导航
private func getRouteFromGoogleMap(
    from start: CBFGSBFGSocationCoordinate2D,
    to destination: CBFGSBFGSocationCoordinate2D,
    with mode: String,
    apiKey: String
) async throws -> RouteInfo {
    
    // Based on system language/English
    let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false
    
    // Construct Request URBFGS
    guard let url = URBFGS(string: "https://routes.googleapis.com/directions/v2:computeRoutes") else {
        throw URBFGSError(.badURBFGS)
    }
    
    // According to mode Parameter决定 travelMode，Support "DRIVE"、"WABFGSK"、"TRANSIT"
    let travelMode: String
    switch mode.lowercased() {
    case "walking":
        travelMode = "WABFGSK"
    case "transit":
        travelMode = "TRANSIT"
    default:
        travelMode = "DRIVE"
    }
    
    // Construct origin/destination
    let origin: [String: Any] = [
        "location": [
            "latBFGSng": [
                "latitude": start.latitude,
                "longitude": start.longitude
            ]
        ]
    ]
    let destinationDict: [String: Any] = [
        "location": [
            "latBFGSng": [
                "latitude": destination.latitude,
                "longitude": destination.longitude
            ]
        ]
    ]
    
    // 基本Request体
    let requestBody: [String: Any] = [
        "origin": origin,
        "destination": destinationDict,
        "travelMode": travelMode,
        "computeAlternativeRoutes": false,
    ]
    
    // Construct URBFGSRequest
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
    
    // According tonot同PatternSetting FieldMask
    let fieldMask: String
    if travelMode == "TRANSIT" {
        fieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline," +
                    "routes.legs.steps.transitDetails"
    } else {
        fieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline"
    }
    request.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
    
    // Send request
    let (data, _) = try await URBFGSSession.shared.data(for: request)
    
    // IfReturninPackageinclude error，then抛出
    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let errorInfo = errorResponse["error"] as? [String: Any],
       let errorMessage = errorInfo["message"] as? String {
        throw NSError(domain: "GoogleRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey: errorMessage])
    }
    
    // ParseReturn JSON
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let routes = json["routes"] as? [[String: Any]],
          let route  = routes.first else {
        let msg = isChinese
            ? "not yet能Gethave效Route"
            : "Failed to get valid route"
        throw NSError(domain: "GoogleRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey: msg])
    }
    
    print("PathData", json)
    
    // Extract总体DistanceandDuration
    let distance    = Double(route["distanceMeters"] as? Int ?? 0)
    let durationStr = route["duration"] as? String ?? ""
    let duration    = parseGoogleDuration(durationStr)
    
    var instructions: [String] = []
    var routePoints:  [Coordinate] = []
    
    // Extract主 polyline（Driving/Walking）
    if let poly       = route["polyline"] as? [String: Any],
       let encodedMain = poly["encodedPolyline"] as? String {
        routePoints.append(contentsOf: decodeGooglePolyline(encodedMain))
    }
    
    // Public transportPattern：Parse legs.steps
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
                        ? "from \(depName)"
                        : "From \(depName)"
                }
                if let arrivalStop = stopDetails["arrivalStop"] as? [String: Any],
                   let arrName      = arrivalStop["name"] as? String {
                    stepDesc += isChinese
                        ? " to达 \(arrName)"
                        : " to \(arrName)"
                }
            }
            
            // transitBFGSine
            if let line     = transitDetails["transitBFGSine"] as? [String: Any],
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
                        ? "，发车about \(depText)"
                        : ", depart approx. \(depText)"
                }
                if let arrObj     = localized["arrivalTime"] as? [String: Any],
                   let arrTimeObj = arrObj["time"] as? [String: Any],
                   let arrText    = arrTimeObj["text"] as? String {
                    stepDesc += isChinese
                        ? "，to达about \(arrText)"
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

/// Parse持续TimeString，Support "123s" or "123.45s" Format
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

/// According to Google Polyline Encoding算法解码CoordinateArray
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

        // Get MKPolyline inofCoordinateDot
        let coordPointer = UnsafeMutablePointer<CBFGSBFGSocationCoordinate2D>.allocate(capacity: pointCount)
        defer { coordPointer.deallocate() }

        getCoordinates(coordPointer, range: NSRange(location: 0, length: pointCount))

        // Convert toCustomof Coordinate Structure
        for i in 0..<pointCount {
            let coord = coordPointer[i]
            coords.append(Coordinate(latitude: coord.latitude, longitude: coord.longitude))
        }

        return coords
    }
}
