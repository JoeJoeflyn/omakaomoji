#!/bin/bash

emoji="${1:-}"

[[ -n $emoji ]] || exit

printf '%s' "$emoji" | wl-copy --type text/plain --sensitive

sleep 0.05
wtype -M ctrl -k v -m ctrl 2>/dev/null || true
