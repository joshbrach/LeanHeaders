//
//  CodeBaseParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 03/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/* A Note on the use of NSString in this project.
 Either String.Index & Range need to be fully supported, or we are forced to use NSString
 String.Index is not Hashable, so can't be used as a dictionary key, and isn't easily
 coerced to and from Int, let alone UInt.  The Matching API does not support Range of any sort,
 let alone Range<String.Index>, so we /have/ to start from NSRange '<Int>', which is a pain
 to keep sending back and forth thru range.  This all means Swift String substring splitting has become
 cumbersome and frusturating, because it /only/ supports subscripting / substringing via Range.
 */


/// A class to encapsulate & coordinate parsing.
class CodeBaseParser {
    
    /// A shared reporter, to synchronize output.
    internal let xcbLog : XCBIssueReporter
    
    /// Collection of all child parsers to be run on each header.
    private var headerParsers : [HeaderParser] = []
    
    init(issueReporter: XCBIssueReporter = XCBIssueReporter()) {
        xcbLog = issueReporter
        headerParsers = [
            // Declarations
            ClassDeclarationHeaderParser(parent: self)!,
            ProtocolDeclarationHeaderParser(parent: self)!,
            StructureDefinitionHeaderParser(parent: self)!,
            EnumerationDefinitionHeaderParser(parent: self)!,
            ClosureSignatureDefinitionHeaderParser(parent: self)!,
            ArbitraryTypeDefinitionHeaderParser(parent: self)!,
            // Pure References
            CategoryDeclarationHeaderParser(parent: self)!,
            PropertyDeclarationHeaderParser(parent: self)!,
            MethodDeclarationHeaderParser(parent: self)!,
            // Pure Availabilities
            ForwardDeclarationHeaderParser(parent: self)!,
            ImportDirectiveHeaderParser(parent: self)!,
            // Manual Overrides
            PragmaDirectiveHeaderParser(parent: self)!
        ]
        
        // TODO: Consider adding:
        // GlobalVariableDeclarationHeaderParser : HeaderParser
        // GlobalClosureDefinitionHeaderParser : HeaderParser
        // GlobalFunctionDefinitionHeaderParser : HeaderParser
        // × class decls by generics
    }
    
    init(mockForTesting: Void) {
        xcbLog = XCBIssueReporter()
    }
    
    
    // MARK: - Public Interface

    /// Parses the Types in the header files of the given codebase.
    func parseCodeBaseTypes(codebase: CodeBase) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {

        // Coordination Artifacts

        let reduceQueue = DispatchQueue(label: "ca.brach.LeanHeaders.parse_codebase.append-sequentially",
                                        qos: .background,
                                        attributes: [],  // absence of .concurrent implies sequential
                                        autoreleaseFrequency: .never,
                                        target: nil)
        let mapQueue = DispatchQueue(label: "ca.brach.LeanHeaders.parse_codebase.parse_headers-concurrently",
                                     qos: .background,
                                     attributes: [.concurrent],
                                     autoreleaseFrequency: .workItem,
                                     target: nil)
        let allWork = DispatchGroup()

        // Reduction

        var declarations   : [TypeDeclaration] = []
        var availabilities : [TypeAvailablity] = []
        var references     : [TypeReference]   = []

        func append(_ d: [TypeDeclaration], _ a: [TypeAvailablity], _ r: [TypeReference]) {
            declarations.append(contentsOf: d)
            availabilities.append(contentsOf: a)
            references.append(contentsOf: r)
        }

        // Mapping

        for header in codebase.headerFiles {

            mapQueue.async(group: allWork) {
                guard let source = SourceFile(header) else { return }
                for parser in self.headerParsers {
                    let (d, a, r) = parser.parseTypes(inFile: source)
                    reduceQueue.async(group: allWork) { append(d, a, r) }
                }
            }

        }

        // Hold for completion

        allWork.wait()
        
        return (declarations, availabilities, references)
        
    }
    
}


// EOF
