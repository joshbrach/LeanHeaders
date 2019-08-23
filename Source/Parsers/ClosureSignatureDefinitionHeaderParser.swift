//
//  ClosureSignatureDefinitionHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 10/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Closure Signature Definitions from headers.
class ClosureSignatureDefinitionHeaderParser : HeaderParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    private let blockDescriptorParser : BlockDescriptorParser
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: ClosureSignatureDefinitionHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile closure signature definition parser.")
            return nil
        }
        if let parser = BlockDescriptorParser(parent: parent) {
            blockDescriptorParser = parser
        } else {
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C block signature definitiontion.
        typedef \\s++                               # Objective-C keyword for type definition.
        (?<signature>                               # Named capture group for the whole signature.
            \(BlockDescriptorParser.pattern())      # Whole signature.
        ) \\s*+                                     # End capture group: <signature>
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
            
            let signatureRange : NSRange
            if #available(macOS 10.13, *) {
                signatureRange = result.range(withName: "signature")
            } else {
                signatureRange = result.range(at: 1)
            }
            
            guard signatureRange.location != NSNotFound else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Missing non-optional component from closure signature definition match.")
                return
            }
            guard let blockDescriptor = blockDescriptorParser.parseIdentifiers(inRange: signatureRange, ofSourceFile: file) else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Cannot parse block descriptor from closure signature definition match.")
                return
            }
            guard let typeName = blockDescriptor.identifier else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Missing non-optional component from closure signature definition match.")
                return
            }
            declarations.append(
                TypeDeclaration(location: typeName.location,
                                rawLine: definitionSource,
                                metatype: .closure,
                                identifier: typeName.identifier)
            )
            blockDescriptor.flatEnumerateAllDescriptors {
                references.append( .composition(
                    CompositionReference(location: $0.location,
                                         rawLine: definitionSource,
                                         metatype: .closure,
                                         identifier: $0.identifier)
                ) )
            }
            
        } // end enumerate matches
        
        return (declarations, [], references)
    }
    
}

// EOF

