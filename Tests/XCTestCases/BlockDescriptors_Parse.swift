//
//  BlockDescriptors_Parse.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 14/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest


class BlockDescriptors_Parse: XCTestCase {

    private let expectedNumberOfParsedResults = 4
    
    private let parsedResults : [BlockDescriptor]! = {
        let bundle = Bundle(for: BlockDescriptors_Parse.self)
        
        guard let exampleURL = bundle.url(forResource: "ExampleDescriptors", withExtension: "h") else {
            return nil
        }
        guard let exampleFile = SourceFile(exampleURL) else {
            return nil
        }

        let wholeRange = NSRange(location: 0, length: exampleFile.sourceLength)
        
        guard let parser = BlockDescriptorParser(parent: Mock_CodeBaseParser()) else {
            return nil
        }
        
        let pattern = "@test \\s (?<signature>\(BlockDescriptorParser.pattern()));"
        
        guard let engine = try? NSRegularExpression(pattern:pattern, options: .allowCommentsAndWhitespace) else {
            return nil
        }
        
        var descriptors : [BlockDescriptor] = []
        
        engine.enumerateMatches(in: exampleFile.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            var signatureRange : NSRange
            if #available(macOS 10.13, *) {
                signatureRange = result.range(withName: "signature")
            } else {
                signatureRange = result.range(at: 1)
            }
            
            guard signatureRange.location != NSNotFound else {
                return
            }
            if let descriptor = parser.parseIdentifiers(inRange: signatureRange, ofSourceFile: exampleFile) {
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
    
    
    // MARK: Expected Block Descriptors

    func test_expect_SimplestBlock() {
        XCTAssert(parsedResults.contains {
            $0.identifier?.identifier == "blockName" &&
                $0.returnType.identifier.identifier == "BlockReturn" &&
                $0.parameters?.count == 1
        })
    }

    func test_expect_PureBlock() {
        XCTAssert(parsedResults.contains {
            $0.identifier?.identifier == "pureBlock" &&
                $0.returnType.identifier.identifier == "void" &&
                $0.parameters?.count == 1
        })
    }

    func test_expect_NoParamIdsBlock() {
        XCTAssert(parsedResults.contains {
            $0.identifier?.identifier == "noParamIdsBlock" &&
                $0.returnType.identifier.identifier == "NoParamIDsBlockReturn" &&
                $0.parameters?.count == 2 &&
                $0.parameters!.contains { $0.identifier.identifier == "BlockParamWithoutIDA" } &&
                $0.parameters!.contains { $0.identifier.identifier == "BlockParamWithoutIDB" }
        })
    }

    func test_expect_NoNameBlock() {
        XCTAssert(parsedResults.contains {
            $0.identifier == nil &&
                $0.returnType.identifier.identifier == "NoNameBlockReturn" &&
                $0.parameters?.count == 1 &&
                $0.parameters!.contains { $0.identifier.identifier == "NoNameBlockParam" }
        })
    }

}
