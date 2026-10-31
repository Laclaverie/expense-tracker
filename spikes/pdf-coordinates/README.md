# Spike: coordinate-based PDF parsing (Python)

Throwaway reference implementation, **not shipped**. Proves that Desjardins statements can be parsed reliably
using word coordinates, and that statement self-checks (running balances, totals) validate the result.
See [docs/09-tech-choices.md](../../docs/09-tech-choices.md) for results.

```sh
uv run python -I spike_parse.py path/to/statements/*.pdf   # one summary line per file, no personal data
uv run python -I dump_rows.py statement.pdf [pages]        # prints rows with x positions — CONTAINS PERSONAL DATA, do not commit output
```

Real statements stay outside the repo.
