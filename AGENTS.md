# Instructions for coding agents

Read `CLAUDE.md` (project rules for any agent, not only Claude) and `CONTRIBUTING.md`.

Adding a bank or a statement type: follow [docs/10-adding-a-bank.md](docs/10-adding-a-bank.md) step by step.
Its privacy rules are non-negotiable: real statements and tool output with personal data never leave the
owner's machine and never enter the repository. A cloud agent never reads statements or `banks:dump` /
`banks:parse -v` output: it works from `banks:shape` (`--facts` for a CSV), `banks:check` and `banks:compare`
(doc 10 §0b). The step-by-step checklist
(Claude Code: `/add-bank`) is `.claude/skills/add-bank/SKILL.md`; other agents can follow the same file.
