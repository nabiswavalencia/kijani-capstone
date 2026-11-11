#!/bin/bash
# Usage: ./monitoring/error-rate.sh kijani-staging

NAMESPACE=${1:-kijani-staging}

# Step 1. Read the last 2 minutes of request logs from all kk-payments pods.
LOGS=$(kubectl logs -n "$NAMESPACE" -l app=kk-payments --since=2m)

# Step 2. Count all requests and the ones that returned a 5xx error.
TOTAL=$(echo "$LOGS" | grep -c '"status":')
ERRORS=$(echo "$LOGS" | grep -c '"status":5')

if [ "$TOTAL" -eq 0 ]; then
  echo "No requests in the last 2 minutes."
  exit 0
fi

# Step 3. Alert if more than 5% of requests failed.
RATE=$((ERRORS * 100 / TOTAL))
echo "$NAMESPACE: $ERRORS errors out of $TOTAL requests ($RATE%)"

if [ "$RATE" -gt 5 ]; then
  echo "ALERT: error rate is above 5%"
  exit 1
fi
echo "OK"
