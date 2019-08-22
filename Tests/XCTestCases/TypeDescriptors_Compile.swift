//
//  TypeDescriptors_Compile.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 04/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest


class TypeDescriptors_Compile: XCTestCase {
    
    private var parentParser = Mock_CodeBaseParser()
    
    
    func test_Capture_patternCompiles() {
        XCTAssertNotNil(TypeDescriptorParser(parent: parentParser))
    }
    
    // MARK: - 3x
    
    func test_nullExcluded_conformanceExcluded_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: 2x 1o
    
    func test_nullOptional_conformanceExcluded_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullExcluded_conformanceOptional_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullExcluded_conformanceExcluded_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: 2x 1r
    
    func test_nullRequired_conformanceExcluded_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullExcluded_conformanceRequired_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullExcluded_conformanceExcluded_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: - 3o
    
    func test_nullOptional_conformanceOptional_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: 2o 1x
    
    func test_nullExcluded_conformanceOptional_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullOptional_conformanceExcluded_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullOptional_conformanceOptional_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: 2o 1r
    
    func test_nullRequired_conformanceOptional_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullOptional_conformanceRequired_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullOptional_conformanceOptional_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: - 3r
    
    func test_nullRequired_conformanceRequired_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: 2r 1x
    
    func test_nullExcluded_conformanceRequired_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullRequired_conformanceExcluded_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullRequired_conformanceRequired_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: 2r 1o
    
    func test_nullOptional_conformanceRequired_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullRequired_conformanceOptional_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullRequired_conformanceRequiredd_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    // MARK: - 1x 1o 1r
    
    func test_nullExcluded_conformanceOptional_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullExcluded_conformanceRequired_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    func test_nullOptional_conformanceExcluded_genericRequired_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: false)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullOptional_conformanceRequired_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: true,
                                                   conformanceIncludedOptionally: false,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
    func test_nullRequired_conformanceExcluded_genericOptional_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: nil,
                                                   genericArgsIncludedOptionally: true)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    func test_nullRequired_conformanceOptional_genericExcluded_patternCompiles() {
        let pattern = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: false,
                                                   conformanceIncludedOptionally: true,
                                                   genericArgsIncludedOptionally: nil)
        XCTAssertNotNil(try? NSRegularExpression(pattern: pattern,
                                                 options: .allowCommentsAndWhitespace)
        )
    }
    
}

// EOF
