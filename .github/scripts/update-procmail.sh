#!/usr/bin/env bash

PROCMAIL_URL="https://api.github.com/repos/BuGlessRB/procmail/releases"

FULL_LAST_VERSION=$(curl -SsL ${PROCMAIL_URL} | \
              jq -r -c '.[] | select( .prerelease == false ) | .tag_name' |\
              head -1 \
              )
LAST_VERSION="${FULL_LAST_VERSION:1}"

if [ "${LAST_VERSION}" ]; then
  sed -i -e "s|PROCMAIL_VERSION='.*'|PROCMAIL_VERSION='${LAST_VERSION}'|" Dockerfile*
fi

if output=$(git status --porcelain) && [ -z "$output" ]; then
  # Working directory clean
  echo "No new version available!"
else 
  # Uncommitted changes
  git commit -a -m "update procmail to version: ${LAST_VERSION}"
  git push
fi
