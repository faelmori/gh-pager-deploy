#!/usr/bin/env bash

# 🤖 Interactive Input Functions
# Smart interactive/non-interactive input handling

# Source dependencies
if [[ -z "${COLOR_RESET:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
    source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
fi

# 🎯 Enhanced Interactive Input Function
# This is your brilliant idea implemented with improvements!
interactive_input() {
    local input_type="${1:-text}"
    local input_value="${2:-}"
    local input_condition="${3:-false}"
    local input_false_response="${4:-}"
    local input_no_interactive="${5:-}"
    local user_input=""

    # 🔍 Debug logging
    print_log "DEBUG" "interactive_input: type=$input_type, condition=$input_condition, interactive=$IS_INTERACTIVE"

    if [[ "$IS_INTERACTIVE" == "true" ]]; then
        # Normalize condition to true/false
        input_condition="${input_condition,,}"
        
        # Handle numeric conditions (0/1)
        if [[ "$input_condition" =~ ^[01]$ ]]; then
            if [[ "$input_condition" == "1" ]]; then
                input_condition="true"
            else
                input_condition="false"
            fi
        fi
        
        # Validate condition
        if [[ "$input_condition" != "true" && "$input_condition" != "false" ]]; then
            print_log "ERROR" "Invalid condition: $input_condition (must be true, false, 0, or 1)"
            return 1
        fi

        if [[ "$input_condition" == "true" ]]; then
            case "$input_type" in
                ask|request|prompt)
                    print_log "INTERACTIVE" "$input_value"
                    read -rp "❯ " user_input
                    # Use default if empty and available
                    [[ -z "$user_input" && -n "$input_no_interactive" ]] && user_input="$input_no_interactive"
                    printf '%s\n' "$user_input"
                    ;;
                    
                password|secure|secret)
                    print_log "INTERACTIVE" "$input_value"
                    read -rsp "❯ " user_input
                    echo  # New line after password input
                    printf '%s\n' "$user_input"
                    ;;
                    
                confirm|yes_no|yn)
                    print_log "INTERACTIVE" "$input_value (y/N)"
                    read -rp "❯ " user_input
                    case "${user_input,,}" in
                        y|yes|true|1)
                            echo "true"
                            ;;
                        *)
                            echo "false"
                            ;;
                    esac
                    ;;
                    
                callback|function|cmd)
                    if function_exists "$input_value"; then
                        print_log "DEBUG" "Executing function: $input_value"
                        "$input_value" || return 1
                    else
                        print_log "DEBUG" "Executing command: $input_value"
                        if ! eval "$input_value" 2>/dev/null; then
                            print_log "ERROR" "Failed to execute: $input_value"
                            return 1
                        fi
                    fi
                    ;;
                    
                select|menu|choice)
                    # Expected format: "option1,option2,option3"
                    local IFS=','
                    local -a options
                    read -ra options <<< "$input_value"
                    local choice
                    
                    print_log "INTERACTIVE" "Please select an option:"
                    for i in "${!options[@]}"; do
                        echo "  $((i+1))) ${options[i]}"
                    done
                    
                    while true; do
                        read -rp "❯ Enter choice (1-${#options[@]}): " choice
                        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
                            echo "${options[$((choice-1))]}"
                            break
                        else
                            print_log "ERROR" "Invalid choice. Please enter a number between 1 and ${#options[@]}"
                        fi
                    done
                    ;;
                    
                *)
                    # Default: just return the value
                    printf '%s\n' "$input_value"
                    ;;
            esac
        else
            # Condition is false
            if [[ -n "$input_false_response" ]]; then
                printf '%s\n' "$input_false_response"
            else
                print_log "DEBUG" "Condition false, no response provided"
                return 1
            fi
        fi
    else
        # Non-interactive mode
        if [[ -n "$input_no_interactive" ]]; then
            printf '%s\n' "$input_no_interactive"
        else
            print_log "DEBUG" "Non-interactive mode, no default response provided"
            return 0
        fi
    fi
}

