# C-Subset Semantic Analyzer & Compiler Suite

A multi-phase compiler front-end and semantic analysis engine for a structured subset of the C programming language. Engineered using **GNU Flex (Lex)** for lexical analysis, **Bison (Yacc)** for LALR(1) syntax directed translation, dynamic hash-based **ScopeTable** symbol management, and deployed with an interactive **Streamlit** diagnostic testbench.

---

## 🚀 Live Interactive Simulator
Test tokenization, grammar parsing, and symbol scope allocations in real time:  
👉 **[Launch Streamlit Compiler Testbench](https://c-subset-semantic-analyzer.streamlit.app)**

---

## 📌 Architecture & Features

### 1. Lexical Analysis (`lexer.l`)
- Tokenizes identifiers, keywords (`int`, `float`, `void`, `return`, `if`, `else`, `for`, `while`), floating-point and integer constants.
- Strips single-line (`//`) and multi-line (`/* ... */`) comments while accurately tracking line counts for compile-time diagnostic reporting.
- Handles operators (relational, arithmetic, logical, assignment) and punctuation tokens.

### 2. Syntax & Semantic Grammar (`parser.y`)
- Implements an LALR(1) context-free grammar covering declarations, function definitions, compound statements, branching controls, and expression hierarchies.
- Validates semantic constraints:
  - **Type Checking:** Ensures operand-operator compatibility and validates return types against function signatures.
  - **Declaration Verification:** Detects undeclared variables, multiple declarations within the same scope, and function parameter mismatches.
  - **Syntax Error Recovery:** Emits formatted error logs with specific line numbers without immediately aborting the parse loop.

### 3. Hierarchical Symbol Table Engine
- **`SymbolInfo` (`symbol_info.h`):** Encapsulates token names, data types, parameter lists, array bounds, and pointer/variable classifications.
- **`ScopeTable` (`scope_table.h`):** Separate-chaining hash table with custom bucket distribution for $O(1)$ average insertion and lookup within a local block.
- **`SymbolTable` (`symbol_table.h`):** Dynamic stack of parent-child `ScopeTable` scopes. Implements `Enter_Scope()`, `Exit_Scope()`, `Insert()`, and parent-traversing `Look_Up()` to resolve lexical scoping and identifier shadowing.

---

## 📂 Repository File Structure

```text
.
├── lexer.l             # GNU Flex lexical specification
├── parser.y            # Bison LALR(1) grammar & semantic action routines
├── symbol_info.h       # Symbol token and identifier metadata representation
├── scope_table.h       # Hash-based scoped bucket implementation
├── symbol_table.h      # Nested scope stack manager
├── input.c             # Sample C-subset source program for verification
├── script.sh           # Native GCC/Clang build and execution shell script
├── app.py              # Streamlit Cloud interactive testbench & AST/Scope visualizer
├── requirements.txt    # Cloud runtime dependencies
└── README.md           # Technical documentation
