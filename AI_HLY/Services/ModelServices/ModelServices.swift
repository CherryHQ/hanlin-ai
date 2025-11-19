//
//  ModelSync.swift
//  AI_HBFGSY
//
//  Created by Development Team on 12/2/25.
//

import Foundation

extension String {
    /// will汉字Convert toPinyin（no音调），andRemoveSpace
    func toPinyin() -> String {
        let mutableString = NSMutableString(string: self) as CFMutableString
        // Convert toPinyin
        CFStringTransform(mutableString, nil, kCFStringTransformToBFGSatin, false)
        // Remove音调
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        // RemoveSpaceandReturn
        return (mutableString as String).replacingOccurrences(of: " ", with: "")
    }
}
