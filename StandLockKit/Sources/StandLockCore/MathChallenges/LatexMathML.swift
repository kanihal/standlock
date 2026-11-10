import Foundation

/// Typesets the bank's documented LaTeX vocabulary into native MathML. This is a
/// deliberately bounded math grammar, not a TeX interpreter: no macros, I/O or scripts.
public enum LatexMathML {
    public struct Result: Sendable {
        public let markup: String
        public let unsupportedCommands: Set<String>
    }

    public static func convert(_ source: String) -> Result {
        var parser = Parser(source)
        let body = parser.expression()
        return Result(markup: body, unsupportedCommands: parser.unsupported)
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private struct Parser {
        let input: [Character]
        var position = 0
        var unsupported = Set<String>()

        init(_ source: String) { input = Array(Self.normalizeScripts(source)) }

        mutating func expression(until end: Character? = nil) -> String {
            var nodes = ""
            while position < input.count {
                spaces()
                guard position < input.count else { break }
                if let end, input[position] == end { position += 1; break }
                var base = atom()
                guard !base.isEmpty else { continue }
                var sub: String?
                var sup: String?
                while position < input.count {
                    spaces()
                    guard position < input.count else { break }
                    let character = input[position]
                    if character == "_" || character == "^" {
                        position += 1
                        let script = argument()
                        if character == "_" { sub = script } else { sup = script }
                    } else if character == "'" {
                        position += 1
                        sup = "<mrow>" + (sup ?? "") + "<mo>′</mo></mrow>"
                    } else { break }
                }
                if let sub, let sup { base = "<msubsup>\(base)\(sub)\(sup)</msubsup>" }
                else if let sub { base = "<msub>\(base)\(sub)</msub>" }
                else if let sup { base = "<msup>\(base)\(sup)</msup>" }
                nodes += base
            }
            return "<mrow>" + nodes + "</mrow>"
        }

        mutating func atom() -> String {
            spaces()
            guard position < input.count else { return "<mrow/>" }
            let character = input[position]
            position += 1
            if character == "{" { return expression(until: "}") }
            if character == "\\" { return command() }
            if character.isNumber || (character == "." && position < input.count && input[position].isNumber) {
                var value = String(character)
                while position < input.count && (input[position].isNumber || input[position] == ".") {
                    value.append(input[position]); position += 1
                }
                return "<mn>\(escape(value))</mn>"
            }
            if character.isLetter { return "<mi>\(escape(String(character)))</mi>" }
            return "<mo>\(escape(String(character)))</mo>"
        }

        mutating func argument() -> String {
            spaces()
            if position < input.count && input[position] == "{" {
                position += 1
                return expression(until: "}")
            }
            return atom()
        }

        mutating func rawArgument() -> String {
            spaces()
            guard position < input.count else { return "" }
            guard input[position] == "{" else {
                let value = String(input[position]); position += 1; return value
            }
            position += 1
            var depth = 1
            var result = ""
            while position < input.count {
                let c = input[position]; position += 1
                if c == "{" { depth += 1 }
                if c == "}" { depth -= 1; if depth == 0 { break } }
                result.append(c)
            }
            return result
        }

        mutating func command() -> String {
            guard position < input.count else { return "<mo>\\</mo>" }
            var name = ""
            if input[position].isLetter {
                while position < input.count && input[position].isLetter {
                    name.append(input[position]); position += 1
                }
                if position < input.count && input[position] == "*" { position += 1 }
            } else {
                name.append(input[position]); position += 1
            }
            switch name {
            case "frac", "dfrac", "tfrac":
                let numerator = argument(), denominator = argument()
                return "<mfrac>\(numerator)\(denominator)</mfrac>"
            case "binom":
                let top = argument(), bottom = argument()
                return "<mrow><mo>(</mo><mfrac linethickness=\"0\">\(top)\(bottom)</mfrac><mo>)</mo></mrow>"
            case "sqrt":
                spaces()
                var index: String?
                if position < input.count && input[position] == "[" {
                    position += 1; index = expression(until: "]")
                }
                let radicand = argument()
                if let index { return "<mroot>\(radicand)\(index)</mroot>" }
                return "<msqrt>\(radicand)</msqrt>"
            case "text", "textrm", "mbox": return "<mtext>\(escape(rawArgument()))</mtext>"
            case "operatorname": return "<mi mathvariant=\"normal\">\(escape(rawArgument()))</mi>"
            case "mathrm", "mathsf", "mathbb", "mathbf", "boldsymbol", "mathcal", "mathit", "mathfrak":
                let variants = ["mathrm": "normal", "mathsf": "sans-serif", "mathbb": "double-struck",
                                "mathbf": "bold", "boldsymbol": "bold-italic", "mathcal": "script",
                                "mathit": "italic", "mathfrak": "fraktur"]
                return "<mstyle mathvariant=\"\(variants[name] ?? "normal")\">\(argument())</mstyle>"
            case "hat", "widehat", "bar", "overline", "tilde", "widetilde", "dot", "ddot", "vec":
                let marks = ["hat": "^", "widehat": "^", "bar": "¯", "overline": "¯", "tilde": "~",
                             "widetilde": "~", "dot": "˙", "ddot": "¨", "vec": "→"]
                return "<mover accent=\"true\">\(argument())<mo>\(marks[name] ?? "¯")</mo></mover>"
            case "underline": return "<munder accentunder=\"true\">\(argument())<mo>¯</mo></munder>"
            case "begin": return environment(rawArgument())
            case "left", "right", "big", "Big", "bigg", "Bigg", "bigl", "bigr":
                if position < input.count && input[position] == "." { position += 1 }
                return ""
            case "displaystyle", "textstyle", "limits", "nolimits": return ""
            case "quad": return "<mspace width=\"1em\"/>"
            case "qquad": return "<mspace width=\"2em\"/>"
            case ",", ";", ":", " ", "enspace", "thinspace": return "<mspace width=\"0.2em\"/>"
            case "!": return ""
            case "\\": return "<mspace linebreak=\"newline\"/>"
            default:
                if let symbol = Self.symbols[name] {
                    let tag = Self.greek.contains(name) || ["ell", "hbar", "imath", "jmath"].contains(name) ? "mi" : "mo"
                    return "<\(tag)>\(escape(symbol))</\(tag)>"
                }
                if Self.functions.contains(name) { return "<mi mathvariant=\"normal\">\(escape(name))</mi>" }
                if ["{", "}", "|", "%", "_", "$", "#", "&"].contains(name) {
                    return "<mo>\(escape(name == "|" ? "‖" : name))</mo>"
                }
                unsupported.insert(name)
                return "<mtext>\(escape("\\" + name))</mtext>"
            }
        }

        mutating func environment(_ name: String) -> String {
            let supported = ["bmatrix", "pmatrix", "matrix", "vmatrix", "Vmatrix", "cases", "aligned", "gathered"]
            if !supported.contains(name) { unsupported.insert("begin{" + name + "}") }
            let closing = Array("\\end{" + name + "}")
            let opening = Array("\\begin{" + name + "}")
            var depth = 0
            var content = ""
            while position < input.count {
                if matches(opening) { depth += 1 }
                if matches(closing) {
                    if depth == 0 { position += closing.count; break }
                    depth -= 1
                }
                content.append(input[position]); position += 1
            }
            let rows = Self.cells(content)
            let table = rows.map { row in
                "<mtr>" + row.map { cell in
                    var nested = Parser(cell)
                    let markup = nested.expression()
                    unsupported.formUnion(nested.unsupported)
                    return "<mtd>" + markup + "</mtd>"
                }.joined() + "</mtr>"
            }.joined()
            let delimiters: (String, String)
            switch name {
            case "bmatrix": delimiters = ("[", "]")
            case "pmatrix": delimiters = ("(", ")")
            case "vmatrix": delimiters = ("|", "|")
            case "Vmatrix": delimiters = ("‖", "‖")
            case "cases": delimiters = ("{", "")
            default: delimiters = ("", "")
            }
            let alignment = ["cases", "aligned"].contains(name) ? "left" : "center"
            return "<mrow><mo stretchy=\"true\">\(escape(delimiters.0))</mo>"
                + "<mtable columnalign=\"\(alignment)\" rowspacing=\"0.3em\" columnspacing=\"0.8em\">\(table)</mtable>"
                + "<mo stretchy=\"true\">\(escape(delimiters.1))</mo></mrow>"
        }

        private func matches(_ token: [Character]) -> Bool {
            position + token.count <= input.count && Array(input[position..<(position + token.count)]) == token
        }

        private mutating func spaces() {
            while position < input.count && input[position].isWhitespace { position += 1 }
        }

        private static func cells(_ source: String) -> [[String]] {
            let characters = Array(source)
            var rows: [[String]] = []
            var row: [String] = []
            var cell = ""
            var braces = 0
            var i = 0
            while i < characters.count {
                let c = characters[i]
                if c == "{" { braces += 1 }
                if c == "}" { braces = max(0, braces - 1) }
                if braces == 0 && c == "&" { row.append(cell); cell = "" }
                else if braces == 0 && c == "\\" && i + 1 < characters.count && characters[i + 1] == "\\" {
                    row.append(cell); rows.append(row); cell = ""; row = []; i += 1
                } else { cell.append(c) }
                i += 1
            }
            row.append(cell); rows.append(row)
            return rows
        }

        private static func normalizeScripts(_ source: String) -> String {
            let superscripts: [Character: String] = ["⁰":"0","¹":"1","²":"2","³":"3","⁴":"4","⁵":"5","⁶":"6","⁷":"7","⁸":"8","⁹":"9","⁻":"-","⁺":"+","ᵀ":"T","ⁿ":"n","ᵏ":"k","ⁱ":"i","⁽":"(","⁾":")"]
            let subscripts: [Character: String] = ["₀":"0","₁":"1","₂":"2","₃":"3","₄":"4","₅":"5","₆":"6","₇":"7","₈":"8","₉":"9","ᵢ":"i","ⱼ":"j","ₖ":"k","ₙ":"n","ₘ":"m","ₜ":"t","ₓ":"x","₌":"=","₊":"+","₋":"-"]
            let characters = Array(source)
            var result = ""
            var i = 0
            while i < characters.count {
                let mapping: [Character: String]?
                let marker: String
                if superscripts[characters[i]] != nil { mapping = superscripts; marker = "^" }
                else if subscripts[characters[i]] != nil { mapping = subscripts; marker = "_" }
                else { mapping = nil; marker = "" }
                if let mapping {
                    var script = ""
                    while i < characters.count, let value = mapping[characters[i]] { script += value; i += 1 }
                    result += marker + "{" + script + "}"
                } else { result.append(characters[i]); i += 1 }
            }
            return result
        }

        private static let functions: Set<String> = ["tr", "det", "rank", "log", "ln", "exp", "sin", "cos", "tan", "tanh", "min", "max", "argmin", "argmax", "inf", "sup", "lim", "Pr", "diag", "ker", "dim", "sign", "sgn"]
        private static let greek: Set<String> = ["alpha","beta","gamma","delta","epsilon","varepsilon","zeta","eta","theta","vartheta","iota","kappa","lambda","mu","nu","xi","pi","varpi","rho","varrho","sigma","varsigma","tau","upsilon","phi","varphi","chi","psi","omega","Gamma","Delta","Theta","Lambda","Xi","Pi","Sigma","Upsilon","Phi","Psi","Omega"]
        private static let symbols: [String: String] = [
            "alpha":"α","beta":"β","gamma":"γ","delta":"δ","epsilon":"ϵ","varepsilon":"ε","zeta":"ζ","eta":"η","theta":"θ","vartheta":"ϑ","iota":"ι","kappa":"κ","lambda":"λ","mu":"μ","nu":"ν","xi":"ξ","pi":"π","varpi":"ϖ","rho":"ρ","varrho":"ϱ","sigma":"σ","varsigma":"ς","tau":"τ","upsilon":"υ","phi":"ϕ","varphi":"φ","chi":"χ","psi":"ψ","omega":"ω",
            "Gamma":"Γ","Delta":"Δ","Theta":"Θ","Lambda":"Λ","Xi":"Ξ","Pi":"Π","Sigma":"Σ","Upsilon":"Υ","Phi":"Φ","Psi":"Ψ","Omega":"Ω",
            "sum":"∑","prod":"∏","int":"∫","iint":"∬","oint":"∮","infty":"∞","partial":"∂","nabla":"∇","ell":"ℓ","hbar":"ℏ","imath":"ı","jmath":"ȷ",
            "times":"×","cdot":"⋅","otimes":"⊗","oplus":"⊕","pm":"±","mp":"∓","div":"÷","le":"≤","leq":"≤","ge":"≥","geq":"≥","neq":"≠","ne":"≠","approx":"≈","sim":"∼","simeq":"≃","equiv":"≡","propto":"∝","in":"∈","notin":"∉","subset":"⊂","subseteq":"⊆","supset":"⊃","cup":"∪","cap":"∩","emptyset":"∅","forall":"∀","exists":"∃",
            "to":"→","rightarrow":"→","leftarrow":"←","mapsto":"↦","Rightarrow":"⇒","Leftrightarrow":"⇔","mid":"|","vert":"|","Vert":"‖","lVert":"‖","rVert":"‖","lvert":"|","rvert":"|","langle":"⟨","rangle":"⟩","lceil":"⌈","rceil":"⌉","lfloor":"⌊","rfloor":"⌋","lbrace":"{","rbrace":"}","ldots":"…","cdots":"⋯","vdots":"⋮","ddots":"⋱","top":"⊤","perp":"⊥","prime":"′","star":"⋆"
        ]
    }
}
