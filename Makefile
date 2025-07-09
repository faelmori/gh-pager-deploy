# 🚀 Makefile for pages-deploy
# Enterprise GitHub Pages deployment tool

# 🎨 Colors for beautiful output
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BLUE := \033[34m
RESET := \033[0m

# 📁 Configuration
SCRIPT_DIR := $(shell pwd)
DEPLOY_SCRIPT := $(SCRIPT_DIR)/bin/deploy.sh
TEST_SCRIPT := $(SCRIPT_DIR)/tests/interactive_test.sh

# 🎯 Default target
.DEFAULT_GOAL := help

# 📖 Help target
help: ## Show this help message
	@echo "$(BLUE)🚀 pages-deploy - Enterprise GitHub Pages Deploy$(RESET)"
	@echo "$(BLUE)   Modular deployment tool with interactive pipeline$(RESET)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(RESET)"
	@echo "  make deploy          # Interactive deployment"
	@echo "  make deploy-auto     # Automated deployment"
	@echo "  make test            # Run all tests"
	@echo "  make install         # Install globally"
	@echo "  make demo            # Interactive demo with rafa-mori"
	@echo "  make test-with-rafa-mori  # Test with real Next.js project"

# 🚀 Main deployment targets
deploy: ## Deploy with interactive mode (default)
	@echo "$(BLUE)🚀 Starting interactive deployment...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@$(DEPLOY_SCRIPT)

deploy-auto: ## Deploy with automated mode (no prompts)
	@echo "$(BLUE)🤖 Starting automated deployment...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@$(DEPLOY_SCRIPT) --yes

deploy-dry: ## Test deployment without pushing (dry run)
	@echo "$(YELLOW)🧪 Starting dry run deployment...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@$(DEPLOY_SCRIPT) --dry-run

deploy-verbose: ## Deploy with verbose output
	@echo "$(BLUE)🔍 Starting verbose deployment...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@$(DEPLOY_SCRIPT) --verbose

# 🧪 Testing targets
test: ## Run all tests
	@echo "$(BLUE)🧪 Running test suite...$(RESET)"
	@chmod +x $(TEST_SCRIPT)
	@$(TEST_SCRIPT)

test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)🔍 Running verbose tests...$(RESET)"
	@chmod +x $(TEST_SCRIPT)
	@VERBOSE=true $(TEST_SCRIPT)

test-interactive: ## Test interactive functions specifically
	@echo "$(BLUE)🤖 Testing interactive functions...$(RESET)"
	@chmod +x $(TEST_SCRIPT)
	@IS_INTERACTIVE=true $(TEST_SCRIPT)

# 🎯 Real project testing targets
test-with-rafa-mori: ## Test deployment with real Next.js project (rafa-mori)
	@echo "$(BLUE)🧪 Testing with real Next.js project...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@cd ../rafa-mori && $(DEPLOY_SCRIPT) --dry-run --verbose

test-rafa-mori-auto: ## Test automated deployment with rafa-mori project
	@echo "$(BLUE)🤖 Testing automated deployment with rafa-mori...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@cd ../rafa-mori && IS_INTERACTIVE=false $(DEPLOY_SCRIPT) --dry-run --yes

demo: ## Show interactive demo with rafa-mori project
	@echo "$(BLUE)🎭 Interactive demo with real Next.js project...$(RESET)"
	@echo "$(YELLOW)This will demonstrate the full interactive pipeline$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@cd ../rafa-mori && $(DEPLOY_SCRIPT) --dry-run

# 🔧 Development targets
setup: ## Set up development environment
	@echo "$(BLUE)🔧 Setting up development environment...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@chmod +x $(TEST_SCRIPT)
	@echo "$(GREEN)✅ Development environment ready$(RESET)"

install: ## Install globally (creates symlink in /usr/local/bin)
	@echo "$(BLUE)📦 Installing pages-deploy globally...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@sudo ln -sf $(DEPLOY_SCRIPT) /usr/local/bin/pages-deploy
	@echo "$(GREEN)✅ Installed! Use 'pages-deploy' from anywhere$(RESET)"

uninstall: ## Remove global installation
	@echo "$(YELLOW)🗑️  Uninstalling pages-deploy...$(RESET)"
	@sudo rm -f /usr/local/bin/pages-deploy
	@echo "$(GREEN)✅ Uninstalled successfully$(RESET)"

# 📁 Project maintenance
clean: ## Clean temporary files and caches
	@echo "$(YELLOW)🧹 Cleaning temporary files...$(RESET)"
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@find . -name "*.log" -delete 2>/dev/null || true
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@rm -rf /tmp/pages-deploy.* 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

validate: ## Validate shell scripts with shellcheck
	@echo "$(BLUE)🔍 Validating shell scripts...$(RESET)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "$(BLUE)Running shellcheck...$(RESET)"; \
		find . -name "*.sh" -exec shellcheck {} \; || true; \
		echo "$(GREEN)✅ Validation completed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  shellcheck not found. Install it for script validation.$(RESET)"; \
	fi

# 📚 Documentation targets
docs: ## Generate documentation
	@echo "$(BLUE)📚 Generating documentation...$(RESET)"
	@echo "$(YELLOW)ℹ️  Documentation is in README.md and docs/$(RESET)"

# 🎯 Framework-specific targets
deploy-nextjs: ## Deploy Next.js project with optimizations
	@echo "$(BLUE)⚡ Deploying Next.js project...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@FRAMEWORK=nextjs $(DEPLOY_SCRIPT) --yes

deploy-vite: ## Deploy Vite project with optimizations
	@echo "$(BLUE)⚡ Deploying Vite project...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@FRAMEWORK=vite $(DEPLOY_SCRIPT) --yes

deploy-astro: ## Deploy Astro project with optimizations
	@echo "$(BLUE)⚡ Deploying Astro project...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@FRAMEWORK=astro $(DEPLOY_SCRIPT) --yes

# 🚀 Quick deployment shortcuts
quick: deploy-auto ## Quick automated deployment (alias for deploy-auto)

# 🔍 Debug targets
debug: ## Deploy with maximum debugging information
	@echo "$(BLUE)🐛 Starting debug deployment...$(RESET)"
	@chmod +x $(DEPLOY_SCRIPT)
	@VERBOSE=true DEBUG=true $(DEPLOY_SCRIPT) --verbose --dry-run

info: ## Show environment and configuration info
	@echo "$(BLUE)ℹ️  pages-deploy Environment Information$(RESET)"
	@echo ""
	@echo "$(YELLOW)Script Location:$(RESET) $(SCRIPT_DIR)"
	@echo "$(YELLOW)Deploy Script:$(RESET) $(DEPLOY_SCRIPT)"
	@echo "$(YELLOW)Test Script:$(RESET) $(TEST_SCRIPT)"
	@echo ""
	@echo "$(YELLOW)System Information:$(RESET)"
	@echo "  Shell: $$SHELL"
	@echo "  OS: $$(uname -s)"
	@echo "  Architecture: $$(uname -m)"
	@echo ""
	@echo "$(YELLOW)Available Tools:$(RESET)"
	@command -v git >/dev/null && echo "  ✅ git: $$(git --version)" || echo "  ❌ git: not found"
	@command -v npm >/dev/null && echo "  ✅ npm: $$(npm --version)" || echo "  ❌ npm: not found"
	@command -v node >/dev/null && echo "  ✅ node: $$(node --version)" || echo "  ❌ node: not found"
	@command -v zip >/dev/null && echo "  ✅ zip: available" || echo "  ❌ zip: not found"
	@command -v shellcheck >/dev/null && echo "  ✅ shellcheck: available" || echo "  ⚠️  shellcheck: not found (optional)"
	@echo ""
	@if [ -f "package.json" ]; then \
		echo "$(YELLOW)Project Information:$(RESET)"; \
		echo "  📦 package.json: found"; \
		echo "  🎯 Framework: $$($(SCRIPT_DIR)/src/config.sh && detect_framework 2>/dev/null || echo 'unknown')"; \
		echo "  🏗️  Build script: $$(grep -o '"build": "[^"]*"' package.json | cut -d'"' -f4 || echo 'not found')"; \
	else \
		echo "$(YELLOW)No package.json found in current directory$(RESET)"; \
	fi

# 🧪 CI/CD targets
ci-test: ## Run tests suitable for CI environment
	@echo "$(BLUE)🤖 Running CI tests...$(RESET)"
	@IS_INTERACTIVE=false VERBOSE=true $(MAKE) test

ci-deploy: ## Deploy in CI environment
	@echo "$(BLUE)🚀 Running CI deployment...$(RESET)"
	@IS_INTERACTIVE=false $(MAKE) deploy-auto

# 📋 Status and monitoring
status: ## Show current git and project status
	@echo "$(BLUE)📊 Project Status$(RESET)"
	@echo ""
	@if git rev-parse --git-dir >/dev/null 2>&1; then \
		echo "$(YELLOW)Git Status:$(RESET)"; \
		echo "  📍 Branch: $$(git branch --show-current 2>/dev/null || echo 'unknown')"; \
		echo "  🔗 Remote: $$(git config --get remote.origin.url 2>/dev/null || echo 'not set')"; \
		echo "  📝 Last commit: $$(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'none')"; \
		if ! git diff --quiet 2>/dev/null; then \
			echo "  ⚠️  Uncommitted changes detected"; \
		else \
			echo "  ✅ Working directory clean"; \
		fi; \
	else \
		echo "$(RED)❌ Not a git repository$(RESET)"; \
	fi
	@echo ""
	@if [ -d "node_modules" ]; then \
		echo "$(GREEN)✅ Dependencies installed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  Dependencies not installed (run npm install)$(RESET)"; \
	fi

# 🔄 Update targets
update: ## Update pages-deploy to latest version (if installed via git)
	@echo "$(BLUE)🔄 Updating pages-deploy...$(RESET)"
	@if git rev-parse --git-dir >/dev/null 2>&1; then \
		git pull origin main && echo "$(GREEN)✅ Updated successfully$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  Not a git repository. Manual update required.$(RESET)"; \
	fi

# 🎯 Make targets PHONY
.PHONY: help deploy deploy-auto deploy-dry deploy-verbose test test-verbose test-interactive
.PHONY: setup install uninstall clean validate docs info debug status update
.PHONY: deploy-nextjs deploy-vite deploy-astro quick ci-test ci-deploy
.PHONY: test-with-rafa-mori test-rafa-mori-auto demo
