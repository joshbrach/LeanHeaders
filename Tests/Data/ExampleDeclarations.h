//
//  ExampleDeclarations.h
//  LeanHeaders
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//


#pragma mark Explanation

// A file containing example declarations with wich to test HeaderParsers
// This file does not neccessarily contain correct Objective-C code, e.g. interfaces may be begun but never @ended.
// This file is happy-path-only, i.e. nothing a parser should not be able to match.


#pragma mark - Class Declarations
// expect count: (d,a,r) = ( 9, 0, 15 )

@interface ExampleRootClass
@end

@interface ExampleDerivedClass : ExampleRootClass
@end

@interface ExampleRootClassWithProtocol <ExampleRootProtocol>
@interface ExampleRootClassWithProtocols <ExampleRootProtocol, UITableViewDelegate>

@interface ExampleDerivedClassWithProtocol : ExampleRootClass <ExampleRootProtocol>
@interface ExampleDerivedClassWithProtocols : ExampleRootClass <ExampleRootProtocol, UITableViewDelegate>

@interface ExampleOneLineClass : NSObject @property BOOL isOneLine; @end

@interface ExampleMultiLineClass
                : NSObject
@end
@interface ExampleMultiLineClassWithProtocols
                : NSObject
                <ExampleProtocol, UITableViewDelegate>
@end


#pragma mark - Category & Extension Declarations
// expect count: (d,a,r) = ( 0, 0, 8 )

@interface ExampleDerivedClass ()

@interface ExampleDerivedClassWithProtocol () <ExtensionProtocol>

@interface ExampleDerivedClass (Category)

@interface ExampleDerivedClassWithProtocol (Category) <CategoryProtocol>

@interface ExampleOneLineClass (Category) @property BOOL hasCategory; @end


#pragma mark - Protocol Declarations
// expect count: (d,a,r) = ( 5, 0, 5 )

@protocol ExampleRootProtocol
@end

@protocol ExampleProtocol <ExampleRootProtocol >
@end

@protocol ExampleProtocolWithProtocols <ExampleRootProtocol, UITableViewDelegate>
@end

@protocol ExampleOneLineProtocol <ExampleRootProtocol> @end

@protocol ExampleMultiLineProtocol
            <ExampleRootProtocol>
@end


#pragma mark - Member Declarations
// expect count: (d,a,r) = ( 0, 0, 27 )

@property (weak, nullable, nonatomic, readwrite) IBOutlet UILabelSubclass *text;

@property (assign, nonatomic, getter=isProperty) IBInspectable BooleanScalar property;

@property (class, strong, atomic, nonnull, readonly) AnotherProperyClass *value;

@property (unsafe_unretained, nonatomic, null_unspecified, setter=useValue) GenericProperty<SpecifiedProperty *> *value;

@property (strong, atomic, nonnull, readonly) BlockPropertyReturn (^blockName)(BlockPropertyParamA *paramA, BlockPropertyParamB *paramB);

+(SimpleClassMethodReturn *)classMethod;

+(nonnull ComplexMethodReturn * const)classMethodWith:(nullable ComplexMethodParameterA *const)a andAlso:(nullable ComplexMethodParameterB**)b;

- (SimpleInstanceMethodReturn *)instanceMethod;

- (InstanceMethodReturn *)instanceMethodWith:(SimpleMethodParameter *)param;

-(GenericMethodReturn<GenericMethodReturnSpecifier*_Nullable>*const)instanceMethodWith:(GenericMethodParameter<GenericMethodParameterSpecifier*>*)param;

-(BlockMethodReturn*)blockMethodWith:(void (^nullable)(BlockMethodParam param))blockParam;

-(ManipulateAndCallbackObject *)initWith:(ManipulatableObject*)objToManipulate onClose: (void (^)(CloseReason, ManipulatableObject*))onCloseBlock;

// TODO: More block examples, raw & macro attribute examples.


#pragma mark - Forward Declarations
// expect count: (d,a,r) = ( 0, 6, 0 )

@class PromisedClass;

@protocol PromisedProtocol;

@class MultiPromisedClassA, MultiPromisedClassB;

@protocol MultiPromisedProtocolA, MultiPromisedProtocolB;


// EOF
