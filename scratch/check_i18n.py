import json
import os

files = [
    'assets/i18n/en.json',
    'assets/i18n/ar.json',
    'assets/i18n/bn.json',
    'assets/i18n/ur.json'
]

def get_keys(d, prefix=''):
    keys = set()
    for k, v in d.items():
        if isinstance(v, dict):
            keys.update(get_keys(v, prefix + k + '.'))
        else:
            keys.add(prefix + k)
    return keys

all_keys = {}
for f in files:
    try:
        if not os.path.exists(f):
            print(f"Error: {f} does not exist")
            continue
        with open(f, 'r', encoding='utf-8') as jf:
            data = json.load(jf)
            all_keys[f] = get_keys(data)
    except Exception as e:
        print(f"Error reading {f}: {e}")

if not all_keys:
    print("No files read successfully.")
    exit(1)

master_file = files[0]
if master_file not in all_keys:
    master_file = list(all_keys.keys())[0]

master_keys = all_keys[master_file]

print(f"Master file: {master_file} ({len(master_keys)} keys)")

for f in files:
    if f == master_file: continue
    if f not in all_keys: continue
    
    keys = all_keys[f]
    missing = master_keys - keys
    extra = keys - master_keys
    
    if not missing and not extra:
        print(f"PASS: {f} is perfectly consistent.")
    else:
        if missing:
            print(f"FAIL: {f} is missing {len(missing)} keys:")
            for m in sorted(list(missing)):
                print(f"  - {m}")
        if extra:
            print(f"WARN: {f} has {len(extra)} extra keys:")
            for e in sorted(list(extra)):
                print(f"  + {e}")
