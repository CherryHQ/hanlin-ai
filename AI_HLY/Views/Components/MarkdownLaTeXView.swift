import SwiftUI
import Foundation
import MarkdownUI
import LaTeXSwiftUI

struct MarkdownLaTeXView: View {
    let text: String
    let fontSize: CGFloat
    let isStreaming: Bool
    private let blocks: [MarkdownLaTeXBlock]

    init(_ text: String, fontSize: CGFloat, isStreaming: Bool = false) {
        self.text = text
        self.fontSize = fontSize
        self.isStreaming = isStreaming
        // 流式进行中跳过解析与富排版，避免逐 token 全量重解析；结束后再走完整排版（带缓存）。
        self.blocks = isStreaming ? [] : MarkdownLaTeXCache.blocks(for: text)
    }

    var body: some View {
        if isStreaming {
            Markdown(text)
                .font(.system(size: fontSize))
        } else {
            renderedBlocks
        }
    }

    private var renderedBlocks: some View {
        let blockSpacing = max(6, fontSize * 0.45)
        return VStack(alignment: .leading, spacing: blockSpacing) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .markdown(let markdownText):
                    Markdown(markdownText)
                        .font(.system(size: fontSize))
                case .paragraph(let content):
                    InlineParagraphView(content: content, fontSize: fontSize)
                case .latexBlock(let latexText):
                    LatexBlockView(content: latexText, fontSize: fontSize)
                case .spacer(let count):
                    Color.clear.frame(height: CGFloat(count) * blockSpacing)
                }
            }
        }
    }
}

private struct InlineParagraphView: View {
    let content: InlineContent
    let fontSize: CGFloat

