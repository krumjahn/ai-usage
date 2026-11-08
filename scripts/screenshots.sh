#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p docs/images
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
sources=()
for source in App/*.swift; do
  [[ "$source" == "App/Entry.swift" ]] || sources+=("$source")
done
swiftc Core/*.swift "${sources[@]}" Design/GenerateScreenshots.swift -o "$scratch/screenshots"
"$scratch/screenshots"
