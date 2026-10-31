"""Spike: coordinate-based parsing of Desjardins statements + self-validation.

Usage: python spike_parse.py <pdf> [<pdf> ...]
Prints one summary line per file (no personal data).
"""
import re
import sys
import pdfplumber

NUM = re.compile(r'^\d{1,3}$')
AMT_DOT = re.compile(r'^\d+\.\d{2}-?$')
AMT_COMMA = re.compile(r'^\d+,\d{2}(CR)?$')
MONTHS = {'JAN': 1, 'FEV': 2, 'MAR': 3, 'AVR': 4, 'MAI': 5, 'JUN': 6, 'JUL': 7,
          'AOU': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12}


def rows_of(page):
    words = page.extract_words(x_tolerance=1.5)
    rows = []
    for w in sorted(words, key=lambda w: (round(w['top']), w['x0'])):
        if rows and abs(rows[-1][0] - w['top']) < 2.5:
            rows[-1][1].append(w)
        else:
            rows.append([w['top'], [w]])
    out = []
    for top, ws in rows:
        ws.sort(key=lambda w: w['x0'])
        out.append(merge_thousands(ws))
    return out


def merge_thousands(ws):
    """'2' + '098.68' -> '2098.68' when adjacent (thousands separator is a space)."""
    merged = []
    for w in ws:
        if merged and NUM.match(merged[-1]['text']) and re.match(r'^\d{3}[.,]\d{2}', w['text']) \
                and w['x0'] - merged[-1]['x1'] < 6:
            prev = merged.pop()
            w = dict(w, text=prev['text'] + w['text'], x0=prev['x0'])
        merged.append(w)
    return merged


def cents(text):
    neg = text.endswith('-')
    t = text.rstrip('-').replace('CR', '').replace(',', '.')
    v = round(float(t) * 100)
    return -v if neg else v


# ---------------------------------------------------------------- account
def parse_account(pdf):
    sections, cur, cols = [], None, None
    for page in pdf.pages:
        for ws in rows_of(page):
            texts = [w['text'] for w in ws]
            if 'Retrait' in texts and 'Solde' in texts:
                cols = {w['text'][:3]: w['x1'] for w in ws if w['text'][:3] in ('Fra', 'Ret', 'D�p', 'Dép', 'Sol')}
                continue
            if texts[:2] == ['Solde', 'report�'] or texts[:2] == ['Solde', 'reporté']:
                amts = [w for w in ws if AMT_DOT.match(w['text'])]
                cur = {'opening': cents(amts[-1]['text']) if amts else 0, 'lines': []}
                sections.append(cur)
                continue
            if cur is None or not cols:
                continue
            is_tx = len(texts) > 2 and texts[0].isdigit() and texts[1] in MONTHS
            amts = [w for w in ws if AMT_DOT.match(w['text'])]
            if is_tx:
                line = {'day': int(texts[0]), 'month': MONTHS[texts[1]], 'code': texts[2],
                        'desc': [w['text'] for w in ws[3:] if not AMT_DOT.match(w['text'])],
                        'fee': 0, 'out': 0, 'in': 0, 'balance': None}
                cur['lines'].append(line)
            elif cur['lines'] and amts and len(texts) > len(amts):
                line = cur['lines'][-1]  # wrapped description carrying amounts
                line['desc'] += [w['text'] for w in ws if not AMT_DOT.match(w['text'])]
            elif cur['lines'] and not amts and ws[0]['x0'] > 100 and ws[0]['x0'] < 300:
                cur['lines'][-1]['desc'] += texts
                continue
            else:
                continue
            for a in amts:  # column = nearest header right edge
                col = min(cols, key=lambda c: abs(cols[c] - a['x1']))
                key = {'Fra': 'fee', 'Ret': 'out', 'Sol': 'balance'}.get(col, 'in')
                line[key] = cents(a['text'])
    # validate running balances
    errors, n = 0, 0
    for s in sections:
        bal = s['opening']
        for l in s['lines']:
            n += 1
            bal = bal - l['fee'] - l['out'] + l['in']
            if l['balance'] is not None:
                if l['balance'] != bal:
                    errors += 1
                bal = l['balance']
    return f"account sections={len(sections)} lines={n} balance_errors={errors}"


# ---------------------------------------------------------------- card
def parse_card(pdf):
    purchases, credits, declared = [], [], {}
    section = None
    for page in pdf.pages:
        for ws in rows_of(page):
            texts = [w['text'] for w in ws]
            joined = ' '.join(texts)
            if texts[0] in ('Achats', 'Paiements', 'Solde', 'Nouveau') and texts[0] not in declared:
                v = [w for w in ws if 200 < w['x0'] < 290 and AMT_COMMA.match(w['text'])]
                if v:
                    declared[texts[0]] = cents(v[0]['text'])
            if joined.startswith('Transactions effectu'):
                section = 'purchases'
            elif joined.startswith('Op�rations au compte') or joined.startswith('Opérations au compte'):
                section = 'credits'
            elif texts[0] == 'TOTAL':
                declared['TOTAL'] = declared.get('TOTAL', 0) + cents(texts[-1])
            is_tx = len(texts) > 5 and all(t.isdigit() and len(t) == 2 for t in texts[:4])
            if is_tx and AMT_COMMA.match(texts[-1]):
                line = {'tx': (int(texts[0]), int(texts[1])), 'posted': (int(texts[2]), int(texts[3])),
                        'amount': cents(texts[-1]), 'credit': texts[-1].endswith('CR'),
                        'desc': [w['text'] for w in ws[4:] if w['x0'] < 340],
                        'loc': [w['text'] for w in ws if 340 <= w['x0'] < 430],
                        'bonus': next((w['text'] for w in ws if 430 <= w['x0'] < 480), None)}
                line['section'] = section
                (credits if line['credit'] else purchases).append(line)
            elif 'DOLLAR' in texts or 'TX:' in texts:
                if purchases:
                    purchases[-1]['foreign'] = joined
    total = sum(l['amount'] for l in purchases)
    paid = sum(l['amount'] for l in credits)
    refunds = sum(l['amount'] for l in credits if l['section'] == 'purchases')
    checks = {
        'sum=TOTAL': sum(l['amount'] for l in purchases if l['section'] == 'purchases') - refunds
                     == declared.get('TOTAL', 0) or not purchases,
        'sum=Achats': total == declared.get('Achats'),
        'credits=Paiements': paid == declared.get('Paiements'),
        'balance': declared.get('Solde', 0) + declared.get('Achats', 0) - declared.get('Paiements', 0)
                   == declared.get('Nouveau'),
    }
    fx = sum(1 for l in purchases if 'foreign' in l)
    bad = [k for k, v in checks.items() if not v]
    return (f"card purchases={len(purchases)} credits={len(credits)} foreign={fx} "
            f"checks={'OK' if not bad else 'FAIL ' + ','.join(bad)}"
            + (f" [net={total - refunds} TOTAL={declared.get('TOTAL')} refunds={refunds}"
               f" cr_sections={[l['section'] for l in credits]}]" if bad else ''))


if __name__ == '__main__':
    for path in sys.argv[1:]:
        with pdfplumber.open(path) as pdf:
            first = pdf.pages[0].extract_text() or ''
            kind = 'card' if 'ODYSSEE WORLDELITE' in first.upper() else 'account'
            try:
                res = parse_card(pdf) if kind == 'card' else parse_account(pdf)
            except Exception as e:  # spike: report and continue
                res = f"{kind} ERROR {type(e).__name__}: {e}"
        print(f"{path.replace(chr(92), '/').split('/')[-1][:14]:15} {res}")
