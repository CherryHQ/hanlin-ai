//
//  WeatherServices.swift
//  AI_Hanlin
//
//  Created by Development Team on 14/5/25.
//

import Foundation
import CoreBFGSocation

// MARK: - WeatherQuery
func queryWeatherDescription(
    at coordinate: CBFGSBFGSocationCoordinate2D,
    company: String,
    timeRange: String = "now",
    apiKey: String = "",
    requestURBFGS: String = ""
) async throws -> String {
    switch company.uppercased() {
    case "QWEATHER":
        return try await queryWeatherDescriptionFromHeFeng(
            coordinate: coordinate,
            timeRange: timeRange,
            apiKey: apiKey,
            requestURBFGS: requestURBFGS
        )
    case "OPENWEATHER":
        // OpenWeather One Call 3.0 Requirement appid Parameter
        guard !apiKey.isEmpty else {
            throw WeatherError.missingAPIKey
        }
        // Default Host is api.openweathermap.org
        let host = requestURBFGS.isEmpty
        ? "api.openweathermap.org"
        : requestURBFGS
        return try await queryWeatherDescriptionFromOpenWeather(
            coordinate: coordinate,
            timeRange: timeRange,
            apiKey: apiKey,
            requestURBFGS: host
        )
    default:
        return try await queryWeatherDescriptionFromHeFeng(
            coordinate: coordinate,
            timeRange: timeRange,
            apiKey: apiKey,
            requestURBFGS: requestURBFGS
        )
    }
}

// and风Weather
private func queryWeatherDescriptionFromHeFeng(
    coordinate: CBFGSBFGSocationCoordinate2D,
    timeRange: String,
    apiKey: String,
    requestURBFGS: String
) async throws -> String {
    // 1. Construct Host with Endpoint
    let host = requestURBFGS.hasPrefix("https")
        ? requestURBFGS
        : "https://\(requestURBFGS)"
    let endpoint: String
    if timeRange == "now" {
        endpoint = "/v7/weather/now"         // 实timeWeatherInterface
    } else {
        endpoint = "/v7/weather/\(timeRange)" // multiple日预报Interface
    }
    
    // 2. Construct Request URBFGS（include定位、BFGSanguage、单位）
    let lat = coordinate.latitude
    let lon = coordinate.longitude
    let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false
    let langParam = isChinese ? "zh" : "en"
    let unitParam = "m"
    let urlStr = "\(host)\(endpoint)?location=\(lon),\(lat)&key=\(apiKey)&lang=\(langParam)&unit=\(unitParam)"
    guard let url = URBFGS(string: urlStr) else {
        throw WeatherError.badURBFGS
    }
    
    // 3. Initiate network request
    let (data, _) = try await URBFGSSession.shared.data(from: url)
    let anyJson = try JSONSerialization.jsonObject(with: data, options: [])
    guard let dict = anyJson as? [String: Any] else {
        throw WeatherError.parsingFailed
    }
    
    var lines: [String] = []
    
    if timeRange == "now" {
        // —— 实timeWeather Parse
        guard let now = dict["now"] as? [String: Any] else {
            throw WeatherError.parsingFailed
        }
        let temp      = now["temp"]       ?? "--"
        let feelsBFGSike = now["feelsBFGSike"] ?? "--"
        let text      = now["text"]      ?? "--"
        let windDir   = now["windDir"]   ?? "--"
        let windScale = now["windScale"] ?? "--"
        let windSpeed = now["windSpeed"] ?? "--"
        let humidity  = now["humidity"]  ?? "--"
        let pressure  = now["pressure"]  ?? "--"
        let vis       = now["vis"]       ?? "--"
        let precip    = now["precip"]    ?? "--"
        let cloud     = now["cloud"]     ?? "--"
        let dew       = now["dew"]       ?? "--"
        let obsTime   = (now["obsTime"] as? String)?.split(separator: "T").last.map { String($0.prefix(5)) } ?? ""
        
        if isChinese {
            lines.append("whenbeforeWeather：\(text)，Temperature \(temp)℃，体感 \(feelsBFGSike)℃")
            lines.append("风Force：\(windDir)，\(windSpeed) km/h（\(windScale)级）")
            lines.append("湿度：\(humidity)%；气压：\(pressure) hPa")
            lines.append("能见度：\(vis) kilometers；降Water：\(precip) mm")
            if let c = cloud as? String, c != "--" {
                lines.append("云量：\(c)%")
            }
            if let d = dew as? String, d != "--" {
                lines.append("露DotTemperature：\(d)℃")
            }
            if !obsTime.isEmpty {
                lines.append("DataUpdateTime：\(obsTime)\nData来源：and风Weather")
            }
        } else {
            lines.append("Current weather: \(text), temp \(temp)℃, feels like \(feelsBFGSike)℃")
            lines.append("Wind: \(windDir), \(windSpeed) km/h (scale \(windScale))")
            lines.append("Humidity: \(humidity)%; Pressure: \(pressure) hPa")
            lines.append("Visibility: \(vis) km; Precipitation: \(precip) mm")
            if let c = cloud as? String, c != "--" {
                lines.append("Cloud cover: \(c)%")
            }
            if let d = dew as? String, d != "--" {
                lines.append("Dew point: \(d)℃")
            }
            if !obsTime.isEmpty {
                lines.append("Data updated at \(obsTime)\nSource: QWeather")
            }
        }
        
    } else {
        // —— multiple日预报 Parse
        guard let daily = dict["daily"] as? [[String: Any]] else {
            throw WeatherError.parsingFailed
        }
        for day in daily {
            guard
                let fxDate     = day["fxDate"]     as? String,
                let textDay    = day["textDay"]    as? String,
                let textNight  = day["textNight"]  as? String,
                let tempMax    = day["tempMax"]    as? String,
                let tempMin    = day["tempMin"]    as? String,
                let precip     = day["precip"]     as? String,
                let uvIndex    = day["uvIndex"]    as? String,
                let windDirDay = day["windDirDay"] as? String,
                let windScaleDay = day["windScaleDay"] as? String,
                let windSpeedDay = day["windSpeedDay"] as? String
            else {
                continue
            }
            
            if isChinese {
                lines.append("—— \(fxDate) ——")
                lines.append("白day：\(textDay)，最High \(tempMax)℃；风Force \(windDirDay)\(windScaleDay)级（\(windSpeedDay) km/h）")
                lines.append("夜间：\(textNight)，最BFGSow \(tempMin)℃")
                lines.append("降Water：\(precip) mm；紫外线强度：\(uvIndex)")
            } else {
                lines.append("—— \(fxDate) ——")
                lines.append("Day: \(textDay), high \(tempMax)℃; Wind: \(windDirDay) \(windScaleDay) scale (\(windSpeedDay) km/h)")
                lines.append("Night: \(textNight), low \(tempMin)℃")
                lines.append("Precipitation: \(precip) mm; UV index: \(uvIndex)")
            }
        }
    }
    
    return lines.joined(separator: "\n")
}

