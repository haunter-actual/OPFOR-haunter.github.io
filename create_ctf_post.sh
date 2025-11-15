#!/usr/bin/env bash
# create_ctf_post.sh
# Creates working dirs and a Jekyll post .md file for a CTF writeup.
# Behavior:
#   - Always create directories that don't exist (including attacker/).
#   - Create the post .md only if it does not already exist. If it exists, warn and skip.
# Usage:
#   ./create_ctf_post.sh                 # interactive prompts
#   PLATFORM OS DIFFICULTY "System Name" # positional args also accepted

set -euo pipefail

# ---------- helpers ----------
trim() { local var="$*"; var="${var#"${var%%[![:space:]]*}"}"; var="${var%"${var##*[![:space:]]}"}"; printf '%s' "$var"; }

titlecase() {
  awk '{
    for(i=1;i<=NF;i++){
      $i = toupper(substr($i,1,1)) tolower(substr($i,2))
    }
    print
  }' <<<"$*"
}

slugify() {
  local s="$*"
  s="${s// /-}"
  s="${s//\//-}"
  s="$(tr '[:upper:]' '[:lower:]' <<<"$s")"
  printf '%s' "$s" | sed 's/[^a-z0-9._-]//g'
}

slugify_titlecase() {
  local s
  s="$(titlecase "$*")"
  s="${s// /-}"
  printf '%s' "$s" | sed 's/[^A-Za-z0-9._-]//g'
}

# ---------- platform mapping ----------
platform_map_fullname() {
  local p="$1"
  case "${p,,}" in
    htb)     printf 'HackTheBox' ;;
    hs)      printf 'Hack Smarter' ;;
    thm)     printf 'TryHackMe' ;;
    offsec)  printf 'OffSec PG Play' ;;   # OffSec capitalization as requested
    vulnlab) printf 'Vulnlab' ;;
    *)       return 1 ;;
  esac
}

# ---------- read inputs ----------
if [ $# -ge 4 ]; then
  PLATFORM_RAW="$1"
  OS_RAW="$2"
  DIFFICULTY_RAW="$3"
  SYSTEM_RAW="$4"
else
  read -rp "Platform (htb, hs, thm, offsec, vulnlab): " PLATFORM_RAW
  read -rp "OS (windows, linux, AD): " OS_RAW
  read -rp "Difficulty (very easy, easy, intermediate, hard, very hard): " DIFFICULTY_RAW
  read -rp "System Name (e.g. Blueprint): " SYSTEM_RAW
fi

PLATFORM_RAW="$(trim "$PLATFORM_RAW")"
OS_RAW="$(trim "$OS_RAW")"
DIFFICULTY_RAW="$(trim "$DIFFICULTY_RAW")"
SYSTEM_RAW="$(trim "$SYSTEM_RAW")"

if ! PLATFORM_FULLNAME="$(platform_map_fullname "$PLATFORM_RAW")"; then
  echo "Error: unknown platform '$PLATFORM_RAW'." >&2
  echo "Supported: htb, hs, thm, offsec, vulnlab" >&2
  exit 2
fi

# Normalizations
PLATFORM_DIR="$(slugify "$PLATFORM_RAW")"          # e.g. offsec
DIFFICULTY_DIR="$(slugify "$DIFFICULTY_RAW")"      # e.g. very-hard (for dirs)
SYSTEM_DIR="$(slugify "$SYSTEM_RAW")"              # e.g. bossman
OS_TITLE="$(titlecase "$OS_RAW")"                  # Linux, Windows, AD
DIFFICULTY_TITLE="$(titlecase "$DIFFICULTY_RAW")"  # Very Hard
SYSTEM_TITLE="$(titlecase "$SYSTEM_RAW")"          # Bossman
PLATFORM_FULLNAME_TITLE="$PLATFORM_FULLNAME"       # OffSec PG Play

# Tags should be lowercase; multi-word difficulties keep spaces (not hyphenated)
OS_TAG="$(tr '[:upper:]' '[:lower:]' <<<"$OS_RAW")"
DIFFICULTY_TAG="$(tr '[:upper:]' '[:lower:]' <<<"$DIFFICULTY_RAW")"

# filename pieces
DATE_STR="$(date +%F)"
PLATFORM_FULLNAME_HYPHENS="$(slugify_titlecase "$PLATFORM_FULLNAME_TITLE")"
DIFFICULTY_TITLE_HYPHENS="$(slugify_titlecase "$DIFFICULTY_TITLE")"
SYSTEM_FILENAME="$(slugify_titlecase "$SYSTEM_TITLE")"
OS_FILENAME="$(slugify_titlecase "$OS_TITLE")"

# Directory paths (including new attacker dir)
DIR1="$HOME/working/$PLATFORM_DIR/$DIFFICULTY_DIR/$SYSTEM_DIR/"
DIR2="/opt/haunter-actual.github.io/_posts/ctf/$PLATFORM_DIR/$DIFFICULTY_DIR/$SYSTEM_DIR/"
DIR3="/opt/haunter-actual.github.io/assets/img/ctf/$PLATFORM_DIR/$DIFFICULTY_DIR/$SYSTEM_DIR/"
DIR4="$HOME/working/$PLATFORM_DIR/$DIFFICULTY_DIR/$SYSTEM_DIR/attacker"

POST_FILENAME="${DATE_STR}-${PLATFORM_FULLNAME_HYPHENS}-${OS_FILENAME}-${DIFFICULTY_TITLE_HYPHENS}-${SYSTEM_FILENAME}.md"
POST_PATH="${DIR2%/}/$POST_FILENAME"

cat <<EOF
Will create (if missing):
  1) $DIR1
  2) $DIR2
  3) $DIR3
  4) $DIR4

