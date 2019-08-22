//
//  CommonPatterns.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
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
    
    
    /// A coma-delimited list of the given pattern.
    static func list(of pattern: String) -> String {
        return "\(pattern) (?: \\s*+ , \\s*+ \(pattern) )*+"
    }
    
    
    // MARK: Identifier Patterns
    
    /// A single Objective-C identifier.
    static let identifierPattern = "\\b [ A-Z a-z ] [ A-Z a-z 0-9 _ ]*+ \\b"
    
    
    // MARK: Keyword Patterns
    
    /// Any of the nullability specifiers available in Objective-C.
    static let nullabilitySpecifierPattern = "\\b (?: (?:__)?n|_N ) (?: ull(?:able|_unspecified)|onnull ) \\b"
    
    /// The context-specific nullability keywords available in Objective-C.
    static let prefixNullabilitySpecifierPattern = "\\b n(?: ull(?:able|_unspecified) | onnull ) \\b"
    
    /// Any of the property attributes available in Objective-C.
    static let propertyAttributesPattern = """
        (?:
            class |
            [gs]etter=\(identifierPattern) |
            read(?: write|only ) |
            (?: non )?atomic | NS_NONATOMIC_IOSONLY |
            assign|retain|copy |
            weak|strong|unsafe_unretained |
            \(prefixNullabilitySpecifierPattern)
        )
        """
    
    /// An attribute.
    static let attributePattern = "\\b __attribute__ \\(\\( (?: [^\\)] | \\) [^\\)] )*+ \\)\\)"
    
    // MARK: Macro Patterns
    
    private static let macroStringArg = " \" (?: \\\\ \" | [^\"] )*+ \" "  // quote (escaped-quote | non-quote)* quote
    private static let macroVersionArg = " [0-9_]++ "  // digits and underscores
    
    private static let postfixCommonAttributeMacrosPattern = """
            UNAVAILABLE | SWIFT_UNAVAILABLE \\( \(macroStringArg) \\) |
            SWIFT_NAME \\( [^;]* \\) |
            AVAILABLE (?:  \\( \(macroVersionArg) , | _MAC \\( | _IOS \\( | _IPHONE \\( ) \(macroVersionArg) \\) |
            # DEPRECATED (?: _MAC | _IOS )? \\( ??? \\) |
            EXTENSION_UNAVAILABLE (?: _MAC | _IOS )? \\( \(macroStringArg) \\)
        """
    
    /* Maintenance Note:
        There are more defined in NSObjCRuntime.h
        additional macros can be added on an as-needed / as-requested basis.
    */
    static let postfixMethodAttributeMacrosPattern = """
        NS_(?:
            RETURNS_RETAINED | RETURNS_NOT_RETAINED | RETURNS_INNER_POINTER | AUTOMATED_REFCOUNT_UNAVAILABLE |
            REPLACES_RECEIVER | RELEASES_ARGUMENT |
            REQUIRES_NIL_TERMINATION |
            FORMAT_FUNCTION \\( \(macroVersionArg) , \(macroVersionArg) \\) | FORMAT_ARGUMENT \\( \(macroVersionArg) \\) |
            REQUIRES_SUPER | DESIGNATED_INITIALIZER | PROTOCOL_REQUIRES_EXPLICIT_IMPLEMENTATION |
            NO_TAIL_CALL |
            REFINED_FOR_SWIFT | SWIFT_NOTHROW |
            \(postfixCommonAttributeMacrosPattern)
        )
        """
    
    /* Maintenance Note:
     There are more defined in NSObjCRuntime.h
     additional macros can be added on an as-needed / as-requested basis.
     */
    static let postfixPropertyAttributeMacrosPattern = """
        NS_(?:
            \(postfixCommonAttributeMacrosPattern)
        )
        """
    
    /* Maintenance Note:
     There may be more defined, but these seem to be the ones defined in NSObjCRuntime.h,
     tho NS_CLASS_DEPRECATED(_MAC|_IOS)?\\( ... \\) have not been completed, because of the
     variadic arguments, which are dificult to make non-ambiguous.
     */
    static let prefixClassAttributeMacrosPattern = """
        NS_(?:
            ROOT_CLASS |
            REQUIRES_PROPERTY_DEFINITIONS |
            AUTOMATED_REFCOUNT_WEAK_UNAVAILABLE |
            CLASS_AVAILABLE \(macroVersionArg) \\) |
            CLASS_AVAILABLE (?: \\( \(macroVersionArg) , | _MAC \\( | _IOS \\( ) \(macroVersionArg) \\)
            # CLASS_DEPRECATED (?: _MAC | _IOS )? \\( ??? \\)
        )
        """
    
    
}

// EOF
