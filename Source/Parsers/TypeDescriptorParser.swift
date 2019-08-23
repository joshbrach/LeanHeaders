//
//  TypeDescriptorParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 09/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


typealias ArbitraryIdentifier = (identifier: String, location: SourceCodeLocation)


/// A structure to encapsulate the relevant identifiers
/// in constituent components of an Objective-C Type Descriptor.
/// - note: At most one of the two qualifier lists will be non-nil,
///         as they are mutually exclusive type qualifiers.
struct TypeDescriptor {
    /// The primary identifier of the Type.
    let identifier   :  ArbitraryIdentifier
    /// The identifiers of the protocols to which the Type conforms.
    let conformances : [ArbitraryIdentifier]?
    /// The descriptors of the specifications of a generic Type.
    let specifiers   : [TypeDescriptor]?
    
    func flatEnumerateAllIdentifiers(_ process: (ArbitraryIdentifier)->Void) {
        process(identifier)
        conformances?.forEach(process)
        flatEnumerateSpecifierIdentifiers(process)
    }
    func flatEnumerateSpecifierIdentifiers(_ process: (ArbitraryIdentifier)->Void) {
        specifiers?.forEach({ $0.flatEnumerateAllIdentifiers(process) })
    }
}


/// A class to parse Identifiers of Objective-C Type Descriptors.
class TypeDescriptorParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    /// Initializes the parser with the given parent parser.
    /// Can fail to compile parsing grammar at runtime
    init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: "^\(TypeDescriptorParser.pattern(capture: true))$",
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile type descriptor parser.")
            return nil
        }
    }
    
    /// Generates a pattern for an arbitrary Objective-C type, without embedded capture groups.
    /// - note: All parameters describe the mode of inclusion for a pattern component where:
    ///         nil indicates exclusion, true indicates optional, and flase indicates mandatory.
    /// - parameters:
    ///    - nullability: Inclusion for context-specific nullability specifiers
    ///                   which are sometimes acceptable before the type name.
    ///                   Default is to include as optional.
    ///    - conformance: Inclusion for conformances qualifier.
    ///                   Default is to include as optional.
    ///    - genericArgs: Inclusion for generic arguments qualifier.
    ///                   Default is to include as optional.
    /// - returns: An ICU Pattern which will match a Type as confingured, with no leading nor trailing spaces.
    /// - warning: If generic argument qualifiers are permitted, the result of this function must be followed
    ///            by an unambiguous pattern or lookahead to collapse the ambiguity of recursive qualifiers.
    class func pattern(nullabilityIncludedOptionally nullability: Bool? = true,
                       conformanceIncludedOptionally conformance: Bool? = true,
                       genericArgsIncludedOptionally genericArgs: Bool? = true) -> String {
        return pattern(capture: false,
                       nullability: nullability, conformance: conformance, genericArgs: genericArgs)
    }
    
    /// Generates a pattern for an arbitrary Objective-C type, configured according to the given arguments.
    /// - note: All parameters describe the mode of inclusion for a pattern component where:
    ///         nil indicates exclusion, true indicates optional, and flase indicates mandatory.
    /// - parameters:
    ///    - capture: Idicates whether embedded capture groups should be enabled.
    ///    - nullability: Inclusion for context-specific nullability specifiers
    ///                   which are sometimes acceptable before the type name.
    ///                   Never captured.
    ///                   Default is to include as optional.
    ///    - conformance: Inclusion for conformances qualifier.
    ///                   Match is named 'conformances' when captureing.
    ///                   Default is to include as optional.
    ///    - genericArgs: Inclusion for generic arguments qualifier.
    ///                   Match is named 'genericSpecifiers' when captureing.
    ///                   Default is to include as optional.
    /// - returns: An ICU Pattern which will match a Type as confingured, with no leading nor trailing spaces.
    /// - warning: If generic argument qualifiers are permitted, the result of this function must be followed
    ///            by an unambiguous pattern or lookahead to collapse the ambiguity of recursive qualifiers.
    private class func pattern(capture: Bool,
                               nullability: Bool? = true,
                               conformance: Bool? = true,
                               genericArgs: Bool? = true) -> String {
        
        // SoFar Supports:
        // const nullability Identifier<Conformance, nlty OrGeneric< nlty NestedType * _Nullability> * const _Nlty> * _Nlty const * _Nlty
        
        // TODO Support:
        //        let preOwnership = "(?: weak | strong | unsafe_unretained | autoreleasing )"   ?
        //        let postOwnership = "__\(preOwnership)"
        //
        //        let postAttributes = "__attribute\\(\\( ??? \\)\\)"   ?
        //        let postAttributeMacros = "NS_ (?: DEPRECATED | ??? )"   ?
        
        // 'Pointer' Qualifiers
        // (Not only pointers, but how often do you declare const int on the stack?)
        
        let constPattern = "const"
        let preNullPattern  = CommonPatterns.prefixNullabilitySpecifierPattern
        let postNullPattern = "_(?:_n|N) (?: ull(?:able|_unspecified) | onnull )"
        
        var prefixPointerMode = true
        var prefixPointerQualifierComponent : String
        switch nullability {
            case .some(true):
                prefixPointerQualifierComponent = """
                    (?:
                        \(constPattern) (?: \\s++ \(preNullPattern) )?
                    |
                        \(preNullPattern) (?: \\s++ \(constPattern) )?
                    )
                    """
            case .some(false):
                prefixPointerQualifierComponent = """
                    (?:
                        \(constPattern) \\s++ \(preNullPattern)
                    |
                        \(preNullPattern) (?: \\s++ \(constPattern) )?
                    )
                    """
                prefixPointerMode = false
            case .none:
                prefixPointerQualifierComponent = constPattern
        }
        prefixPointerQualifierComponent = wrap(component: "\(prefixPointerQualifierComponent) \\s++", withMode: prefixPointerMode)
        
        var postfixPointerQualifierComponent = """
            (?:
            \(constPattern) (?: \\s++ \(postNullPattern) )?
            |
            \(postNullPattern) (?: \\s++ \(constPattern) )?
            )
            """
        postfixPointerQualifierComponent = wrap(component: "\\s*+ \(postfixPointerQualifierComponent)", withMode: true)
        
        let indirectionComponent = "\(postfixPointerQualifierComponent) (?: \\s*+ \\* \(postfixPointerQualifierComponent) )*"
        
        // 'Class' Qualifiers
        // (Can also qualify protocols, but the point is that they're objective-oriented-y.)
        
        // Class qualifier inclusion is a sort of convolution of inclusions for the types of qualifiers…
        let classQualifiersList : Bool?
        if conformance == nil && genericArgs == nil {
            // neither is included, so the whole qualifier is excluded
            classQualifiersList = nil
        } else if conformance == nil || genericArgs == nil {
            // only one is included, so it determines overall optionality
            classQualifiersList = conformance ?? genericArgs!
        } else {
            // both will be included; they are each optional by nature of alternation,
            // and so long as either is mandetory the qualifier delimiters are mandetory;
            // only when both are optional is the whole qualifier optional
            classQualifiersList = conformance! && genericArgs!
        }
        
        // Conformance qualifier is a simple comma-delimited list of protocol identifiers.
        let conformanceListPattern = wrap(component: CommonPatterns.list(of: CommonPatterns.identifierPattern),
                                          withMode: conformance,
                                          captureName: capture ? "conformances" : nil,
                                          forceGroup: true)
        // Generic qualifier is a complex free-form repitition of any character that can be part of a type pattern.
        let genericArgsListPattern = wrap(component: "[ A-Z a-z 0-9 _ \\s < > : * , ]*",
                                          withMode: genericArgs,
                                          captureName: capture ? "genericSpecifiers" : nil)
        
        // Generic qualifiers are recursive patterns.  Recursion is far away from regular that
        // even the bastardization that is regex can't express it.  This pattern avoids some
        // ambiguity by describing the straight-forward conformance qualifier first, only
        // failing back to the free-form generic qualifier if that fails.  The identifier list
        // pattern has been definied using possesive repitition (*+) in an attempt to fail
        // quickly on encountering the first indication that the text is not a conformance
        // qualifier (e.g the first < or *).  Note that the repitition in the generic qualifier
        // portion cannot be possessive since the closing delimiter for the pattern is an
        // option within the repitition.  This, in a word, sucks.
        var classQualifiersListComponent = "< \\s*+ (?: \(conformanceListPattern) \\s*+ | \(genericArgsListPattern) ) >"
        classQualifiersListComponent = wrap(component: "\\s*+ \(classQualifiersListComponent)", withMode: classQualifiersList)
        
        // Pattern Composition
        
        let primaryComponent = wrap(component: CommonPatterns.identifierPattern, withMode: false,
                                    captureName: capture ? "primaryIdentifier" : nil)
        
        return "\(prefixPointerQualifierComponent)\(primaryComponent)\(classQualifiersListComponent)\(indirectionComponent)"
    }
    
    /// Utility method to wrap pattern components in groups, whether optional or mandatory, capturing or non-capturing.
    private class func wrap(component: String,
                             withMode mode: Bool?,
                             captureName capture: String? = nil,
                             forceGroup: Bool = false) -> String {
        // nil mode indicates mandatory exclusion from overall pattern…
        guard let optional = mode else {
            return ""
        }
        // short circuit if no group is needed…
        guard forceGroup || optional || capture != nil else {
            return component
        }
        let openGroup  = capture == nil ? "(?:" : capture!.isEmpty ? "(" : "(?<\(capture!)>"
        let closeGroup = optional ? ")?" : ")"
        return "\(openGroup)\(component)\(closeGroup)"
    }

    /// Parses Identifiers of Objective-C Type Descriptor components from text matching an arbitrary Objective-C type.
    /// - parameters:
    ///    - inRange: The range of a single match of a pattern generated by a TypeDescriptorParser.
    ///    - ofSourceFile: The file in which the match was found.
    /// - returns: The identifiers from constituent components of the type.
    /// - warning: Performs recursive RegEx matching, which may degrade overall performance.
    func parseIdentifiers(inRange wholeRange: NSRange, ofSourceFile file: SourceFile) -> TypeDescriptor! {
        let results = safeParseIdentifiers(inRange: wholeRange, ofSourceFile: file)
        if (results?.count ?? 0) > 1 {
            let location = file.location(ofRange: wholeRange)
            parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                      ofSeverity: GlobalOptions.options.metaIssues,
                                      withMessage: "Unexpectedly found multiple type descriptors in range '\(file.sourceText.substring(with: wholeRange))'.")
        }
        return results?.first
    }
    
    /// Parses Identifiers of Objective-C Type Descriptor components from text matching an arbitrary Objective-C type.
    /// Attempts to make some recovery on ambiguously matched generic types, if it appears that it is parsing from a list
    /// of types, and the last type in the given range is well-formed (i.e. not cut off).
    /// - parameters:
    ///    - inRange: The range of a single match of a pattern generated by a TypeDescriptorParser.
    ///    - ofSourceFile: The file in which the match was found.
    /// - returns: The identifiers from constituent components of the type.
    /// - warning: Performs recursive RegEx matching, which may degrade overall performance.
    func safeParseIdentifiers(inRange wholeRange: NSRange, ofSourceFile file: SourceFile) -> [TypeDescriptor]! {
        guard let match = engine.firstMatch(in: file.sourceText as String, range: wholeRange) else {
            let matchlocation = file.location(ofRange: wholeRange)
            parent.xcbLog.reportIssue(atSourceCodeLocation: matchlocation,
                                      ofSeverity: GlobalOptions.options.metaIssues,
                                      withMessage: "Cannot parse type descriptor from range '\(file.sourceText.substring(with: wholeRange))'.")
            return nil
        }
        
        var identifier   :  ArbitraryIdentifier!
        var conformances : [ArbitraryIdentifier]? = nil
        var specifiers   : [TypeDescriptor]? = nil
        
        let identifierRange : NSRange
        let conformancesRange : NSRange
        var specifiersRange : NSRange
        var recoveryRange : NSRange? = nil
        if #available(macOS 10.13, *) {
            identifierRange = match.range(withName: "primaryIdentifier")
            conformancesRange = match.range(withName: "conformances")
            specifiersRange = match.range(withName: "genericSpecifiers")
        } else {
            identifierRange = match.range(at: 1)
            conformancesRange = match.range(at: 2)
            specifiersRange = match.range(at: 3)
        }

        // Primary Identifier
        
        if identifierRange.location == NSNotFound {
            let location = file.location(ofRange: match.range)
            parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                      ofSeverity: GlobalOptions.options.metaIssues,
                                      withMessage: "Cannot parse primary identifier from type descriptor.")
            return nil
        } else {
            let location = file.location(ofRange: identifierRange)
            identifier = ( file.sourceText.substring(with: identifierRange), location )
        }
        
        // Qualifier Lists
        
        if conformancesRange.location != NSNotFound {
            let location = file.location(ofRange: conformancesRange)
            conformances = file.sourceText.substring(with: conformancesRange).split(separator: ",").map {
                ( $0.trimmingCharacters(in: .whitespacesAndNewlines), location )  // TODO: Better location?
            }
        }

        let nonSpace = NSCharacterSet.whitespacesAndNewlines.inverted
        if specifiersRange.location != NSNotFound {
            specifiers = []
            var nestDepth = 0
            var specifierOffset = 0
            for (currentOffset, char) in file.sourceText.substring(with: specifiersRange).enumerated() {
                switch (char, nestDepth) {
                    case (",", 0):
                        let range = NSRange(location: specifiersRange.location + specifierOffset,
                                            length: currentOffset - specifierOffset)
                        if let nestedSpecifiers = safeParseIdentifiers(inRange: range, ofSourceFile: file) {
                            specifiers!.append(contentsOf: nestedSpecifiers)
                        }
                        specifierOffset = currentOffset + 1
                        // fast-forward to next non-space…
                        let rest = NSRange(location: specifiersRange.location + specifierOffset,
                                           length: specifiersRange.length - specifierOffset)
                        let nextNonSpace = file.sourceText.rangeOfCharacter(from: nonSpace, options: [], range: rest)
                        specifierOffset = nextNonSpace.location - specifiersRange.location
                    case (">", 0):
                        let location = file.location(ofRange: specifiersRange)
                        parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                                  ofSeverity: .note,
                                                  withMessage: "Ambiguous type descriptor generic specifier, will attempt to recover.")
                        // this character should have been the one immediately after specifiersRange,
                        // instead: multiple type descriptors have been captured; retcon this to be the end of
                        // the specifiers range, stop this loop and take care of the final nested specifier
                        // of this type, and then trigger recovery from this point…
                        // Note that we attempt recovery from the remainder of the whole given range,
                        // not specifiersRange or even the match range.
                        specifiersRange.length = currentOffset
                        recoveryRange = NSRange(location: specifiersRange.upperBound,
                                                length: wholeRange.upperBound - specifiersRange.upperBound)
                    case ("<", _):
                        nestDepth += 1
                    case (">", _):
                        nestDepth -= 1
                    default:
                        continue
                }
                if currentOffset == specifiersRange.length {
                    // iteration bounds have changed…
                    break
                }
            }
            if nestDepth == 0 {
                // reached end of specifiersRange properly nested, take care of final specifier…
                var range = NSRange(location: specifiersRange.location + specifierOffset,
                                    length: specifiersRange.length - specifierOffset)
                // trim trailing spaces…
                let lastNonSpace = file.sourceText.rangeOfCharacter(from: nonSpace, options: [.backwards], range: range)
                range.length = lastNonSpace.upperBound - range.location
                if let nestedSpecifiers = safeParseIdentifiers(inRange: range, ofSourceFile: file) {
                    specifiers!.append(contentsOf: nestedSpecifiers)
                }
            } else {
                let range = NSRange(location: specifiersRange.upperBound, length: 1)
                let location = file.location(ofRange: range)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Improperly nested generic arguments.")
            }
        }

        // Result

        var result = [TypeDescriptor(identifier: identifier, conformances: conformances, specifiers: specifiers)]

        // Recovery

        if var recoveryRange = recoveryRange {
            // The recovery starts at the first character after a generic specifier,
            // we will assume we are in a list of types, allowing for trailing identifiers;
            // therefore there may be an indirection component (*, const, & postfix nullability)
            // and an identifier, but no more commas until the next type starts and no more type
            // identifiers until the next comma.

            // find next comma…
            let nextComma = file.sourceText.range(of: ",", options: [], range: recoveryRange)

            // nextComma may be not found at the end of a recovery recursion…
            if nextComma.location != NSNotFound {

                // fast-forward to next comma…
                recoveryRange = NSRange(location: nextComma.upperBound,
                                        length: recoveryRange.upperBound - nextComma.upperBound)

                // fast-forward to next non-space…
                let nextNonSpace = file.sourceText.rangeOfCharacter(from: nonSpace, options: [], range: recoveryRange)
                recoveryRange = NSRange(location: nextNonSpace.location,
                                        length: recoveryRange.upperBound - nextNonSpace.location)

                // recover…
                if let recoveredDescriptors = safeParseIdentifiers(inRange: recoveryRange, ofSourceFile: file), !recoveredDescriptors.isEmpty {
                    result.append(contentsOf: recoveredDescriptors)
                } else {
                    let location = file.location(ofRange: recoveryRange)
                    parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                            ofSeverity: GlobalOptions.options.metaIssues,
                                            withMessage: "Unable to recover from ambiguous type descriptor list.")
                }
            }
        }

        return result
    }
    
}

// EOF

