"""Group words into rows by y coordinate and print them, to check alignment."""
import sys
import pdfplumber

path = sys.argv[1]
pages = [int(p) for p in sys.argv[2].split(',')] if len(sys.argv) > 2 else None
with pdfplumber.open(path) as pdf:
    for i, page in enumerate(pdf.pages):
        if pages and i not in pages:
            continue
        words = page.extract_words(keep_blank_chars=False, use_text_flow=False, x_tolerance=1.5)
        rows = []
        for w in sorted(words, key=lambda w: (round(w['top']), w['x0'])):
            if rows and abs(rows[-1][0] - w['top']) < 2.5:
                rows[-1][1].append(w)
            else:
                rows.append([w['top'], [w]])
        print(f'--- page {i}')
        for top, ws in rows:
            ws.sort(key=lambda w: w['x0'])
            print(f'{top:6.1f} ' + ' '.join(f"{w['text']}@{w['x0']:.0f}" for w in ws))
