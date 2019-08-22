//__FILEHEADER__

import Foundation


/// A class to parse Objective-C <#Info#> from headers.
class ___FILEBASENAMEASIDENTIFIER___ : HeaderParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: ___FILEBASENAMEASIDENTIFIER___.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile <#info#> parser.")
            return nil
        }
    }
    
    private static let pattern = """
        <#Info-specific RegEx#>
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)

        var declarations   : [TypeDeclaration] = []
        var availabilities : [TypeAvailablity] = []
        var references     : [TypeReference]   = []
        
        engine.enumerateMatches(in: file.sourceText as String, range: wholeRange) { (result, flags, _) in

            guard let result = result else {
                // just reporting progress…
                return
            }
            
            <#Extract Info from matches#>
            
        } // end enumerate matches
        
        return (declarations, availabilities, references)
    }
    
}

// EOF
