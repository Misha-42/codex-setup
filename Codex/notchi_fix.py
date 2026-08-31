import re
p = r'C:\Users\user\Desktop\codex-stack\tmp\notchi-win\windows\app.py'
with open(p, 'r', encoding='utf-8') as f: text = f.read()
# Replace animation base values (double each)
text = text.replace('"working": 95,', '"working": 190,')
text = text.replace('"waiting": 120,', '"waiting": 240,')
text = text.replace('"compacting": 140,', '"compacting": 280,')
text = text.replace('"sleeping": 220,', '"sleeping": 440,')
text = text.replace('"idle": 130,', '"idle": 260,')
with open(p, 'w', encoding='utf-8') as f: f.write(text)
print('Done')
