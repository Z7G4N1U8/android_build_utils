#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Z7G4N1U8 (Peace)

MAX_TRIES=3
COUNT=0

# Remove uncommitted/unstaged changes
DIRTY_REPOS=$(repo status -j$(nproc --all) 2>/dev/null | awk '/^project/ {print $2}')
[ -n "$DIRTY_REPOS" ] && repo forall -j$(nproc --all) $DIRTY_REPOS -c "git reset --hard ; git clean -fdx" > /dev/null

while [ $COUNT -lt $MAX_TRIES ]; do
  COUNT=$((COUNT + 1))
  echo "===== Sync Attempt $COUNT of $MAX_TRIES ====="

  # Run repo sync command and capture the output
  repo sync -c -j$(nproc --all) --force-sync --no-tags --no-clone-bundle --prune 2>&1 | tee sync_output.txt

  [ ${PIPESTATUS[0]} -eq 0 ] && break # Success: Exit loop
  [ $COUNT -eq $MAX_TRIES ] && exit 1 # Failure: Abort script

  # Delete failing repositories
  FAILING_REPOS=$(awk '/Failing repos.*:/{f=1;next}/Try/{exit}f{print $NF}' sync_output.txt | sort -u)
  if [ -n "$FAILING_REPOS" ]; then
    for REPO_PATH in $FAILING_REPOS; do
      echo "Deleting: $REPO_PATH"
      rm -rf "$REPO_PATH" ".repo/projects/$REPO_PATH.git"
    done
  fi

  # Remove stray .lock files under .repo but skip large object and log dirs
  find .repo -name objects -prune -o -name logs -prune -o -name *.lock -type f -exec rm -f {} +
done
