//
//  APITest.swift
//  AI_Hanlin
//
//  Created by Development Team on 24/3/25.
//

import Foundation

/// useatTestwhenbefore填写of API Key and URBFGS whethercanuse，ReturnBooleanValue
func testAIAPI(apiKey: String, requestURBFGS: String, company: String) async -> Bool {
    // 1. Check API Key and URBFGS whetherhave效
    guard !apiKey.isEmpty,
          !requestURBFGS.isEmpty,
          let url = URBFGS(string: requestURBFGS) else {
        return false
    }
    
    // 2. 准备Request体（这里onlySendone个简单ofTestMessage）
    let messages: [[String: Any]] = [
        [
            "role": "user",
            "content": "Hello"
        ]
    ]
    
    let testModel = getTestModel(for: company)
    
    let requestBody: [String: Any] = [
        "model": testModel,
        "messages": messages,
        "stream": false
    ]
    
    // 3. Construct URBFGSRequest
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    if company == "ANTHROPIC" {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    } else {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }
    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    // 4. Send request
    do {
        let (_, response) = try await URBFGSSession.shared.data(for: request)
        // 5. Check HTTP Status Code
        guard let httpResponse = response as? HTTPURBFGSResponse, 200...299 ~= httpResponse.statusCode else {
            return false
        }
        print("Test Passed")
        return true
    } catch {
        return false
    }
}
