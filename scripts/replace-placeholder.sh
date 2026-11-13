#!/bin/sh
set -eu

from=$1
to=$2

if [ "$from" = "$to" ]; then
    exit 0
fi

pattern=$(printf '%s' "$from" | sed 's/[][\.^$*|]/\\&/g')
replacement=$(printf '%s' "$to" | sed 's/[\&|]/\\&/g')
find apps/web/.next apps/web/public -type f \( \
    -name '*.js' -o -name '*.json' -o -name '*.html' -o -name '*.rsc' -o -name '*.txt' -o -name '*.body' -o -name '*.map' -o -name '*.css' \
\) -exec sh -ec '
    pattern=$1
    replacement=$2
    shift 2
    for file do
        if grep -q -- "$pattern" "$file"; then
            sed -i "s|$pattern|$replacement|g" "$file"
        fi
    done
' sh "$pattern" "$replacement" {} +
