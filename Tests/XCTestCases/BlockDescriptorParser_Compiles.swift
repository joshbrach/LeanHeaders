//
//  BlockDescriptorParser_Compiles.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 14/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest


class BlockDescriptorParser_Compiles: XCTestCase {
    
    private var parentParser = Mock_CodeBaseParser()
    
    
    func test_Capture_patternCompiles() {
        XCTAssertNotNil(BlockDescriptorParser(parent: parentParser))
    }
    
    func test_NonCapture_patternCompiles() {
        XCTAssertNotNil(try? NSRegularExpression(pattern: BlockDescriptorParser.pattern(),
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
}

// EOF
