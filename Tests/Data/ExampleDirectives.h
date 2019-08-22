//
//  ExampleDirectives.h
//  LeanHeaders
//
//  Created by Joshua Brach on 20/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//


#pragma mark Explanation

// A file containing example directives with wich to test HeaderParsers
// This file does not neccessarily contain correct Objective-C code, e.g. types may not be available.
// This file is happy-path-only, i.e. nothing a parser should not be able to match.


#pragma mark - Pragma 'Need' Directives
// expect count: (d,a,r) = ( 0, 0, 4 )
// TODO: import file not implemented

#pragma LeanHeaders need import class RequiredBaseClass

#pragma LeanHeaders need import protocol RequiredBaseProtocol

#pragma LeanHeaders need import file FileWithNeededDefinitions.h

#pragma LeanHeaders need import file FileWithNeeded+Category.h

#pragma LeanHeaders need forward class RequiredCompositionClass

#pragma LeanHeaders need forward protocol RequiredCompositionProtocol


#pragma mark - Pragma 'Have' Directives
// expect count: (d,a,r) = ( 2, 4, 0 )

#pragma LeanHeaders have import class SuppliedBaseClass

#pragma LeanHeaders have import protocol SuppliedBaseProtocol

#pragma LeanHeaders have import file FileWithSuppliedDefinitions.h

#pragma LeanHeaders have import file FileWithSupplied+Category.h

#pragma LeanHeaders have forward class SuppliedCompositionClass

#pragma LeanHeaders have forward protocol SuppliedCompositionProtocol


// EOF
