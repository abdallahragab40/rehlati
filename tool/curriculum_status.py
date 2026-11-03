"""يحدّث عمود الحالة في خرايط المنهج (tool/curriculum/p*-t*.json) من الشرح الموجود في assets/lessons/.

  python3 tool/curriculum_status.py

شغّله بعد ما تضيف شرح أو المدرّس يراجع درس — test/domain/curriculum_map_test.dart بيفشل لو الحالة قديمة.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    content = {}
    for f in (ROOT / 'assets/lessons').glob('*.json'):
        d = json.loads(f.read_text(encoding='utf-8'))
        for l in d['lessons']:
            content[(d['book'], l['key'])] = l

    for path in sorted((ROOT / 'tool/curriculum').glob('p*-t*.json')):
        data = json.loads(path.read_text(encoding='utf-8'))
        changed = 0
        for book in data['books']:
            for unit in book['units']:
                for e in unit['lessons']:
                    found = [content.get((book['book'], k)) for k in e['app']]
                    if not found:
                        status = 'not_in_app'
                    elif all(found):
                        status = 'reviewed' if all(l['review'] == 'reviewed' for l in found) else 'explained'
                    else:
                        status = 'partly_explained' if any(found) else 'indexed'
                    if e['status'] != status:
                        e['status'] = status
                        changed += 1
        path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
        print(f'{path.name}: {changed} changed')


if __name__ == '__main__':
    main()
