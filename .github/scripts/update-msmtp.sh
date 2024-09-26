#!/usr/bin/env bash

PACKAGE_NAME="msmtp"; 
PACKAGE_ARCH="x86_64"; 
PACKAGE_REPO="community";
ALPINE_VERSION=$(grep "FROM alpine:" Dockerfile_alpine | awk '{print $2}'| sed  -E "s|alpine:||" | awk -F '.' '{print $1"."$2}')

NEW_VERSION=$(curl -SsL https://pkgs.alpinelinux.org/package/v${ALPINE_VERSION}/${PACKAGE_REPO}/${PACKAGE_ARCH}/${PACKAGE_NAME} | grep -i -A 2 version | tail -1 | awk '{print $1}')

if [ "${NEW_VERSION}" ]; then
  sed -i -e "s|ARG ${PACKAGE_NAME^^}_VERSION='.*|ARG ${PACKAGE_NAME^^}_VERSION='${NEW_VERSION}'|" Dockerfile_alpine
fi

if output=$(git status --porcelain) && [ -z "$output" ]; then
  # Working directory clean
  echo "No new version available!"
else
  # Uncommitted changes
  git commit -a -m "Updated Package ${PACKAGE_NAME} to version: ${NEW_VERSION}"
  git push
fi
