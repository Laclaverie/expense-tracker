# Spike: PDF word coordinates in Dart (PDFium)

Throwaway check that Dart + PDFium (`pdfium_dart`) extracts the same rows as the Python spike.
Result in [docs/09-tech-choices.md](../../docs/09-tech-choices.md#dart--pdfium-check-2026-10-17).

```sh
dart run bin/pdf_coordinates_dart.dart statement.pdf            # rows with x positions
dart run bin/pdf_coordinates_dart.dart --compact statement.pdf  # one line per row, for diffing
```

Output **contains personal data** when run on real statements — never commit it.
