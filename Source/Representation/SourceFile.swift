//
//  SourceFile.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 04/03/2018.
//  Copyright © 2018 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to represent a source-code file.
class SourceFile {

    /// The file system location of the file.
    let url : URL

    /// The contents of the file.
    ///
    /// NSString for convenience with NSRange & NSRegularExpression.
    let sourceText : NSString

    /// The memoized length of the source text.
    private(set) lazy var sourceLength = sourceText.length

    init?(_ fileSystemLocation: URL) {
        url = fileSystemLocation
        // Swift still does not have a convenient lazy file read…
        guard let text = try? NSString(contentsOf: url, usedEncoding: nil) else {
            XCBIssueReporter().reportIssue(withMessage: "Cannot read header file '\(url.path)'.")
            return nil
        }
        sourceText = text
    }

    // MARK: - Utility Functions

    /// For use only in location(ofRange:inSource:fromFile:)
    private var memoizedLocationsForRanges : [Int: (UInt, UInt)] = [:]  // [range.start : (line, col)]

    /// Returns the SourceCode Location of the given range in the source text of the file.
    internal func location(ofRange range: NSRange) -> SourceCodeLocation {
        var lineNumber : UInt = 1  // Xcode starts line counting at 1!
        var colNumber : UInt = 0

        // rewind from desired location to find memoized position from which to restart new-line counting…
        var reStart = range.location
        while reStart > 0 && memoizedLocationsForRanges[reStart] == nil {
            reStart -= 1
        }
        if let memo = memoizedLocationsForRanges[reStart] {
            (lineNumber, colNumber) = memo
        }

        // restrict source to the range in which to count new-lines…
        let searchRange = NSRange(location: reStart, length: range.location - reStart)
        let searchText = sourceText.substring(with: searchRange)

        // count new-lines…
        var lastLineStart : Int = 0
        for (offset, character) in searchText.enumerated() {
            if character == "\n" {
                lineNumber = lineNumber + 1
                // offset is zero-based, meaning that the new-line is at position reStart+offset+1,
                // and the next position is the first column of the next line.
                lastLineStart = reStart + offset + 2
                memoizedLocationsForRanges[lastLineStart] = (lineNumber, 1)
            }
        }

        // count column on line…
        if lastLineStart == 0 {
            // no newline between restart and range…
            colNumber += UInt(range.location - reStart)
        } else {
            // fresh line…
            colNumber = UInt(range.location - lastLineStart + 1)
        }

        // memoize…
        if memoizedLocationsForRanges[range.location] == nil {
            memoizedLocationsForRanges[range.location] = (lineNumber, colNumber)
        }

        return (url, lineNumber, colNumber)
    }

}
