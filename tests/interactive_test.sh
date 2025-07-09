#!/usr/bin/env bash

# 🧪 Interactive Input Tests
# Unit tests for the interactive_input function

# Set up test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/src/config.sh"
source "$SCRIPT_DIR/src/utils.sh"
source "$SCRIPT_DIR/src/interactive.sh"

# Test configuration
export IS_INTERACTIVE="true"
export VERBOSE="true"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# 🎯 Test framework functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_RUN++))
    
    print_log "INFO" "🧪 Running: $test_name"
    
    if "$test_function"; then
        ((TESTS_PASSED++))
        print_log "SUCCESS" "✅ PASS: $test_name"
    else
        ((TESTS_FAILED++))
        print_log "ERROR" "❌ FAIL: $test_name"
    fi
    
    echo
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        print_log "ERROR" "$message"
        print_log "ERROR" "Expected: '$expected'"
        print_log "ERROR" "Actual: '$actual'"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"
    
    if [[ "$condition" == "true" ]]; then
        return 0
    else
        print_log "ERROR" "$message"
        print_log "ERROR" "Expected: true"
        print_log "ERROR" "Actual: $condition"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"
    
    if [[ "$condition" == "false" ]]; then
        return 0
    else
        print_log "ERROR" "$message"
        print_log "ERROR" "Expected: false"
        print_log "ERROR" "Actual: $condition"
        return 1
    fi
}

# 🧪 Test Cases

test_text_input_with_true_condition() {
    local result
    result=$(interactive_input "text" "Test message" "true")
    assert_equals "Test message" "$result" "Text input with true condition should return the message"
}

test_text_input_with_false_condition() {
    local result
    result=$(interactive_input "text" "Test message" "false" "Default response")
    assert_equals "Default response" "$result" "Text input with false condition should return false response"
}

test_numeric_condition_conversion() {
    local result
    result=$(interactive_input "text" "Test message" "1")
    assert_equals "Test message" "$result" "Numeric condition 1 should be converted to true"
    
    result=$(interactive_input "text" "Test message" "0" "Default response")
    assert_equals "Default response" "$result" "Numeric condition 0 should be converted to false"
}

test_non_interactive_mode() {
    local old_interactive="$IS_INTERACTIVE"
    export IS_INTERACTIVE="false"
    
    local result
    result=$(interactive_input "text" "Test message" "true" "" "Non-interactive response")
    assert_equals "Non-interactive response" "$result" "Non-interactive mode should return default response"
    
    export IS_INTERACTIVE="$old_interactive"
}

test_invalid_condition_handling() {
    local result
    local exit_code=0
    
    result=$(interactive_input "text" "Test message" "invalid" 2>/dev/null) || exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        return 0  # Test passes if function returns error
    else
        print_log "ERROR" "Function should have failed with invalid condition"
        return 1
    fi
}

test_function_exists_utility() {
    if function_exists "print_log"; then
        return 0
    else
        print_log "ERROR" "function_exists should detect existing functions"
        return 1
    fi
    
    if ! function_exists "non_existent_function_12345"; then
        return 0
    else
        print_log "ERROR" "function_exists should not detect non-existent functions"
        return 1
    fi
}

test_interactive_confirm() {
    # Mock user input for confirm function
    local old_interactive="$IS_INTERACTIVE"
    export IS_INTERACTIVE="false"  # Use non-interactive mode for predictable testing
    
    # Test with default true
    if interactive_confirm "Test question" "true"; then
        :  # Expected behavior
    else
        print_log "ERROR" "interactive_confirm should return true with default true"
        export IS_INTERACTIVE="$old_interactive"
        return 1
    fi
    
    # Test with default false
    if ! interactive_confirm "Test question" "false"; then
        :  # Expected behavior
    else
        print_log "ERROR" "interactive_confirm should return false with default false"
        export IS_INTERACTIVE="$old_interactive"
        return 1
    fi
    
    export IS_INTERACTIVE="$old_interactive"
    return 0
}

test_detect_interactive_mode() {
    local old_ci="$CI"
    local old_interactive="$IS_INTERACTIVE"
    
    # Test CI detection
    export CI="true"
    export IS_INTERACTIVE=""
    
    if detect_interactive_mode; then
        print_log "ERROR" "Should detect non-interactive mode in CI"
        export CI="$old_ci"
        export IS_INTERACTIVE="$old_interactive"
        return 1
    fi
    
    # Test manual override
    export CI=""
    export IS_INTERACTIVE="false"
    
    if detect_interactive_mode; then
        print_log "ERROR" "Should respect manual IS_INTERACTIVE=false"
        export CI="$old_ci"
        export IS_INTERACTIVE="$old_interactive"
        return 1
    fi
    
    export CI="$old_ci"
    export IS_INTERACTIVE="$old_interactive"
    return 0
}

test_sanitize_input() {
    local dangerous_input='$(rm -rf /) && echo "safe"'
    local sanitized
    sanitized=$(sanitize_input "$dangerous_input")
    
    if [[ "$sanitized" =~ \$|\(|\)|rm|rf ]]; then
        print_log "ERROR" "sanitize_input should remove dangerous characters"
        print_log "ERROR" "Original: $dangerous_input"
        print_log "ERROR" "Sanitized: $sanitized"
        return 1
    fi
    
    return 0
}

test_format_file_size() {
    local size_1kb
    size_1kb=$(format_file_size 1024)
    assert_equals "1KB" "$size_1kb" "1024 bytes should format as 1KB"
    
    local size_1mb
    size_1mb=$(format_file_size 1048576)
    assert_equals "1MB" "$size_1mb" "1048576 bytes should format as 1MB"
    
    local size_1gb
    size_1gb=$(format_file_size 1073741824)
    assert_equals "1GB" "$size_1gb" "1073741824 bytes should format as 1GB"
}

# 🎯 Run all tests
run_all_tests() {
    print_header "Interactive Input Tests" "Testing the brilliant interactive_input function"
    
    # Core interactive_input tests
    run_test "Text input with true condition" test_text_input_with_true_condition
    run_test "Text input with false condition" test_text_input_with_false_condition
    run_test "Numeric condition conversion" test_numeric_condition_conversion
    run_test "Non-interactive mode" test_non_interactive_mode
    run_test "Invalid condition handling" test_invalid_condition_handling
    
    # Utility function tests
    run_test "Function exists utility" test_function_exists_utility
    run_test "Interactive confirm" test_interactive_confirm
    run_test "Detect interactive mode" test_detect_interactive_mode
    run_test "Sanitize input" test_sanitize_input
    run_test "Format file size" test_format_file_size
    
    # Print summary
    print_header "Test Results"
    print_log "INFO" "🧪 Tests run: $TESTS_RUN"
    print_log "SUCCESS" "✅ Tests passed: $TESTS_PASSED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        print_log "ERROR" "❌ Tests failed: $TESTS_FAILED"
        return 1
    else
        print_log "SUCCESS" "🎉 All tests passed!"
        return 0
    fi
}

# 🚀 Execute tests if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi
