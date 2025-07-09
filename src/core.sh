#!/usr/bin/env bash

# ⚡ Core Deployment Pipeline
# Main deployment logic with interactive steps

# Source dependencies
if [[ -z "${COLOR_RESET:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/config.sh"
    source "$SCRIPT_DIR/utils.sh"
    source "$SCRIPT_DIR/interactive.sh"
fi

# 🌍 Global variables for cleanup
declare -g TEMP_DIR=""
declare -g TEMP_ARCHIVE=""
declare -g ORIGINAL_BRANCH=""
declare -g REPO_URL=""

# 🧹 Comprehensive cleanup function
cleanup_deployment() {
    local exit_code=$?
    
    print_log "DEBUG" "🧹 Cleanup trap executed (exit_code: $exit_code, caller: ${FUNCNAME[1]:-unknown})"
    
    # Avoid cleanup during critical operations
    if [[ "${CLEANUP_TRAP_SET:-true}" == "false" ]]; then
        print_log "DEBUG" "Cleanup temporarily disabled, skipping"
        return $exit_code
    fi
    
    print_log "STATUS" "🧹 Performing cleanup..."
    
    # Return to original branch if needed
    if [[ -n "$ORIGINAL_BRANCH" && "$ORIGINAL_BRANCH" != "$(git branch --show-current 2>/dev/null || echo '')" ]]; then
        print_log "STATUS" "🔙 Returning to original branch: $ORIGINAL_BRANCH"
        git checkout "$ORIGINAL_BRANCH" --quiet 2>/dev/null || true
    fi
    
    # Clean temporary files
    safe_remove "$TEMP_DIR" "temporary directory"
    safe_remove "$TEMP_ARCHIVE" "temporary archive"
    
    # Final status
    if [[ $exit_code -eq 0 ]]; then
        print_log "SUCCESS" "🎉 Deploy completed successfully!"
        
        local project_name
        project_name=$(get_project_info "name")
        local github_user
        github_user=$(git config user.name 2>/dev/null || echo 'your-username')
        
        print_log "INFO" "🌐 Your site will be available at:"
        print_log "INFO" "   https://${github_user}.github.io/${project_name}"
    else
        print_log "ERROR" "❌ Deploy failed, but environment is clean"
    fi
    
    exit $exit_code
}

# 🛡️ Set up cleanup trap
setup_cleanup_trap() {
    print_log "DEBUG" "Setting up cleanup trap"
    trap cleanup_deployment EXIT INT TERM
    export CLEANUP_TRAP_SET="true"
}

# 🛡️ Disable cleanup trap temporarily
disable_cleanup_trap() {
    print_log "DEBUG" "Temporarily disabling cleanup trap"
    trap - EXIT INT TERM
    export CLEANUP_TRAP_SET="false"
}

# 🛡️ Re-enable cleanup trap
enable_cleanup_trap() {
    print_log "DEBUG" "Re-enabling cleanup trap"
    trap cleanup_deployment EXIT INT TERM
    export CLEANUP_TRAP_SET="true"
}

# 🔍 Step 1: Environment Validation
step_validate_environment() {
    if ! interactive_step "Environment Validation" "Checking git repository, dependencies, and permissions" "$AUTO_CONFIRM"; then
        return 0
    fi
    
    print_log "STATUS" "🔍 Validating environment..."
    
    # Git repository validation
    validate_git_repository
    REPO_URL=$(validate_git_remote)
    REPO_URL="${REPO_URL%.git}"  # Clean URL
    
    # Save current branch
    ORIGINAL_BRANCH="$(git branch --show-current 2>/dev/null || echo '')"
    if [[ -z "$ORIGINAL_BRANCH" ]]; then
        print_log "FATAL" "Cannot determine current branch. Are you in detached HEAD state?"
    fi
    
    # Check required tools
    validate_command "npm" "Node.js Package Manager"
    validate_command "zip" "ZIP compression utility"
    validate_command "unzip" "ZIP extraction utility"
    
    # Framework detection
    init_config
    print_log "INFO" "📍 Detected framework: $DETECTED_FRAMEWORK"
    print_log "INFO" "📍 Build directory: $BUILD_DIR"
    print_log "INFO" "📍 Build command: $BUILD_COMMAND"
    print_log "INFO" "📍 Current branch: $ORIGINAL_BRANCH"
    print_log "INFO" "🔗 Repository: $REPO_URL"
    
    # Internet connectivity check
    if ! check_internet; then
        if [[ "$IS_INTERACTIVE" == "true" ]]; then
            if ! interactive_confirm "No internet detected. Continue anyway?" "false"; then
                print_log "FATAL" "Internet connectivity required for deployment"
            fi
        else
            print_log "WARNING" "No internet detected, continuing anyway in non-interactive mode"
        fi
    fi
    
    print_log "SUCCESS" "✅ Environment validation completed"
}

# 📦 Step 2: Dependencies Check
step_check_dependencies() {
    if ! interactive_step "Dependencies Check" "Ensuring all required packages are installed" "$AUTO_CONFIRM"; then
        return 0
    fi
    
    print_log "STATUS" "📦 Checking project dependencies..."
    
    # Check package.json
    validate_file "package.json" "package.json configuration"
    
    # Check node_modules
    if [[ ! -d "node_modules" ]]; then
        if [[ "$IS_INTERACTIVE" == "true" ]]; then
            if interactive_confirm "Dependencies not installed. Install now?" "true"; then
                print_log "INFO" "📥 Installing dependencies..."
                retry_command 3 2 "npm install" "dependency installation"
            else
                print_log "FATAL" "Dependencies required for build process"
            fi
        else
            print_log "INFO" "📥 Installing dependencies (non-interactive mode)..."
            retry_command 3 2 "npm install" "dependency installation"
        fi
    fi
    
    # Verify framework is available
    if ! npm list "$DETECTED_FRAMEWORK" >/dev/null 2>&1 && [[ "$DETECTED_FRAMEWORK" != "unknown" ]]; then
        print_log "FATAL" "$DETECTED_FRAMEWORK not found in dependencies. Please add it to package.json"
    fi
    
    print_log "SUCCESS" "✅ Dependencies validated"
}

# 🏗️ Step 3: Project Build
step_build_project() {
    if ! interactive_step "Project Build" "Building production-ready static files" "$AUTO_CONFIRM"; then
        return 0
    fi
    
    print_log "STATUS" "🏗️ Building project for production..."
    
    # Clean previous build
    if [[ -d "$BUILD_DIR" ]]; then
        if [[ "$IS_INTERACTIVE" == "true" ]]; then
            if interactive_confirm "Previous build found. Clean it first?" "true"; then
                safe_remove "$BUILD_DIR" "previous build directory"
            fi
        else
            print_log "INFO" "🧹 Cleaning previous build (non-interactive mode)..."
            safe_remove "$BUILD_DIR" "previous build directory"
        fi
    fi
    
    # Show build info
    print_log "INFO" "🔨 Running: $BUILD_COMMAND"
    
    # Execute build with progress
    local start_time
    start_time=$(date +%s)
    
    if [[ "$VERBOSE" == "true" ]]; then
        eval "$BUILD_COMMAND"
    else
        if ! eval "$BUILD_COMMAND" >/dev/null 2>&1; then
            print_log "ERROR" "Build failed! Running with verbose output..."
            eval "$BUILD_COMMAND"
            exit 1
        fi
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Verify build output
    validate_directory "$BUILD_DIR" "build output directory"
    
    if [[ -z "$(ls -A "$BUILD_DIR" 2>/dev/null)" ]]; then
        print_log "FATAL" "Build directory is empty! Check your build configuration."
    fi
    
    # Build statistics
    local file_count
    file_count=$(find "$BUILD_DIR" -type f | wc -l)
    local total_size
    total_size=$(du -sb "$BUILD_DIR" 2>/dev/null | cut -f1 || echo "0")
    
    print_log "SUCCESS" "✅ Build completed in $(format_duration $duration)"
    print_log "INFO" "📊 Generated $file_count files ($(format_file_size $total_size))"
}

# 📁 Step 4: Create Isolated Workspace
step_create_isolated_workspace() {
    if ! interactive_step "Isolated Workspace" "Creating secure temporary environment" "$AUTO_CONFIRM"; then
        return 0
    fi
    
    print_log "STATUS" "📁 Creating isolated workspace..."
    
    # Temporarily disable cleanup trap during critical operations
    disable_cleanup_trap
    
    # Create temporary directory
    TEMP_DIR=$(create_secure_temp_dir "$APP_NAME")
    TEMP_ARCHIVE="$TEMP_DIR/project.zip"
    
    print_log "DEBUG" "Created temporary directory: $TEMP_DIR"
    print_log "DEBUG" "Archive will be: $TEMP_ARCHIVE"
    
    # Re-enable cleanup trap
    enable_cleanup_trap
    
    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        local has_changes="true"
        if [[ "$IS_INTERACTIVE" == "true" ]]; then
            interactive_confirm "Uncommitted changes detected. Continue?" "true" \
                "Warning: The deployment will use the current committed state, not uncommitted changes."
        else
            print_log "WARNING" "Uncommitted changes detected. Using committed state for deployment."
        fi
    fi
    
    print_log "SUCCESS" "✅ Temporary workspace created: $TEMP_DIR"
}

# 📦 Step 5: Create Project Archive
step_create_project_archive() {
    if ! interactive_step "Project Archive" "Creating compressed project snapshot" "$AUTO_CONFIRM"; then
        return 0
    fi
    
    print_log "STATUS" "📦 Creating project archive..."
    
    # Temporarily disable cleanup trap during archive creation
    disable_cleanup_trap
    
    local start_time
    start_time=$(date +%s)
    
    print_log "INFO" "🗜️ Creating compressed archive..."
    
    # Verify temporary directory still exists
    if [[ ! -d "$TEMP_DIR" ]]; then
        print_log "FATAL" "Temporary directory disappeared: $TEMP_DIR (cleanup trap may have been executed prematurely)"
    fi
    
    # Verify archive path is valid
    if [[ -z "$TEMP_ARCHIVE" ]]; then
        print_log "FATAL" "Archive path not set"
    fi
    
    print_log "DEBUG" "Archive path: $TEMP_ARCHIVE"
    print_log "DEBUG" "Temp directory exists: $(test -d "$TEMP_DIR" && echo "yes" || echo "no")"
    
    # Create ZIP archive with exclusions (much simpler than tar!)
    if ! zip -0 -r -q "$TEMP_ARCHIVE" . \
        -x "node_modules/*" \
        -x ".git/objects/pack/*" \
        -x ".git/logs/*" \
        -x ".git/refs/remotes/origin/*" \
        -x "*.log" \
        -x ".DS_Store" \
        -x "Thumbs.db" \
        -x "*.tmp" \
        -x "coverage/*" \
        -x ".nyc_output/*" \
        -x "dist/*" \
        -x ".next/*" \
        -x ".vercel/*" \
        -x ".cache/*" \
        -x "*.swp" \
        -x "*.swo"; then
        print_log "FATAL" "Failed to create project archive"
    fi
    
    # Verify archive integrity
    if ! unzip -t "$TEMP_ARCHIVE" >/dev/null 2>&1; then
        print_log "FATAL" "Archive integrity check failed"
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local archive_size
    archive_size=$(stat -f%z "$TEMP_ARCHIVE" 2>/dev/null || stat -c%s "$TEMP_ARCHIVE" 2>/dev/null || echo "0")
    
    # Re-enable cleanup trap
    enable_cleanup_trap
    
    print_log "SUCCESS" "✅ Archive created in $(format_duration $duration) ($(format_file_size $archive_size))"
}

# 🚚 Step 6: Deploy from Isolated Environment
step_deploy_from_isolated_env() {
    if ! interactive_step "GitHub Pages Deploy" "Deploying to GitHub Pages from isolated environment" "$AUTO_CONFIRM"; then
        return 0
    fi
    
    print_log "STATUS" "🚚 Deploying from isolated environment..."
    
    # Extract to temporary workspace
    local work_dir="$TEMP_DIR/workspace"
    mkdir -p "$work_dir"
    
    print_log "INFO" "📤 Extracting project to temporary workspace..."
    if ! unzip -q "$TEMP_ARCHIVE" -d "$work_dir" 2>/dev/null; then
        print_log "FATAL" "Failed to extract project archive"
    fi
    
    # Change to work directory
    local original_pwd
    original_pwd=$(pwd)
    cd "$work_dir" || print_log "FATAL" "Cannot access temporary workspace"
    
    # Validate extracted environment
    validate_extracted_environment
    
    # Perform actual deployment
    perform_github_pages_deployment
    
    # Return to original directory
    cd "$original_pwd" || true
    
    print_log "SUCCESS" "✅ Deployment from isolated environment completed"
}

# ✅ Validate extracted environment
validate_extracted_environment() {
    print_log "DEBUG" "Validating extracted environment..."
    
    validate_directory ".git" "Git repository"
    validate_directory "$BUILD_DIR" "Build output"
    
    # Test git operations
    if ! git status >/dev/null 2>&1; then
        print_log "FATAL" "Git operations failed in extracted environment"
    fi
    
    print_log "DEBUG" "Extracted environment validated"
}

# 🎯 Perform GitHub Pages deployment
perform_github_pages_deployment() {
    print_log "DEBUG" "Performing GitHub Pages deployment..."
    
    # Switch to or create gh-pages branch
    if git show-ref --verify --quiet "refs/heads/$GH_PAGES_BRANCH"; then
        print_log "INFO" "🔄 Switching to existing $GH_PAGES_BRANCH branch..."
        
        # Try to checkout, if it fails due to corruption, recreate the branch
        if ! git checkout "$GH_PAGES_BRANCH" --quiet 2>/dev/null; then
            print_log "WARNING" "Existing $GH_PAGES_BRANCH branch appears corrupted, recreating..."
            git branch -D "$GH_PAGES_BRANCH" 2>/dev/null || true
            git checkout --orphan "$GH_PAGES_BRANCH" --quiet
            git rm -rf . --quiet 2>/dev/null || true
        else
            # Clean existing files (except .git)
            find . -mindepth 1 -maxdepth 1 -not -name '.git' -exec rm -rf {} \; 2>/dev/null || true
        fi
    else
        print_log "INFO" "🆕 Creating new $GH_PAGES_BRANCH branch..."
        git checkout --orphan "$GH_PAGES_BRANCH" --quiet
        git rm -rf . --quiet 2>/dev/null || true
    fi
    
    # Copy build files to root
    print_log "INFO" "📋 Copying build files to repository root..."
    cp -r "$BUILD_DIR"/* . 2>/dev/null || true
    cp -r "$BUILD_DIR"/.* . 2>/dev/null || true
    
    # Create .nojekyll to prevent Jekyll processing
    echo "" > .nojekyll
    print_log "DEBUG" "Created .nojekyll file"
    
    # Copy CNAME if it exists in the original branch
    if git show "$ORIGINAL_BRANCH":CNAME >/dev/null 2>&1; then
        git show "$ORIGINAL_BRANCH":CNAME > CNAME
        print_log "INFO" "📝 CNAME file copied from $ORIGINAL_BRANCH branch"
    fi
    
    # Stage all files
    git add .
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        print_log "INFO" "📝 No changes detected - deployment up to date"
        return 0
    fi
    
    # Show what will be committed
    if [[ "$VERBOSE" == "true" ]]; then
        print_log "DEBUG" "Files to be committed:"
        git diff --cached --name-status
    fi
    
    # Commit changes
    local commit_message
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local commit_hash
    commit_hash="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    
    commit_message="🚀 Deploy to GitHub Pages - $timestamp

🔨 Built from: $ORIGINAL_BRANCH ($commit_hash)
📦 Framework: $DETECTED_FRAMEWORK
🏗️ Build dir: $BUILD_DIR
🤖 Deployed via: pages-deploy"
    
    git commit -m "$commit_message" --quiet
    print_log "SUCCESS" "✅ Changes committed"
    
    # Push to GitHub
    if [[ "$DRY_RUN" == "true" ]]; then
        print_log "INFO" "🏃 DRY RUN: Would push to origin/$GH_PAGES_BRANCH"
        print_log "INFO" "   Commit: $commit_message"
    else
        if [[ "$IS_INTERACTIVE" == "true" ]]; then
            if interactive_confirm "Push to GitHub Pages?" "true"; then
                print_log "STATUS" "🚀 Pushing to GitHub Pages..."
                
                if retry_command 3 2 "git push origin $GH_PAGES_BRANCH" "GitHub Pages push"; then
                    print_log "SUCCESS" "🎉 Successfully deployed to GitHub Pages!"
                else
                    print_log "FATAL" "Failed to push to GitHub Pages"
                fi
            else
                print_log "INFO" "📦 Deployment prepared but not pushed (user choice)"
            fi
        else
            print_log "STATUS" "🚀 Pushing to GitHub Pages (non-interactive mode)..."
            
            if retry_command 3 2 "git push origin $GH_PAGES_BRANCH" "GitHub Pages push"; then
                print_log "SUCCESS" "🎉 Successfully deployed to GitHub Pages!"
            else
                print_log "FATAL" "Failed to push to GitHub Pages"
            fi
        fi
    fi
}

# 🎯 Main deployment pipeline
run_deployment_pipeline() {
    local start_time
    start_time=$(date +%s)
    
    print_header "Enterprise GitHub Pages Deploy" "Isolation-First Architecture • Zero Side-Effects"
    
    # Initialize interactive mode
    init_interactive
    
    # Set up cleanup
    setup_cleanup_trap
    
    # Initialize configuration
    init_config
    
    # Execute pipeline steps
    TOTAL_STEPS=6
    CURRENT_STEP=1
    
    step_validate_environment
    step_check_dependencies
    step_build_project
    step_create_isolated_workspace
    step_create_project_archive
    step_deploy_from_isolated_env
    
    local end_time
    end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    print_log "SUCCESS" "🎉 Pipeline completed in $(format_duration $total_duration)"
}

# 🔧 Pipeline with custom options
run_deployment_with_options() {
    local auto_confirm="${1:-false}"
    local dry_run="${2:-false}"
    local verbose="${3:-false}"
    
    export AUTO_CONFIRM="$auto_confirm"
    export DRY_RUN="$dry_run"
    export VERBOSE="$verbose"
    
    run_deployment_pipeline
}
