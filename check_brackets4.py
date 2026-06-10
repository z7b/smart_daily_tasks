import re

with open('lib/app/modules/keep/views/keep_view.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def find_what_popped(s, target_line):
    stack = []
    # remove comments and strings to avoid false positives!
    s = re.sub(r'//.*', '', s)
    s = re.sub(r'\'[^\']*\'', '', s)
    s = re.sub(r'\"[^\"]*\"', '', s)
    
    lines = s.split('\n')
    for line_idx, line in enumerate(lines):
        for char_idx, char in enumerate(line):
            if char in '({[':
                stack.append((char, line_idx + 1, char_idx + 1))
            elif char in ')}]':
                if stack:
                    popped = stack.pop()
                    if line_idx + 1 == target_line:
                        print(f"Line {target_line} char {char_idx + 1} '{char}' closed {popped[0]} from line {popped[1]}:{popped[2]}")

find_what_popped(text, 569)
find_what_popped(text, 568)
find_what_popped(text, 567)
find_what_popped(text, 566)
