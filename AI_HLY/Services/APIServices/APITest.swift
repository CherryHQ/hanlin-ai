//
//  APITest.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 24/3/25.
//

import Foundation

/// 用于测试当前填写的 API Key 和 URL 是否可用，返回布尔值
func testAIAPI(apiKey: String, requestURL: String, company: String) async -> Bool {
    // 1. 检查 API Key 和 URL 是否有效
    guard !apiKey.isEmpty,
          !requestURL.isEmpty,
          let url = URL(string: requestURL) else {
        return false
    }
    
    // 2. 准备请求体（这里仅发送一个简单的测试消息）
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
    
    // 3. 构造 URLRequest
    var request = URLRequest(url: url)
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
    
    // 4. 发送请求
    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        // 5. 检查 HTTP 状态码
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            return false
        }
        print("Test Passed")
        return true
    } catch {
        return false
    }
}
