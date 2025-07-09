#!/usr/bin/env bash

# 🛠️ Utility Functions
# Logging, validation, and common helper functions

# Source config if not already loaded
if [[ -z "${COLOR_RESET:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
fi

# 🎯 Enhanced logging with timestamps and colors
print_log() {
    local log_type="${1:-INFO}"
    local message="${2:-}"
    local timestamp=""
    timestamp="$(date '+%H:%M:%S')"
    
    case "$log_type" in
        "SUCCESS") 
            echo -e "${COLOR_GREEN}[✅ $timestamp]${COLOR_RESET} $message" 
            ;;
        "INFO")    
            echo -e "${COLOR_BLUE}[ℹ️  $timestamp]${COLOR_RESET} $message" 
            ;;
        "WARNING") 
            echo -e "${COLOR_YELLOW}[⚠️  $timestamp]${COLOR_RESET} $message" 
            ;;
        "ERROR")   
            echo -e "${COLOR_RED}[❌ $timestamp]${COLOR_RESET} $message" 
            ;;
        "FATAL")   
            echo -e "${COLOR_RED}[💀 $timestamp]${COLOR_RESET} $message"
            exit 1 
            ;;
        "STATUS")  
            echo -e "${COLOR_CYAN}[🔄 $timestamp]${COLOR_RESET} $message" 
            ;;
        "DEBUG")
            [[ "$VERBOSE" == "true" ]] && echo -e "${COLOR_DIM}[🐛 $timestamp]${COLOR_RESET} $message"
            ;;
        "INTERACTIVE")
            echo -e "${COLOR_PURPLE}[🤖 $timestamp]${COLOR_RESET} $message"
            ;;
        *)         
            echo -e "${COLOR_BLUE}[ℹ️  $timestamp]${COLOR_RESET} $message" 
            ;;
    esac
}

# 🎨 Pretty headers
print_header() {
    local title="${1:-}"
    local subtitle="${2:-}"
    
    echo
    echo -e "${COLOR_BOLD}${COLOR_CYAN}🚀 $title${COLOR_RESET}"
    [[ -n "$subtitle" ]] && echo -e "${COLOR_CYAN}   $subtitle${COLOR_RESET}"
    echo
}

# 📝 Step indicator
print_step() {
    local step_num="${1:-}"
    local total_steps="${2:-}"
    local message="${3:-}"
    
    echo -e "${COLOR_BOLD}${COLOR_WHITE}[$step_num/$total_steps]${COLOR_RESET} $message"
}

# 🔍 Validation functions
validate_command() {
    local command="${1:-}"
    local description="${2:-$command}"
    
    if ! command -v "$command" >/dev/null 2>&1; then
        print_log "FATAL" "Required tool '$description' not found. Please install it first."
    fi
}

validate_file() {
    local file_path="${1:-}"
    local description="${2:-$file_path}"
    
    if [[ ! -f "$file_path" ]]; then
        print_log "FATAL" "Required file '$description' not found: $file_path"
    fi
}

validate_directory() {
    local dir_path="${1:-}"
    local description="${2:-$dir_path}"
    
    if [[ ! -d "$dir_path" ]]; then
        print_log "FATAL" "Required directory '$description' not found: $dir_path"
    fi
}

validate_git_repository() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_log "FATAL" "Not in a git repository! Please run this from your project root."
    fi
}

validate_git_remote() {
    local repo_url
    repo_url="$(git config --get remote.origin.url 2>/dev/null || echo '')"
    
    if [[ -z "$repo_url" ]]; then
        print_log "FATAL" "No remote repository found. Please set up a remote origin."
    fi
    
    # Test remote access
    if ! git ls-remote --exit-code "$repo_url" >/dev/null 2>&1; then
        print_log "FATAL" "Cannot access remote repository. Check your credentials and permissions."
    fi
    
    echo "$repo_url"
}

# 🧹 Safe cleanup utilities
safe_remove() {
    local path="${1:-}"
    local description="${2:-$path}"
    
    if [[ -n "$path" && -e "$path" ]]; then
        print_log "DEBUG" "Removing: $description"
        rm -rf "$path" 2>/dev/null || true
    fi
}

# 📊 Progress indicator
show_progress() {
    local current="${1:-0}"
    local total="${2:-100}"
    local message="${3:-Processing...}"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${COLOR_CYAN}%s${COLOR_RESET} [" "$message"
    printf "%${filled}s" "" | tr ' ' '='
    printf "%${empty}s" "" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [[ "$current" -eq "$total" ]]; then
        echo
    fi
}

# 🔄 Retry mechanism
retry_command() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    local command="${3:-}"
    local description="${4:-command}"
    
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        print_log "DEBUG" "Attempting $description (try $attempt/$max_attempts)"
        
        if eval "$command"; then
            print_log "SUCCESS" "$description succeeded on attempt $attempt"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            print_log "WARNING" "$description failed on attempt $attempt, retrying in ${delay}s..."
            sleep "$delay"
        fi
        
        ((attempt++))
    done
    
    print_log "ERROR" "$description failed after $max_attempts attempts"
    return 1
}

# 📁 Create secure temporary directory
create_secure_temp_dir() {
    local prefix="${1:-pages-deploy}"
    local temp_dir
    
    temp_dir="$(mktemp -d "/tmp/${prefix}.XXXXXX")"
    
    if [[ ! -d "$temp_dir" ]]; then
        echo "FATAL: Failed to create temporary directory" >&2
        return 1
    fi
    
    # Set secure permissions
    chmod 700 "$temp_dir"
    
    # Only echo the directory path, no logging
    echo "$temp_dir"
}

# 🔐 Sanitize input
sanitize_input() {
    local input="${1:-}"
    # Remove dangerous characters and sequences
    echo "$input" | sed 's/[;&|`$(){}[\]\\]//g' | tr -d '\n\r'
}

# 📏 Format file size
format_file_size() {
    local bytes="${1:-0}"
    
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(( bytes / 1073741824 ))GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(( bytes / 1048576 ))MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(( bytes / 1024 ))KB"
    else
        echo "${bytes}B"
    fi
}

# ⏱️ Format duration
format_duration() {
    local seconds="${1:-0}"
    
    if [[ $seconds -ge 3600 ]]; then
        printf "%dh %dm %ds" $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
    elif [[ $seconds -ge 60 ]]; then
        printf "%dm %ds" $((seconds / 60)) $((seconds % 60))
    else
        printf "%ds" "$seconds"
    fi
}

# 🎯 Check if function exists
function_exists() {
    local func_name="${1:-}"
    declare -f "$func_name" >/dev/null 2>&1
}

# 🌐 Check internet connectivity
check_internet() {
    if ping -c 1 github.com >/dev/null 2>&1; then
        return 0
    else
        print_log "WARNING" "No internet connectivity detected"
        return 1
    fi
}

# 📦 Get project info
get_project_info() {
    local info_type="${1:-name}"
    
    case "$info_type" in
        "name")
            basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
            ;;
        "url")
            git config --get remote.origin.url 2>/dev/null || echo ""
            ;;
        "branch")
            git branch --show-current 2>/dev/null || echo ""
            ;;
        "commit")
            git rev-parse HEAD 2>/dev/null || echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}
