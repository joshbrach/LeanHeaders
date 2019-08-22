//
//  ExampleDefinitions_Parse.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 04/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest

class ExampleDefinitions_Parse: XCTestCase {
    
    private let expectedNumberOfParsedResults = (declarations: 3+8+4+2, availabilities: 0, references: 20+3)
    
    private let parsedResults : (declarations: [TypeDeclaration], availabilities: [TypeAvailablity], references: [TypeReference])! = {
        let bundle = Bundle(for: ExampleDefinitions_Parse.self)
        
        guard let exampleFile = bundle.url(forResource: "ExampleDefinitions", withExtension: "h")  else {
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
        XCTAssertNotNil(parsedResults, "ExampleDefinitions test suite failed test integrity check!")
    }
    
    func test_NoRedundantParseResult() {
        // This test is only relevant when all other tests pass, otherwise a missed result may hide a redundant result.
        XCTAssertEqual(parsedResults.declarations.count,   expectedNumberOfParsedResults.declarations)
        XCTAssertEqual(parsedResults.availabilities.count, expectedNumberOfParsedResults.availabilities)
        XCTAssertEqual(parsedResults.references.count,     expectedNumberOfParsedResults.references)
    }
    
    
    // MARK: Expected Structure Definitions
    
    func test_expect_PlainStructure() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "PlainStruct" && $0.metatype == .structure
        })
    }
    
    func test_expect_TypedefStructure() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "TypedefStruct" && $0.metatype == .structure
        })
    }
    
    func test_expect_RedundantStructure() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "RedundantStruct" && $0.metatype == .structure
        })
    }
    
    
    // MARK: Expected Enumeration Definitions
    
    func test_expect_PlainEnumeration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "PlainEnum" && $0.metatype == .enumeration
        })
    }
    
    func test_expect_TypedefEnumeration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "TypedefEnum" && $0.metatype == .enumeration
        })
    }
    
    func test_expect_RedundantEnumeration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "RedundantEnum" && $0.metatype == .enumeration
        })
    }
    
    func test_expect_ExplicitRawTypeTypedefEnumeration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExplicitTypeEnum" && $0.metatype == .enumeration
        })
    }
    
    func test_expect_ExplicitRawTypeRedundantEnumeration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExplicitRedundantEnum" && $0.metatype == .enumeration
        })
    }
    
    func test_expect_EnumerationMacro() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "EnumMacro" && $0.metatype == .enumeration
        })
    }
    
    func test_expect_OptionsMacro() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "OptionsMacro" && $0.metatype == .enumeration
        })
    }
    
    func test_expect_ErrorMacro() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ErrorMacro" && $0.metatype == .enumeration
        })
    }
    
    
    // MARK: Expected Closure Signature Definitions
    
    func test_expect_SimpleSignature() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "SimpleSignature" && $0.metatype == .closure
        })
    }
    func test_expect_SimpleSignature_references() {
        guard let loc = parsedResults.declarations.filter({
            $0.identifier == "SimpleSignature" && $0.metatype == .closure
        }).first?.location else {
            XCTAssertTrue(false, "Fix expect_SimpleSignature")
            return
        }
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "void" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
    }
    
    func test_expect_Signature() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "Signature" && $0.metatype == .closure
        })
    }
    func test_expect_Signature_references() {
        guard let loc = parsedResults.declarations.filter({
            $0.identifier == "Signature" && $0.metatype == .closure
        }).first?.location else {
            XCTAssertTrue(false, "Fix expect_Signature")
            return
        }
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ReturnType" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "int" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "RedundantStruct" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
    }
    
    func test_expect_ComplicatedSignature() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ComplicatedSignature" && $0.metatype == .closure
        })
    }
    func test_expect_ComplicatedSignature_references() {
        guard let loc = parsedResults.declarations.filter({
            $0.identifier == "ComplicatedSignature" && $0.metatype == .closure
        }).first?.location else {
            XCTAssertTrue(false, "Fix expect_ComplicatedSignature")
            return
        }
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ReturnType" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ConformsTo" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ConformsThre" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "FirstType" && comp.metatype == .closure && comp.location ≈ loc
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "AnotherType" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ThatsComplicated" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "id" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "JustAProtocol" && comp.metatype == .closure
            } else {
                return false
            }
        })
    }
    
    func test_expect_GenericSignature() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "NestedGenericParametersSignature" && $0.metatype == .closure
        })
    }
    func test_expect_GenericSignature_references() {
        guard let loc = parsedResults.declarations.filter({
            $0.identifier == "NestedGenericParametersSignature" && $0.metatype == .closure
        }).first?.location else {
            XCTAssertTrue(false, "Fix expect_GenericSignature")
            return
        }
        let refs = parsedResults.references.filter {
            let this = $0.sourceCodeRepresentation.location
            return this.file == loc.file && abs(Int(loc.line) - Int(this.line)) < 3
        }
        XCTAssert(refs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "void" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(refs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "NSArray" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(refs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "GenericSigParamSpecifierA" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(refs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "NSDictionary" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(refs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "NestedGenericSigParam" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(refs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "GenericSigParamSpecifierB" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(refs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ValueType" && comp.metatype == .closure
            } else {
                return false
            }
        })
    }
    
    
    // MARK: Expected Arbitrary Definitions
    
    func test_expect_ArbitraryType() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "NewType" && $0.metatype == .arbitrary(sameAs:"ExistingType")
        })
    }
    func test_expect_ArbitraryType_references() {
        guard let loc = parsedResults.declarations.filter({
            $0.identifier == "NewType" && $0.metatype == .arbitrary(sameAs:"ExistingType")
        }).first?.location else {
            XCTAssertTrue(false, "Fix expect_ArbitraryType")
            return
        }
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ExistingType" && comp.metatype == .arbitrary && comp.location ≈ loc
            } else {
                return false
            }
        })
    }
    
    func test_expect_QualifiedType() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "NewQualifiedType" && $0.metatype == .`class`
        })
    }
    func test_expect_QualifiedType_references() {
        guard let loc = parsedResults.declarations.filter({
            $0.identifier == "NewQualifiedType" && $0.metatype == .`class`
        }).first?.location else {
            XCTAssertTrue(false, "Fix expect_QualifiedType")
            return
        }
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ExistingType" && comp.metatype == .arbitrary && comp.location ≈ loc
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ThatsQualified" && comp.metatype == .arbitrary && comp.location ≈ loc
            } else {
                return false
            }
        })
    }
    
}

// EOF
