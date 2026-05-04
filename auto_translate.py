import os
import re
import time
from deep_translator import GoogleTranslator

# 1. Parse messages.dart to extract the EN map
with open('lib/app/core/translations/messages.dart', 'r', encoding='utf-8') as f:
    messages_content = f.read()

# Find the EN map block: 'en': { ... }
en_block_match = re.search(r"'en':\s*\{([\s\S]*?)\},", messages_content)
if not en_block_match:
    print("Could not find EN map block.")
    exit(1)

en_block = en_block_match.group(1)

# Extract key-value pairs
# We'll use a regex that handles single quotes containing escaped single quotes or not
# 'key': 'value'
en_map = {}
# simple line-by-line parsing:
lines = en_block.split('\n')
for line in lines:
    line = line.strip()
    if not line: continue
    if line.startswith('//'): continue
    
    match = re.match(r"'([a-zA-Z0-9_]+)'\s*:\s*'(.*?)',?$", line)
    if match:
        en_map[match.group(1)] = match.group(2)

print(f"Extracted {len(en_map)} English keys.")

# 2. Languages mapping
langs_map = {
    'fr_fr': 'fr',
    'es_es': 'es',
    'ru_ru': 'ru',
    'hi_in': 'hi'
}

for file_name, lang_code in langs_map.items():
    file_path = f'lib/app/core/translations/{file_name}.dart'
    if not os.path.exists(file_path):
        continue
        
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # extract existing keys
    existing_keys = set(re.findall(r"'([a-zA-Z0-9_]+)'\s*:", content))
    
    missing_keys = [k for k in en_map.keys() if k not in existing_keys]
    
    if not missing_keys:
        print(f"[{file_name}] No missing keys.")
        continue
        
    print(f"[{file_name}] Translating {len(missing_keys)} keys to {lang_code}...")
    
    # Translate and append
    translator = GoogleTranslator(source='en', target=lang_code)
    
    appended_content = ""
    for k in missing_keys:
        en_text = en_map[k]
        # Skip empty or variables only
        if not en_text.strip():
            translated = ""
        elif en_text.count('@') > 0 and len(en_text) < 10:
            translated = en_text # leave variables as is if it's mostly variable
        else:
            try:
                translated = translator.translate(en_text)
            except Exception as e:
                print(f"Error translating {k}: {e}")
                translated = en_text
                time.sleep(1)
        
        # fix quotes
        translated = translated.replace("'", "\\'") if translated else ""
        appended_content += f"  '{k}': '{translated}',\n"
    
    # insert before the closing brace
    content = content.replace('\n};', f'\n{appended_content}}};')
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"[{file_name}] Saved successfully!")
