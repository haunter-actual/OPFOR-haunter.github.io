import re
from pathlib import Path

# Regex for <img> tags
IMG_TAG_PATTERN = re.compile(r"<img\s+[^>]*src=['\"]([^'\"]+)['\"][^>]*>", re.IGNORECASE)

# Convert <img> → markdown ![alt](src)
def convert_img_tags(content):
    def repl(match):
        src = match.group(1)
        alt = Path(src).stem
        return f"![{alt}]({src})"
    return IMG_TAG_PATTERN.sub(repl, content)

# Rewrite head matter block
def fix_front_matter(lines):
    in_header = False
    new_lines = []
    for line in lines:
        stripped = line.strip()

        # Detect YAML start / end
        if stripped == "---":
            if not in_header:
                in_header = True
            else:
                in_header = False
            new_lines.append(line)
            continue

        if in_header:
            if stripped.startswith("categories:"):
                # Extract words after colon
                cats = stripped.split(":", 1)[1].strip().replace(",", " ").split()
                formatted = f"categories: [ {', '.join(cats)} ]\n"
                new_lines.append(formatted)
                continue

            if stripped.startswith("tags:"):
                tags = stripped.split(":", 1)[1].strip().replace(",", " ").split()
                formatted = f"tags: [ {', '.join(tags)} ]\n"
                new_lines.append(formatted)
                continue

        new_lines.append(line)
    return new_lines


root = Path(".")  # adjust if needed
count = 0

for md_file in root.rglob("*.md"):
    text = md_file.read_text(encoding="utf-8")
    orig = text
    lines = text.splitlines(keepends=True)

    # Fix head matter + image tags
    lines = fix_front_matter(lines)
    text = "".join(lines)
    text = convert_img_tags(text)

    if text != orig:
        md_file.write_text(text, encoding="utf-8")
        print(f"✔ Updated: {md_file}")
        count += 1

print(f"\n✅ Done. {count} files updated.")