    var body: some View {
        let inlineSpacing = max(2, fontSize * 0.08)
        let lineSpacing = max(4, fontSize * 0.28)
        let items = InlineContentBuilder.buildItems(from: content)

        InlineFlowLayout(spacing: inlineSpacing, lineSpacing: lineSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                switch item {
                case .text(let attributed):
                    Text(attributed)
                        .font(.system(size: fontSize))
                        .foregroundColor(.primary)
                case .math(let latex):
                    LaTeX(latex)
                        .font(.system(size: fontSize))
                        // 异步后台渲染，避免 MathJax 在主线程同步阻塞（默认 .wait）；渲染前先显示原始源码。
                        .renderingStyle(.original)
                case .lineBreak:
                    Color.clear
                        .frame(width: 0, height: 0)
                        .layoutValue(key: InlineBreakKey.self, value: true)
                        .accessibilityHidden(true)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct LatexBlockView: View {
    let content: String
    let fontSize: CGFloat

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LaTeX(content)
                .font(.system(size: fontSize))
                // 异步后台渲染，避免 MathJax 在主线程同步阻塞（默认 .wait）；渲染前先显示原始源码。
                .renderingStyle(.original)
                .padding(.vertical, fontSize * 0.2)
                .padding(.horizontal, fontSize * 0.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum MarkdownLaTeXBlock {
    case markdown(String)
    case paragraph(InlineContent)
    case latexBlock(String)
    case spacer(Int)
}

private struct InlineContent {
    let text: String
    let inlineMath: [String]
    let tokenPrefix: String
    let tokenSuffix: String

    func token(for index: Int) -> String {
        "\(tokenPrefix)\(index)\(tokenSuffix)"
    }
}

private struct MarkdownLaTeXParser {
    static func parseBlocks(_ text: String) -> [MarkdownLaTeXBlock] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var blocks: [MarkdownLaTeXBlock] = []
        var buffer = ""
        var index = normalized.startIndex

        while index < normalized.endIndex {
            if isAtLineStart(normalized, index),
               let fence = fenceDelimiter(in: normalized, at: index) {
                appendParagraphs(from: buffer, to: &blocks)
                buffer = ""
                let (block, next) = consumeCodeFence(in: normalized, start: index, delimiter: fence)
                blocks.append(.markdown(block))
                index = next
                continue
            }

            if let inlineDelim = inlineBacktickDelimiter(in: normalized, at: index),
               let closeRange = findInlineClosing(in: normalized, start: index, delimiter: inlineDelim) {
                buffer.append(contentsOf: normalized[index..<closeRange.upperBound])
                index = closeRange.upperBound
                continue
            }

            if let blockDelimiter = blockMathDelimiter(in: normalized, at: index) {
                if let closeRange = findBlockClosing(in: normalized, from: index, delimiter: blockDelimiter) {
                    appendParagraphs(from: buffer, to: &blocks)
                    buffer = ""
                    let start = normalized.index(index, offsetBy: blockDelimiter.start.count)
                    let contentRange = start..<closeRange.lowerBound
                    let content = String(normalized[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    blocks.append(.latexBlock(content))
                    index = closeRange.upperBound
                    continue
                } else {
                    buffer.append(contentsOf: blockDelimiter.start)
                    index = normalized.index(index, offsetBy: blockDelimiter.start.count)
                    continue
                }
            }

            buffer.append(normalized[index])
            index = normalized.index(after: index)
        }

        appendParagraphs(from: buffer, to: &blocks)
        return blocks
    }

    private static func appendParagraphs(from buffer: String, to blocks: inout [MarkdownLaTeXBlock]) {
        guard !buffer.isEmpty else { return }

        let lines = buffer.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var currentLines: [String] = []
        var blankCount = 0
        var hasContent = !blocks.isEmpty

        func flushCurrent() {
            let paragraph = currentLines.joined(separator: "\n")
            let content = InlineMathParser.parse(paragraph)
            if content.inlineMath.isEmpty {
                blocks.append(.markdown(paragraph))
            } else {
                blocks.append(.paragraph(content))
            }
            currentLines.removeAll()
            hasContent = true
        }

        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !currentLines.isEmpty {
                    flushCurrent()
                }
                if hasContent {
                    blankCount += 1
                }
                continue
            }

            if blankCount > 0 {
                blocks.append(.spacer(blankCount))
                blankCount = 0
            }

            currentLines.append(String(line))
        }

        if !currentLines.isEmpty {
            flushCurrent()
        }
    }

    private static func isAtLineStart(_ text: String, _ index: String.Index) -> Bool {
        if index == text.startIndex { return true }
        let previous = text.index(before: index)
        return text[previous] == "\n"
    }

    private static func fenceDelimiter(in text: String, at index: String.Index) -> String? {
        let char = text[index]
        guard char == "`" || char == "~" else { return nil }
        var count = 0
        var cursor = index
        while cursor < text.endIndex && text[cursor] == char {
            count += 1
            cursor = text.index(after: cursor)
        }
        guard count >= 3 else { return nil }
        return String(repeating: char, count: count)
    }

    private static func consumeCodeFence(
        in text: String,
        start: String.Index,
        delimiter: String
    ) -> (String, String.Index) {
        var cursor = text.index(start, offsetBy: delimiter.count)
        while cursor < text.endIndex {
            if isAtLineStart(text, cursor), text[cursor...].hasPrefix(delimiter) {
                let lineEnd = text[cursor...].firstIndex(of: "\n") ?? text.endIndex
                let blockEnd = lineEnd == text.endIndex ? lineEnd : text.index(after: lineEnd)
                return (String(text[start..<blockEnd]), blockEnd)
            }
            cursor = text.index(after: cursor)
        }
        return (String(text[start..<text.endIndex]), text.endIndex)
    }

    private static func inlineBacktickDelimiter(in text: String, at index: String.Index) -> String? {
        guard text[index] == "`" else { return nil }
        var count = 0
        var cursor = index
        while cursor < text.endIndex && text[cursor] == "`" {
            count += 1
            cursor = text.index(after: cursor)
        }
        return String(repeating: "`", count: count)
    }

    private static func findInlineClosing(
        in text: String,
        start: String.Index,
        delimiter: String
    ) -> Range<String.Index>? {
        let searchStart = text.index(start, offsetBy: delimiter.count)
        guard searchStart < text.endIndex else { return nil }
        return text.range(of: delimiter, range: searchStart..<text.endIndex)
    }

    private struct BlockDelimiter {
        let start: String
        let end: String
    }

    private static func blockMathDelimiter(in text: String, at index: String.Index) -> BlockDelimiter? {
        if text[index] == "$" {
            let next = text.index(after: index)
            if next < text.endIndex, text[next] == "$", !isEscaped(text, at: index) {
                return BlockDelimiter(start: "$$", end: "$$")
            }
        }
        if text[index] == "\\", !isEscaped(text, at: index) {
            let next = text.index(after: index)
            if next < text.endIndex, text[next] == "[" {
                return BlockDelimiter(start: "\\[", end: "\\]")
            }
        }
        return nil
    }

    private static func findBlockClosing(
        in text: String,
        from index: String.Index,
        delimiter: BlockDelimiter
    ) -> Range<String.Index>? {
        var cursor = text.index(index, offsetBy: delimiter.start.count)
        while cursor < text.endIndex {
            if text[cursor...].hasPrefix(delimiter.end), !isEscaped(text, at: cursor) {
                let end = text.index(cursor, offsetBy: delimiter.end.count)
                return cursor..<end
            }
            cursor = text.index(after: cursor)
        }
        return nil
    }
}

/// 完整解析结果的 LRU 缓存（仅主线程访问，无需加锁）。
/// 非流式重建（滚动、contextMenu、兄弟 @State 变化）时复用解析结果，避免重复扫描。
private enum MarkdownLaTeXCache {
    private static var storage: [String: [MarkdownLaTeXBlock]] = [:]
    private static var order: [String] = []
    private static let limit = 64

    static func blocks(for text: String) -> [MarkdownLaTeXBlock] {
        if let cached = storage[text] {
            // 命中：刷新为最近使用
            if let idx = order.firstIndex(of: text) {
                order.remove(at: idx)
                order.append(text)
            }
            return cached
        }

        let parsed = MarkdownLaTeXParser.parseBlocks(text)
        storage[text] = parsed
        order.append(text)

        if order.count > limit {
            let evicted = order.removeFirst()
            storage.removeValue(forKey: evicted)
        }
        return parsed
    }
}

private struct InlineMathParser {
    static func parse(_ text: String) -> InlineContent {
        let tokenPrefix = "@@LATEX_INLINE_TOKEN_\(text.hashValue)_"
        let tokenSuffix = "@@"
        var output = ""
        var inlineMath: [String] = []
        var index = text.startIndex

        while index < text.endIndex {
            if let inlineDelim = inlineBacktickDelimiter(in: text, at: index),
               let closeRange = findInlineClosing(in: text, start: index, delimiter: inlineDelim) {
                output.append(contentsOf: text[index..<closeRange.upperBound])
                index = closeRange.upperBound
                continue
            }

            if text[index] == "\\", !isEscaped(text, at: index) {
                let next = text.index(after: index)
                if next < text.endIndex, text[next] == "(" {
                    if let closeIndex = findInlineEnd(in: text, from: text.index(after: next), delimiter: "\\)") {
                        let contentRange = text.index(index, offsetBy: 2)..<closeIndex
                        let content = String(text[contentRange])
                        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            output.append(contentsOf: "\(tokenPrefix)\(inlineMath.count)\(tokenSuffix)")
                            inlineMath.append(content)
                            index = text.index(closeIndex, offsetBy: 2)
                            continue
                        }
                    }
                }
            }

            if text[index] == "$", !isEscaped(text, at: index) {
                let next = text.index(after: index)
                if next < text.endIndex, text[next] == "$" {
                    output.append("$$")
                    index = text.index(after: next)
                    continue
                }
                if next < text.endIndex, text[next].isWhitespaceOrNewline {
                    output.append("$")
                    index = next
                    continue
                }
                if let closeIndex = findInlineDollarEnd(in: text, from: next) {
                    let contentRange = next..<closeIndex
                    let content = String(text[contentRange])
                    if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        output.append(contentsOf: "\(tokenPrefix)\(inlineMath.count)\(tokenSuffix)")
                        inlineMath.append(content)
                        index = text.index(after: closeIndex)
                        continue
                    }
                }
            }

            output.append(text[index])
            index = text.index(after: index)
        }

        return InlineContent(
            text: output,
            inlineMath: inlineMath,
            tokenPrefix: tokenPrefix,
            tokenSuffix: tokenSuffix
        )
    }

    private static func inlineBacktickDelimiter(in text: String, at index: String.Index) -> String? {
        guard text[index] == "`" else { return nil }
        var count = 0
        var cursor = index
        while cursor < text.endIndex && text[cursor] == "`" {
            count += 1
            cursor = text.index(after: cursor)
        }
        return String(repeating: "`", count: count)
    }

    private static func findInlineClosing(
        in text: String,
        start: String.Index,
        delimiter: String
    ) -> Range<String.Index>? {
        let searchStart = text.index(start, offsetBy: delimiter.count)
        guard searchStart < text.endIndex else { return nil }
        return text.range(of: delimiter, range: searchStart..<text.endIndex)
    }

    private static func findInlineEnd(
        in text: String,
        from index: String.Index,
        delimiter: String
    ) -> String.Index? {
        var cursor = index
        while cursor < text.endIndex {
            if text[cursor...].hasPrefix(delimiter), !isEscaped(text, at: cursor) {
                return cursor
            }
            cursor = text.index(after: cursor)
        }
        return nil
    }

    private static func findInlineDollarEnd(in text: String, from index: String.Index) -> String.Index? {
        var cursor = index
        while cursor < text.endIndex {
            if text[cursor] == "$", !isEscaped(text, at: cursor) {
                let next = text.index(after: cursor)
                if next < text.endIndex, text[next] == "$" {
                    cursor = next
                    continue
                }
                let prev = text.index(before: cursor)
                if text[prev].isWhitespaceOrNewline {
                    cursor = next
                    continue
                }
                return cursor
            }
            cursor = text.index(after: cursor)
        }
        return nil
    }
}

private enum InlineItem {
    case text(AttributedString)
    case math(String)
    case lineBreak
}

private struct InlineContentBuilder {
    static func buildItems(from content: InlineContent) -> [InlineItem] {
        let attributed = parseMarkdown(content.text)
        guard !content.inlineMath.isEmpty else {
            return splitByNewlines(attributed)
        }

        let plain = String(attributed.characters)
        var items: [InlineItem] = []
        var searchStart = plain.startIndex

        for (index, math) in content.inlineMath.enumerated() {
            let token = content.token(for: index)
            guard let tokenRange = plain.range(of: token, range: searchStart..<plain.endIndex) else {
                break
            }
            appendSlice(
                from: attributed,
                plain: plain,
                range: searchStart..<tokenRange.lowerBound,
                to: &items
            )
            items.append(.math(math))
            searchStart = tokenRange.upperBound
        }

        appendSlice(
            from: attributed,
            plain: plain,
            range: searchStart..<plain.endIndex,
            to: &items
        )

        return items
    }

    private static func parseMarkdown(_ text: String) -> AttributedString {
        if let parsed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return parsed
        }
        return AttributedString(text)
    }

    private static func appendSlice(
        from attributed: AttributedString,
        plain: String,
        range: Range<String.Index>,
        to items: inout [InlineItem]
    ) {
        guard let lower = AttributedString.Index(range.lowerBound, within: attributed),
              let upper = AttributedString.Index(range.upperBound, within: attributed),
              lower < upper else { return }
        let slice = AttributedString(attributed[lower..<upper])
        items.append(contentsOf: splitByNewlines(slice))
    }

    private static func splitByNewlines(_ attributed: AttributedString) -> [InlineItem] {
        let plain = String(attributed.characters)
        var items: [InlineItem] = []
        var searchStart = plain.startIndex

        while let newlineRange = plain.range(of: "\n", range: searchStart..<plain.endIndex) {
            appendTextSlice(
                from: attributed,
                plain: plain,
                range: searchStart..<newlineRange.lowerBound,
                to: &items
            )
            items.append(.lineBreak)
            searchStart = newlineRange.upperBound
        }

        appendTextSlice(
            from: attributed,
            plain: plain,
            range: searchStart..<plain.endIndex,
            to: &items
        )

        return items
    }

    private static func appendTextSlice(
        from attributed: AttributedString,
        plain: String,
        range: Range<String.Index>,
        to items: inout [InlineItem]
    ) {
        guard let lower = AttributedString.Index(range.lowerBound, within: attributed),
              let upper = AttributedString.Index(range.upperBound, within: attributed),
              lower < upper else { return }
        let slice = AttributedString(attributed[lower..<upper])
        if !slice.characters.isEmpty {
            items.append(.text(slice))
        }
    }
}

private struct InlineFlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    /// 缓存每个子视图的度量结果，避免 sizeThatFits 与 placeSubviews 各测量一遍。
    struct Cache {
        var metrics: [InlineFlowMetrics?]
        var maxWidth: CGFloat
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache(metrics: Array(repeating: nil, count: subviews.count), maxWidth: .nan)
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        if cache.metrics.count != subviews.count {
            cache.metrics = Array(repeating: nil, count: subviews.count)
            cache.maxWidth = .nan
        }
    }

    private func metrics(
        for index: Int,
        subview: LayoutSubview,
        maxWidth: CGFloat,
        cache: inout Cache
    ) -> InlineFlowMetrics {
        // 宽度变化时整体失效（requiresFullWidth/换行结果与宽度相关）。
        if cache.maxWidth != maxWidth {
            cache.maxWidth = maxWidth
            for i in cache.metrics.indices { cache.metrics[i] = nil }
        }
        if let cached = cache.metrics[index] {
            return cached
        }
        let measured = InlineFlowMetrics.measure(subview, maxWidth: maxWidth)
        cache.metrics[index] = measured
        return measured
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowAscent: CGFloat = 0
        var rowDescent: CGFloat = 0
        var maxRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowCount = 0

        func finalizeRow() {
            guard rowWidth > 0 else { return }
            maxRowWidth = max(maxRowWidth, rowWidth)
            totalHeight += rowAscent + rowDescent
            rowWidth = 0
            rowAscent = 0
            rowDescent = 0
            rowCount += 1
        }

        for index in subviews.indices {
            let subview = subviews[index]
            if subview[InlineBreakKey.self] {
                finalizeRow()
                continue
            }

            let metrics = metrics(for: index, subview: subview, maxWidth: maxWidth, cache: &cache)
            if rowWidth > 0 && (metrics.requiresFullWidth || rowWidth + spacing + metrics.size.width > maxWidth) {
                finalizeRow()
            }
            if metrics.requiresFullWidth && rowWidth > 0 {
                finalizeRow()
            }

            if metrics.requiresFullWidth {
                rowWidth = metrics.size.width
                rowAscent = max(rowAscent, metrics.ascent)
                rowDescent = max(rowDescent, metrics.descent)
                finalizeRow()
                continue
            }

            rowWidth += (rowWidth > 0 ? spacing : 0) + metrics.size.width
            rowAscent = max(rowAscent, metrics.ascent)
            rowDescent = max(rowDescent, metrics.descent)
        }

        finalizeRow()
        if rowCount > 1 {
            totalHeight += lineSpacing * CGFloat(rowCount - 1)
        }

        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowItems: [(LayoutSubview, InlineFlowMetrics)] = []
        var rowAscent: CGFloat = 0
        var rowDescent: CGFloat = 0

        func placeRow(addSpacing: Bool) {
            guard !rowItems.isEmpty else { return }
            var currentX = x
            for (subview, metrics) in rowItems {
                let yOffset = rowAscent - metrics.ascent
                subview.place(
                    at: CGPoint(x: currentX, y: y + yOffset),
                    proposal: ProposedViewSize(width: metrics.size.width, height: metrics.size.height)
                )
                currentX += metrics.size.width + spacing
            }
            y += rowAscent + rowDescent + (addSpacing ? lineSpacing : 0)
            rowItems.removeAll()
            rowAscent = 0
            rowDescent = 0
        }

        for index in subviews.indices {
            let subview = subviews[index]
            if subview[InlineBreakKey.self] {
                placeRow(addSpacing: true)
                x = bounds.minX
                continue
            }

            let metrics = metrics(for: index, subview: subview, maxWidth: maxWidth, cache: &cache)
            if !rowItems.isEmpty && (metrics.requiresFullWidth || currentRowWidth(rowItems) + spacing + metrics.size.width > maxWidth) {
                placeRow(addSpacing: true)
                x = bounds.minX
            }

            if metrics.requiresFullWidth {
                rowItems.append((subview, metrics))
                rowAscent = max(rowAscent, metrics.ascent)
                rowDescent = max(rowDescent, metrics.descent)
                placeRow(addSpacing: true)
                x = bounds.minX
                continue
            }

            rowItems.append((subview, metrics))
            rowAscent = max(rowAscent, metrics.ascent)
            rowDescent = max(rowDescent, metrics.descent)
        }

        placeRow(addSpacing: false)
    }

    private func currentRowWidth(_ rowItems: [(LayoutSubview, InlineFlowMetrics)]) -> CGFloat {
        rowItems.reduce(0) { width, item in
            width + item.1.size.width
        } + max(0, CGFloat(rowItems.count - 1)) * spacing
    }
}

private struct InlineFlowMetrics {
    let size: CGSize
    let ascent: CGFloat
    let descent: CGFloat
    let requiresFullWidth: Bool

