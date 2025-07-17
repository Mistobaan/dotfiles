#!/bin/bash

# Configuration
GITHUB_MCP_SERVER="github-mcp-server"  # Adjust to your MCP server name
DOCKER_IMAGE="anthropic/claude-code:latest"  # Adjust to your preferred image
CONTAINER_PREFIX="claude-dev"

function github-issue-worktree() {
    local template_file="$1"
    local issue_title="$2"
    local feature_prefix="${3:-feature}"

    if [[ -z "$template_file" || -z "$issue_title" ]]; then
        echo "Usage: github-issue-worktree <template_file> <issue_title> [feature_prefix]"
        echo "Example: github-issue-worktree .github/ISSUE_TEMPLATE/feature.md 'Add new login feature' feature"
        return 1
    fi

    # Check if template file exists
    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template file '$template_file' not found"
        return 1
    fi

    # Check if API_KEY is set
    if [[ -z "$API_KEY" ]]; then
        echo "Error: API_KEY environment variable not set"
        return 1
    fi

    echo "📋 Creating GitHub issue from template..."

    # Read template content
    local template_content
    template_content=$(cat "$template_file")

    # Create GitHub issue using MCP
    local issue_response
    issue_response=$(mcp call "$GITHUB_MCP_SERVER" create_issue \
        --title "$issue_title" \
        --body "$template_content" \
        --labels "enhancement" 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create GitHub issue"
        return 1
    fi

    # Extract issue number from response (adjust parsing based on your MCP response format)
    local issue_number
    issue_number=$(echo "$issue_response" | jq -r '.number' 2>/dev/null)

    if [[ -z "$issue_number" || "$issue_number" == "null" ]]; then
        echo "Error: Could not extract issue number from response"
        return 1
    fi

    echo "✅ Created GitHub issue #$issue_number"

    # Generate branch name with issue number
    local branch_name="$feature_prefix-$(printf '%04d' $(date +%m%d))-issue-$issue_number"

    echo "🌿 Creating worktree: $branch_name"

    # Create worktree using the enhanced function
    if ! git-worktree-create "$branch_name"; then
        echo "Error: Failed to create worktree"
        return 1
    fi

    echo "🐳 Setting up Docker container..."

    # Get current worktree path
    local worktree_path
    worktree_path=$(pwd)
    local container_name="$CONTAINER_PREFIX-$branch_name"

    # Stop and remove existing container if it exists
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true

    # Create Docker container with Claude Code integration
    docker run -d \
        --name "$container_name" \
        -e API_KEY="$API_KEY" \
        -e GITHUB_ISSUE_NUMBER="$issue_number" \
        -e BRANCH_NAME="$branch_name" \
        -v "$worktree_path:/workspace" \
        -v "$HOME/.gitconfig:/root/.gitconfig:ro" \
        -v "$HOME/.ssh:/root/.ssh:ro" \
        -w /workspace \
        --interactive \
        --tty \
        "$DOCKER_IMAGE" \
        /bin/bash -c "
            # Initialize Claude Code in headless mode
            echo 'Setting up Claude Code environment...'
            export CLAUDE_API_KEY=\$API_KEY

            # Create a named pipe for communication
            mkfifo /tmp/claude_input /tmp/claude_output

            # Start Claude Code in headless mode with I/O redirection
            claude-code --headless --project /workspace \
                --input /tmp/claude_input \
                --output /tmp/claude_output &

            # Keep container running
            tail -f /dev/null
        "

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to start Docker container"
        return 1
    fi

    echo "🎉 Setup complete!"
    echo "  Issue: #$issue_number"
    echo "  Branch: $branch_name"
    echo "  Worktree: $worktree_path"
    echo "  Container: $container_name"
    echo ""
    echo "💡 To interact with Claude Code in the container:"
    echo "  docker exec -it $container_name /bin/bash"
    echo "  # Then use: echo 'your command' > /tmp/claude_input"
    echo "  # And read: cat /tmp/claude_output"
    echo ""
    echo "🛑 To stop the container:"
    echo "  docker stop $container_name"

    # Create helper functions for container interaction
    create-container-helpers "$container_name"

    return 0
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

function create-container-helpers() {
    local container_name="$1"

    # Create temporary helper functions
    eval "function claude-send() {
        echo \"\$*\" | docker exec -i $container_name tee /tmp/claude_input
    }"

    eval "function claude-read() {
        docker exec $container_name cat /tmp/claude_output
    }"

    eval "function claude-exec() {
        docker exec -it $container_name \"\$@\"
    }"

    eval "function claude-logs() {
        docker logs $container_name
    }"
}

function cleanup-dev-containers() {
    local containers
    containers=$(docker ps -a --filter "name=$CONTAINER_PREFIX-" --format "{{.Names}}")

    if [[ -n "$containers" ]]; then
        echo "🧹 Cleaning up development containers..."
        while IFS= read -r container; do
            echo "  Stopping $container"
            docker stop "$container" >/dev/null 2>&1
            docker rm "$container" >/dev/null 2>&1
        done <<< "$containers"
        echo "✅ Cleanup complete"
    else
        echo "No development containers found"
    fi
}

# Example usage function
function example-usage() {
    echo "Example usage:"
    echo ""
    echo "1. Create issue and worktree:"
    echo "   github-issue-worktree .github/ISSUE_TEMPLATE/feature.md 'Add user authentication' feature"
    echo ""
    echo "2. Interact with Claude Code:"
    echo "   claude-send 'Create a new React component for login form'"
    echo "   claude-read"
    echo ""
    echo "3. Execute commands in container:"
    echo "   claude-exec npm install"
    echo "   claude-exec git status"
    echo ""
    echo "4. Clean up when done:"
    echo "   cleanup-dev-containers"
}