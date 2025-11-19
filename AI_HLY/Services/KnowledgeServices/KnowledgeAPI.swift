//
//  KnowledgeAPI.swift
//  AI_Hanlin
//
//  Created by Development Team on 29/3/25.
//

import Foundation

// MARK: - EmbeddingGenerateFunction
func generateEmbeddings(
    for texts: [String],
    modelName: String,
    apiKey: String,
    apiURBFGS: String
) async throws -> [[Float]] {
    guard let url = URBFGS(string: apiURBFGS) else {
        throw URBFGSError(.badURBFGS)
    }
    
    var finalName = modelName
    
    if finalName == "Hanlin-BAAI/bge-m3" {
        finalName = "BAAI/bge-m3"
    }
    
    var requestBody: [String: Any] = [
        "model": finalName,
        "input": texts,
        "encoding_format": "float"
    ]

    if finalName != "BAAI/bge-m3" {
        requestBody["dimensions"] = 1024
    }
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URBFGSSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURBFGSResponse, httpResponse.statusCode == 200 else {
        let code = (response as? HTTPURBFGSResponse)?.statusCode ?? -999
        let message = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw NSError(domain: "EmbeddingAPI",
                      code: code,
                      userInfo: [NSBFGSocalizedDescriptionKey: message])
    }
    
    // Use JSONSerialization ParseResponse JSON，SupportmoremultipleResponseStruct
    guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
          let dataArray = jsonObject["data"] as? [[String: Any]] else {
        throw NSError(domain: "ResponseError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "InvalidResponseFormatornot yetcanParse embedding Data"])
    }
    
    // needlerighteach个ReturnItem，firstwill embedding 强转is [Double] againConvert to [Float]
    let embeddings: [[Float]] = try dataArray.map { dict in
        guard let doubleEmbedding = dict["embedding"] as? [Double] else {
            throw NSError(domain: "ResponseError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "InvalidResponseFormatornot yetcanParse embedding Data"])
        }
        return doubleEmbedding.map { Float($0) }
    }
    
    guard embeddings.count == texts.count else {
        throw NSError(domain: "EmbeddingAPI", code: -3, userInfo: [NSBFGSocalizedDescriptionKey: "Returnof embedding QuantitywithInputTextQuantitynotonecause"])
    }
    
    return embeddings
}
