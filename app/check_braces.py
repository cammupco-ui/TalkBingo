
import sys

def check_balance(filename):
    stack = []
    
    with open(filename, 'r') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        line_num = i + 1
        for j, char in enumerate(line):
            if char in '([{':
                stack.append((char, line_num, j))
            elif char in ')]}':
                if not stack:
                    print(f"Error: Unmatched '{char}' at line {line_num}:{j+1}")
                    return
                
                last, last_line, last_col = stack.pop()
                expected = {'(':')', '[':']', '{':'}'}[last]
                if char != expected:
                    print(f"Error: Mismatched '{char}' at line {line_num}:{j+1}. Expected '{expected}' to match '{last}' from line {last_line}:{last_col+1}")
                    return

    if stack:
        print("Error: Unclosed items remaining:")
        for char, line_num, col in stack:
            print(f"  '{char}' from line {line_num}:{col+1}")

check_balance('temp_game.dart')
