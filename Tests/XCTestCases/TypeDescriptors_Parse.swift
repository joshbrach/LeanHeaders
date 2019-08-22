//
//  TypeDescriptors_Parse.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 04/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest


class TypeDescriptors_Parse: XCTestCase {
    
    private let expectedNumberOfParsedResults = 7+7+2+8
    
    private let parsedResults : [TypeDescriptor]! = {
        let bundle = Bundle(for: TypeDescriptors_Parse.self)
        
        guard let exampleURL = bundle.url(forResource: "ExampleDescriptors", withExtension: "h") else {
            return nil
        }
        guard let exampleFile = SourceFile(exampleURL) else {
            return nil
        }

        let wholeRange = NSRange(location: 0, length: exampleFile.sourceLength)
        
        guard let parser = TypeDescriptorParser(parent: Mock_CodeBaseParser()) else {
            return nil
        }
        
        let pattern = "@test \\s (?<type>\(TypeDescriptorParser.pattern())) \\s*+ \(CommonPatterns.identifierPattern);"
        
        guard let engine = try? NSRegularExpression(pattern:pattern, options: .allowCommentsAndWhitespace) else {
            return nil
        }
        
        var descriptors : [TypeDescriptor] = []
        
        engine.enumerateMatches(in: exampleFile.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            var typeRange : NSRange
            if #available(macOS 10.13, *) {
                typeRange = result.range(withName: "type")
            } else {
                typeRange = result.range(at: 1)
            }
            
            guard typeRange.location != NSNotFound else {
                return
            }
            if let descriptor = parser.parseIdentifiers(inRange: typeRange, ofSourceFile: exampleFile) {
                descriptors.append(descriptor)
            }
            
        } // end enumerate matches
        
        return descriptors
    }()
    
    
    // MARK: Meta
    
    func test_ExampleDeclarationsIntegrity() {
        XCTAssertNotNil(parsedResults, "ExampleDescriptors test suite failed test integrity check!")
        XCTAssertNotNil(parsedResults.first)
    }
    
    func test_NoRedundantParseResult() {
        // This test is only relevant when all other tests pass, otherwise a missed result may hide a redundant result.
        XCTAssertEqual(parsedResults.count, expectedNumberOfParsedResults)
    }
    
    
    // MARK: Expected Constant Descriptors
    
    func test_expect_ConstType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "ConstType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_PrefixConstType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "PreConstType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_InfixConstType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "InfixConstType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_ConstTypeNoSpace() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "ConstTypeNoSpace" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_IndirectedConstType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "IndirectedConstType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_ConstIndirectionType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "ConstIndirectionType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_DoubleConstType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "DoubleConstType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    
    // MARK: Expected Nullability Descriptors
    
    func test_expect_NullableType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NullableType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_NullableTypeNoSpace() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NullableTypeNoSpace" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_NullableProtocol() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "id" && $0.conformances?.first?.identifier == "NullableProtocol" && $0.specifiers == nil
        })
    }
    
    func test_expect_NonNullType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NonNullType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_NullUnspecifiedType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NullUnspecifiedType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_NullableIndirectedType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NullableIndirectedType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    func test_expect_NonNullConstType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NonNullConstType" && $0.conformances == nil && $0.specifiers == nil
        })
    }
    
    
    // MARK: Expected Conformance Descriptors
    
    func test_expect_SingleConformingType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "ConformingType" && $0.conformances?.count == 1 && $0.specifiers == nil
        })
    }
    
    func test_expect_MultiConformingType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "MultiConformingType" && $0.conformances?.count == 2 && $0.specifiers == nil
        })
    }
    
    // MARK: Expected Generic Specification Descriptors
    
    func test_expect_GenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "GenericType" && $0.conformances == nil && $0.specifiers?.count == 1
        })
    }
    
    func test_expect_NullableGenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NullableGenericType" && $0.conformances == nil && $0.specifiers?.count == 1
        })
    }
    
    func test_expect_ConstGenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "ConstGenericType" && $0.conformances == nil && $0.specifiers?.count == 1
        })
    }
    
    func test_expect_MultiGenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "MultiGenericType" && $0.conformances == nil && $0.specifiers?.count == 2
        })
    }
    
    func test_expect_NestedGenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NestedGenericType" && $0.conformances == nil && $0.specifiers?.count == 1 && $0.specifiers?.first?.specifiers?.count == 1
        })
    }
    
    func test_expect_MultiNestedGenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "MultiNestedGenericType" && $0.conformances == nil && $0.specifiers?.count == 2 &&
                $0.specifiers?.first?.specifiers?.count == 1 && $0.specifiers?.last?.specifiers?.count == 1
        })
    }
    
    func test_expect_NestedConformanceGenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "NestedConformanceGenericType" && $0.conformances == nil && $0.specifiers?.count == 1 && $0.specifiers?.first?.conformances?.count == 1
        })
    }
    
    func test_expect_MultiConformingGenericType() {
        XCTAssert(parsedResults.contains {
            $0.identifier.identifier == "MultiConformingGenericType" && $0.conformances == nil && $0.specifiers?.count == 2
        })
    }
    
}

// EOF
