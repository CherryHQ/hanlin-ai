//
//  Embeddings.swift
//  AI_HLY
//
//  AICore —— 与 provider 无关的纯向量/文本相似度算法。
//  从 APIManager 中抽出的无副作用工具函数（逻辑逐字一致），供知识检索/召回复用。
//

import Foundation
import Accelerate

enum Embeddings {

    /// 计算两个向量的余弦相似度
    static func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        // 保证长度一致，取最小长度进行计算
        let count = min(v1.count, v2.count)
        let n = vDSP_Length(count)

        // 1. 计算点积 dot = ∑ v1[i] * v2[i]
        var dot: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dot, n)

        // 2. 计算二范数的平方：sum1 = ∑ v1[i]^2, sum2 = ∑ v2[i]^2
        var sum1: Float = 0
        var sum2: Float = 0
        vDSP_svesq(v1, 1, &sum1, n)
        vDSP_svesq(v2, 1, &sum2, n)

        // 3. 归一化并避免除零：denom = ||v1|| * ||v2|| + ε
        let denom = sqrt(sum1) * sqrt(sum2) + Float.leastNonzeroMagnitude

        // 4. 返回余弦相似度
        return dot / denom
    }

    /// 将文本拆分成小写词语数组
    static func tokenize(_ text: String) -> [String] {
        let separators = CharacterSet.alphanumerics.inverted
        return text
            .lowercased()
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
    }

    /// 使用 TF–IDF 权重计算加权 Jaccard 相似度
    static func weightedJaccard(
        between queryTokens: [String],
        and docTokens: [String],
        idfMap: [String: Double]
    ) -> Double {
        let qSet = Set(queryTokens)
        let dSet = Set(docTokens)
        guard !qSet.isEmpty && !dSet.isEmpty else { return 0 }

        let intersection = qSet.intersection(dSet)
        let union = qSet.union(dSet)

        // 交集权重 = ∑ idf(token)
        let interWeight = intersection.reduce(0) { $0 + (idfMap[$1] ?? 0) }
        // 并集权重 = ∑ idf(token)
        let unionWeight = union.reduce(0) { $0 + (idfMap[$1] ?? 0) }

        return unionWeight > 0 ? interWeight / unionWeight : 0
    }
}
