#!/bin/bash
set -e
DREP="${1%.drep.vkey}"
PROPOSALS="$2"
URL="$3"

if [ -z "$DREP" ] || [ -z "$PROPOSALS" ]; then
  echo "Usage: $0 <DREP> <PROPOSALS> [URL]"
  exit 1
fi

DREP_FILE="${DREP}.drep.vkey"
if [ ! -f "$DREP_FILE" ]; then
  echo "Missing file: $DREP_FILE"
  exit 1
fi

if [ ! -f "$PROPOSALS" ]; then
  echo "Missing file: $PROPOSALS"
  exit 1
fi

PROPOSAL_TOTAL=$(jq 'length' "$PROPOSALS")
echo -e "\033[1;33mVOTING FOR $PROPOSAL_TOTAL PROPOSALS\033[0m"
echo -e "\033[1;36mDRep:\033[0m $DREP"

if [ -n "$URL" ]; then
  BODY=$(curl -fs --max-time 10 "$URL") || {
    echo -e "\033[1;36mRationale URL:\033[0m $URL \033[1;31m ❌ Unreachable\033[0m"
    exit 1
  }
  if echo "$BODY" | jq empty >/dev/null 2>&1; then
    echo -e "\033[1;36mRationale URL:\033[0m $URL \033[1;32m✅\033[0m"
  else
    echo -e "\033[1;36mRationale URL:\033[0m $URL \033[1;31m ❌ Does not look like JSON\033[0m"
    exit 1
  fi
else
  echo -e "\033[1;36mNo rationale\033[0m"
fi

PROPOSAL_INDEX=0
jq -c '.[]' $PROPOSALS | while read -r item; do
  read -p $'\n\033[1;33mPress Enter to continue...\033[0m' < /dev/tty
  echo -e "\n\033[1;33m====================================================================================================\033[0m\n"
  echo -e "\033[1;33m$((++PROPOSAL_INDEX))/$PROPOSAL_TOTAL) $(jq -r '.title' <<< "$item")\033[0m"
  TX_INDEX=$(jq -r '.txHash + "#" + (.index|tostring)' <<< "$item")
  echo -e "\033[1;36m$TX_INDEX\033[0m"
  if [ -n "$URL" ]; then
    24a_genVote.sh "$DREP" "$TX_INDEX" "url: $URL"
  else
    24a_genVote.sh "$DREP" "$TX_INDEX"
  fi
done
