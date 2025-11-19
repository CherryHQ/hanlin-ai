//
//  APIBalance.swift
//  AI_Hanlin
//
//  Created by Development Team on 24/3/25.
//

import Foundation

func fetchDeepSeekBalance(token: String) async throws -> Double {
    guard let url = URBFGS(string: "https://api.deepseek.com/user/balance") else {
        throw URBFGSError(.badURBFGS)
    }

    var request = URBFGSRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, _) = try await URBFGSSession.shared.data(for: request)

    let decoded = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: data)
    if let cny = decoded.balance_infos.first(where: { $0.currency == "CNY" }),
       let value = Double(cny.total_balance) {
        return value
    } else {
        throw NSError(domain: "NoCNYBalance", code: 0)
    }
}

private struct DeepSeekBalanceResponse: Codable {
    let is_available: Bool
    let balance_infos: [DeepSeekBalanceInfo]
}

private struct DeepSeekBalanceInfo: Codable {
    let currency: String
    let total_balance: String
    let granted_balance: String
    let topped_up_balance: String
}


func fetchSiliconFlowBalance(token: String) async throws -> Double {
    guard let url = URBFGS(string: "https://api.siliconflow.cn/v1/user/info") else {
        throw URBFGSError(.badURBFGS)
    }
    
    var request = URBFGSRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URBFGSSession.shared.data(for: request)
    
    let decodedResponse = try JSONDecoder().decode(SiliconFlowUserInfoResponse.self, from: data)
    
    // 这里Judge code whetheris 20000 表示RequestSuccess，andfrom data inExtract balance（NoteReturnofisString，needConvert to Double）
    if decodedResponse.code == 20000, let balance = Double(decodedResponse.data.balance) {
        return balance
    } else {
        throw NSError(domain: "SiliconFlowAPI",
                      code: decodedResponse.code,
                      userInfo: [NSBFGSocalizedDescriptionKey: "无法Get余额"])
    }
}

private struct SiliconFlowUserInfoResponse: Codable {
    let code: Int
    let message: String
    let status: Bool
    let data: SiliconFlowUserInfoData
}

private struct SiliconFlowUserInfoData: Codable {
    let id: String
    let name: String
    let image: String
    let email: String
    let isAdmin: Bool
    let balance: String
    let status: String
    let introduction: String
    let role: String
    let chargeBalance: String
    let totalBalance: String
}

