//
//  ExampleDefinitions.h
//  LeanHeaders
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//


#pragma mark Explanation

// A file containing example definitions with wich to test HeaderParsers
// This file does not neccessarily contain correct Objective-C code, e.g. types may not be available.
// This file is happy-path-only, i.e. nothing a parser should not be able to match.


#pragma mark - Structure Definitions
// expect count: (d,a,r) = ( 3, 0, 0 )
// Field types aren't parsed yet.

struct PlainStruct {
    int plainField;
};

typedef struct {
    int typeField
} TypedefStruct;

typedef struct RedundantStruct {
    int redundantField
} RedundantStruct;


#pragma mark - Enumeration Definitions
// expect count: (d,a,r) = ( 8, 0, 0 )
// Raw types are assumed to be system types and are not parsed.

enum PlainEnum {
    PlainEnumCaseA
};

typedef enum {
    TypedefEnumCaseA,
} TypedefEnum;

typedef enum RedundantEnum {
    RedundantEnumCaseA,
} RedundantEnum;

typedef enum : NSUInteger {
    ExplicitTypeEnumCaseA,
    ExplicitTypeEnumCaseB
} ExplicitTypeEnum;

typedef enum ExplicitRedundantEnum:NSUInteger {
    ExplicitRedundantEnumCaseA,
    ExplicitRedundantEnumCaseB
} ExplicitRedundantEnum;

typedef NS_ENUM(NSUInteger, EnumMacro) {
    MacroEnumCaseA,
    MacroEnumCaseB,
};

typedef NS_OPTIONS(NSUInteger, OptionsMacro) {
    MacroOptionA = 1 << 0,
    MacroOptionB = 1 << 1,
};

static NSString *const ExampleErrorDomain = @"com.example.ErrorDomain";  // Doesn't count as reference… static vars not implemented
typedef NS_ERROR_ENUM(ExampleErrorDomain, ErrorMacro) {
    ExampleErrorA = 0,
    ExampleErrorB = 1
};


#pragma mark - Closure Signature Definitions
// expect count: (d,a,r) = ( 4, 0, 20 )

typedef void (^SimpleSignature)(void);

typedef ReturnType(^Signature)(int arg1, RedundantStruct arg2);

typedef ReturnType<ConformsTo, ConformsThre> * _Nonnull (^ComplicatedSignature)(FirstType * arg1,
                                                                                AnotherType<ThatsComplicated> * _Nullable arg2,
                                                                                id<JustAProtocol> arg3);

typedef void(^NestedGenericParametersSignature)(NSArray<GenericSigParamSpecifierA *> *listA,
                                                NSDictionary<NestedGenericSigParam<GenericSigParamSpecifierB *> *, ValueType> *listB);

#pragma mark - Arbitrary Definitions
// expect count: (d,a,r) = ( 2, 0, 3 )

typedef ExistingType NewType;

typedef ExistingType<ThatsQualified> NewQualifiedType;


// EOF
