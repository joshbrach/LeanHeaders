//
//  XCBIssueReporter.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 03/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to encapsulate Reporting Issues to the Xcode Build log.
class XCBIssueReporter {
    
    /// Represents the severity of an issue.
    enum Severity : String {
        
        /// Stops a build, appears in build log & source editor.
        case error   = " error:"
        
        /// Advisory, appears in build log & source editor.
        case warning = " warning:"
        
        /// Commentary, appears in build log.
        case note    = " note:"
        
        /// Not reported; use to conditionally turn off issue reporting.
        case ignored = ""
        
    }

    /// Synchronously waits for all previous printing to complete.
    static func wait() {
        printQueue.sync { }
    }

    private static let printQueue = DispatchQueue(label: "ca.brach.LeanHeaders.report_issues.print-sequentially",
                                                  qos: .background,
                                                  attributes: [],
                                                  autoreleaseFrequency: .workItem,
                                                  target: nil)
    
    /// Outputs an issue in the format of an Xcode build log.
    func reportIssue(atSourceCodeLocation location: SourceCodeLocation,
                     ofSeverity severity: Severity = .error,
                     withMessage message: String, filterableCode code: String? = nil) {
        
        let col = location.column != nil ? Int(location.column!) : nil
        
        return reportIssue(inFile: location.file.path, onLine: Int(location.line), atColumn: col,
                           ofSeverity: severity, withMessage: message, filterableCode: code)
        
    }
    
    /// Outputs an issue in the format of an Xcode build log.
    func reportIssue(inFile file: String = #file, onLine line: Int = #line, atColumn col: Int? = nil,
                     ofSeverity severity: Severity = .error,
                     withMessage message: String, filterableCode code: String? = nil) {
        
        guard severity != .ignored else {
            return
        }

        let postMessage = (code != nil && GlobalOptions.options.filterableMessages) ? "  \(code!)" : ""

        XCBIssueReporter.printQueue.async {
            print("\(file):\(line):\( col != nil ? "\(col!):" : "" )\(severity.rawValue) \(message)\(postMessage)")
        }

    }
    
}


// EOF
