//
//  Mock_CodeBaseParser.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


class Mock_CodeBaseParser : CodeBaseParser {
    
    init() { super.init(mockForTesting: ()) }  // Don't automatically compile child parsers.
    
}

// EOF
