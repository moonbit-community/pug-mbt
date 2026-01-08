#!/usr/bin/env python3
"""
Transform tests to add @json.inspect(parse(...)) alongside render tests.

Current pattern:
  let html = render("...")
  @json.inspect(html, content="...")

New pattern:
  inspect(@pug.render("..."), content="...")
  @json.inspect(@pug.parse("..."))
"""

import re
from pathlib import Path

PROJECT_DIR = Path(__file__).parent.parent


def process_file(filepath: Path) -> bool:
    content = filepath.read_text()
    lines = content.split('\n')
    result = []
    changed = False
    i = 0

    while i < len(lines):
        line = lines[i]

        # Pattern 1: Single-line render
        # let html = render("...")
        m = re.match(r'^(\s*)let\s+html\s*=\s*(render(?:_pretty|_with_locals)?)\((.+)\)\s*$', line)
        if m:
            indent, func, args = m.groups()

            # Check next line for @json.inspect(html, content=...)
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                m2 = re.match(r'^\s*@json\.inspect\(html,\s*content=(.+)\)\s*$', next_line)
                if m2:
                    content_val = m2.group(1)

                    # For render_with_locals, extract source for parse
                    if func == 'render_with_locals':
                        # args is like: "source", locals or pug, locals
                        parts = args.rsplit(',', 1)
                        source = parts[0].strip()
                    else:
                        source = args

                    result.append(f'{indent}inspect(@pug.{func}({args}), content={content_val})')
                    result.append(f'{indent}@json.inspect(@pug.parse({source}))')
                    i += 2
                    changed = True
                    continue

        # Pattern 2: Multi-line render with pug variable
        # let pug = #|...
        # let html = render(pug)
        # @json.inspect(html, content=...)
        if re.match(r'^\s*let\s+pug\s*=\s*$', line):
            # Collect the multiline string
            pug_lines = [line]
            j = i + 1
            while j < len(lines) and lines[j].strip().startswith('#|'):
                pug_lines.append(lines[j])
                j += 1

            # Check for let html = render(pug)
            if j < len(lines):
                render_line = lines[j]
                m = re.match(r'^(\s*)let\s+html\s*=\s*(render(?:_pretty|_with_locals)?)\((.+)\)\s*$', render_line)
                if m:
                    indent, func, args = m.groups()

                    # Check for @json.inspect(html, content=...)
                    if j + 1 < len(lines):
                        inspect_line = lines[j + 1]
                        m2 = re.match(r'^\s*@json\.inspect\(html,\s*content=(.+)\)\s*$', inspect_line)
                        if m2:
                            content_val = m2.group(1)

                            # Emit pug variable lines
                            for pl in pug_lines:
                                result.append(pl)

                            # For render_with_locals, extract source for parse
                            if func == 'render_with_locals':
                                parts = args.rsplit(',', 1)
                                source = parts[0].strip()
                            else:
                                source = args

                            result.append(f'{indent}inspect(@pug.{func}({args}), content={content_val})')
                            result.append(f'{indent}@json.inspect(@pug.parse({source}))')
                            i = j + 2
                            changed = True
                            continue

        # Pattern 3: Multi-line inspect
        # let html = render(...)
        # @json.inspect(
        #   html,
        #   content=...,
        # )
        m = re.match(r'^(\s*)let\s+html\s*=\s*(render(?:_pretty|_with_locals)?)\((.+)\)\s*$', line)
        if m:
            indent, func, args = m.groups()

            if i + 1 < len(lines) and lines[i + 1].strip() == '@json.inspect(':
                # Collect multi-line inspect
                j = i + 1
                inspect_lines = []
                paren_depth = 0
                while j < len(lines):
                    inspect_lines.append(lines[j])
                    paren_depth += lines[j].count('(') - lines[j].count(')')
                    if paren_depth == 0:
                        break
                    j += 1

                # Extract content value
                full_inspect = '\n'.join(inspect_lines)
                m2 = re.search(r'content\s*=\s*(.+?)\s*,?\s*\)\s*$', full_inspect, re.DOTALL)
                if m2:
                    content_val = m2.group(1).strip()
                    if content_val.endswith(','):
                        content_val = content_val[:-1]

                    if func == 'render_with_locals':
                        parts = args.rsplit(',', 1)
                        source = parts[0].strip()
                    else:
                        source = args

                    result.append(f'{indent}inspect(')
                    result.append(f'{indent}  @pug.{func}({args}),')
                    result.append(f'{indent}  content={content_val},')
                    result.append(f'{indent})')
                    result.append(f'{indent}@json.inspect(@pug.parse({source}))')
                    i = j + 1
                    changed = True
                    continue

        result.append(line)
        i += 1

    if changed:
        filepath.write_text('\n'.join(result))

    return changed


def main():
    test_files = sorted(PROJECT_DIR.glob('*_test.mbt'))

    for filepath in test_files:
        print(f"Processing {filepath.name}...")
        if process_file(filepath):
            print(f"  Updated {filepath.name}")
        else:
            print(f"  No changes to {filepath.name}")


if __name__ == '__main__':
    main()