Jekyll post target:
  $POST_PATH

Continue? [Y/n]
EOF

read -rn1 answer || true
echo
if [[ -n "$answer" && ! $answer =~ [Yy] ]]; then
  echo "Aborted."
  exit 0
fi

# Create directories (always; ok if they already exist)
mkdir -p "$DIR1" "$DIR2" "$DIR3" "$DIR4"
echo "Created directories (or they already existed)."

# Create the post only if it doesn't already exist. If it exists, warn and continue.
POST_TIME="12:00:00 -0000"

if [ -e "$POST_PATH" ]; then
  echo "Warning: post already exists at:"
  echo "  $POST_PATH"
  echo "Skipping post creation to avoid overwrite."
else
  cat > "$POST_PATH" <<EOF
---
title: "${PLATFORM_FULLNAME_TITLE} - ${OS_TITLE} - ${DIFFICULTY_TITLE} - ${SYSTEM_TITLE}"
date: ${DATE_STR} ${POST_TIME}
categories: [CTF, ${PLATFORM_FULLNAME_TITLE}]
tags: [${OS_TAG}, ${DIFFICULTY_TAG}]
---

![${PLATFORM_FULLNAME_TITLE} ${SYSTEM_TITLE}](/assets/img/ctf/${PLATFORM_DIR}/${DIFFICULTY_DIR}/${SYSTEM_DIR}/${SYSTEM_DIR}.png)

# Initial Intel
* OS: ${OS_TITLE}
* Difficulty: ${DIFFICULTY_TITLE}

# tl;dr
<details><summary>Spoilers</summary>
</details>

# Attack Path

## Recon

### Service Enumeration

Standard TCP scan to start:

\`\`\`bash
┌──(haunter㉿kali)-[~/working/${PLATFORM_DIR}/${DIFFICULTY_DIR}/${SYSTEM_DIR}/
└─\$ sudo nmap -A -p- -vvv -T3 --open -oN nmap_tcp_full \$${SYSTEM_DIR}
\`\`\`

Notable services:

#### /TCP - 

## Foothold

## Lateral Movement / Privilege Escalation

## Root / SYSTEM
EOF

  chmod 644 "$POST_PATH"
  echo "Created post file: $POST_PATH"
fi

echo
echo "Done. If needed, add an image at:"
echo "  ${DIR3%/}/${SYSTEM_DIR}.png"
echo "Edit the post at:"
echo "  $POST_PATH"

