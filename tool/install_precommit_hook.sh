#!/usr/bin/env bash
# Installs tool/pre-commit as the repository's git pre-commit hook.
#
#   bash tool/install_precommit_hook.sh
#
# The hook itself is versioned in tool/ so it survives clones; this script
# copies it into .git/hooks/ (which is local to each checkout).
# Re-run after updating tool/pre-commit.

set -eu

ROOT="$(git rev-parse --show-toplevel)" || { echo "Not in a git work tree."; exit 1; }
cd "$ROOT" || exit 1

install -m 0755 tool/pre-commit .git/hooks/pre-commit
echo "Installed pre-commit hook -> .git/hooks/pre-commit"
echo "Every commit will now run 'flutter analyze' + 'flutter test' on Dart-relevant changes."
