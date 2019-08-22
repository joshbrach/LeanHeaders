//
//  HeaderParsers_Compile.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest


class HeaderParsers_Compile: XCTestCase {
    
    private var parentParser = Mock_CodeBaseParser()
    
    
    func test_ClassDeclaration_patternCompiles() {
        XCTAssertNotNil(ClassDeclarationHeaderParser(parent: parentParser))
    }
    
    func test_CategoryDeclaration_patternCompiles() {
        XCTAssertNotNil(CategoryDeclarationHeaderParser(parent: parentParser))
    }
    
    func test_ProtocolDeclaration_patternCompiles() {
        XCTAssertNotNil(ProtocolDeclarationHeaderParser(parent: parentParser))
    }
    
    func test_ForwardDeclaration_patternCompiles() {
        XCTAssertNotNil(ForwardDeclarationHeaderParser(parent: parentParser))
    }
    
    func test_PropertyDeclaration_patternCompiles() {
        XCTAssertNotNil(PropertyDeclarationHeaderParser(parent: parentParser))
    }
    
    func test_MethodDeclaration_patternCompiles() {
        XCTAssertNotNil(MethodDeclarationHeaderParser(parent: parentParser))
    }
    
    func test_StructureDefinition_patternCompiles() {
        XCTAssertNotNil(StructureDefinitionHeaderParser(parent: parentParser))
    }
    
    func test_EnumerationDefinition_patternCompiles() {
        XCTAssertNotNil(EnumerationDefinitionHeaderParser(parent: parentParser))
    }
    
    func test_ClosureSignatureDefinition_patternCompiles() {
        XCTAssertNotNil(ClosureSignatureDefinitionHeaderParser(parent: parentParser))
    }
    
    func test_ArbitraryDefinition_patternCompiles() {
        XCTAssertNotNil(ArbitraryTypeDefinitionHeaderParser(parent: parentParser))
    }

    func test_ImportDirective_patternCompiles() {
        XCTAssertNotNil(ImportDirectiveHeaderParser(parent: parentParser))
    }

    func test_PragmaDirective_patternCompiles() {
        XCTAssertNotNil(PragmaDirectiveHeaderParser(parent: parentParser))
    }

}

// EOF
