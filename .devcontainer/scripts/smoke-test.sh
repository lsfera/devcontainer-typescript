#!/bin/bash
# Check that node, deno and bun are installed and can run TypeScript.
# Run inside the container: /scripts/smoke-test.sh
set -uo pipefail

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Typed TS using a node: builtin; each runtime must print the same line.
cat > "$TMP/smoke.ts" <<'EOF'
import { createHash } from "node:crypto";
const sum = (xs: number[]): number => xs.reduce((a, b) => a + b, 0);
const hash: string = createHash("sha256").update("smoke").digest("hex").slice(0, 8);
console.log(`ok ${sum([1, 2, 3])} ${hash}`);
EOF
EXPECTED="ok 6 $(printf smoke | sha256sum | cut -c1-8)"

failed=0
check() {
    local name=$1; shift
    if ! command -v "$name" >/dev/null 2>&1; then
        echo "FAIL $name: not found on PATH"
        failed=1
        return
    fi
    local version out
    version=$("$name" --version 2>&1 | head -n1)
    if out=$("$@" "$TMP/smoke.ts" 2>&1) && [ "$out" = "$EXPECTED" ]; then
        echo "PASS $name ($version)"
    else
        echo "FAIL $name ($version): expected '$EXPECTED', got:"
        echo "$out" | sed 's/^/    /'
        failed=1
    fi
}

check node node
check deno deno run --quiet
check bun  bun run

exit $failed
