"""سجل كتب الوزارة: كل كتاب (المرحلة، الصف، الترم، المادة، السنة، الرابط، تاريخ المراجعة) من
studentbooks.moe.gov.eg، ومعاه الكتاب المقابل في التطبيق لو موجود.

  python3 tool/curriculum_registry.py              # يحدّث tool/curriculum/books-2026-2027.json
  python3 tool/curriculum_registry.py --dry-run    # يطبع اللي اتغيّر من غير ما يكتب

الموقع بيعرض الكتب من ملف books.json في كل قسم. لو الوزارة نشرت الترم التاني أو غيّرت رابط،
الملف هنا بيتغيّر والمراجعة بتبان في git. الكتب نفسها ماتتحمّلش هنا — بس فهرسها.
"""
import argparse
import datetime
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'tool/curriculum/books-2026-2027.json'
YEAR = '2026/2027'
SECTIONS = {
    'kg': 'https://studentbooks.moe.gov.eg/Books/Books-Kindergarten/books.json',
    'primary': 'https://studentbooks.moe.gov.eg/Books/Books-Primary/books.json',
}

GRADES = {
    'مستوى أول': 'kg1', 'مستوى ثان': 'kg2',
    'الصف الأول الابتدائي': 'p1', 'الصف الثاني الابتدائي': 'p2', 'الصف الثالث الابتدائي': 'p3',
    'الصف الرابع الابتدائي': 'p4', 'الصف الخامس الابتدائي': 'p5', 'الصف السادس الابتدائي': 'p6',
}
TERMS = {'الفصل الدراسى الأول': 1, 'الفصل الدراسي الأول': 1, 'الفصل الدراسى الثانى': 2, 'الفصل الدراسي الثاني': 2}

# المادة في التطبيق (نفس أسماء العوالم في lib/content/school_curriculum.dart)
APP_SUBJECTS = {
    'اللغة العربية': 'arabic',
    'اللغة الإنجليزية': 'english',
    'اللغة الإنجليزية-لغة أجنبية أولى': 'english',
    'الرياضيات باللغة العربية': 'math',
}


def fetch(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (rehlati curriculum registry)'})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode('utf-8-sig'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    today = datetime.date.today().isoformat()
    books = []
    for stage, url in SECTIONS.items():
        for b in fetch(url):
            grade = GRADES.get(b['grade'])
            term = TERMS.get(b['term'])
            if grade is None or term is None:
                sys.exit(f'unknown grade or term: {b["grade"]} / {b["term"]} — add it to GRADES/TERMS')
            app = APP_SUBJECTS.get(b['subject'])
            books.append({
                'grade': grade,
                'term': term,
                'subject': b['subject'],
                'type': b['type'],
                'year': YEAR,
                'url': b['link'],
                'app_book': f'{grade}-t{term}-{app}' if app and not grade.startswith('kg') else None,
                'source': url,
                'checked': today,
            })
    order = list(GRADES.values())
    books.sort(key=lambda b: (order.index(b['grade']), b['term'], b['subject'], b['type']))
    old = json.loads(OUT.read_text(encoding='utf-8')) if OUT.exists() else {'books': []}
    strip = lambda l: [{k: v for k, v in b.items() if k != 'checked'} for b in l]
    changed = strip(old['books']) != strip(books)
    print(f'{len(books)} books, {sum(1 for b in books if b["app_book"])} with an app book —',
          'changed' if changed else 'no change')
    if not args.dry_run:
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(json.dumps({'year': YEAR, 'books': books}, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
