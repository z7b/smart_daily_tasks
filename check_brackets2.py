import re

with open('lib/app/modules/keep/views/keep_view.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def print_stack_before_line(s, target_line):
    stack = []
    # remove comments and strings to avoid false positives!
    s = re.sub(r'//.*', '', s)
    s = re.sub(r'\'[^\']*\'', '', s)
    s = re.sub(r'\"[^\"]*\"', '', s)
    
    lines = s.split('\n')
    for line_idx, line in enumerate(lines):
        if line_idx + 1 == target_line:
            print("Stack before line", target_line, ":")
            for item in stack:
                print(item)
            return

        for char_idx, char in enumerate(line):
            if char in '({[':
                stack.append((char, line_idx + 1, char_idx + 1))
            elif char in ')}]':
                if stack:
                    stack.pop()

print_stack_before_line(text, 571)
