//
//  PragmaDirectives_Parse.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 20/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest

class PragmaDirectives_Parse: XCTestCase {

    private let expectedNumberOfParsedResults = (declarations: 2, availabilities: 4, references: 4)

    private let parsedResults : (declarations: [TypeDeclaration], availabilities: [TypeAvailablity], references: [TypeReference])! = {
        let bundle = Bundle(for: ExampleDefinitions_Parse.self)

        guard let exampleFile = bundle.url(forResource: "ExampleDirectives", withExtension: "h")  else {
            return nil
        }

        guard let codebase = Mock_CodeBase(mockHeaderFiles: [exampleFile]) else {
            return nil
        }

        let parser = CodeBaseParser()

        return parser.parseCodeBaseTypes(codebase: codebase)
    }()


    // MARK: Meta

    func test_ExampleDeclarationsIntegrity() {
        XCTAssertNotNil(parsedResults, "ExampleDirectives test suite failed test integrity check!")
    }

    func test_NoRedundantParseResult() {
        // This test is only relevant when all other tests pass, otherwise a missed result may hide a redundant result.
        XCTAssertEqual(parsedResults.declarations.count,   expectedNumberOfParsedResults.declarations)
        XCTAssertEqual(parsedResults.availabilities.count, expectedNumberOfParsedResults.availabilities)
        XCTAssertEqual(parsedResults.references.count,     expectedNumberOfParsedResults.references)
    }


    // MARK: Expected Pragma 'Need' Directives

    func test_expect_NeedImportClass() {
        XCTAssert(parsedResults.references.contains {
            if case .implementing(let imp) = $0 {
                return imp.identifier == "RequiredBaseClass" && imp.metatype == .inheritance
            } else {
                return false
            }
        })
    }

    func test_expect_NeedImportProtocol() {
        XCTAssert(parsedResults.references.contains {
            if case .implementing(let imp) = $0 {
                return imp.identifier == "RequiredBaseProtocol" && imp.metatype == .conformance
            } else {
                return false
            }
        })
    }

    func test_expect_NeedForwardClass() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let imp) = $0 {
                return imp.identifier == "RequiredCompositionClass" && imp.metatype == .arbitrary
            } else {
                return false
            }
        })
    }

    func test_expect_NeedForwardProtocol() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let imp) = $0 {
                return imp.identifier == "RequiredCompositionProtocol" && imp.metatype == .arbitrary
            } else {
                return false
            }
        })
    }


    // MARK: Expected Pragma 'Have' Directives

    func test_expect_HaveImportClass() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "SuppliedBaseClass" && $0.metatype == .`class`
        })
    }

    func test_expect_HaveImportProtocol() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "SuppliedBaseProtocol" && $0.metatype == .`protocol`
        })
    }

    func test_expect_HaveImportFile() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .`import`(let imp) = $0 {
                return imp.importsFile == "FileWithSuppliedDefinitions.h"
            } else {
                return false
            }
        })
    }

    func test_expect_HaveImportCategory() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .`import`(let imp) = $0 {
                return imp.importsFile == "FileWithSupplied+Category.h"
            } else {
                return false
            }
        })
    }

    func test_expect_HaveForwardClass() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "SuppliedCompositionClass" && forward.metatype == .`class`
            } else {
                return false
            }
        })
    }

    func test_expect_HaveForwardProtocol() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "SuppliedCompositionProtocol" && forward.metatype == .`protocol`
            } else {
                return false
            }
        })
    }

}

// EOF
