//
//  HeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// An interface for specialized Parsers of header files.
protocol HeaderParser {
    
    /// Initializes the parser with the given parent parser.
    /// Can fail to compile parsing grammar at runtime
    init?(parent: CodeBaseParser)
    
    /// Parses the given text from the given file.
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference])
    
}

// EOF
