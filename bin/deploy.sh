#!/usr/bin/env bash

# 🚀 Enterprise GitHub Pages Deploy - Entry Point
# Smart modular deployment with interactive pipeline

set -euo pipefail
set -o errtrace
set -o functrace
IFS=$'\n\t'

# 📁 Load all modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_DIR="$SCRIPT_DIR"

# Source modules in correct order
source "$SCRIPT_DIR/src/config.sh"
source "$SCRIPT_DIR/src/utils.sh"
source "$SCRIPT_DIR/src/interactive.sh"
source "$SCRIPT_DIR/src/core.sh"

# 📖 Show help information
show_help() {
    cat << EOF
🚀 Enterprise GitHub Pages Deploy

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -y, --yes          Auto-confirm all prompts (non-interactive mode)
    -d, --dry-run      Perform all steps except the actual push to GitHub
    -v, --verbose      Enable verbose output for debugging
    -q, --quiet        Suppress non-essential output
    -h, --help         Show this help message
    --framework NAME   Override framework detection (nextjs, vite, astro, etc.)
    --build-dir DIR    Override build directory
    --branch NAME      Override target branch (default: gh-pages)

INTERACTIVE MODE:
    The deploy process will guide you through each step with confirmations.
    Perfect for first-time deployments or when you want full control.

NON-INTERACTIVE MODE:
    Use --yes for CI/CD pipelines or when you want fully automated deployments.
    All steps will proceed with sensible defaults.

EXAMPLES:
    $(basename "$0")                    # Interactive deployment
    $(basename "$0") --yes              # Automated deployment
    $(basename "$0") --dry-run          # Test deployment without pushing
    $(basename "$0") --yes --verbose    # Automated with detailed output
    
ENVIRONMENT VARIABLES:
    IS_INTERACTIVE=false    # Force non-interactive mode
    DRY_RUN=true           # Enable dry-run mode
    VERBOSE=true           # Enable verbose output
    BUILD_DIR=dist         # Override build directory
    FRAMEWORK=vite         # Override framework detection

FEATURES:
    ✅ Complete environment isolation
    ✅ Zero side-effects guarantee  
    ✅ Automatic cleanup on failure
    ✅ Fast compressed transfer
    ✅ Comprehensive validation
    ✅ Beautiful interactive prompts
    ✅ Multi-framework support
    ✅ Smart framework detection

For more information: docs/github-pages-deploy.md
EOF
}

# 🎯 Parse command line arguments
parse_arguments() {
    local auto_confirm="false"
    local dry_run="false"
    local verbose="false"
    local quiet="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes|--auto-confirm)
                auto_confirm="true"
                export IS_INTERACTIVE="false"
                shift
                ;;
            -d|--dry-run)
                dry_run="true"
                export DRY_RUN="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                export VERBOSE="true"
                shift
                ;;
            -q|--quiet)
                quiet="true"
                export QUIET="true"
                shift
                ;;
            --framework)
                if [[ -n "${2:-}" ]]; then
                    export FRAMEWORK="$2"
                    shift 2
                else
                    print_log "ERROR" "--framework requires a value"
                    exit 1
                fi
                ;;
            --build-dir)
                if [[ -n "${2:-}" ]]; then
                    export BUILD_DIR="$2"
                    shift 2
                else
                    print_log "ERROR" "--build-dir requires a value"
                    exit 1
                fi
                ;;
            --branch)
                if [[ -n "${2:-}" ]]; then
                    export GH_PAGES_BRANCH="$2"
                    shift 2
                else
                    print_log "ERROR" "--branch requires a value"
                    exit 1
                fi
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_log "ERROR" "Unknown option: $1"
                echo
                show_help
                exit 1
                ;;
        esac
    done
    
    # Export parsed options
    export AUTO_CONFIRM="$auto_confirm"
    export DRY_RUN="$dry_run"
    export VERBOSE="$verbose"
    export QUIET="$quiet"
}

# 🎯 Pre-flight checks
preflight_checks() {
    # Check if we're in the right directory
    if [[ ! -f "package.json" ]]; then
        print_log "ERROR" "No package.json found. Are you in the project root?"
        print_log "INFO" "Please run this script from your project's root directory."
        exit 1
    fi
    
    # Check Node.js version
    if command -v node >/dev/null 2>&1; then
        local node_version
        node_version=$(node --version 2>/dev/null | sed 's/v//')
        print_log "DEBUG" "Node.js version: $node_version"
    else
        print_log "WARNING" "Node.js not found. This may cause issues with the build process."
    fi
    
    # Check if this looks like a deployable project
    local has_scripts
    has_scripts=$(grep -c '"build"' package.json 2>/dev/null || echo "0")
    
    if [[ "$has_scripts" -eq 0 ]]; then
        print_log "WARNING" "No 'build' script found in package.json"
        if [[ "$IS_INTERACTIVE" == "true" ]]; then
            if ! interactive_confirm "Continue anyway?" "false"; then
                exit 1
            fi
        fi
    fi
}

# 🎯 Main execution function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize configuration
    init_config
    
    # Show banner unless quiet
    if [[ "${QUIET:-false}" != "true" ]]; then
        print_header "pages-deploy" "Modular GitHub Pages deployment tool"
        
        if [[ "${VERBOSE:-false}" == "true" ]]; then
            print_log "DEBUG" "Script directory: $SCRIPT_DIR"
            print_log "DEBUG" "Project root: $PROJECT_ROOT"
            print_log "DEBUG" "Detected framework: $DETECTED_FRAMEWORK"
            print_log "DEBUG" "Build directory: $BUILD_DIR"
            print_log "DEBUG" "Interactive mode: $IS_INTERACTIVE"
            print_log "DEBUG" "Dry run: $DRY_RUN"
        fi
    fi
    
    # Pre-flight checks
    preflight_checks
    
    # Run the deployment pipeline
    run_deployment_pipeline
}

# 🚀 Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
