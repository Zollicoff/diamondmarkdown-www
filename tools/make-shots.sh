#!/bin/sh
# Puts the app's pictures into shots/, the way the page uses them.
#
#   tools/make-shots.sh <folder of pictures>
#
# The folder is what the app's screenshots mode writes; the README says how
# to run it. The picture at the top of the page is used whole. The four in
# the gallery are the middle of the window, without the panels either side:
# 800 by 600, starting 260 pixels in from the left.
set -e
pictures="${1:?usage: tools/make-shots.sh <folder of pictures>}"
cd "$(dirname "$0")/.."
mkdir -p shots
cp "$pictures/editor-and-preview.png" shots/
for name in board graph canvas query; do
	sips -c 600 800 --cropOffset 0 260 "$pictures/$name.png" --out "shots/$name.png" >/dev/null
done
ls -l shots
