# 🚀 pages-deploy

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-222222?style=for-the-badge&logo=github&logoColor=white)](https://pages.github.com/)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Enterprise-grade modular deployment system for GitHub Pages** with isolation-first architecture and zero side-effects guarantee.

## ✨ Features

- 🤖 **Smart Interactive Mode** - Step-by-step guidance with beautiful prompts
- 🚀 **Multi-Framework Support** - Next.js, Vite, Astro, Vue, React, Angular, Svelte, Nuxt
- 🔒 **Zero Side-Effects** - Complete environment isolation with secure cleanup
- 🎯 **Auto-Detection** - Intelligent framework and configuration detection
- 📦 **Modular Architecture** - Clean separation of concerns, easy to extend
- 🧪 **Fully Tested** - Comprehensive test suite with unit tests
- 🌍 **CI/CD Ready** - Works perfectly in automated environments
- 🎨 **Beautiful Output** - Colorful logs with progress indicators

## 🚀 Quick Start

```bash
# Clone or download the pages-deploy tool
git clone https://github.com/your-username/pages-deploy.git
cd pages-deploy

# Make the deploy script executable
chmod +x bin/deploy.sh

# Run interactive deployment
./bin/deploy.sh

# Or automated deployment
./bin/deploy.sh --yes
```

## 🎯 Interactive Mode Demo

```bash
$ ./bin/deploy.sh

🚀 Enterprise GitHub Pages Deploy
   Modular GitHub Pages deployment tool

[🔄 10:30:15] 🤖 Interactive mode enabled
[ℹ️  10:30:15] You'll be prompted before each major step

[1/6] Environment Validation
[ℹ️  10:30:15] Checking git repository, dependencies, and permissions
[🤖 10:30:15] Proceed with this step? (y/N)
❯ y

[✅ 10:30:16] ✅ Environment validation completed
[ℹ️  10:30:16] 📍 Detected framework: nextjs
[ℹ️  10:30:16] 📍 Build directory: out
[ℹ️  10:30:16] 🔗 Repository: https://github.com/user/project

[2/6] Dependencies Check
[🤖 10:30:16] Proceed with this step? (y/N)
❯ y

[✅ 10:30:18] ✅ Dependencies validated

# ... continues with each step
```

## 📖 Usage

### Interactive Mode (Default)
Perfect for first-time deployments or when you want full control:

```bash
./bin/deploy.sh
```

### Automated Mode
Ideal for CI/CD pipelines:

```bash
./bin/deploy.sh --yes
```

### Advanced Options

```bash
# Dry run (test without pushing)
./bin/deploy.sh --dry-run

# Verbose output for debugging
./bin/deploy.sh --verbose

# Override framework detection
./bin/deploy.sh --framework vite

# Custom build directory
./bin/deploy.sh --build-dir dist

# Custom target branch
./bin/deploy.sh --branch main

# Combined options
./bin/deploy.sh --yes --verbose --dry-run
```

## 🎨 Framework Support

| Framework | Auto-Detection | Build Command | Build Dir | Status |
|-----------|----------------|---------------|-----------|---------|
| **Next.js** | ✅ `next.config.js` | `npm run build` | `out` | ✅ Full Support |
| **Vite** | ✅ `vite.config.js` | `npm run build` | `dist` | ✅ Full Support |
| **Astro** | ✅ `astro.config.mjs` | `npm run build` | `dist` | ✅ Full Support |
| **Vue** | ✅ `vue.config.js` | `npm run build` | `dist` | ✅ Full Support |
| **React** | ✅ `package.json` | `npm run build` | `build` | ✅ Full Support |
| **Angular** | ✅ `angular.json` | `ng build --prod` | `dist` | ✅ Full Support |
| **Svelte** | ✅ `svelte.config.js` | `npm run build` | `public` | ✅ Full Support |
| **Nuxt** | ✅ `nuxt.config.js` | `npm run generate` | `dist` | ✅ Full Support |

## 🏗️ Architecture

```
pages-deploy/
├── bin/
│   └── deploy.sh              # 🚀 Entry point
├── src/
│   ├── core.sh                # ⚡ Main deployment pipeline
│   ├── interactive.sh         # 🤖 Interactive input system
│   ├── utils.sh               # 🛠️ Utilities and logging
│   └── config.sh              # ⚙️ Configuration management
├── presets/
│   └── nextjs.sh              # 🎨 Next.js optimizations
├── tests/
│   ├── interactive_test.sh    # 🧪 Unit tests
│   └── dry_run_test.sh        # 🧪 Integration tests
└── docs/
    └── github-pages-deploy.md # 📚 Detailed documentation
```

## 🤖 Interactive Input System

The core innovation of this tool is the smart `interactive_input` function that adapts to both interactive and automated environments:

```bash
# Interactive mode - prompts user
result=$(interactive_input "confirm" "Deploy to production?" "true" "false" "true")

# Non-interactive mode - uses defaults
IS_INTERACTIVE=false
result=$(interactive_input "confirm" "Deploy to production?" "true" "false" "true")
# Returns: "true" (the default)
```

### Input Types

- `text` - Simple text output
- `ask|request|prompt` - User input with prompt
- `password|secure` - Hidden password input
- `confirm|yes_no` - Yes/No confirmation
- `select|menu` - Multiple choice selection
- `callback|function` - Execute function/command

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `IS_INTERACTIVE` | Enable/disable interactive mode | `true` |
| `DRY_RUN` | Test mode without actual deployment | `false` |
| `VERBOSE` | Enable detailed output | `false` |
| `BUILD_DIR` | Override build directory | Auto-detected |
| `FRAMEWORK` | Override framework detection | Auto-detected |
| `GH_PAGES_BRANCH` | Target deployment branch | `gh-pages` |

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
./tests/interactive_test.sh

# Run with verbose output
VERBOSE=true ./tests/interactive_test.sh

# Test specific framework preset
./tests/preset_test.sh nextjs
```

## 🎯 CI/CD Integration

### GitHub Actions

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Deploy to GitHub Pages
      run: |
        chmod +x pages-deploy/bin/deploy.sh
        IS_INTERACTIVE=false pages-deploy/bin/deploy.sh --yes
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Other CI Systems

```bash
# GitLab CI
script:
  - IS_INTERACTIVE=false ./pages-deploy/bin/deploy.sh --yes

# Jenkins
sh 'IS_INTERACTIVE=false ./pages-deploy/bin/deploy.sh --yes'

# CircleCI
- run: IS_INTERACTIVE=false ./pages-deploy/bin/deploy.sh --yes
```

## 🔒 Security Features

- ✅ **Input Sanitization** - All user inputs are sanitized
- ✅ **Secure Temporary Files** - Proper permissions and cleanup
- ✅ **Isolated Execution** - No side-effects on your working directory
- ✅ **Git State Protection** - Automatic return to original branch
- ✅ **Error Recovery** - Comprehensive cleanup on failure

## 🎨 Customization

### Adding New Framework Support

1. Create preset file: `presets/myframework.sh`
2. Implement detection logic in `src/config.sh`
3. Add configuration to framework arrays
4. Test with the framework's project structure

### Custom Build Process

```bash
# Override build command
BUILD_COMMAND="yarn build:prod" ./bin/deploy.sh

# Custom build directory
BUILD_DIR="public" ./bin/deploy.sh

# Multiple build steps
BUILD_COMMAND="npm run prebuild && npm run build && npm run postbuild" ./bin/deploy.sh
```

## 🎯 Roadmap

- [ ] **GitHub Action** - Official action for marketplace
- [ ] **NPM Package** - `npx pages-deploy`
- [ ] **Docker Support** - Containerized deployments
- [ ] **Multiple Targets** - Deploy to Netlify, Vercel, etc.
- [ ] **Rollback System** - Easy deployment rollbacks
- [ ] **Analytics Integration** - Deploy performance metrics
- [ ] **Multi-site Support** - Deploy multiple projects

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by enterprise deployment practices
- Built with ❤️ for the developer community
- Special thanks to all contributors and testers

---

<div align="center">

**Made with ❤️ for better GitHub Pages deployments**

[Report Bug](https://github.com/your-username/pages-deploy/issues) • [Request Feature](https://github.com/your-username/pages-deploy/issues) • [Documentation](docs/)

</div>
