#!/bin/bash

# review-critic: Analyze uncommitted git changes using code-reviewer-critic agent
# Usage: ./review-critic.sh

echo "🔍 Analyzing uncommitted changes with code-reviewer-critic..."
echo ""

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check for both modified tracked files and untracked files
MODIFIED_FILES=$(git diff --name-only HEAD)
STAGED_FILES=$(git diff --cached --name-only)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard)

# Combine all types of changes
ALL_CHANGES=""
if [ -n "$MODIFIED_FILES" ]; then
    ALL_CHANGES="$ALL_CHANGES$MODIFIED_FILES"$'\n'
fi
if [ -n "$STAGED_FILES" ]; then
    ALL_CHANGES="$ALL_CHANGES$STAGED_FILES"$'\n'
fi
if [ -n "$UNTRACKED_FILES" ]; then
    ALL_CHANGES="$ALL_CHANGES$UNTRACKED_FILES"$'\n'
fi

# Remove empty lines and duplicates
ALL_CHANGES=$(echo "$ALL_CHANGES" | grep -v '^$' | sort -u)

if [ -z "$ALL_CHANGES" ]; then
    echo "✅ No uncommitted changes found"
    exit 0
fi

# Display all files with changes
echo "📋 Files with uncommitted changes:"
echo "$ALL_CHANGES" | while read file; do
    if [ -n "$file" ]; then
        # Check if file is untracked
        if echo "$UNTRACKED_FILES" | grep -q "^$file$"; then
            echo "  - $file (untracked)"
        elif echo "$STAGED_FILES" | grep -q "^$file$"; then
            echo "  - $file (staged)"
        else
            echo "  - $file (modified)"
        fi
    fi
done
echo ""

# Get the full diff for analysis
echo "🔬 Running code review analysis..."
echo ""

# Show modified and staged files diff
if [ -n "$MODIFIED_FILES" ] || [ -n "$STAGED_FILES" ]; then
    echo "Git Diff Output:"
    echo "================"
    git diff HEAD
    if [ -n "$STAGED_FILES" ]; then
        echo ""
        echo "Staged Changes:"
        echo "==============="
        git diff --cached
    fi
fi

# Show content of untracked files
if [ -n "$UNTRACKED_FILES" ]; then
    echo ""
    echo "Untracked Files Content:"
    echo "======================="
    echo "$UNTRACKED_FILES" | while read file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            echo ""
            echo "--- New file: $file ---"
            cat "$file"
        fi
    done
fi