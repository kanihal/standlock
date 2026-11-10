import Foundation
import Testing
@testable import StandLockCore

@Suite("Local LaTeX typesetting")
struct MathPromptDocumentTests {
    @Test func rendersFractionsScriptsAndMatricesAsMathML() {
        let source = #"Given $A^{-1}$, compute $$\frac{1}{2}\begin{bmatrix}1&2\\3&4\end{bmatrix}x_i^2.$$"#
        let document = MathPromptDocument(source)
        #expect(document.mathCount == 2)
        #expect(document.unsupportedCommands.isEmpty)
        #expect(document.htmlFragment.contains("<mfrac>"))
        #expect(document.htmlFragment.contains("<mtable"))
        #expect(document.htmlFragment.contains("<msubsup>"))
        #expect(document.htmlFragment.contains("application/x-tex"))
        let xml = "<root>" + document.htmlFragment + "</root>"
        #expect(XMLParser(data: Data(xml.utf8)).parse())
    }

    @Test func proseAndMathCannotInjectHTMLOrLoadExternalScripts() {
        let document = MathPromptDocument(#"<script>alert(1)</script> $\text{<img src=x>}$"#)
        #expect(!document.htmlFragment.contains("<script>"))
        #expect(!document.htmlFragment.contains("<img"))
        #expect(document.html(dark: false).contains("default-src 'none'"))
        #expect(!document.html(dark: false).contains("<script"))
    }

    @Test func rendersEveryBankTemplateWithoutUnknownCommands() {
        for template in MathProblemCatalog.templates {
            let problem = MathProblemCatalog.problem(topic: template.topic, index: template.index,
                parameters: MathParameters([2,3,4,5,6,7,8,9]))
            let document = MathPromptDocument(problem.prompt)
            #expect(document.mathCount > 0, "Missing math in \(template.id)")
            #expect(document.unsupportedCommands.isEmpty, "\(template.id): \(document.unsupportedCommands)")
            let xml = "<root>" + document.htmlFragment + "</root>"
            #expect(XMLParser(data: Data(xml.utf8)).parse(), "Invalid MathML in \(template.id)")
        }
    }
}
