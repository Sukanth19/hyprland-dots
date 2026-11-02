#!/usr/bin/env bash
# Select a region, then open it in swappy to draw/blur/crop.
pidof slurp >/dev/null && exit 0
region="$(slurp)" || exit 0
grim -g "$region" - | swappy -f -