# 🎯 Interactive confirmation with context
interactive_confirm() {
    local message="${1:-Continue?}"
    local default="${2:-false}"
    local context="${3:-}"
    
    if [[ -n "$context" ]]; then
        print_log "INFO" "$context"
    fi
    
    local result
    result=$(interactive_input "confirm" "$message" "true" "$default" "$default")
    
    [[ "$result" == "true" ]]
}

# 🎯 Interactive step confirmation
interactive_step() {
    local step_name="${1:-}"
    local step_description="${2:-}"
    local auto_confirm="${3:-false}"
    
    print_step "$CURRENT_STEP" "$TOTAL_STEPS" "$step_name"
    
    if [[ -n "$step_description" ]]; then
        print_log "INFO" "$step_description"
    fi
    
    if [[ "$auto_confirm" != "true" ]]; then
        interactive_confirm "Proceed with this step?" "true" || {
            print_log "INFO" "Step skipped by user"
            return 1
        }
    fi
    
    ((CURRENT_STEP++)) || true
}

# 🎯 Interactive selection from list
interactive_select() {
    local prompt="${1:-Select an option}"
    local options_string="${2:-}"
    local default="${3:-}"
    
    interactive_input "select" "$options_string" "true" "$default" "$default"
}

# 🎯 Interactive text input with validation
interactive_text() {
    local prompt="${1:-Enter value}"
    local default="${2:-}"
    local validator="${3:-}"
    local max_attempts="${4:-3}"
    
    local attempt=1
    local user_input
    
    while [[ $attempt -le $max_attempts ]]; do
        user_input=$(interactive_input "ask" "$prompt" "true" "" "$default")
        
        # If no validator, accept any input
        if [[ -z "$validator" ]]; then
            echo "$user_input"
            return 0
        fi
        
        # Run validator
        if eval "$validator '$user_input'"; then
            echo "$user_input"
            return 0
        else
            print_log "ERROR" "Invalid input. Please try again (attempt $attempt/$max_attempts)"
            ((attempt++))
        fi
    done
    
    print_log "ERROR" "Max attempts reached. Using default: $default"
    echo "$default"
    return 1
}

# 🎯 Interactive password with confirmation
interactive_password() {
    local prompt="${1:-Enter password}"
    local confirm_prompt="${2:-Confirm password}"
    local max_attempts="${3:-3}"
    
    local attempt=1
    local password1 password2
    
    while [[ $attempt -le $max_attempts ]]; do
        password1=$(interactive_input "password" "$prompt" "true")
        password2=$(interactive_input "password" "$confirm_prompt" "true")
        
        if [[ "$password1" == "$password2" ]]; then
            echo "$password1"
            return 0
        else
            print_log "ERROR" "Passwords don't match. Please try again (attempt $attempt/$max_attempts)"
            ((attempt++))
        fi
    done
    
    print_log "ERROR" "Max attempts reached for password confirmation"
    return 1
}

# 🎯 Smart interactive mode detection
detect_interactive_mode() {
    # Check if we're in a terminal
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        export IS_INTERACTIVE="false"
        print_log "DEBUG" "Non-interactive mode detected (no TTY)"
        return 1
    fi
    
    # Check for CI environment
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${JENKINS_URL:-}" ]]; then
        export IS_INTERACTIVE="false"
        print_log "DEBUG" "Non-interactive mode detected (CI environment)"
        return 1
    fi
    
    # Check for explicit setting
    if [[ "${IS_INTERACTIVE:-}" == "false" ]]; then
        print_log "DEBUG" "Non-interactive mode set explicitly"
        return 1
    fi
    
    export IS_INTERACTIVE="true"
    print_log "DEBUG" "Interactive mode enabled"
    return 0
}

# 🎯 Initialize interactive mode
init_interactive() {
    detect_interactive_mode
    
    # Set up step counters
    export CURRENT_STEP="${CURRENT_STEP:-1}"
    export TOTAL_STEPS="${TOTAL_STEPS:-6}"
    
    if [[ "$IS_INTERACTIVE" == "true" ]]; then
        print_log "INTERACTIVE" "🤖 Interactive mode enabled"
        print_log "INFO" "You'll be prompted before each major step"
    else
        print_log "INFO" "🤖 Non-interactive mode - using defaults"
    fi
}