    static func measure(_ subview: LayoutSubview, maxWidth: CGFloat) -> InlineFlowMetrics {
        let ideal = subview.sizeThatFits(.unspecified)
        var size = ideal
        var fullWidth = false

        if maxWidth.isFinite && size.width > maxWidth {
            size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            fullWidth = true
        }

        let dimensions = subview.dimensions(in: ProposedViewSize(width: size.width, height: size.height))
        var baseline = dimensions[VerticalAlignment.firstTextBaseline]
        if baseline == 0 {
            baseline = size.height
        }
        let ascent = baseline
        let descent = size.height - baseline
        return InlineFlowMetrics(size: size, ascent: ascent, descent: descent, requiresFullWidth: fullWidth)
    }
}

private struct InlineBreakKey: LayoutValueKey {
    static let defaultValue = false
}

private func isEscaped(_ text: String, at index: String.Index) -> Bool {
    guard index > text.startIndex else { return false }
    var cursor = text.index(before: index)
    var count = 0
    while true {
        if text[cursor] == "\\" {
            count += 1
            if cursor == text.startIndex { break }
            cursor = text.index(before: cursor)
        } else {
            break
        }
    }
    return count % 2 == 1
}

private extension Character {
    var isWhitespaceOrNewline: Bool {
        isWhitespace || isNewline
    }
}
