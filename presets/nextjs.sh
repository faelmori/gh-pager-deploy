#!/usr/bin/env bash

# 🎨 Next.js Preset for GitHub Pages Deploy
# Optimized configuration and validation for Next.js projects

# 📦 Next.js specific configuration
NEXTJS_CONFIG_FILES=("next.config.js" "next.config.mjs" "next.config.ts")
NEXTJS_BUILD_DIR="out"
NEXTJS_BUILD_COMMAND="npm run build"

# 🔍 Validate Next.js project
validate_nextjs_project() {
    print_log "INFO" "🔍 Validating Next.js project configuration..."
    
    # Check for Next.js config file
    local config_found=""
    for config_file in "${NEXTJS_CONFIG_FILES[@]}"; do
        if [[ -f "$config_file" ]]; then
            config_found="$config_file"
            break
        fi
    done
    
    if [[ -z "$config_found" ]]; then
        print_log "WARNING" "No Next.js config file found. Creating basic next.config.js..."
        create_nextjs_config
    else
        validate_nextjs_config "$config_found"
    fi
    
    # Check package.json for Next.js and required scripts
    validate_nextjs_package_json
    
    # Check for pages or app directory
    validate_nextjs_directory_structure
    
    print_log "SUCCESS" "✅ Next.js project validation completed"
}

# 🔧 Create basic Next.js config for GitHub Pages
create_nextjs_config() {
    local repo_name
    repo_name=$(get_project_info "name")
    
    cat > next.config.js << EOF
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true
  },
  basePath: process.env.NODE_ENV === 'production' ? '/${repo_name}' : '',
  assetPrefix: process.env.NODE_ENV === 'production' ? '/${repo_name}' : '',
}

module.exports = nextConfig
EOF
    
    print_log "SUCCESS" "✅ Created next.config.js with GitHub Pages optimization"
    print_log "INFO" "📝 Configuration includes:"
    print_log "INFO" "   • Static export enabled"
    print_log "INFO" "   • Trailing slashes for compatibility"
    print_log "INFO" "   • Unoptimized images for static hosting"
    print_log "INFO" "   • Base path set to /$repo_name"
}

# ✅ Validate existing Next.js config
validate_nextjs_config() {
    local config_file="$1"
    print_log "INFO" "🔍 Validating $config_file..."
    
    # Check for static export
    if ! grep -q "output.*export" "$config_file"; then
        print_log "WARNING" "Static export not enabled in $config_file"
        
        if interactive_confirm "Enable static export for GitHub Pages?" "true"; then
            fix_nextjs_static_export "$config_file"
        fi
    fi
    
    # Check for image optimization
    if ! grep -q "unoptimized.*true" "$config_file"; then
        print_log "WARNING" "Image optimization should be disabled for static export"
        
        if interactive_confirm "Disable image optimization?" "true"; then
            fix_nextjs_image_optimization "$config_file"
        fi
    fi
    
    print_log "DEBUG" "Next.js configuration validated"
}

# 🔧 Fix static export in Next.js config
fix_nextjs_static_export() {
    local config_file="$1"
    print_log "INFO" "🔧 Adding static export to $config_file..."
    
    # This is a simple approach - in production, you'd want more sophisticated parsing
    if grep -q "const nextConfig" "$config_file"; then
        sed -i.bak 's/const nextConfig = {/const nextConfig = {\n  output: '\''export'\'',/' "$config_file"
        print_log "SUCCESS" "✅ Static export enabled"
    else
        print_log "WARNING" "Could not automatically fix $config_file. Please add output: 'export' manually."
    fi
}

# 🔧 Fix image optimization in Next.js config
fix_nextjs_image_optimization() {
    local config_file="$1"
    print_log "INFO" "🔧 Disabling image optimization in $config_file..."
    
    if grep -q "images:" "$config_file"; then
        sed -i.bak 's/images: {/images: {\n    unoptimized: true,/' "$config_file"
    else
        sed -i.bak 's/const nextConfig = {/const nextConfig = {\n  images: {\n    unoptimized: true\n  },/' "$config_file"
    fi
    
    print_log "SUCCESS" "✅ Image optimization disabled"
}

