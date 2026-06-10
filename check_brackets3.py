import re

with open('lib/app/modules/keep/views/keep_view.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def find_where_popped(s, target_line, target_char):
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
                    if popped[1] == target_line and popped[2] == target_char:
                        print(f"Popped at line {line_idx + 1}:{char_idx + 1}")
                        return

find_where_popped(text, 446, 38)
