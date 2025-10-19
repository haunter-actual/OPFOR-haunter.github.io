import re
from pathlib import Path
import yaml

# 🔧 Adjust this if needed (root where markdown files live)
ROOT_DIR = Path(".")  # search everything under current dir
EXTENSIONS = (".md", ".markdown")

IMG_TAG_PATTERN = re.compile(
    r"<img\s+[^>]*src=['\"]([^'\"]+)['\"][^>]*>", re.IGNORECASE
)

def convert_front_matter(content):
    """Convert front matter block to normalized YAML array format."""
    if not content.startswith("---"):
        return content, False

    parts = content.split("---", 2)
    if len(parts) < 3:
        return content, False

    _, fm_text, body = parts
    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError:
        print("⚠️ YAML parse error, skipping front matter")
        return content, False

    changed = False
    for key in ("categories", "tags"):
        if key in fm and isinstance(fm[key], str):
            fm[key] = fm[key].split()
            changed = True

    new_fm = yaml.dump(fm, sort_keys=False).strip()
    new_content = f"---\n{new_fm}\n---{body}"
    return new_content, changed


def convert_img_tags(content):
    """Replace <img> tags with Markdown image syntax."""
    def repl(match):
        src = match.group(1)
        alt = Path(src).stem  # filename as alt text
        return f"![{alt}]({src})"
    new_content, n = IMG_TAG_PATTERN.subn(repl, content)
    return new_content, n


def process_file(md_file):
    text = md_file.read_text(encoding="utf-8")
    new_text, fm_changed = convert_front_matter(text)
    new_text, img_count = convert_img_tags(new_text)

    if fm_changed or img_count > 0:
        backup = md_file.with_suffix(md_file.suffix + ".bak")
        md_file.rename(backup)
        md_file.write_text(new_text, encoding="utf-8")
        print(f"✅ Updated {md_file.relative_to(ROOT_DIR)} "
              f"({'front matter' if fm_changed else ''}"
              f"{' & ' if fm_changed and img_count else ''}"
              f"{img_count} img{'s' if img_count != 1 else ''} replaced)")
    else:
        print(f"↩️  No changes in {md_file.relative_to(ROOT_DIR)}")


if __name__ == "__main__":
    files = list(ROOT_DIR.rglob("*"))
    md_files = [f for f in files if f.suffix in EXTENSIONS]

    if not md_files:
        print("❌ No Markdown files found.")
    else:
        print(f"🔍 Found {len(md_files)} markdown files.\n")
        for f in md_files:
            process_file(f)

