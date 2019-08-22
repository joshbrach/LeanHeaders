//
//  Mock_CodeBase.swift
//  LeanHeaders-Tests
//
//  Created by Joshua Brach on 04/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


class Mock_CodeBase: CodeBase {
    
    init?(mockHeaderFiles: [URL]) {
        if let nonEmpty = mockHeaderFiles.first {
            _headerFiles = mockHeaderFiles
            super.init(rootDirectory: nonEmpty)
        } else {
            return nil
        }
    }
    
    var _headerFiles : [URL]
    override var headerFiles: [URL] {
        return _headerFiles
    }
    
}

// EOF
