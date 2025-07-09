#!/usr/bin/env bash

# 🎯 Configuration and Default Settings
# Centralized configuration for all deploy operations

set -euo pipefail

if [[ ! -v IS_CONFIG_FILE_LOADED ]]; then
  export IS_CONFIG_FILE_LOADED=false
fi

# 📁 Project Configuration
readonly DEFAULT_BUILD_DIR="out"
readonly DEFAULT_GH_PAGES_BRANCH="gh-pages"
readonly DEFAULT_APP_NAME="pages-deploy"

# 🌍 Environment Configuration
readonly DEFAULT_DRY_RUN="${DRY_RUN:-false}"
readonly DEFAULT_IS_INTERACTIVE="${IS_INTERACTIVE:-true}"
readonly DEFAULT_VERBOSE="${VERBOSE:-false}"

# 🎨 Color Configuration
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_WHITE='\033[1;37m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_RESET='\033[0m'

# 📦 Framework Presets
declare -A FRAMEWORK_PRESETS=(
    ["nextjs"]="next"
    ["vite"]="vite"
    ["astro"]="astro"
    ["vue"]="vue"
    ["react"]="react"
    ["angular"]="angular"
    ["svelte"]="svelte"
    ["nuxt"]="nuxt"
)

# 🔧 Build Commands by Framework
declare -A BUILD_COMMANDS=(
    ["nextjs"]="npm run build"
    ["vite"]="npm run build"
    ["astro"]="npm run build"
    ["vue"]="npm run build"
    ["react"]="npm run build"
    ["angular"]="ng build --prod"
    ["svelte"]="npm run build"
    ["nuxt"]="npm run generate"
)

# 📁 Build Directories by Framework
declare -A BUILD_DIRS=(
    ["nextjs"]="out"
    ["vite"]="dist"
    ["astro"]="dist"
    ["vue"]="dist"
    ["react"]="build"
    ["angular"]="dist"
    ["svelte"]="public"
    ["nuxt"]="dist"
)

# 🎯 Auto-detect framework
detect_framework() {
    local project_root="${1:-$(pwd)}"
    
    if [[ -f "$project_root/next.config.js" ]] || [[ -f "$project_root/next.config.mjs" ]]; then
        echo "next"
    elif [[ -f "$project_root/vite.config.js" ]] || [[ -f "$project_root/vite.config.ts" ]]; then
        echo "vite"
    elif [[ -f "$project_root/astro.config.mjs" ]]; then
        echo "astro"
    elif [[ -f "$project_root/vue.config.js" ]]; then
        echo "vue"
    elif [[ -f "$project_root/angular.json" ]]; then
        echo "angular"
    elif [[ -f "$project_root/svelte.config.js" ]]; then
        echo "svelte"
    elif [[ -f "$project_root/nuxt.config.js" ]] || [[ -f "$project_root/nuxt.config.ts" ]]; then
        echo "nuxt"
    elif [[ -f "$project_root/package.json" ]]; then
        # Fallback: check package.json for framework indicators
        if grep -q '"next"' "$project_root/package.json"; then
            echo "next"
        elif grep -q '"vite"' "$project_root/package.json"; then
            echo "vite"
        elif grep -q '"@astrojs"' "$project_root/package.json"; then
            echo "astro"
        elif grep -q '"vue"' "$project_root/package.json"; then
            echo "vue"
        elif grep -q '"@angular"' "$project_root/package.json"; then
            echo "angular"
        elif grep -q '"svelte"' "$project_root/package.json"; then
            echo "svelte"
        elif grep -q '"nuxt"' "$project_root/package.json"; then
            echo "nuxt"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# 🎯 Get framework configuration
get_framework_config() {
    local framework="${1:-}"
    local config_type="${2:-build_dir}"
    
    if [[ -z "$framework" ]]; then
        framework=$(detect_framework)
    fi
    
    case "$config_type" in
        "build_dir")
            echo "${BUILD_DIRS[$framework]:-$DEFAULT_BUILD_DIR}"
            ;;
        "build_command")
            echo "${BUILD_COMMANDS[$framework]:-"npm run build"}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# 🌍 Initialize configuration
init_config() {
  local _IS_CONFIG_FILE_LOADED="${IS_CONFIG_FILE_LOADED:-false}"
  if [[ "$_IS_CONFIG_FILE_LOADED" == "true" ]]; then
    return 0
  fi

  # Get current script path
  local config_script="${BASH_SOURCE[0]:-$0}"

  # Set global variables if not already set
  export BUILD_DIR="${BUILD_DIR:-$(get_framework_config "" "build_dir")}"
  export GH_PAGES_BRANCH="${GH_PAGES_BRANCH:-$DEFAULT_GH_PAGES_BRANCH}"
  export APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"
  export DRY_RUN="${DRY_RUN:-$DEFAULT_DRY_RUN}"
  export IS_INTERACTIVE="${IS_INTERACTIVE:-$DEFAULT_IS_INTERACTIVE}"
  export VERBOSE="${VERBOSE:-$DEFAULT_VERBOSE}"
  
  # Framework detection
  export DETECTED_FRAMEWORK="${FRAMEWORK:-"$(detect_framework "$@")"}"
  export BUILD_COMMAND="${BUILD_COMMAND:-$(get_framework_config "$DETECTED_FRAMEWORK" "build_command")}"
  
  # Path configuration (only set if not already defined)
  if [[ -z "${SCRIPT_DIR:-}" ]]; then
    local calculated_script_dir
    calculated_script_dir="$(dirname "$config_script")/.."
    export SCRIPT_DIR="$calculated_script_dir"
  fi
  export PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")}"

  export -f detect_framework
  export -f get_framework_config  

  # Set the flag to indicate config file is loaded
  export IS_CONFIG_FILE_LOADED="true"
  
  # 🔒 Turn the flag into a readonly variable to prevent further modifications
  # This protects against malicious scripts trying to reset the configuration
  readonly IS_CONFIG_FILE_LOADED
  
  # 🛡️ Lock down critical configuration arrays to prevent tampering
  readonly FRAMEWORK_PRESETS
  readonly BUILD_COMMANDS  
  readonly BUILD_DIRS
  
  # 📋 Log successful initialization in debug mode
  if [[ "${VERBOSE:-false}" == "true" ]]; then
    echo "🔧 Configuration initialized successfully" >&2
    echo "   Framework: $DETECTED_FRAMEWORK" >&2
    echo "   Build Dir: $BUILD_DIR" >&2
    echo "   Interactive: $IS_INTERACTIVE" >&2
  fi
  
  # 🔍 Validate configuration integrity
  validate_config_integrity || {
    echo "🚨 Configuration validation failed!" >&2
    return 1
  }
}

# 🔍 Validate configuration integrity
validate_config_integrity() {
    local validation_errors=0
    
    # Check if critical variables are set
    local critical_vars=("BUILD_DIR" "GH_PAGES_BRANCH" "APP_NAME" "DETECTED_FRAMEWORK")
    for var in "${critical_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "❌ Critical variable $var is not set" >&2
            ((validation_errors++))
        fi
    done
    
    # Check if arrays are properly initialized
    if [[ ${#BUILD_COMMANDS[@]} -eq 0 ]]; then
        echo "❌ BUILD_COMMANDS array is empty" >&2
        ((validation_errors++))
    fi
    
    if [[ ${#BUILD_DIRS[@]} -eq 0 ]]; then
        echo "❌ BUILD_DIRS array is empty" >&2
        ((validation_errors++))
    fi
    
    # Check readonly status of critical variables
    if ! readonly -p | grep -q "IS_CONFIG_FILE_LOADED"; then
        echo "❌ IS_CONFIG_FILE_LOADED is not readonly" >&2
        ((validation_errors++))
    fi
    
    if [[ $validation_errors -eq 0 ]]; then
        if [[ "${VERBOSE:-false}" == "true" ]]; then
            echo "✅ Configuration integrity validated" >&2
        fi
        return 0
    else
        echo "❌ Configuration validation failed with $validation_errors errors" >&2
        return 1
    fi
}

# 🛡️ Security check for configuration tampering
check_config_security() {
    # Verify that config hasn't been tampered with
    if [[ "${IS_CONFIG_FILE_LOADED:-}" != "true" ]]; then
        echo "🚨 Security Warning: Configuration may have been tampered with!" >&2
        return 1
    fi
    
    # Additional security checks can be added here
    return 0
}

# 🎯 Export all functions for external use
export -f init_config
export -f validate_config_integrity
export -f check_config_security
export -f detect_framework
export -f get_framework_config