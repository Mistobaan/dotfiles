#!/bin/bash

container_name=claude-code-agent
issue_number=100
branch_name="claude-code-issue-$issue_number"
DOCKER_IMAGE=code-worker

function git-worktree-switch() {
    local branch_name="$1"
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir)
    local repo_root
    repo_root=$(dirname "$git_common_dir")
    local worktree_path="$repo_root/.worktrees/$branch_name"

    if [[ -d "$worktree_path" ]]; then
        cd "$worktree_path" || return 1
        return 0
    else
        return 1
    fi
}


function git-worktree-create() {
    local branch_name="$1"

    if [[ -z "$branch_name" ]]; then
        echo "Usage: git-worktree-create <branch_name>"
        return 1
    fi

    # Try to switch to existing worktree or create a new one
    if git-worktree-switch "$branch_name" 2>/dev/null; then
        return 0
    fi

    # No existing worktree, create one
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir)
    local repo_root
    repo_root=$(dirname "$git_common_dir")
    local worktree_path="$repo_root/.worktrees/$branch_name"

    # Check if branch exists
    if git show-ref --verify --quiet refs/heads/"$branch_name"; then
        # Branch exists, don't use -b flag
        git worktree add "$worktree_path" "$branch_name"
    else
        # Branch doesn't exist, create it
        git worktree add "$worktree_path" -b "$branch_name"
    fi

    if [[ $? -eq 0 ]]; then
        cd "$worktree_path" || return 1
        echo "📁 Switched to worktree: $worktree_path"
        return 0
    else
        echo "Error: Failed to create worktree"
        return 1
    fi
}

function run_worker() {
    local worktree_path="$1"

    docker build -t "$DOCKER_IMAGE" .
    docker run \
            -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
            -e GITHUB_ISSUE_NUMBER="$issue_number" \
            -e BRANCH_NAME="$branch_name" \
            -v "$worktree_path:/workspace" \
            -v "$HOME/.gitconfig:/root/.gitconfig:ro" \
            -w /workspace \
            --interactive \
            --tty \
            "$DOCKER_IMAGE" \
	    bash -c \
            "claude \
                --add-dir /workspace \
                --output-format stream-json \
                --verbose \
                --dangerously-skip-permissions"
}


run_worker ../.worktrees/test-branch
