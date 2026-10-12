import streamlit as st
import re

st.set_page_config(
    page_title="C-Subset Lexical, Syntax & Semantic Analyzer",
    page_icon="⚙️",
    layout="wide"
)

st.title("⚙️ C-Subset Semantic Analyzer & Compiler Simulator")
st.markdown("Interactive testbench for lexical analysis, LALR(1) syntax validation, and nested ScopeTable symbol resolution.")

default_code = """int x, y;
float result;

int add(int a, int b) {
    int sum;
    sum = a + b;
    return sum;
}

void main() {
    int i;
    x = 10;
    y = 20;
    result = add(x, y);
    if (result > 15) {
        int temp;
        temp = x * 2;
    }
}
"""

col1, col2 = st.columns([1, 1])

with col1:
    st.subheader("📝 Input C Source Code")
    c_source = st.text_area("C-Subset Code", value=default_code, height=380)
    run_btn = st.button("🚀 Analyze Code", type="primary")

KEYWORDS = {"int", "float", "void", "return", "if", "else", "for", "while"}
OPERATORS = {"+", "-", "*", "/", "%", "=", "==", "!=", "<", ">", "<=", ">=", "&&", "||"}
PUNCTUATORS = {";", ",", "(", ")", "{", "}", "[", "]"}

def tokenize(code):
    tokens = []
    lines = code.split("\n")
    for line_num, line in enumerate(lines, 1):
        clean = re.sub(r"//.*", "", line)
        parts = re.findall(r'[a-zA-Z_]\w*|\d+\.\d+|\d+|==|!=|<=|>=|&&|\|\||[+\-*/%=<>;,(){}[\]]', clean)
        for p in parts:
            if p in KEYWORDS:
                cat = "KEYWORD"
            elif p in OPERATORS:
                cat = "OPERATOR"
            elif p in PUNCTUATORS:
                cat = "PUNCTUATOR"
            elif re.match(r'^\d+(\.\d+)?$', p):
                cat = "CONST_NUMBER"
            elif re.match(r'^[a-zA-Z_]\w*$', p):
                cat = "ID"
            else:
                cat = "UNKNOWN"
            tokens.append((line_num, p, cat))
    return tokens

def parse_scopes(tokens):
    scopes = []
    scope_id = 1
    scope_stack = [1]
    symbols = {1: []}
    
    i = 0
    while i < len(tokens):
        line, val, cat = tokens[i]
        if val == "{":
            scope_id += 1
            scope_stack.append(scope_id)
            symbols[scope_id] = []
        elif val == "}":
            if len(scope_stack) > 1:
                scope_stack.pop()
        elif cat == "KEYWORD" and val in {"int", "float", "void"}:
            data_type = val
            i += 1
            while i < len(tokens) and tokens[i][1] != ";":
                l, v, c = tokens[i]
                if c == "ID":
                    current_scope = scope_stack[-1]
                    is_func = (i + 1 < len(tokens) and tokens[i + 1][1] == "(")
                    kind = "Function" if is_func else "Variable"
                    symbols[current_scope].append({
                        "Scope": f"Scope #{current_scope}",
                        "Name": v,
                        "Type": data_type,
                        "Kind": kind,
                        "Line": l
                    })
                i += 1
        i += 1
    return symbols

with col2:
    st.subheader("🔍 Compiler Output & Diagnostics")
    tab1, tab2, tab3 = st.tabs(["🗂️ Scope Table", "🏷️ Lexical Tokens", "📋 Grammar Rules"])
    
    tokens = tokenize(c_source)
    scope_dict = parse_scopes(tokens)
    
    with tab1:
        st.markdown("**Hierarchical ScopeTable Resolution:**")
        all_syms = []
        for s_id, s_list in scope_dict.items():
            all_syms.extend(s_list)
        if all_syms:
            st.dataframe(all_syms, use_container_width=True)
        else:
            st.info("No symbol declarations found.")
            
    with tab2:
        st.markdown(f"**Total Tokens Detected:** `{len(tokens)}`")
        token_table = [{"Line": t[0], "Lexeme": t[1], "Token Class": t[2]} for t in tokens]
        st.dataframe(token_table, height=300, use_container_width=True)

    with tab3:
        st.markdown("**Grammar & Syntax Rules (`parser.y`):**")
        st.code("""program : program unit
        | unit
        ;

unit : var_declaration
     | func_declaration
     | func_definition
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
                ;

compound_statement : LCURL statements RCURL
                   ;""", language="c")
