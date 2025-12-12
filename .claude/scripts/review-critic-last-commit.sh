#!/bin/bash

# review-critic-last-commit: Analyze the last git commit using code-reviewer-critic agent
# Usage: ./review-critic-last-commit.sh

echo "🔍 Analyzing last commit with code-reviewer-critic..."
echo ""

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check if there are any commits in the repository
if ! git rev-parse --verify HEAD > /dev/null 2>&1; then
    echo "❌ Error: No commits found in repository"
    exit 1
fi

# Get the last commit hash and info
LAST_COMMIT=$(git rev-parse HEAD)
COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an")
COMMIT_DATE=$(git log -1 --pretty=format:"%ad" --date=short)

echo "📝 Last commit: $LAST_COMMIT"
echo "📄 Message: $COMMIT_MESSAGE"
echo "👤 Author: $COMMIT_AUTHOR"
echo "📅 Date: $COMMIT_DATE"
echo ""

# Get the list of files changed in the last commit
echo "📋 Files changed in last commit:"
git diff-tree --no-commit-id --name-only -r HEAD | while read file; do
    echo "  - $file"
done
echo ""

# Get the full diff for analysis
echo "🔬 Running code review analysis..."
echo ""
echo "Git Diff Output:"
echo "================"
git show HEAD --format=""