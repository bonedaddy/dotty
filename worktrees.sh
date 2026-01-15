#!/bin/bash

# Git Worktree Helper
# A simple helper script for managing git worktrees

set -e

SCRIPT_NAME=$(basename "$0")

show_help() {
    cat << EOF
Git Worktree Helper

Usage: $SCRIPT_NAME <command> [options]

Commands:
  create <branch> [options]   Create a new worktree
    -n, --name <name>         Custom name for worktree directory (default: branch name)
    -c, --cd                  Change directory to the new worktree
    -o, --open                Change directory and open claude (implies -c)
    -b, --base <ref>          Base branch/commit for new branch (default: HEAD)

  commit <name> [message]      Commit changes in a worktree
    If no message provided, opens editor

  remove <name>                Remove a worktree and optionally its branch
    -f, --force               Force removal even if dirty
    -d, --delete-branch       Also delete the branch

  list                        List all worktrees

Examples:
  $SCRIPT_NAME create feature-login
  $SCRIPT_NAME create feature-login -c
  $SCRIPT_NAME create feature-login --open
  $SCRIPT_NAME create feature-login -b main
  $SCRIPT_NAME create feature-login -n login-work
  $SCRIPT_NAME commit feature-login "Add login form"
  $SCRIPT_NAME commit login-work "Add login form"
  $SCRIPT_NAME remove feature-login
  $SCRIPT_NAME remove login-work -d
EOF
}

get_worktree_path() {
    local branch="$1"
    local git_root
    git_root=$(git rev-parse --show-toplevel)
    echo "${git_root}-worktrees/${branch}"
}

cmd_create() {
    local branch=""
    local name=""
    local change_dir=false
    local open_claude=false
    local base_ref="HEAD"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--cd)
                change_dir=true
                shift
                ;;
            -o|--open)
                open_claude=true
                change_dir=true
                shift
                ;;
            -b|--base)
                base_ref="$2"
                shift 2
                ;;
            -n|--name)
                name="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                exit 1
                ;;
            *)
                if [[ -z "$branch" ]]; then
                    branch="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$branch" ]]; then
        echo "Error: Branch name required" >&2
        echo "Usage: $SCRIPT_NAME create <branch> [options]" >&2
        exit 1
    fi

    # Use custom name if provided, otherwise use branch name
    if [[ -z "$name" ]]; then
        name="$branch"
    fi

    local worktree_path
    worktree_path=$(get_worktree_path "$name")

    echo "Creating worktree for branch '$branch' at $worktree_path..."

    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        git worktree add "$worktree_path" "$branch"
    else
        git worktree add -b "$branch" "$worktree_path" "$base_ref"
    fi

    echo "Worktree created successfully!"

    if [[ "$open_claude" == true ]]; then
        echo "Opening claude in $worktree_path..."
        cd "$worktree_path" && exec claude
    elif [[ "$change_dir" == true ]]; then
        echo "To change to the worktree directory, run:"
        echo "  cd $worktree_path"
        echo ""
        echo "Or source this script:"
        echo "  source $0 create $branch -c"
        cd "$worktree_path" && exec $SHELL
    fi
}

cmd_commit() {
    local name="$1"
    shift || true
    local message="$*"

    if [[ -z "$name" ]]; then
        echo "Error: Worktree name required" >&2
        echo "Usage: $SCRIPT_NAME commit <name> [message]" >&2
        exit 1
    fi

    local worktree_path
    worktree_path=$(get_worktree_path "$name")

    if [[ ! -d "$worktree_path" ]]; then
        echo "Error: Worktree not found at $worktree_path" >&2
        exit 1
    fi

    cd "$worktree_path"

    git add -A

    if [[ -z "$message" ]]; then
        git commit
    else
        git commit -m "$message"
    fi

    echo "Changes committed in worktree '$name'"
}

cmd_remove() {
    local name=""
    local force=false
    local delete_branch=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=true
                shift
                ;;
            -d|--delete-branch)
                delete_branch=true
                shift
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                exit 1
                ;;
            *)
                if [[ -z "$name" ]]; then
                    name="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$name" ]]; then
        echo "Error: Worktree name required" >&2
        echo "Usage: $SCRIPT_NAME remove <n> [options]" >&2
        exit 1
    fi

    local worktree_path
    worktree_path=$(get_worktree_path "$name")

    # Get the branch name from the worktree before removing it
    local branch=""
    if [[ "$delete_branch" == true ]]; then
        branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    fi

    echo "Removing worktree at $worktree_path..."

    if [[ "$force" == true ]]; then
        git worktree remove --force "$worktree_path"
    else
        git worktree remove "$worktree_path"
    fi

    echo "Worktree removed successfully!"

    if [[ "$delete_branch" == true && -n "$branch" ]]; then
        echo "Deleting branch '$branch'..."
        if [[ "$force" == true ]]; then
            git branch -D "$branch"
        else
            git branch -d "$branch"
        fi
        echo "Branch deleted!"
    fi
}

cmd_list() {
    git worktree list
}

# Main entry point
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

command="$1"
shift

case "$command" in
    create)
        cmd_create "$@"
        ;;
    commit)
        cmd_commit "$@"
        ;;
    remove|rm)
        cmd_remove "$@"
        ;;
    list|ls)
        cmd_list
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$command'" >&2
        echo "Run '$SCRIPT_NAME help' for usage" >&2
        exit 1
        ;;
esac
