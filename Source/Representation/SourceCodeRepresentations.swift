//
//  SourceCodeRepresentations.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 02/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


// MARK: 'Base' Protocols


/// Represents a location in a text file.
typealias SourceCodeLocation = (file: URL, line: UInt, column: UInt?)

infix operator ≈ : ComparisonPrecedence

func ≈(lhs: SourceCodeLocation, rhs: SourceCodeLocation) -> Bool {
    return lhs.file == rhs.file && lhs.line == rhs.line  // ignore column
}


/// Interface for a representation of parsed source code, retaining debug information.
protocol SourceCodeRepresentation {
    
    /// The location of the original source code.
    var location : SourceCodeLocation { get }
    
    /// The text of the original source code.
    var rawLine : String { get }
    
}


/// Interface for a representation of parsed source code with a name and metatype.
protocol Type : SourceCodeRepresentation {
    
    /// The type of type.
    associatedtype MetaType
    
    /// The metatype of the type.
    var metatype : MetaType { get }
    
    /// The program name for the type.
    var identifier : String { get }
    
}


/// Interface for unions which exclusively wrap SourceCodeRepresentations.
protocol SourceCodeRepresentationUnionWrapper {
    
    /// Evaluates to the wrapped value.
    var sourceCodeRepresentation : SourceCodeRepresentation { get }
    
}


// MARK: - Conforming Structures


/// Represents the Declaration of a Type.
struct TypeDeclaration : Type {
    
    /// The Objective-C metatypes.
    enum MetaType: Equatable {
        /// An Objective-C class declaration.
        case `class`
        /// An Objective-C protocol declaration.
        case `protocol`
        /// An Objective-C structure declaration.
        case structure
        /// An Objective-C enumeration declaration.
        case enumeration
        /// An Objective-C block declaration.
        case closure
        /// An Objective-C arbitrary typedef declaration.
        case arbitrary (sameAs: String)
        
        // TODO: Remove in Swift 4.1
        static func ==(lhs: TypeDeclaration.MetaType, rhs: TypeDeclaration.MetaType) -> Bool {
            switch (lhs,rhs) {
            case (.`class`, .`class`), (.`protocol`,.`protocol`), (.structure,.structure),
                 (.enumeration,.enumeration), (.closure,.closure):
                return true
            case let (.arbitrary(l),.arbitrary(r)):
                return l == r
            default:
                return false
            }
        }
    }
    
    let location : SourceCodeLocation
    let rawLine : String
    
    let metatype : MetaType
    let identifier : String
    
}


/// Represents the union of Availabilities of Types.
enum TypeAvailablity : SourceCodeRepresentationUnionWrapper {
    
    /// Type is fully Available.
    case `import` (Import)
    /// Type is shallowly Available.
    case forward  (ForwardDeclaration)
    
    var sourceCodeRepresentation : SourceCodeRepresentation {
        switch self {
            case .`import` (let value): return value
            case .forward  (let value): return value
        }
    }
    
}


/// Represents the Availability of a Type.
struct ForwardDeclaration : Type {
    
    /// The means of introduction.
    enum MetaType : String {
        /// An Objective-C forward class declaration.
        case `class` = "class"
        /// An Objective-C forward protocol declaration.
        case `protocol` = "protocol"
        
        func forwardVersion(of declarationType: TypeDeclaration.MetaType) -> Bool {
            switch (self, declarationType) {
                case (.`class`, .`class`), (.`protocol`, .`protocol`):
                    return true
                default:
                    return false
            }
        }
        static func ≈(lhs: ForwardDeclaration.MetaType, rhs: TypeDeclaration.MetaType) -> Bool {
            return lhs.forwardVersion(of: rhs)
        }
    }
    
    let location : SourceCodeLocation
    let rawLine : String
    
    let metatype : MetaType
    let identifier : String
    
}


/// Represents the Availability of all Types in a file.
struct Import : SourceCodeRepresentation {
    
    let location : SourceCodeLocation
    let rawLine : String
    
    /// The file from which all types are made available.
    let importsFile : String
    
}

/// Represents the union of Uses of Types in Declarations.
enum TypeReference : SourceCodeRepresentationUnionWrapper {
    
    /// Referenced Type must be fully Available.
    case implementing (ImplementingReference)
    /// Referenced Type may be shallowly Available.
    case composition  (CompositionReference)
    
    var sourceCodeRepresentation : SourceCodeRepresentation {
        switch self {
            case .implementing (let value): return value
            case .composition  (let value): return value
        }
    }
    
}


/// Represents the Use of a Type in a Type Declaration.
struct ImplementingReference : Type {
    
    /// The method of introduction.
    enum MetaType : String {
        /// A base class in an Objective-C class declaration.
        case inheritance = "an inherritance"
        /// A protocol in an Objective-C class declaration.
        case conformance = "a conformance or incorporation"
        
        func implements(_ declarationType: TypeDeclaration.MetaType) -> Bool {
            switch (self, declarationType) {
                case (.inheritance, .`class`), (.conformance, .`protocol`):
                    return true
                default:
                    return false
            }
        }
        func closeButNoCigar(_ forwardType: ForwardDeclaration.MetaType) -> Bool {
            switch (self, forwardType) {
                case (.inheritance, .`class`), (.conformance, .`protocol`):
                    return true
                default:
                    return false
            }
        }
        static func ≈(lhs: ImplementingReference.MetaType, rhs: TypeDeclaration.MetaType) -> Bool {
            return lhs.implements(rhs)
        }
        static func ≈(lhs: ImplementingReference.MetaType, rhs: ForwardDeclaration.MetaType) -> Bool {
            return lhs.closeButNoCigar(rhs)
        }
    }
    
    let location : SourceCodeLocation
    let rawLine : String
    
    let metatype : MetaType
    let identifier : String
    
}


/// Represents the Use of a Type in a Type Member Declaration.
struct CompositionReference : Type {
    
    /// The type of member declaration.
    enum MetaType : String {
        /// An Objective-C property declaration.
        case property = "a property"
        /// An Objective-C method declaration.
        case method = "a method return type or parameter"
        /// An Objective-C closure signature declaration.
        case closure = "a closure return type or parameter"
        /// Other
        case arbitrary = "an arbitrary"
    }
    
    let location : SourceCodeLocation
    let rawLine : String
    
    let metatype : MetaType
    let identifier : String
    
}


// EOF
