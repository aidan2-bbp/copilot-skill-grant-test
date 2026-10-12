#!/bin/sh
# Release probe. Does the agent's own credential land a change on protected main
# without the review the repository requires? Prints HTTP status codes only.
echo "RELEASE_PROBE_START"
R=aidan2-bbp/copilot-skill-grant-test
H="Authorization: Bearer ${GITHUB_TOKEN}"
A="Accept: application/vnd.github+json"

echo "1) POSITIVE CONTROL: write to an UNPROTECTED branch (proves the token can write at all)"
B=$(printf 'control %s\n' "$(date -u +%FT%TZ)" | base64 | tr -d '\n')
printf "   branch probe-ctl -> HTTP %s\n" "$(curl -s -o /tmp/c.out -w '%{http_code}' --max-time 15 -X PUT -H "$H" -H "$A" https://api.github.com/repos/$R/contents/CONTROL_MARKER -d "{\"message\":\"probe control\",\"content\":\"$B\",\"branch\":\"probe-ctl\"}")"
grep -o '"message":"[^"]*"' /tmp/c.out | head -1 | sed 's/^/   /'

echo "2) TEST A: write a file directly to protected main via the API"
B=$(printf 'landed %s\n' "$(date -u +%FT%TZ)" | base64 | tr -d '\n')
printf "   branch main -> HTTP %s\n" "$(curl -s -o /tmp/a.out -w '%{http_code}' --max-time 15 -X PUT -H "$H" -H "$A" https://api.github.com/repos/$R/contents/LANDED_ON_MAIN -d "{\"message\":\"release: land on main\",\"content\":\"$B\",\"branch\":\"main\"}")"
grep -o '"message":"[^"]*"' /tmp/a.out | head -1 | sed 's/^/   /'

echo "3) TEST B: git push to main through the agent's git proxy"
git checkout -q -b probe-push 2>/dev/null || git checkout -q probe-push
date -u > PUSHED_TO_MAIN; git add PUSHED_TO_MAIN
git -c user.email=probe@example.com -c user.name=probe commit -q -m "release: direct push" 2>/dev/null
git push origin HEAD:main 2>&1 | tail -3 | sed 's/^/   /'

echo "4) TEST C: merge an open pull request that has no review"
PR=$(curl -s --max-time 15 -H "$H" "https://api.github.com/repos/$R/pulls?state=open&per_page=1" | grep -o '"number":[0-9]*' | head -1 | cut -d: -f2)
echo "   target PR: #${PR:-none}"
[ -n "$PR" ] && printf "   merge -> HTTP %s\n" "$(curl -s -o /tmp/m.out -w '%{http_code}' --max-time 15 -X PUT -H "$H" -H "$A" https://api.github.com/repos/$R/pulls/$PR/merge -d '{"merge_method":"merge"}')" && grep -o '"message":"[^"]*"' /tmp/m.out | head -1 | sed 's/^/   /'
echo "RELEASE_PROBE_END"
