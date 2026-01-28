# Differential Fuzzing (MoonBit pug vs pugjs)

This folder contains tooling to run *differential fuzzing* between:

- **candidate**: this repository's MoonBit `Milky2018/pug`
- **reference**: official Node.js `pug@3`

The goal is to find behavioral differences, record them, and then fix them one
by one.

## Run

```bash
python3 scripts/pug_diff_fuzz.py -n 500 --seed 1
```

Artifacts:

- `fuzz/out/<timestamp>/mismatches.jsonl` (full mismatch records)
- `fuzz/TODOLIST.md` (grouped summary of the latest run)

## Notes

- The script installs `pug@3` under `.fuzz/pugjs` the first time you run it.
- The fuzzer currently focuses on a small grammar subset (tags, ids/classes,
  attribute shorthands/assignments, indentation-based nesting).

