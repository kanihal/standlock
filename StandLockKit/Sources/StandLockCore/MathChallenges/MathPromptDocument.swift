import Foundation

/// An entirely local HTML/MathML document: prose is escaped, and LaTeX lives only in
/// the explicitly delimited math regions. Annotation preserves the original TeX source.
public struct MathPromptDocument: Sendable {
    public let htmlFragment: String
    public let mathCount: Int
    public let unsupportedCommands: Set<String>

    public init(_ source: String) {
        let characters = Array(source)
        var i = 0
        var prose = ""
        var fragment = ""
        var count = 0
        var unsupported = Set<String>()
        func text(_ value: String) -> String {
            LatexMathML.escape(value).replacingOccurrences(of: "\n", with: "<br/>")
        }
        while i < characters.count {
            guard characters[i] == "$" else { prose.append(characters[i]); i += 1; continue }
            let display = i + 1 < characters.count && characters[i + 1] == "$"
            let delimiter = display ? 2 : 1
            let start = i + delimiter
            var end = start
            while end < characters.count {
                if characters[end] == "$" && (end == 0 || characters[end - 1] != "\\") {
                    if !display || (end + 1 < characters.count && characters[end + 1] == "$") { break }
                }
                end += 1
            }
            guard end < characters.count else { prose.append(characters[i]); i += 1; continue }
            fragment += text(prose); prose = ""
            let latex = String(characters[start..<end])
            let math = LatexMathML.convert(latex)
            unsupported.formUnion(math.unsupportedCommands)
            let markup = "<math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"\(display ? "block" : "inline")\"><semantics>"
                + math.markup + "<annotation encoding=\"application/x-tex\">\(LatexMathML.escape(latex))</annotation></semantics></math>"
            fragment += display ? "<div class=\"display-math\">\(markup)</div>" : markup
            count += 1
            i = end + delimiter
        }
        htmlFragment = fragment + text(prose)
        mathCount = count
        unsupportedCommands = unsupported
    }

    public func html(dark: Bool) -> String {
        let foreground = dark ? "#eeeeef" : "#222225"
        let background = dark ? "#29292d" : "#f5f5f7"
        return """
        <!doctype html><html><head><meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width,initial-scale=1"/>
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"/>
        <style>
        :root {color-scheme: \(dark ? "dark" : "light");}
        body {margin:0;padding:16px;font:15px/1.65 -apple-system,system-ui,sans-serif;color:\(foreground);background:\(background);overflow-wrap:break-word;}
        math {font-family:'STIX Two Math','STIXGeneral','Cambria Math',serif;font-size:1.14em;}
        .display-math {overflow-x:auto;padding:10px 0;max-width:100%;}
        .display-math math {margin:0 auto;}
        </style></head><body>\(htmlFragment)</body></html>
        """
    }
}
