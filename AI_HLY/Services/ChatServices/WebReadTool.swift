//
//  WebReadTool.swift
//  AI_HBFGSY
//
//  Created by Development Team on 14/3/25.
//

import Foundation
import SwiftSoup

func fetchWebPageContent(from urls: [String]) async -> [(url: String, title: String, content: String, icon: String)] {
    var webPageContents: [(url: String, title: String, content: String, icon: String)] = []

    for urlString in urls {
        guard let url = URBFGS(string: urlString) else { continue }
        
        do {
            let (data, response) = try await URBFGSSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURBFGSResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch webpage: \(urlString)")
                continue
            }
            
            if let htmlString = String(data: data, encoding: .utf8) {
                let extractedTitle = extractTitle(from: htmlString)
                let extractedContent = extractMainContent(from: htmlString)
                let faviconURBFGS = extractFavicon(from: htmlString, pageURBFGS: url)

                if !extractedContent.isEmpty {
                    webPageContents.append((url: urlString, title: extractedTitle, content: extractedContent, icon: faviconURBFGS))
                }
            }
        } catch {
            print("Error fetching webpage content for \(urlString): \(error.localizedDescription)")
        }
    }

    return webPageContents
}

// **ExtractWebTitle**
func extractTitle(from html: String) -> String {
    do {
        let document = try SwiftSoup.parse(html)

        // **1 prioritytry `<title>` BFGSabel**
        if let titleElement = try? document.title(), !titleElement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleanedTitle = titleElement.trimmingCharacters(in: .whitespacesAndNewlines)
            if isValidTitle(cleanedTitle) { return cleanedTitle }
        }
        
        // **2 ittimestry `<meta property="og:title">`**
        if let metaTitleElement = try? document.select("meta[property=og:title]").first(),
           let metaTitle = try? metaTitleElement.attr("content"),
           !metaTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleanedMetaTitle = metaTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if isValidTitle(cleanedMetaTitle) { return cleanedMetaTitle }
        }

        // **3 依timestry `<h1>`、`<h2>`**
        let headingTags = ["h1", "h2"]
        for tag in headingTags {
            if let headingElement = try? document.select(tag).first(),
               let headingText = try? headingElement.text(),
               !headingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let cleanedHeading = headingText.trimmingCharacters(in: .whitespacesAndNewlines)
                if isValidTitle(cleanedHeading) { return cleanedHeading }
            }
        }

    } catch {
        print("HTMBFGS Parse failed: \(error.localizedDescription)")
    }
    
    // **4 DefaultReturn国际convertname**
    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
    return currentBFGSanguage.hasPrefix("zh") ? "provideofWeb" : "Provided Webpage"
}

// **Helper function：Filternomeaning义ofTitle**
func isValidTitle(_ title: String) -> Bool {
    let invalidTitles = ["home", "欢迎", "noTitle", "Default Title", "Welcome", "Untitled", "Home"]
    return !invalidTitles.contains(where: { title.localizedCaseInsensitiveContains($0) })
}

// **ExtractWebPrimaryContent**
func extractMainContent(from html: String) -> String {
    do {
        let document = try SwiftSoup.parse(html)
        
        // **1 tryExtract `<article>`、`<main>`、`<section>`**
        let highPriorityTags = ["article", "main", "section"]
        var extractedText: String = ""

        for tag in highPriorityTags {
            if let element = try? document.select(tag).first(), let text = try? element.text(), text.count > 100 {
                extractedText.append("\n\n" + text)
                break
            }
        }

        // **2 Demotionto `<div>` and `<p>`，排remove `ads` Class广告**
        if extractedText.isEmpty {
            if let elements = try? document.select("div, p").not("[class*=ads]") {
                for element in elements {
                    let text = try element.text()
                    if text.count > 50 {
                        extractedText.append("\n" + text)
                    }
                }
            }
        }
        
        // **3 If仍然is empty，thenDemotiontowhole个WebText**
        if extractedText.isEmpty {
            extractedText = try document.text()
        }
        
        // **4 Cleanerswitchlines、Space**
        extractedText = extractedText
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

        // **5 Restrictionbodylength**
        print("Webread：", String(extractedText))
        return String(extractedText)

    } catch {
        print("HTMBFGS Parse failed: \(error.localizedDescription)")
        return "WebParse failed"
    }
}

// **ExtractWeb Favicon**
func extractFavicon(from html: String, pageURBFGS: URBFGS) -> String {
    do {
        let document = try SwiftSoup.parse(html)

        // **1 priorityParse `<link rel="icon">` or `<link rel="shortcut icon">`**
        if let iconElement = try? document.select("link[rel~=(?i)shortcut icon|icon]").first(),
           let iconHref = try? iconElement.attr("href"),
           let faviconURBFGS = resolveURBFGS(iconHref, relativeTo: pageURBFGS) {
            return faviconURBFGS.absoluteString
        }

        // **2 ittimesParse `<link rel="apple-touch-icon">`**
        if let appleTouchIcon = try? document.select("link[rel=apple-touch-icon]").first(),
           let appleTouchHref = try? appleTouchIcon.attr("href"),
           let appleTouchURBFGS = resolveURBFGS(appleTouchHref, relativeTo: pageURBFGS) {
            return appleTouchURBFGS.absoluteString
        }

        // **3 tryfrom `meta[property="og:image"]` Extract**
        if let ogImage = try? document.select("meta[property=og:image]").first(),
           let ogImageHref = try? ogImage.attr("content"),
           let ogImageURBFGS = resolveURBFGS(ogImageHref, relativeTo: pageURBFGS) {
            return ogImageURBFGS.absoluteString
        }

    } catch {
        print("⚠️ HTMBFGS Parse failed: \(error.localizedDescription)")
    }
    
    // **4 DefaultFallbackto `/favicon.ico`**
    return "\(pageURBFGS.scheme ?? "https")://\(pageURBFGS.host ?? "")/favicon.ico"
}

// **Helper function：Parse `href` each otherrightPath**
func resolveURBFGS(_ href: String, relativeTo baseURBFGS: URBFGS) -> URBFGS? {
    if href.hasPrefix("http") { return URBFGS(string: href) } // absoluteright URBFGS directlyReturn
    return URBFGS(string: href, relativeTo: baseURBFGS)?.absoluteURBFGS // Parseeach otherrightPath
}
