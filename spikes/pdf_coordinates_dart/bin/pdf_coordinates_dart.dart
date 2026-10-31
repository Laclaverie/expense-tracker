// Spike: extract words with coordinates using PDFium (pdfium_dart FFI) and
// print rows, for comparison with the Python/pdfplumber spike.
//
// Usage: dart run bin/pdf_coordinates_dart.dart [--compact] <pdf> [<pdf> ...]
//   default   rows as "top word@x word@x ..." (same format as dump_rows.py)
//   --compact one line per row, whitespace removed (for diffing)
// Output CONTAINS PERSONAL DATA when run on real statements: never commit it.
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart';

class Word {
  Word(this.text, this.x0, this.x1, this.y);
  String text;
  final double x0;
  double x1;

  /// Baseline, measured from the top of the page.
  final double y;
}

final pdfium = getPdfium();

List<List<Word>> rowsOf(FPDF_PAGE page) {
  final height = pdfium.FPDF_GetPageHeightF(page);
  final text = pdfium.FPDFText_LoadPage(page);
  final ox = calloc<Double>(), oy = calloc<Double>();
  final box = calloc<FS_RECTF>();
  final words = <Word>[];
  try {
    Word? cur;
    final n = pdfium.FPDFText_CountChars(text);
    for (var i = 0; i < n; i++) {
      final c = String.fromCharCode(pdfium.FPDFText_GetUnicode(text, i));
      if (c.trim().isEmpty) {
        cur = null; // PDFium emits spaces between words and columns
        continue;
      }
      pdfium.FPDFText_GetCharOrigin(text, i, ox, oy);
      pdfium.FPDFText_GetLooseCharBox(text, i, box);
      final x0 = box.ref.left, x1 = box.ref.right, y = height - oy.value;
      if (cur != null && x0 - cur.x1 <= 1.0 && (y - cur.y).abs() < 1.0) {
        cur.text += c;
        cur.x1 = x1;
      } else {
        cur = Word(c, x0, x1, y);
        words.add(cur);
      }
    }
  } finally {
    calloc.free(ox);
    calloc.free(oy);
    calloc.free(box);
    pdfium.FPDFText_ClosePage(text);
  }
  words.sort((a, b) {
    final t = a.y.compareTo(b.y);
    return (a.y - b.y).abs() < 2.5 ? a.x0.compareTo(b.x0) : t;
  });
  final rows = <List<Word>>[];
  for (final w in words) {
    if (rows.isNotEmpty && (rows.last.first.y - w.y).abs() < 2.5) {
      rows.last.add(w);
    } else {
      rows.add([w]);
    }
  }
  for (final r in rows) {
    r.sort((a, b) => a.x0.compareTo(b.x0));
  }
  return rows;
}

void main(List<String> args) {
  final compact = args.contains('--compact');
  pdfium.FPDF_InitLibrary();
  for (final path in args.where((a) => a != '--compact')) {
    final cPath = path.toNativeUtf8();
    final doc = pdfium.FPDF_LoadDocument(cPath.cast(), nullptr);
    calloc.free(cPath);
    if (doc == nullptr) throw StateError('Cannot open $path');
    for (var p = 0; p < pdfium.FPDF_GetPageCount(doc); p++) {
      final page = pdfium.FPDF_LoadPage(doc, p);
      if (!compact) print('--- page $p');
      for (final row in rowsOf(page)) {
        if (compact) {
          print(row.map((w) => w.text).join());
        } else {
          print('${row.first.y.toStringAsFixed(1).padLeft(6)} '
              '${row.map((w) => '${w.text}@${w.x0.round()}').join(' ')}');
        }
      }
      pdfium.FPDF_ClosePage(page);
    }
    pdfium.FPDF_CloseDocument(doc);
  }
  pdfium.FPDF_DestroyLibrary();
}
