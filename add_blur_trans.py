import glob
import re

files = glob.glob('lib/app/core/translations/*.dart')

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    if "'keep_blur'" in content:
        continue
    
    # We want to add 'keep_blur': 'Blur (ضبابة)', before the last occurrence of }; in the file, OR 
    # before ANY occurrence of `};` that is followed by the end of the file or another language map.
    # Actually, simpler: replace `'keep_format': '文本格式',` or equivalent with `'keep_format': '文本格式',\n  'keep_blur': 'Blur (ضبابة)',`
    
    # First, let's just use regex to insert it right before the last };
    idx = content.rfind('};')
    if idx != -1:
        updated = content[:idx] + "  'keep_blur': 'Blur (ضبابة)',\n" + content[idx:]
        with open(f, 'w', encoding='utf-8') as file:
            file.write(updated)
        print(f"Added keep_blur to {f}")
