//
//  ProtocolDeclarationHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Protocol Declarations from headers.
class ProtocolDeclarationHeaderParser : HeaderParser {
    
    private static let idPattern = CommonPatterns.identifierPattern
    private static let idsListPattern = CommonPatterns.list(of: CommonPatterns.identifierPattern)
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: ProtocolDeclarationHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile protocol declaration parser.")
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C protocol declaration.
        # It specifically does /not/ match an Objective-C /forward/ protocol declaration.
        # It allows for root protocols, in that case the incorporates capture group will be NotFound.
        @protocol \\s++                             # Objective-C keyword for protocol declarations.
        (?<protocol>\(idPattern)) \\s*+             # Named capture of the name of the declared protocol.
        (?: < \\s*+                                 # Non-capturing optional group: (null | incorporates).
            (?<incorporates>\(idsListPattern))\\s*+ # Named capture of the incorporated protocols list.
            > \\s*+                                 # Closing incorporates-list delimiter.
        )?                                          # End optional group: (null | incorporates)
        (?! [                                       # The next non-whitespace character must not be:
            <                                       #   one used to start an optional portion of this pattern, nor
            , ;                                     #   one used to indicate a forward declaration.
        ])
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
            
            let declarationRange = result.range
            let declarationSource = file.sourceText.substring(with: declarationRange)
            
            let protocolRange : NSRange
            let incorporatesRange : NSRange
            if #available(macOS 10.13, *) {
                protocolRange = result.range(withName: "protocol")
                incorporatesRange = result.range(withName: "incorporates")
            } else {
                protocolRange = result.range(at: 1)
                incorporatesRange = result.range(at: 2)
            }
            
            if protocolRange.location == NSNotFound {
                let declarationLocation = file.location(ofRange: declarationRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                          withMessage: "Missing non-optional component from protocol declaration match.")
            } else {
                let location = file.location(ofRange: protocolRange)
                declarations.append(
                    TypeDeclaration(location: location,
                                    rawLine: declarationSource,
                                    metatype: .`protocol`,
                                    identifier: file.sourceText.substring(with: protocolRange))
                )
            }
            
            let incorporates : [String]
            if incorporatesRange.location == NSNotFound {
                incorporates = []
            } else {
                incorporates = file.sourceText
                    .substring(with: incorporatesRange)
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            if incorporates.isEmpty || incorporates.first!.isEmpty {
                let location = file.location(ofRange: declarationRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                          ofSeverity: GlobalOptions.options.rootProtoIssue,
                                          withMessage: "Unintentional root protocol declaration; insert ' <NSObject> ' to silence this issue.",
                                          filterableCode: "root-protocol")
            } else {
                let location = file.location(ofRange: incorporatesRange)
                for incorporatedProtocol in incorporates {
                    references.append( .implementing(
                        ImplementingReference(location: location,
                                              rawLine: declarationSource,
                                              metatype: .conformance,
                                              identifier: incorporatedProtocol)
                        ) )
                }
            }
            
        } // end enumerate matches
        
        return (declarations, [], references)
    }
    
}

// EOF
