//
//  PragmaDirectiveHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 20/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse custom Pragma Directives from headers.
class PragmaDirectiveHeaderParser : HeaderParser {

    private let parent : CodeBaseParser

    private let engine : NSRegularExpression

    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: PragmaDirectiveHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile pragma directive parser.")
            return nil
        }
    }

    private static let pattern = """
        # This pattern matches an custom pre-processor pragma directive.
        \\# pragma \\s++                            # Pre-processor pragma directive.
        \(GlobalOptions.options.useShortPragma ? "" : "ca \\. brach \\.")
        LeanHeaders \\s++                           # Custom pragma.
        (?<command> need | have ) \\s++             # Named capture group for the type of manual override
        (?<availability> forward | import ) \\s++   # Named capture group for the object of the manual override.
        (?<metatype> class | protocol | file ) \\s++# Named capture group for reference metatype.
        (?<name> [^\\s]*+ )                         # Named capture group for reference identifier.
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

            let directiveRange = result.range
            let directiveSource = file.sourceText.substring(with: directiveRange)
            let directiveLocation = file.location(ofRange: directiveRange)

            let commandRange : NSRange
            let availabilityRange : NSRange
            let metatypeRange : NSRange
            let nameRange : NSRange
            if #available(macOS 10.13, *) {
                commandRange = result.range(withName: "command")
                availabilityRange = result.range(withName: "availability")
                metatypeRange = result.range(withName: "metatype")
                nameRange = result.range(withName: "name")
            } else {
                commandRange = result.range(at: 1)
                availabilityRange = result.range(at: 2)
                metatypeRange = result.range(at: 3)
                nameRange = result.range(at: 4)
            }

            guard commandRange.location != NSNotFound else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Missing pragma command, expected 'need' or 'have'.")
                return
            }
            let command = file.sourceText.substring(with: commandRange)
            guard ["need", "have"].contains(command) else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Unexpected pragma command, expected 'need' or 'have' but found '\(command)'.")
                return
            }

            guard availabilityRange.location != NSNotFound else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Missing pragma availability, expected 'forward' or 'import'.")
                return
            }
            let availability = file.sourceText.substring(with: availabilityRange)
            guard ["forward", "import"].contains(availability) else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Unexpected pragma availability, expected 'forward' or 'import' but found '\(availability)'.")
                return
            }

            guard metatypeRange.location != NSNotFound else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Missing pragma metatype, expected 'class', 'protocol' or 'file'.")
                return
            }
            let metatype = file.sourceText.substring(with: metatypeRange)
            guard ["class", "protocol", "file"].contains(metatype) else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Unexpected pragma metatype, expected 'class', 'protocol' or 'file' but found '\(metatype)'.")
                return
            }

            guard nameRange.location != NSNotFound else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Missing non-optional component from pragma directive match.")
                return
            }
            let name = file.sourceText.substring(with: nameRange)

            switch (command, availability, metatype) {
                case (_, "forward", "file"):
                    parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                              withMessage: "Invalid pragma directive: there is no such thing as a forward file.")

                case ("need", "import", "file"):
                    // TODO: Support manually requiring a file directly
                    break
                case ("need", "import", _):
                    references.append( .implementing(
                        ImplementingReference(location: directiveLocation,
                                              rawLine: directiveSource,
                                              metatype: (metatype == "class" ? .inheritance : .conformance),
                                              identifier: name)
                    ) )
                case ("need", "forward", _):
                    references.append( .composition(
                        CompositionReference(location: directiveLocation,
                                             rawLine: directiveSource,
                                             metatype: .arbitrary,
                                             identifier: name)
                    ) )

                case ("have", "import", "file"):
                    availabilities.append( .`import`(
                        Import(location: directiveLocation,
                               rawLine: directiveSource,
                               importsFile: name)
                    ) )
                case ("have", "import", _):
                    declarations.append(
                        TypeDeclaration(location: directiveLocation,
                                        rawLine: directiveSource,
                                        metatype: (metatype == "class" ? .`class` : .`protocol`),
                                        identifier: name)
                    )
                case ("have", "forward", _):
                    availabilities.append( .forward(
                        ForwardDeclaration(location: directiveLocation,
                                           rawLine: directiveSource,
                                           metatype: (metatype == "class" ? .`class` : .`protocol`),
                                           identifier: name)
                    ) )
                
                default:
                    return
            }

        } // end enumerate matches

        return (declarations, availabilities, references)
    }

}

// EOF
