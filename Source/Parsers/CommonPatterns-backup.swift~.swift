//
//  CommonPatterns.swift
//  ImportClean
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach. All rights reserved.
//

import Foundation


/* Maintenence Note:
 All patterns in this project are ICU Regular Expressions, written to be used with the 'x' (a.k.a. "UREGEX_COMMENTS") flag.
 Use of the comments flag allows for space characters and hash-delimited comments, which makes patterns at least
 conceivably readable.  These pattens make exclusive use of named capture groups and non-capturing groups for grouping,
 making intentional captures explicit and consecutive.
 Care has been taken to avoid ambiguity with subsequent or nested repititions which cause the matching engine to swap
 characters back and forth, to the severe detriment of performance.  The construct '.*' has been avoided entirely.
 Whitespace matching is done with '\s', which /can/ match new-line and carriage-return characters.
 All escape characters passed thru to the pattern must be doubled, to escape Swift string literal level escaping.
 */


internal struct CommonPatterns {
    
    
    // MARK: Identifier Patterns
    
    /// A single Objective-C identifier.
    static let identifierPattern = "\\b [ A-Z a-z ] [ A-Z a-z 0-9 _ ]* \\b"
    
    /// A comma-delimited list of Objective-C identifiers.
    static let identifierListPattern = "\(identifierPattern) \\s*+ (?: , \\s*+ \(identifierPattern) \\s*+ )*+"  // ToDo: Change to exclude final spaces, audit uses for required changes
    
    
    // MARK: Other Patterns
    
    /// Any of the nullability specifiers possible in Objective-C.
    static let nullabilitySpecifierPattern = "\\b (?: (?:__)?n|_N ) (?: ull(?:able|_unspecified)|onnull ) \\b"
    
    // MARK: Component Configuration
    
    /// A type to specify configuration for pattern components.
    /// - Nil tuple indicates that the component should not be included in the pattern.
    /// - Boolean indicates whether the component should be optional in the pattern.
    /// - Nil string indicates that the component should not be captured.
    /// - Non-trivial string will be used as the capture name.
    typealias PatternComponentConfiguration = (optional: Bool, capture: String?)?
    
    static private func wrap(component: String, withConfiguration config: PatternComponentConfiguration, forceGroup: Bool = false) -> String {
        guard let (optional, capture) = config else {
            return ""
        }
        let groupType = capture == nil ? "?:" : capture!.isEmpty ? "" : "?<\(capture!)>"
        let usesGroup = forceGroup || optional || capture != nil
        let openGroup = usesGroup ? "(\(groupType)" : ""
        let closeGroup = usesGroup ? ")" : ""
        let postGroup = optional ? "?" : ""
        return "\(openGroup)\(component)\(closeGroup)\(postGroup)"
    }
    
    // MARK: Qualified Type Patterns
    
    /// Generates a pattern for an arbitrary Objective-C type, configured according to the given arguments.
    /// - parameters:
    ///    - nullability: Configuration for context-specific nullability specifiers
    ///                   which are sometimes acceptable before the type name.
    ///                   Default is to include as optional with anonymous capture.
    ///    - conformance: Configuration for conformances qualifier.
    ///                   Default is to include as optional with capture named 'conformances'.
    ///    - genericArgs: Configuration for generic arguments qualifier.
    ///                   Default is to include as optional with capture named 'genericSpecifiers'.
    /// - returns: An ICU Pattern which will match a Type as confingured, with no leading nor trailing spaces.
    /// - warning: If generic argument qualifiers are permitted, the result of this function must be followed
    ///            by an unambiguous pattern or lookahead to collapse the ambiguity of recursive qualifiers.
    static func typePattern(nullability: PatternComponentConfiguration = (true, nil),
                            conformance: PatternComponentConfiguration = (true, "conformances"),
                            genericArgs: PatternComponentConfiguration = (true, "genericSpecifiers")) -> String {
        
        // nullability Identifier<Conformance, nlty OrGeneric< nlty NestedType * _Nullability> * _Nlty> * _Nlty * _Nlty
        
        let preNullPattern  = "     n    (?: ull(?:able|_unspecified) | onnull )"
        let postNullPattern = "_(?:_n|N) (?: ull(?:able|_unspecified) | onnull )"
        let nullabilityConfig = nullability
        
        // Qualifier configuration is a sort of convolution of configurations for the types of qualifiers…
        let qualifiersConfig : PatternComponentConfiguration
        if conformance == nil && genericArgs == nil {
            // neither is included, so the whole qualifier is excluded
            qualifiersConfig = nil
        } else if conformance == nil || genericArgs == nil {
            // only one is included, so it determines overall optionality
            qualifiersConfig = (conformance?.optional ?? genericArgs!.optional, nil)
        } else {
            // both will be included; they are each optional by nature of alternation,
            // and so long as either is mandetory the qualifier delimiters are mandetory;
            // only when both are optional is the whole qualifier optional
            qualifiersConfig = (conformance!.optional && genericArgs!.optional, nil)
        }
        let conformanceConfig = conformance == nil ? nil : (false, conformance!.capture)
        let genericArgsConfig = genericArgs == nil ? nil : (false, genericArgs!.capture)
        
        // Conformance qualifier is a simple comma-delimited list of protocol identifiers.
        let conformanceListPattern = wrap(component: identifierListPattern,
                                          withConfiguration: conformanceConfig, forceGroup: true)
        // Generic qualifier is a complex free-form repitition of any character that can be part of a type pattern.
        let genericArgsListPattern = wrap(component: "[ A-Z a-z 0-9 _ \\s < > : * , ]*",
                                          withConfiguration: genericArgsConfig)
        
        // Generic qualifiers are recursive patterns.  Recursion is far away from regular that
        // even the bastardization that is regex can't express it.  This pattern avoids some
        // ambiguity by describing the straight-forward conformance qualifier first, only
        // failing back to the free-form generic qualifier if that fails.  The identifier list
        // pattern has been definied using possesive repitition (*+) in an attempt to fail
        // quickly on encountering the first indication that the text is not a conformance
        // qualifier (e.g the first < or *).  Note that the repitition in the generic qualifier
        // portion cannot be possessive since the closing delimiter for the pattern is an
        // option within the repitition.  This, in a word, sucks.
        let qualifierPattern = "< \\s*+ (?: \(conformanceListPattern) | \(genericArgsListPattern) ) >"
        
        let preNullPatternComponent = wrap(component: "\(preNullPattern) \\s++", withConfiguration: nullabilityConfig)
        let qualifierPatternComponent = wrap(component: "\\s*+ \(qualifierPattern)", withConfiguration: qualifiersConfig)
        let indirectionPatternComponent = "(?: \\s*+ \\* \\s*+ \(postNullPattern) )*"
        
        return "\(preNullPatternComponent)\(identifierPattern)\(qualifierPatternComponent)\(indirectionPatternComponent)"
    }
    
    /// Parses components from a pattern for an arbitrary Objective-C type.
    /// - parameters:
    ///    - fromText: The text of a match of a pattern generated by func typePattern(nullability:conformance:genericArgs)
    static func parseTypes(fromText text: String) -> ([TypeDefinition], [TypeReference]) {
        
        
        
        return ([],[])
    }
    
}


// EOF
