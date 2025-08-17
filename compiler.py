# c2bf.py - toy C -> Brainfuck translator
# Features: main(), putchar('X'), getchar(), user functions
# Writes output to file specified as argv[2]

import sys, re

def char_to_bf(ch: str) -> str:
    """Generate BF to print a character"""
    ascii_val = ord(ch)
    return "+" * ascii_val + "."

def parse_function(src: str):
    """Extract function name and body"""
    match = re.match(r"\s*(?:int|void)\s+(\w+)\s*\(\)\s*{([^}]*)}", src, re.S)
    if match:
        return match.group(1), match.group(2)
    return None, None

def translate_body(body: str, funcs: dict) -> str:
    bf = ""
    # handle putchar
    for call in re.finditer(r"putchar\('(.)'\);", body):
        bf += char_to_bf(call.group(1))
    # handle getchar
    if "getchar();" in body:
        bf += ","
    # handle function calls
    for f in funcs:
        if re.search(rf"\b{f}\s*\(\s*\)\s*;", body):
            bf += funcs[f]  # inline expansion
    return bf

def compile_c_to_bf(src: str) -> str:
    funcs = {}
    # find all functions
    for func_src in re.findall(r"(?:int|void)\s+\w+\s*\(\)\s*{[^}]*}", src, re.S):
        name, body = parse_function(func_src)
        if name and body:
            funcs[name] = ""  # placeholder
    
    # fill function bodies
    for func_src in re.findall(r"(?:int|void)\s+\w+\s*\(\)\s*{[^}]*}", src, re.S):
        name, body = parse_function(func_src)
        if name and body:
            funcs[name] = translate_body(body, funcs)

    return funcs.get("main", "")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 c2bf.py input.c output.bf")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file) as f:
        src = f.read()

    bf_code = compile_c_to_bf(src)

    with open(output_file, "w") as f:
        f.write(bf_code)

    print(f"Brainfuck code written to {output_file}")