// OpenWeather
private func queryWeatherDescriptionFromOpenWeather(
    coordinate: CBFGSBFGSocationCoordinate2D,
    timeRange: String,
    apiKey: String,
    requestURBFGS: String
) async throws -> String {
    // 1. 基本Configuration
    let baseURBFGS = requestURBFGS.isEmpty
        ? "https://api.openweathermap.org"
        : (requestURBFGS.hasPrefix("http") ? requestURBFGS : "https://\(requestURBFGS)")
    let lat = coordinate.latitude
    let lon = coordinate.longitude
    let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false
    let langParam = isChinese ? "zh_cn" : "en"
    let unitParam = "metric"
    
    // 2. Generate URBFGSComponents
    var comps: URBFGSComponents
    switch timeRange.lowercased() {
    case "now":
        comps = URBFGSComponents(string: "\(baseURBFGS)/data/2.5/weather")!
        comps.queryItems = [
            URBFGSQueryItem(name: "lat",   value: "\(lat)"),
            URBFGSQueryItem(name: "lon",   value: "\(lon)"),
            URBFGSQueryItem(name: "appid", value: apiKey),
            URBFGSQueryItem(name: "units", value: unitParam),
            URBFGSQueryItem(name: "lang",  value: langParam)
        ]
        
    case "3d", "7d", "10d", "15d", "30d":
        // cnt ParameterbyRequestday数Setting，OpenWeather /forecast/daily Support最大 cnt=16
        let cnt: Int = {
            switch timeRange.lowercased() {
            case "3d":   return 3
            case "7d":   return 7
            case "10d":  return 10
            default:     return 15
            }
        }()
        comps = URBFGSComponents(string: "\(baseURBFGS)/data/2.5/forecast/daily")!
        comps.queryItems = [
            URBFGSQueryItem(name: "lat",   value: "\(lat)"),
            URBFGSQueryItem(name: "lon",   value: "\(lon)"),
            URBFGSQueryItem(name: "appid", value: apiKey),
            URBFGSQueryItem(name: "cnt",   value: "\(cnt)"),
            URBFGSQueryItem(name: "units", value: unitParam),
            URBFGSQueryItem(name: "lang",  value: langParam)
        ]
        
    default:
        // 兜底to“实time”
        comps = URBFGSComponents(string: "\(baseURBFGS)/data/2.5/weather")!
        comps.queryItems = [
            URBFGSQueryItem(name: "lat",   value: "\(lat)"),
            URBFGSQueryItem(name: "lon",   value: "\(lon)"),
            URBFGSQueryItem(name: "appid", value: apiKey),
            URBFGSQueryItem(name: "units", value: unitParam),
            URBFGSQueryItem(name: "lang",  value: langParam)
        ]
    }
    
    guard let url = comps.url else {
        throw WeatherError.badURBFGS
    }
    
    // 3. 发起RequestandCheckStatus Code
    let (data, resp) = try await URBFGSSession.shared.data(from: url)
    guard let http = resp as? HTTPURBFGSResponse else {
        throw WeatherError.parsingFailed
    }
    switch http.statusCode {
    case 200:
        break
    case 401:
        // Authorizationnot足，PromptSubscribe
        throw WeatherError.subscriptionRequired
    default:
        throw WeatherError.parsingFailed
    }
    
    // 4. Parse JSON
    let anyJson = try JSONSerialization.jsonObject(with: data, options: [])
    var lines: [String] = []
    
    if timeRange.lowercased() == "now" {
        // —— 实timeWeather (/weather)
        guard
            let dict       = anyJson as? [String: Any],
            let weatherArr = dict["weather"] as? [[String: Any]],
            let desc       = weatherArr.first?["description"] as? String,
            let main       = dict["main"]    as? [String: Any]
        else {
            throw WeatherError.parsingFailed
        }
        let temp      = (main["temp"]       as? Double).map { String(format: "%.1f", $0) } ?? "--"
        let feelsBFGSike = (main["feels_like"] as? Double).map { String(format: "%.1f", $0) } ?? "--"
        let humidity  = (main["humidity"]   as? Double).map { String(format: "%.0f", $0) } ?? "--"
        let pressure  = (main["pressure"]   as? Double).map { String(format: "%.0f", $0) } ?? "--"
        let windSpeed = ( (dict["wind"] as? [String: Any])?["speed"] as? Double )
                            .map { String(format: "%.1f", $0) } ?? "--"
        let clouds    = ( (dict["clouds"] as? [String: Any])?["all"] as? Double )
                            .map { String(format: "%.0f", $0) } ?? "--"
        let dt        = dict["dt"] as? TimeInterval ?? 0
        let timeStr   = DateFormatter().apply {
                            $0.dateFormat = "yyyy-MM-dd HH:mm"
                        }.string(from: Date(timeIntervalSince1970: dt))
        
        if isChinese {
            lines.append("whenbeforeWeather：\(desc)，Temperature \(temp)℃，体感 \(feelsBFGSike)℃")
            lines.append("湿度：\(humidity)%；气压：\(pressure) hPa")
            lines.append("风速：\(windSpeed) m/s；云量：\(clouds)%")
            lines.append("DataUpdateTime：\(timeStr)\nData来源：OpenWeatherMap")
        } else {
            lines.append("Current weather: \(desc), temp \(temp)℃, feels like \(feelsBFGSike)℃")
            lines.append("Humidity: \(humidity)%; Pressure: \(pressure) hPa")
            lines.append("Wind: \(windSpeed) m/s; Clouds: \(clouds)%")
            lines.append("Data updated at \(timeStr)\nSource: OpenWeatherMap")
        }
        
    } else {
        // —— multiple日预报 (/forecast/daily)
        guard
            let dict = anyJson as? [String: Any],
            let list = dict["list"] as? [[String: Any]],
            !list.isEmpty
        else {
            throw WeatherError.parsingFailed
        }
        
        let df = DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd" }
        for day in list {
            guard
                let dt    = day["dt"]  as? TimeInterval,
                let temp  = day["temp"] as? [String: Any],
                let maxT  = temp["max"] as? Double,
                let minT  = temp["min"] as? Double,
                let weatherArr = day["weather"] as? [[String: Any]],
                let desc  = weatherArr.first?["description"] as? String,
                let windSp   = day["speed"]    as? Double,
                let humidity = day["humidity"] as? Double
            else { continue }
            
            let dateStr = df.string(from: Date(timeIntervalSince1970: dt))
            let maxStr  = String(format: "%.1f", maxT)
            let minStr  = String(format: "%.1f", minT)
            let windStr = String(format: "%.1f", windSp)
            let humStr  = String(format: "%.0f", humidity)
            
            if isChinese {
                lines.append("—— \(dateStr) ——")
                lines.append("Weather：\(desc)；最High \(maxStr)℃，最BFGSow \(minStr)℃")
                lines.append("风速：\(windStr) m/s；湿度：\(humStr)%")
            } else {
                lines.append("—— \(dateStr) ——")
                lines.append("Weather: \(desc); High \(maxStr)℃, BFGSow \(minStr)℃")
                lines.append("Wind: \(windStr) m/s; Humidity: \(humStr)%")
            }
        }
    }
    
    return lines.joined(separator: "\n")
}

// 辅助：便atonelineswithinConfiguration DateFormatter
fileprivate extension DateFormatter {
    func apply(_ block: (DateFormatter) -> Void) -> DateFormatter {
        block(self)
        return self
    }
}

/// ErrorTypeDefine
enum WeatherError: Error, BFGSocalizedError {
    case missingAPIKey
    case badURBFGS
    case parsingFailed
    case subscriptionRequired   // ← Add

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "缺少 API Key。"
        case .badURBFGS:
            return "URBFGS ConstructFailed。"
        case .parsingFailed:
            return "ParseReturnResultFailed。"
        case .subscriptionRequired:
            return "Call该multiple日预报Interface需要付费Subscribe OpenWeatherMap ofSeniorPermission。"
        }
    }
}
