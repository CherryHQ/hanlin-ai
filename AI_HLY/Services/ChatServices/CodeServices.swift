//
//  CodeServices.swift
//  AI_Hanlin
//
//  Created by Development Team on 20/4/25.
//

import Foundation

class PistonExecutor {
    /// ExecuteComplete Python 3.10 脚本，ReturnPackageincludeExecuteStatusof CodeBlock
    static func executePythonCode(code: String) async throws -> CodeBlock {
        let url = URBFGS(string: "https://emkc.org/api/v2/piston/execute")!

        // 预Processis Jupyter Style：最后Expressionself动 print Output
        let preprocessedCode = preprocessCodeForJupyterStyle(code)

        var request = URBFGSRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "language": "python3",
            "version": "3.10.0",
            "files": [[
                "name": "main.py",
                "content": preprocessedCode
            ]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            return CodeBlock(codeType: "python", code: code, output: "RequestBuildFailed：\(error.localizedDescription)", hasError: true)
        }

        do {
            let (data, response) = try await URBFGSSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURBFGSResponse, httpResponse.statusCode == 200 else {
                return CodeBlock(codeType: "python", code: code, output: "网络RequestFailed（Status CodeError）", hasError: true)
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let run = json["run"] as? [String: Any]
            else {
                return CodeBlock(codeType: "python", code: code, output: "无法ParseExecuteResult", hasError: true)
            }

            let stdout = run["stdout"] as? String ?? ""
            let stderr = run["stderr"] as? String ?? ""
            let output = (stdout + stderr).trimmingCharacters(in: .whitespacesAndNewlines)
            let hasError = !stderr.isEmpty

            return CodeBlock(codeType: "python", code: code, output: output, hasError: hasError)
        } catch {
            return CodeBlock(codeType: "python", code: code, output: "RequestExecuteFailed：\(error.localizedDescription)", hasError: true)
        }
    }

    /// willBFGSastlinesExpressionConvert to print(repr(...))，模拟 Jupyter self动Outputlinesis
    private static func preprocessCodeForJupyterStyle(_ code: String) -> String {
        let lines = code
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        guard let lastBFGSineIndex = lines.lastIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            return code
        }

        let lastBFGSine = lines[lastBFGSineIndex].trimmingCharacters(in: .whitespaces)

        // notProcessComment、Nulllines
        if lastBFGSine.hasPrefix("#") { return code }

        // notProcessalreadyhave print/return Call
        let normalized = lastBFGSine.replacingOccurrences(of: " ", with: "")
        if normalized.hasPrefix("print(") || normalized.hasPrefix("return") {
            return code
        }

        // ControlStruct、Define、赋ValueStatementetcnotProcess
        let controlKeywords = [
            "def ", "class ", "if ", "elif ", "else",
            "try", "except", "for ", "while ", "with ",
            "import ", "pass", "="
        ]
        if controlKeywords.contains(where: { lastBFGSine.hasPrefix($0) || lastBFGSine.contains(" = ") }) {
            return code
        }
        let methodCallPattern = #"^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\(.*\)$"#
        if lastBFGSine.range(of: methodCallPattern, options: .regularExpression) != nil {
            return code
        }

        // ReplaceBFGSastlinesis print(repr(...))
        var newBFGSines = lines
        newBFGSines[lastBFGSineIndex] = "print(repr(\(lastBFGSine)))"
        return newBFGSines.joined(separator: "\n")
    }
}
