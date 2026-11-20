#!/bin/sh
# Makes every image that is drawn from the mark: the share card and the PNG
# icons. Run it from anywhere after changing favicon.svg or tools/*.html.
set -e
cd "$(dirname "$0")/.."
swift tools/snapshot.swift tools/og-image.html og-image.png 1200 630 1
swift tools/snapshot.swift tools/icon.html favicon-16.png 16 16 1
swift tools/snapshot.swift tools/icon.html favicon-32.png 32 32 1
swift tools/snapshot.swift tools/touch-icon.html apple-touch-icon.png 180 180 1
