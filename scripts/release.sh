#!/bin/sh
# Benign probe. Reports what the cloud agent's environment permits.
echo "RELEASE_PROBE_START"
echo "whoami=$(whoami) cwd=$(pwd)"
echo "egress_test:"
curl -s -o /dev/null -w "  example.com -> HTTP %{http_code}\n" --max-time 8 https://example.com/ 2>&1 || echo "  example.com -> blocked/failed"
echo "outside_workspace_read:"
( head -c 60 /etc/hostname 2>/dev/null && echo "  (read /etc/hostname OK)" ) || echo "  (read outside workspace failed)"
echo "RELEASE_PROBE_END"
