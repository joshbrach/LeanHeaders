//
//  ExampleDescriptors.h
//  LeanHeaders
//
//  Created by Joshua Brach on 04/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//


#pragma mark Explanation

// A file containing example type descriptors with wich to test DescriptorParsers
// This file does not neccessarily contain correct Objective-C code, e.g. types are described with no context.
// This file is happy-path-only, i.e. nothing a parser should not be able to match.


#pragma mark - Constants
// expect count: 7

@test ConstType * const varname;

@test const PreConstType *varname;

@test InfixConstType const *varname;

@test ConstTypeNoSpace*const varname;

@test IndirectedConstType *const *varname;

@test ConstIndirectionType **const varname;

@test DoubleConstType * const * const varname;


#pragma mark - Nullability
// expect count: 7

@test NullableType * _Nullable varname;

@test NullableTypeNoSpace*_Nullable varname;

@test id<NullableProtocol> _Nullable varname;

@test NonNullType * _Nonnull varname;

@test NullUnspecifiedType * _Null_unspecified varname;

@test NullableIndirectedType * _Nullable * _Nullable varname;

@test NonNullConstType * _Nonnull const varname;

#pragma mark - Conformance
// expect count: 2

@test ConformingType<Protocol> *varname;

@test MultiConformingType<Protocol, AnotherProtocol> *varname;


#pragma mark - Generic Specification
// expect count: 8

@test GenericType<SpecifingType *> *varname;

@test NullableGenericType<SpecifingType * _Nullable> *varname;

@test ConstGenericType<SpecifingType * const> *varname;

@test MultiGenericType< SpecifingType*, AnotherSpecifyingType* > *varname;

@test NestedGenericType< SpecifingType<NestedSpecifier*> * > *varname;

@test MultiNestedGenericType< SpecifingTypeA<NestedSpecifierA*> *, SpecifingTypeB<NestedSpecifierB*> * > *varname;

@test NestedConformanceGenericType<SpecifingType<WithConformance>*> *varname;

@test MultiConformingGenericType< SpecifingType<WithConformance>*, AnotherSpecifyingType* > *varname;


#pragma mark - Block Syntax
// expect count: 4

@test BlockReturn (^blockName)(BlockParam param);

@test void (^pureBlock)(void);

@test NoParamIDsBlockReturn (^noParamIdsBlock)(BlockParamWithoutIDA *, BlockParamWithoutIDB);

@test NoNameBlockReturn (^)(NoNameBlockParam);


// EOF
