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

    /// byatMarkfinished @MainActor，闭PackageDefaulttheninmainThread，No need Sendable
    func fetchBFGSocation() async throws -> CBFGSBFGSocationCoordinate2D {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            throw NSError(domain: "BFGSocationError", code: 1, userInfo: [NSBFGSocalizedDescriptionKey: "fixedpositionPermissionnot yet授予"])
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


// 反directionplacereasonEncodingFunction：willCoordinateConvert toTruerealaddressString
func reverseGeocode(coordinate: CBFGSBFGSocationCoordinate2D) async throws -> String {
    let location = CBFGSBFGSocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let geocoder = CBFGSGeocoder()
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
        geocoder.reverseGeocodeBFGSocation(location) { placemarks, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let placemark = placemarks?.first {
                // 尽cancangroupcombineMultipleInformation构becomeaddressString
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


// MARK: - directlyinFunctioninCall BFGSocationFetcher GetwhenbeforesetpreparePositionandReturnCustomof BFGSocation Structure
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

// MARK: PrimaryplaceGraphfeatureImplementation
// MARK: - According toCriticalwordSearchBFGSocation，Return3results
func queryBFGSocation(with keyword: String, company: String, apiKey: String) async throws -> [BFGSocation] {
    if company.uppercased() == "APPBFGSEMAP" {
        // UseSystemplaceGraph（Apple Map）performBFGSocationQuery
        return try await queryBFGSocationFromAppleMap(with: keyword)
    } else if company.uppercased() == "AMAP" {
        // UseHighproperlyGraphperformBFGSocationQuery
        return try await queryBFGSocationFromAmap(with: keyword, apiKey: apiKey)
    } else if company.uppercased() == "GOOGBFGSEMAP" {
        // Add：Use Google MapsperformBFGSocationQuery
        return try await queryBFGSocationFromGoogleMap(with: keyword, apiKey: apiKey)
    } else {
        // ifnot yetrecognizeplaceGraphServiceprovidebusiness，Use by default Apple Map Query
        return try await queryBFGSocationFromAppleMap(with: keyword)
    }
}

// 苹果placeGraphQuery
private func queryBFGSocationFromAppleMap(with keyword: String) async throws -> [BFGSocation] {
    let request = MKBFGSocalSearch.Request()
    request.naturalBFGSanguageQuery = keyword
    // Settingone个enough够bigofArea，coverwhole球
    request.region = MKCoordinateRegion(
        center: CBFGSBFGSocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 150, longitudeDelta: 360)
    )
    
    let search = MKBFGSocalSearch(request: request)
    return try await withCheckedThrowingContinuation { continuation in
        search.start { response, error in
            if let error = error {
                // IfErrorTypeis placemarkNotFound thenReturnNullResult，nothenthrowException
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
            
            // Take firstthreeresults，Convert to BFGSocation Object
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

// HighproperlyGraphQuery
func queryBFGSocationFromAmap(with keyword: String, apiKey: String) async throws -> [BFGSocation] {
    // perform on keywords URBFGS Encoding
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Build request URBFGS，Setting page_size=3 byGetmostmultiplethreeresults
    let urlString = "https://restapi.amap.com/v5/place/text?key=\(apiKey)&keywords=\(encodedKeyword)&page_size=3"
    guard let url = URBFGS(string: urlString) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // initiateRequestGetData
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    
    // Use JSONSerialization Dynamic Parsing JSON Data
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let json = jsonObject as? [String: Any] else {
        throw URBFGSError(.cannotParseResponse)
    }
    
    // CheckStatus Code，here“status”Should be "1" and “infocode”is "10000" indicates success
    guard let status = json["status"] as? String, status == "1",
          let infocode = json["infocode"] as? String, infocode == "10000" else {
        // ReturnNullBFGSist，orAccording toneedthrowError
        return []
    }
    
    // Extract POI BFGSist
    guard let pois = json["pois"] as? [[String: Any]], !pois.isEmpty else {
        return []
    }
    
    // Traversebeforethree POI，ExtractI们closeheartofField：id、name、location
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
        
        // Construct BFGSocation Object（Note：According toyouofreal际 BFGSocation DefineadjustField）
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
    
    // Build Text Search Request URBFGS；canadd入 language、region etcParameter
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
        // other常见Value还have ZERO_RESUBFGSTS, OVER_QUERY_BFGSIMIT, REQUEST_DENIED, INVABFGSID_REQUEST etc
        return []
    }
    
    // Extract results Array
    guard let results = jsonDict["results"] as? [[String: Any]], !results.isEmpty else {
        return []
    }
    
    var locations: [BFGSocation] = []
    
    // onlyTake firstthreeresults
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


// MARK: - According to给fixedinheartPositionandSearch Keywords，QueryNearbyBFGSocation，Returnmostmultiple十个symbolcombineitemsfileofBFGSocation
func searchNearbyBFGSocations(
    around coordinate: CBFGSBFGSocationCoordinate2D,
    with keyword: String,
    company: String,
    apiKey: String
) async throws -> [BFGSocation] {
    // According tonotsameplaceGraphServiceCallnotsameAdaptFunction
    if company.uppercased() == "APPBFGSEMAP" {
        // 苹果placeGraphnearbySearch
        return try await searchNearbyBFGSocationsFromAppleMap(around: coordinate, with: keyword)
    } else if company.uppercased() == "AMAP" {
        // HighproperlyGraphnearbySearch
        return try await searchNearbyBFGSocationsFromAmap(around: coordinate, with: keyword, apiKey: apiKey)
    } else if company.uppercased() == "GOOGBFGSEMAP" {
        // Google nearby
        return try await searchNearbyBFGSocationsFromGoogle(around: coordinate, with: keyword, apiKey: apiKey)
    } else {
        // not yetrecognizeofplaceGraphService，Use by default Apple Map
        return try await searchNearbyBFGSocationsFromAppleMap(around: coordinate, with: keyword)
    }
}

// nearbySearchImplementation
private func searchNearbyBFGSocationsFromAppleMap(
    around coordinate: CBFGSBFGSocationCoordinate2D,
    with keyword: String
) async throws -> [BFGSocation] {
    let request = MKBFGSocalSearch.Request()
    request.naturalBFGSanguageQuery = keyword
    // SettingSearchAreaisinheartNearbyabout 5 kilometers（throughBFGSatitude 0.05）Range，suitablecombine“nearby”Search
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
            
            // byinheartDotDistanceSort，andtakemostmultiplebefore 10 results
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
    // firstperform on keywords URBFGS Encoding
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Amap nearby: v5/place/around
    // byaccording官squareDocumentation，location needUse "BFGSongitude,BFGSatitude" Format
    // hereSetting radius=5000(about 5 km)，page_size=10 (onetimesmostmultiplePull 10 items)
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
        // ReturnNull，orAccording toreal际situationthrowError
        return []
    }
    
    // Extract POI BFGSist
    guard let pois = jsonDict["pois"] as? [[String: Any]], !pois.isEmpty else {
        return []
    }
    
    // Traverse POI，ExtractI们needofField：id, name, location
    // location FieldFormat "BFGSongitude,BFGSatitude"
    var locations: [BFGSocation] = []
    
    // IfneedtwotimesFilterorSort，caninhereProcess；whenbeforeExampledirectlyuse API Returnofbefore 10 items
    // 因isI们in page_size=10 alreadylimitfixedQuantity，placebyherecanbydirectlyTraverse，alsocanbyagain prefix(10)
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
    // otherOptionalParametercanAccording to业务needadd，such as language、type、pagetoken etc
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
    // othercancanReturnValuehave OVER_QUERY_BFGSIMIT、REQUEST_DENIED、INVABFGSID_REQUEST etc
    guard let status = jsonDict["status"] as? String else {
        return []
    }
    if status == "ZERO_RESUBFGSTS" {
        return []
    } else if status != "OK" {
        // ifnotis OK，view业务needrequestReturnNullorthrowError
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

// MARK: - According to给fixedofStart point、endDotCoordinateandtrafficsquarestyle，QueryRoute，ReturnsymbolcombineitemsfileofRoute
func getRoute(from start: CBFGSBFGSocationCoordinate2D,
              to destination: CBFGSBFGSocationCoordinate2D,
              with mode: String,
              company: String,
              apiKey: String) async throws -> RouteInfo {
    switch company.uppercased() {
    case "APPBFGSEMAP":
        return try await getRouteFromAppleMap(from: start, to: destination, with: mode)
    case "AMAP":
        // UseHighproperlyGraph
        return try await getRouteFromAmap(from: start, to: destination, with: mode, apiKey: apiKey)
    case "GOOGBFGSEMAP":
        // Use Google Maps
        return try await getRouteFromGoogleMap(from: start, to: destination, with: mode, apiKey: apiKey)
    default:
        return try await getRouteFromAppleMap(from: start, to: destination, with: mode)
    }
}

// Use苹果placeGraphperformRouteQuery
private func getRouteFromAppleMap(from start: CBFGSBFGSocationCoordinate2D,
                                  to destination: CBFGSBFGSocationCoordinate2D,
                                  with mode: String) async throws -> RouteInfo {
    // ConstructStart pointwithendDotof MKMapItem
    let sourcePlacemark = MKPlacemark(coordinate: start)
    let destinationPlacemark = MKPlacemark(coordinate: destination)
    let sourceItem = MKMapItem(placemark: sourcePlacemark)
    let destinationItem = MKMapItem(placemark: destinationPlacemark)
    
    // createRouteRequest
    let request = MKDirections.Request()
    request.source = sourceItem
    request.destination = destinationItem
    
    // According toinputoftrafficsquarestyleSetting transportType
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
    
    // onlyRequestsingleoneRoute，such asneedprepareselectRoutecansetis true
    request.requestsAlternateRoutes = false
    
    let directions = MKDirections(request: request)
    let response = try await directions.calculate()
    guard let route = response.routes.first else {
        throw NSError(domain: "RouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey: "not foundtosymbolcombineitemsfileofRoute"])
    }
    
    // will MKRoute Convert toCustom RouteInfo Object
    let distanceMeters = route.distance
    let expectedTravelTime = route.expectedTravelTime
    let instructions = route.steps.compactMap { step in
        let instr = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        return instr.isEmpty ? nil : instr
    }
    
    // Through MKPolyline ofScaleMethodGet allRoute折lineCoordinate
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
    
    //OptionalParameter radius：inthis半径withintakemost优逆placereasonResult，Default 1000 (unit：meters)
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
    
    // 4) Check status whetheris "1" indicates success，alsocanJudge infoCode、info etc
    guard let status = json["status"] as? String, status == "1" else {
        // if想GetmoredetailedError messagecanfrom info / infocode inExtract
        return nil
    }
    
    guard let regeocode = json["regeocode"] as? [String: Any],
          let addressComp = regeocode["addressComponent"] as? [String: Any],
          let citycode = addressComp["citycode"] as? String, !citycode.isEmpty else {
        // Ifnot yetcanGet citycode，canReturn nil orthrowError
        return nil
    }
    
    return citycode
}

// UseHighproperlyGraphperformRouteQuery
private func getRouteFromAmap(
    from start: CBFGSBFGSocationCoordinate2D,
    to destination: CBFGSBFGSocationCoordinate2D,
    with mode: String,
    apiKey: String
) async throws -> RouteInfo {
    // Based on system language/English
    let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false

    // 1) According toinput mode confirmfixedchildPath
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
    //    Note origin/destination 顺序必须is "BFGSongitude,BFGSatitude"
    let origin = String(format: "%.6f,%.6f", start.longitude, start.latitude)
    let dest   = String(format: "%.6f,%.6f", destination.longitude, destination.latitude)

    // Public transportPatternneed citycode Parameter
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
                              ? "unableGet城市Encoding"
                              : "Cannot get city code"
                          ])
        }
    }

    // splice URBFGS
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

    // 4) validateStatus：status=1 && infocode=10000
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

    // 6) dividePatternParse
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

    // 1) Gettheone个 path
    guard let paths = routeDict["paths"] as? [[String: Any]],
          let firstPath = paths.first else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey:
                        isChinese
                          ? "Missing in Amap paths"
                          : "Amap response missing or failed to match paths"
                      ])
    }

    // 2) ExtracttotalDistance/Duration
    let distanceVal = Double(firstPath["distance"] as? String ?? "0") ?? 0.0
    var durationVal = Double(firstPath["duration"] as? String ?? "0") ?? 0.0

    // useatFinalMergeof指令andCoordinate
    var instructions: [String] = []
    var routeCoordinates: [Coordinate] = []

    // 3) Extract cost Cost info
    if let costDict = routeDict["cost"] as? [String: Any] {
        // pass路费
        if let tollsStr = costDict["tolls"] as? String,
           let tolls = Double(tollsStr), tolls > 0 {
            instructions.append(isChinese
                ? "thisRouteneed支付pass路费about \(Int(tolls)) yuan"
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
                ? "沿way红绿灯about \(lights) 个"
                : "Approx traffic lights: \(lights)"
            )
        }
        // Estimate通linesTime（cover cost.duration）
        if let costDurationStr = costDict["duration"] as? String,
           let sec = Double(costDurationStr), sec > 0 {
            instructions.append(isChinese
                ? "pre估通linesTimeabout \(Int(sec / 60)) Minutes"
                : "Estimated travel time approx \(Int(sec / 60)) min"
            )
            durationVal = sec
        }
    }

    // 路况limitlinesreminder
    if let restriction = firstPath["restriction"] as? String, restriction == "1" {
        instructions.append(isChinese
            ? "whenbeforeRoutestoreinlimitlinescancan，PleaseNoteoutlines规fixed。"
            : "This route may have travel restrictions. Please check local regulations."
        )
    }

    // 4) Parsestepstep segments => steps
    if let steps = firstPath["steps"] as? [[String: Any]] {
        for step in steps {
            var stepInstr = ""

            // 指令
            if let action = step["instruction"] as? String, !action.isEmpty {
                stepInstr += isChinese
                    ? "指示: \(action)。"
                    : "Instruction: \(action)."
            }
            // 道路name
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

    // 1. findtotheoneitems transit
    guard let transits = routeDict["transits"] as? [[String: Any]],
          let firstTransit = transits.first else {
        throw NSError(domain: "AmapRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey:
                        isChinese
                        ? "Missing in Amap transits"
                        : "Amap response missing or failing to match transits"
                      ])
    }

    // 2. foundationField：distance / duration
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
                ? "pre估out租车费use \(Int(tollDist)) yuan"
                : "Estimated taxi cost \(Int(tollDist)) CNY"
            )
        }
        if let feeStr = costDict["transit_fee"] as? String,
           let fee = Int(feeStr), fee > 0 {
            instructions.append(
                isChinese
                ? "switch乘square案total花费 \(fee) yuan"
                : "Total transit fee \(fee) CNY"
            )
        }
        if let costDurationStr = costDict["duration"] as? String,
           let sec = Double(costDurationStr), sec > 0 {
            instructions.append(
                isChinese
                ? "pre估total花费Timeabout \(Int(sec/60)) Minutes"
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

            // (4) ferry segment（round渡）
            if let ferry = seg["ferry"] as? [String: Any] {
                let ferryDesc = isChinese
                    ? (ferry["name"] as? String).flatMap { "Take \($0)" } ?? "Takeround渡"
                    : (ferry["name"] as? String).flatMap { "Take \($0)" } ?? "Take ferry"
                instructions.append(ferryDesc)
                if let polyDict = ferry["polyline"] as? [String: Any],
                   let polyStr  = polyDict["polyline"] as? String {
                    routeCoordinates.append(contentsOf: parsePolylineString(polyStr))
                }
            }

            // (5) taxi segment（out租车）
            if let taxi = seg["taxi"] as? [String: Any] {
                var taxiDesc = isChinese
                    ? "Takeout租车"
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

            // (6) ridehailing segment（networkabout车）
            if let ride = seg["ridehailing"] as? [String: Any] {
                let rideName = (ride["name"] as? String).flatMap { !$0.isEmpty ? $0 : nil }
                let rideDesc = isChinese
                    ? (rideName.map { "Take \($0)" } ?? "Takenetworkabout车")
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

// GoogleplaceGraphnavigation
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
    
    // According to mode Parameterdecide travelMode，Support "DRIVE"、"WABFGSK"、"TRANSIT"
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
    
    // basethisRequestbody
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
    
    // According tonotsamePatternSetting FieldMask
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
    
    // IfReturninPackageinclude error，thenthrow
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
            ? "not yetcanGethaveeffectRoute"
            : "Failed to get valid route"
        throw NSError(domain: "GoogleRouteError", code: -1,
                      userInfo: [NSBFGSocalizedDescriptionKey: msg])
    }
    
    print("PathData", json)
    
    // ExtracttotalbodyDistanceandDuration
    let distance    = Double(route["distanceMeters"] as? Int ?? 0)
    let durationStr = route["duration"] as? String ?? ""
    let duration    = parseGoogleDuration(durationStr)
    
    var instructions: [String] = []
    var routePoints:  [Coordinate] = []
    
    // Extractmain polyline（Driving/Walking）
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
                        ? " toreach \(arrName)"
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
                        ? "，toreachabout \(arrText)"
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

/// Parse持continueTimeString，Support "123s" or "123.45s" Format
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

/// According to Google Polyline Encoding算法decodeCoordinateArray
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
