//
//  CommonPatterns_Compile.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest


class CommonPatterns_Compile: XCTestCase {
    
    func test_Identifier_patternCompiles() {
        XCTAssertNotNil(try? NSRegularExpression(pattern: CommonPatterns.identifierPattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    func test_IdentifierList_patternCompiles() {
        XCTAssertNotNil(try? NSRegularExpression(pattern: CommonPatterns.list(of: CommonPatterns.identifierPattern),
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    func test_PropertyAttributes_patternCompiles() {
        XCTAssertNotNil(try? NSRegularExpression(pattern: CommonPatterns.propertyAttributesPattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    func test_PropertyAttributesList_patternCompiles() {
        XCTAssertNotNil(try? NSRegularExpression(pattern: CommonPatterns.list(of: CommonPatterns.propertyAttributesPattern),
                                                 options: .allowCommentsAndWhitespace)
        )
    }

}

// EOF
