//
//  ArbitraryTypeDefinitionHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Arbitrary TypeDefinitions from headers.
class ArbitraryTypeDefinitionHeaderParser : HeaderParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    private let typeDescriptorParser : TypeDescriptorParser
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: ArbitraryTypeDefinitionHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile arbitrary type definition parser.")
            return nil
        }
        if let parser = TypeDescriptorParser(parent: parent) {
            typeDescriptorParser = parser
        } else {
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an arbitrary Objective-C typedef definition.
        # It should be checked for matches only after all specialized typedef patterns have been checked for matches.
        typedef \\s++                               # Objective-C keyword for type definition.
        (?<sameas>                                  # Named capture group for the pre-existing type.
            \(TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil))
        ) \\s++                                     # End capture group: <sameas>
        (?<type>                                    # Named capture of the name of the defined type.
            \(CommonPatterns.identifierPattern)
        ) \\s*+                                     # End capture group: <type>
        ;                                           # Finalizing semicolon.
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)
        
        var declarations   : [TypeDeclaration] = []
        var references     : [TypeReference]   = []
        
        engine.enumerateMatches(in: file.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            let definitionRange = result.range
            let definitionSource = file.sourceText.substring(with: definitionRange)
            let definitionLocation = file.location(ofRange: definitionRange)
            
            let sameasRange : NSRange
            let typeRange : NSRange
            if #available(macOS 10.13, *) {
                sameasRange = result.range(withName: "sameas")
                typeRange = result.range(withName: "type")
            } else {
                sameasRange = result.range(at: 1)
                typeRange = result.range(at: 2)
            }
            
            if sameasRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          withMessage: "Missing non-optional component from arbitrary definition match.")
            } else if typeRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          withMessage: "Missing non-optional component from arbitrary definition match.")
            } else if let sameasDescriptor = typeDescriptorParser.parseIdentifiers(inRange: sameasRange, ofSourceFile: file) {
                let metatype : TypeDeclaration.MetaType
                if sameasDescriptor.specifiers != nil || sameasDescriptor.conformances != nil {
                    metatype = .`class`
                } else {
                    metatype = .arbitrary(sameAs: sameasDescriptor.identifier.identifier)
                }
                
                let location = file.location(ofRange: typeRange)
                declarations.append(
                    TypeDeclaration(location: location,
                                    rawLine: definitionSource,
                                    metatype: metatype,
                                    identifier: file.sourceText.substring(with: typeRange))
                )
                
                sameasDescriptor.flatEnumerateAllIdentifiers {
                    references.append( .composition(
                        CompositionReference(location: $0.location,
                                             rawLine: definitionSource,
                                             metatype: .arbitrary,
                                             identifier: $0.identifier)
                    ) )
                }
                
            }
            
        } // end enumerate matches
        
        return (declarations, [], references)
    }
    
}

// EOF
