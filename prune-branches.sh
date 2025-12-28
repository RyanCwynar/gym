#!/bin/bash

# Prune local branches that no longer exist on remote
# Usage: ./prune-branches.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🔍 DRY RUN - No branches will be deleted"
    echo ""
fi

# Fetch and prune remote tracking branches
echo "📡 Fetching from remote and pruning stale references..."
git fetch --prune

# Get current branch to avoid deleting it
CURRENT_BRANCH=$(git branch --show-current)
echo "📌 Current branch: $CURRENT_BRANCH"
echo ""

# Find local branches that don't have a remote tracking branch
echo "🗑️  Branches to delete:"
echo "----------------------------------------"

BRANCHES_TO_DELETE=()

for branch in $(git branch --format='%(refname:short)'); do
    # Skip main/master and current branch
    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "$CURRENT_BRANCH" ]]; then
        continue
    fi
    
    # Check if remote tracking branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        BRANCHES_TO_DELETE+=("$branch")
        echo "  - $branch"
    fi
done

echo "----------------------------------------"

if [[ ${#BRANCHES_TO_DELETE[@]} -eq 0 ]]; then
    echo "✅ No branches to prune!"
    exit 0
fi

echo ""
echo "Found ${#BRANCHES_TO_DELETE[@]} branch(es) to delete"

if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "Run without --dry-run to delete these branches"
    exit 0
fi

echo ""
read -p "Delete these branches? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    for branch in "${BRANCHES_TO_DELETE[@]}"; do
        echo "Deleting $branch..."
        git branch -D "$branch"
    done
    echo ""
    echo "✅ Done! Deleted ${#BRANCHES_TO_DELETE[@]} branch(es)"
else
    echo "❌ Aborted"
fi