# 📦 Validate package.json for Next.js
validate_nextjs_package_json() {
    print_log "DEBUG" "Validating package.json for Next.js..."
    
    # Check for Next.js dependency
    if ! grep -q '"next"' package.json; then
        print_log "FATAL" "Next.js not found in package.json dependencies"
    fi
    
    # Check for build script
    if ! grep -q '"build"' package.json; then
        print_log "WARNING" "No build script found in package.json"
        
        if interactive_confirm "Add default Next.js build script?" "true"; then
            add_nextjs_build_script
        fi
    fi
    
    # Verify build script contains Next.js build command
    local build_script
    build_script=$(grep -o '"build": "[^"]*"' package.json | cut -d'"' -f4 || echo "")
    
    if [[ "$build_script" != *"next build"* ]]; then
        print_log "WARNING" "Build script doesn't appear to be Next.js: $build_script"
    fi
}

# 📝 Add Next.js build script
add_nextjs_build_script() {
    print_log "INFO" "📝 Adding Next.js build script to package.json..."
    
    # Use jq if available, otherwise use sed
    if command -v jq >/dev/null 2>&1; then
        jq '.scripts.build = "next build"' package.json > package.json.tmp && mv package.json.tmp package.json
    else
        # Simple sed approach - works for basic cases
        sed -i.bak 's/"scripts": {/"scripts": {\n    "build": "next build",/' package.json
    fi
    
    print_log "SUCCESS" "✅ Build script added"
}

# 📁 Validate Next.js directory structure
validate_nextjs_directory_structure() {
    print_log "DEBUG" "Validating Next.js directory structure..."
    
    local has_pages=""
    local has_app=""
    
    if [[ -d "pages" ]]; then
        has_pages="true"
        print_log "INFO" "📁 Found pages directory (Pages Router)"
    fi
    
    if [[ -d "src/app" ]] || [[ -d "app" ]]; then
        has_app="true"
        print_log "INFO" "📁 Found app directory (App Router)"
    fi
    
    if [[ -z "$has_pages" && -z "$has_app" ]]; then
        print_log "WARNING" "No pages or app directory found"
        print_log "INFO" "This might not be a valid Next.js project structure"
        
        if [[ "$IS_INTERACTIVE" == "true" ]]; then
            if ! interactive_confirm "Continue anyway?" "false"; then
                print_log "FATAL" "Invalid Next.js project structure"
            fi
        fi
    fi
    
    # Check for public directory
    if [[ ! -d "public" ]]; then
        print_log "WARNING" "No public directory found. Static assets may not be served correctly."
    fi
}

# 🎯 Next.js specific build optimizations
optimize_nextjs_build() {
    print_log "INFO" "🎯 Applying Next.js build optimizations..."
    
    # Set NODE_ENV to production
    export NODE_ENV="production"
    
    # Optimize build command for static export
    if [[ "$BUILD_COMMAND" == "npm run build" ]]; then
        export BUILD_COMMAND="NODE_ENV=production npm run build"
    fi
    
    print_log "SUCCESS" "✅ Next.js optimizations applied"
}

# 🔍 Post-build validation for Next.js
validate_nextjs_build() {
    print_log "INFO" "🔍 Validating Next.js build output..."
    
    # Check for static export output
    if [[ ! -d "$BUILD_DIR" ]]; then
        print_log "FATAL" "Build directory $BUILD_DIR not found. Check your next.config.js output setting."
    fi
    
    # Check for index.html
    if [[ ! -f "$BUILD_DIR/index.html" ]]; then
        print_log "WARNING" "No index.html found in build output. This might cause issues with GitHub Pages."
    fi
    
    # Check for _next directory
    if [[ -d "$BUILD_DIR/_next" ]]; then
        print_log "SUCCESS" "✅ Found Next.js static assets in _next directory"
    fi
    
    # Check for 404.html
    if [[ ! -f "$BUILD_DIR/404.html" ]]; then
        print_log "WARNING" "No custom 404.html found. Consider adding one for better UX."
    fi
    
    print_log "SUCCESS" "✅ Next.js build validation completed"
}

# 🎨 Initialize Next.js preset
init_nextjs_preset() {
    print_log "INFO" "🎨 Initializing Next.js preset..."
    
    # Override default configuration
    export BUILD_DIR="out"
    export BUILD_COMMAND="npm run build"
    export FRAMEWORK="nextjs"
    
    # Validate project
    validate_nextjs_project
    
    # Apply optimizations
    optimize_nextjs_build
    
    print_log "SUCCESS" "✅ Next.js preset initialized"
}

# 🚀 Next.js preset hook for post-build
nextjs_post_build_hook() {
    validate_nextjs_build
}

# Export functions for use by main deployment script
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Only export if being sourced
    export -f validate_nextjs_project
    export -f init_nextjs_preset
    export -f nextjs_post_build_hook
fi
