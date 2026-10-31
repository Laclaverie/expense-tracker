import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart';

import 'words.dart';

PDFium? _pdfium;

PDFium _lib() {
  if (_pdfium == null) {
    _pdfium = getPdfium();
    _pdfium!.FPDF_InitLibrary();
  }
  return _pdfium!;
}

/// Extracts the words of every page of the PDF at [path] using PDFium.
///
/// Rows are built from each character's origin (baseline), not its glyph box:
/// glyph boxes are tight around the ink, so `.`, `-` and `'` would land on a
/// different line than the digits and letters around them.
DocumentWords extractWords(String path) {
  final pdfium = _lib();
  final cPath = path.toNativeUtf8();
  final doc = pdfium.FPDF_LoadDocument(cPath.cast(), nullptr);
  calloc.free(cPath);
  if (doc == nullptr) {
    throw FormatException('cannot open PDF (error ${pdfium.FPDF_GetLastError()})', path);
  }
  try {
    return DocumentWords([for (var i = 0; i < pdfium.FPDF_GetPageCount(doc); i++) _page(pdfium, doc, i)]);
  } finally {
    pdfium.FPDF_CloseDocument(doc);
  }
}

PageWords _page(PDFium pdfium, FPDF_DOCUMENT doc, int index) {
  final page = pdfium.FPDF_LoadPage(doc, index);
  final width = pdfium.FPDF_GetPageWidthF(page);
  final height = pdfium.FPDF_GetPageHeightF(page);
  final text = pdfium.FPDFText_LoadPage(page);
  final ox = calloc<Double>(), oy = calloc<Double>();
  final box = calloc<FS_RECTF>();
  final words = <Word>[];
  try {
    StringBuffer? buf;
    late double x0, x1, y;
    void flush() {
      if (buf != null) words.add(Word(buf.toString(), x0, x1, y));
      buf = null;
    }

    final n = pdfium.FPDFText_CountChars(text);
    for (var i = 0; i < n; i++) {
      final c = String.fromCharCode(pdfium.FPDFText_GetUnicode(text, i));
      if (c.trim().isEmpty) {
        flush(); // PDFium emits spaces between words and columns
        continue;
      }
      pdfium.FPDFText_GetCharOrigin(text, i, ox, oy);
      pdfium.FPDFText_GetLooseCharBox(text, i, box);
      final cy = height - oy.value;
      if (buf != null && box.ref.left - x1 <= 1.0 && (cy - y).abs() < 1.0) {
        buf!.write(c);
        x1 = box.ref.right;
      } else {
        flush();
        buf = StringBuffer(c);
        x0 = box.ref.left;
        x1 = box.ref.right;
        y = cy;
      }
    }
    flush();
  } finally {
    calloc.free(ox);
    calloc.free(oy);
    calloc.free(box);
    pdfium.FPDFText_ClosePage(text);
    pdfium.FPDF_ClosePage(page);
  }
  words.sort((a, b) => (a.y - b.y).abs() < 2.5 ? a.x0.compareTo(b.x0) : a.y.compareTo(b.y));
  return PageWords(width, height, words);
}
