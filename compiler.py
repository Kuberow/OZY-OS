# c2bf_expr.py - C->BF translator with variables and char expressions
import sys, re

# Map variable names to BF tape cells
var_cells = {}
next_cell = 0

def get_cell(var):
    global next_cell
    if var not in var_cells:
        var_cells[var] = next_cell
        next_cell += 1
    return var_cells[var]

def move_ptr(current, target):
    if target > current:
        return ">" * (target - current)
    elif target < current:
        return "<" * (current - target)
    return ""

def set_var_from_expr(var, expr, current_ptr):
    """Handle expressions like 'b' + 'h' + getchar() + another_var"""
    cell = get_cell(var)
    bf = move_ptr(current_ptr, cell) + "[-]"  # clear target cell
    current_ptr = cell

    # split expr by '+' and remove spaces
    terms = [t.strip() for t in expr.split('+')]
    for term in terms:
        # constant character
        m = re.match(r"'(.)'", term)
        if m:
            bf += "+" * ord(m.group(1))
        # getchar()
        elif term == "getchar()":
            bf += ","  # read input and add to cell
        # another variable
        else:
            vcell = get_cell(term)
            # move to temp cell, copy value and add (simplified, adds directly to target)
            bf += move_ptr(current_ptr, vcell) + "[->+" + "<"*(current_ptr - vcell) + "]"
            bf += move_ptr(vcell, current_ptr)
    return bf, current_ptr

def parse_line(line, current_ptr):
    line = line.strip()
    bf = ""

    # putchar(var)
    m = re.match(r"putchar\((\w+)\);", line)
    if m:
        var = m.group(1)
        cell = get_cell(var)
        bf += move_ptr(current_ptr, cell) + "."
        current_ptr = cell
        return bf, current_ptr

    # assignment: var = expr;
    m = re.match(r"(\w+)\s*=\s*(.*);", line)
    if m:
        var, expr = m.group(1), m.group(2)
        bf_chunk, current_ptr = set_var_from_expr(var, expr, current_ptr)
        bf += bf_chunk
        return bf, current_ptr

    return "", current_ptr

def compile_c_to_bf(src):
    bf = ""
    current_ptr = 0
    for line in src.splitlines():
        chunk, current_ptr = parse_line(line, current_ptr)
        bf += chunk
    return bf

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 c2bf_expr.py input.c output.bf")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file) as f:
        src = f.read()

    bf_code = compile_c_to_bf(src)

    with open(output_file, "w") as f:
        f.write(bf_code)

    print(f"Brainfuck code written to {output_file}")
