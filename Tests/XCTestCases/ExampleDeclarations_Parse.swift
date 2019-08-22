//
//  ExampleDeclarations_Parse.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 04/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import XCTest


class ExampleDeclarations_Parse: XCTestCase {
    
    private let expectedNumberOfParsedResults = (declarations: 9+5, availabilities: 6, references: 15+8+5+27)
    
    private let parsedResults : (declarations: [TypeDeclaration], availabilities: [TypeAvailablity], references: [TypeReference])! = {
        let bundle = Bundle(for: ExampleDeclarations_Parse.self)
        
        guard let exampleFile = bundle.url(forResource: "ExampleDeclarations", withExtension: "h")  else {
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
        XCTAssertNotNil(parsedResults, "ExampleDeclarations test suite failed test integrity check!")
    }
    
    func test_NoRedundantParseResult() {
        // This test is only relevant when all other tests pass, otherwise a missed result may hide a redundant result.
        XCTAssertEqual(parsedResults.declarations.count,   expectedNumberOfParsedResults.declarations)
        XCTAssertEqual(parsedResults.availabilities.count, expectedNumberOfParsedResults.availabilities)
        XCTAssertEqual(parsedResults.references.count,     expectedNumberOfParsedResults.references)
    }
    
    
    // MARK: Expected Class Declarations
    
    func test_expect_RootClass() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleRootClass" && $0.metatype == .`class`
        })
    }
    
    func test_expect_DerivedClass() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleDerivedClass" && $0.metatype == .`class`
        })
    }
    
    func test_expect_RootConformingClasses() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleRootClassWithProtocol" && $0.metatype == .`class`
        })
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleRootClassWithProtocols" && $0.metatype == .`class`
        })
    }
    
    func test_expect_DerivedConformingClasses() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleDerivedClassWithProtocol" && $0.metatype == .`class`
        })
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleDerivedClassWithProtocols" && $0.metatype == .`class`
        })
    }
    
    func test_expect_SingleLineClassDeclaration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleOneLineClass" && $0.metatype == .`class`
        })
    }
    func test_expect_SingleLineClassDeclaration_references() {
        guard let loc = parsedResults.declarations.filter({
            $0.identifier == "ExampleOneLineClass" && $0.metatype == .`class`
        }).first?.location else {
            XCTAssertTrue(false, "Fix expect_SingleLineClassDeclaration")
            return
        }
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "BOOL" && comp.metatype == .property && comp.location ≈ loc
            } else {
                return false
            }
        })
    }
    
    func test_expect_MultiLineClassDeclaration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleMultiLineClass" && $0.metatype == .`class`
        })
    }
    
    func test_expect_MultiLineConformingDeclaration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleMultiLineClassWithProtocols" && $0.metatype == .`class`
        })
    }
    
    // TODO: Test Inherritance / Conformance References, match line to expected declaration
    
    
    // MARK: Expected Category & Extension Declarations
    
    func test_expect_Extension_references() {
        XCTAssert(parsedResults.references.contains {
            if case .implementing(let imp) = $0 {
                return imp.identifier == "ExtensionProtocol" && imp.metatype == .conformance
            } else {
                return false
            }
        })
    }
    func test_expect_Category_references() {
        XCTAssert(parsedResults.references.contains {
            if case .implementing(let imp) = $0 {
                return imp.identifier == "CategoryProtocol" && imp.metatype == .conformance
            } else {
                return false
            }
        })
    }
    
    func test_DerivedClass_isNotDuplicated() {
        XCTAssertEqual(parsedResults.declarations.filter({
            $0.identifier == "ExampleDerivedClass"
        }).count, 1)
    }
    func test_DerivedClassWithProtocol_isNotDuplicated() {
        XCTAssertEqual(parsedResults.declarations.filter({
            $0.identifier == "ExampleDerivedClassWithProtocol"
        }).count, 1)
    }
    func test_OneLineClass_isNotDuplicated() {
        XCTAssertEqual(parsedResults.declarations.filter({
            $0.identifier == "ExampleOneLineClass"
        }).count, 1)
    }
    
    // MARK: Expected Protocol Declarations
    
    func test_expect_RootProtocol() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleRootProtocol" && $0.metatype == .`protocol`
        })
    }
    
    func test_expect_DerivedProtocol() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleProtocol" && $0.metatype == .`protocol`
        })
    }
    
    func test_expect_IncorporatingProtocol() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleProtocolWithProtocols" && $0.metatype == .`protocol`
        })
    }
    
    func test_expect_SingleLineProtocolDeclaration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleOneLineProtocol" && $0.metatype == .`protocol`
        })
    }
    
    func test_expect_MultiLineProtocolDeclaration() {
        XCTAssert(parsedResults.declarations.contains {
            $0.identifier == "ExampleMultiLineProtocol" && $0.metatype == .`protocol`
        })
    }
    
    // TODO: Test Incorporation References, match line to expected declaration

    
    // MARK: Expected Member Declarations
    
    func test_expect_IBOutletProperty() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "UILabelSubclass" && comp.metatype == .property
            } else {
                return false
            }
        })
    }
    
    func test_expect_IBInspectableProperty() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "BooleanScalar" && comp.metatype == .property
            } else {
                return false
            }
        })
    }
    
    func test_expect_SimpleProperty() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "AnotherProperyClass" && comp.metatype == .property
            } else {
                return false
            }
        })
    }
    
    func test_expect_GenericProperty() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "GenericProperty" && comp.metatype == .property
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "SpecifiedProperty" && comp.metatype == .property
            } else {
                return false
            }
        })
    }
    
    func test_expect_BlockProperty() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "BlockPropertyReturn" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "BlockPropertyParamA" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "BlockPropertyParamB" && comp.metatype == .closure
            } else {
                return false
            }
        })
    }
    
    func test_expect_SimpleClassMethod() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "SimpleClassMethodReturn" && comp.metatype == .method
            } else {
                return false
            }
        })
    }
    
    func test_expect_ComplexMethod() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ComplexMethodReturn" && comp.metatype == .method
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ComplexMethodParameterA" && comp.metatype == .method
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ComplexMethodParameterB" && comp.metatype == .method
            } else {
                return false
            }
        })
    }
    
    func test_expect_SimpleInstanceMethod() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "SimpleInstanceMethodReturn" && comp.metatype == .method
            } else {
                return false
            }
        })
    }
    
    func test_expect_InstanceMethod() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "InstanceMethodReturn" && comp.metatype == .method
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "SimpleMethodParameter" && comp.metatype == .method
            } else {
                return false
            }
        })
    }
    
    func test_expect_GenericMethod() {
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "GenericMethodReturn" && comp.metatype == .method
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "GenericMethodReturnSpecifier" && comp.metatype == .method
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "GenericMethodParameter" && comp.metatype == .method
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "GenericMethodParameterSpecifier" && comp.metatype == .method
            } else {
                return false
            }
        })
    }

    func test_expect_BlockMethod() {
        guard let loc = parsedResults.references.filter({
            if case .composition(let comp) = $0 {
                return comp.identifier == "BlockMethodReturn" && comp.metatype == .method
            } else {
                return false
            }
        }).first?.sourceCodeRepresentation.location else {
            XCTAssertTrue(false)
            return
        }
        let relatedRefs = parsedResults.references.filter {
            $0.sourceCodeRepresentation.location ≈ loc
        }
        XCTAssert(relatedRefs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "void" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(relatedRefs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "BlockMethodParam" && comp.metatype == .closure
            } else {
                return false
            }
        })
    }

    func test_expect_ManipulateAndCallbackMethod() {
        guard let loc = parsedResults.references.filter({
            if case .composition(let comp) = $0 {
                return comp.identifier == "ManipulateAndCallbackObject" && comp.metatype == .method
            } else {
                return false
            }
        }).first?.sourceCodeRepresentation.location else {
            XCTAssertTrue(false)
            return
        }
        let relatedRefs = parsedResults.references.filter {
            $0.sourceCodeRepresentation.location ≈ loc
        }
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ManipulatableObject" && comp.metatype == .method
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.references.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "ManipulatableObject" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(relatedRefs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "void" && comp.metatype == .closure
            } else {
                return false
            }
        })
        XCTAssert(relatedRefs.contains {
            if case .composition(let comp) = $0 {
                return comp.identifier == "CloseReason" && comp.metatype == .closure
            } else {
                return false
            }
        })
    }
    
    
    // MARK: Expected Forward Declarations
    
    func test_expect_ForwardClass() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "PromisedClass" && forward.metatype == .`class`
            } else {
                return false
            }
        })
    }
    func test_expect_ForwardProtocol() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "PromisedProtocol" && forward.metatype == .`protocol`
            } else {
                return false
            }
        })
    }
    
    func test_ForwardClass_isNotDuplicated() {
        XCTAssertFalse(parsedResults.declarations.contains {
            $0.identifier == "PromisedClass"
        })
    }
    func test_ForwardProtocol_isNotDuplicated() {
        XCTAssertFalse(parsedResults.declarations.contains {
            $0.identifier == "PromisedProtocol"
        })
    }
    
    func test_expect_MultiForwardClass() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "MultiPromisedClassA" && forward.metatype == .`class`
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "MultiPromisedClassB" && forward.metatype == .`class`
            } else {
                return false
            }
        })
    }
    func test_expect_MultiForwardProtocol() {
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "MultiPromisedProtocolA" && forward.metatype == .`protocol`
            } else {
                return false
            }
        })
        XCTAssert(parsedResults.availabilities.contains {
            if case .forward(let forward) = $0 {
                return forward.identifier == "MultiPromisedProtocolB" && forward.metatype == .`protocol`
            } else {
                return false
            }
        })
    }
    
    func test_MultiForwardClass_isNotDuplicated() {
        XCTAssertFalse(parsedResults.declarations.contains {
            $0.identifier == "MultiPromisedClassA" || $0.identifier == "MultiPromisedClassB"
        })
    }
    func test_MultiForwardProtocol_isNotDuplicated() {
        XCTAssertFalse(parsedResults.declarations.contains {
            $0.identifier == "MultiPromisedProtocolA" || $0.identifier == "MultiPromisedProtocolB"
        })
    }
    
}

// EOF
