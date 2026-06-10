import re

with open('lib/app/modules/keep/views/keep_view.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def find_unmatched(s):
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
                if not stack:
                    return
                top_char, top_line, top_char_idx = stack.pop()
                if (top_char == '(' and char != ')') or \
                   (top_char == '{' and char != '}') or \
                   (top_char == '[' and char != ']'):
                    print(f'Mismatched {char} at line {line_idx+1}:{char_idx+1}. Expected {top_char} from {top_line}:{top_char_idx}')
                    return

find_unmatched(text)
