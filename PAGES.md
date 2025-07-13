# GitHub Pages Documentation Site

This document provides comprehensive information about the GitHub Pages setup for the Zellij Utils project, including configuration, deployment, and maintenance instructions.

## Overview

The Zellij Utils documentation site is hosted on GitHub Pages using Hugo static site generator with the PaperMod theme. The site is automatically built and deployed via GitHub Actions whenever changes are pushed to the main branch.

- **Live Site**: https://tranqy.github.io/zellij-utils/
- **Source**: `/docs/` directory in this repository
- **Generator**: Hugo (Extended version)
- **Theme**: PaperMod
- **Deployment**: GitHub Actions with automated builds

## Site Structure

```
docs/
├── hugo.yaml                 # Hugo configuration file
├── content/                  # Markdown content files
│   ├── _index.md            # Homepage content
│   ├── blog/                # Blog posts
│   │   ├── _index.md
│   │   └── introducing-zellij-utils.md
│   └── guides/              # Documentation guides
│       ├── _index.md
│       ├── quick-start.md
│       ├── faq.md
│       └── troubleshooting.md
├── layouts/                 # Custom Hugo templates
│   ├── _default/
│   │   ├── baseof.html
│   │   ├── list.html
│   │   └── single.html
│   └── index.html
├── themes/                  # Hugo themes (git submodules)
│   └── PaperMod/           # PaperMod theme submodule
├── public/                  # Generated site output (ignored by git)
└── .hugo_build.lock        # Hugo build lock file
```

## Configuration

### Hugo Configuration (`docs/hugo.yaml`)

```yaml
baseURL: 'https://tranqy.github.io/zellij-utils/'
languageCode: 'en-us'
title: 'Zellij Utils'
theme: 'PaperMod'

params:
  description: "Supercharge your Zellij terminal multiplexer workflows"

markup:
  goldmark:
    renderer:
      unsafe: true
```

### Theme Configuration

The site uses the PaperMod theme, installed as a git submodule:

```bash
# Submodule configuration in .gitmodules
[submodule "docs/themes/PaperMod"]
	path = docs/themes/PaperMod
	url = https://github.com/adityatelange/hugo-PaperMod.git
```

## GitHub Actions Deployment

### Workflow File (`.github/workflows/hugo.yml`)

The deployment is handled by a GitHub Actions workflow that:

1. **Installs Hugo CLI** (Extended version 0.147.0)
2. **Installs Dart Sass** for advanced styling
3. **Checks out repository** with recursive submodules
4. **Configures GitHub Pages** settings
5. **Installs Node.js dependencies** (if any)
6. **Builds the Hugo site** with garbage collection and minification
7. **Uploads the build artifact** to GitHub Pages
8. **Deploys to GitHub Pages** environment

### Workflow Triggers

- **Push to main branch**: Automatic deployment
- **Manual dispatch**: Can be triggered manually from GitHub Actions tab

### Permissions Required

```yaml
permissions:
  contents: read
  pages: write
  id-token: write
```

## Local Development

### Prerequisites

1. **Hugo Extended** (version 0.147.0 or later)
2. **Git** (for submodule management)
3. **Node.js** (optional, for additional dependencies)

### Setup Instructions

1. **Clone the repository with submodules**:
   ```bash
   git clone --recursive https://github.com/tranqy/zellij-utils.git
   cd zellij-utils
   ```

2. **If already cloned, initialize submodules**:
   ```bash
   git submodule update --init --recursive
   ```

3. **Install Hugo Extended**:
   ```bash
   # Ubuntu/Debian
   sudo snap install hugo
   
   # macOS
   brew install hugo
   
   # Manual installation
   wget https://github.com/gohugoio/hugo/releases/download/v0.147.0/hugo_extended_0.147.0_linux-amd64.deb
   sudo dpkg -i hugo_extended_0.147.0_linux-amd64.deb
   ```

### Development Commands

```bash
# Navigate to docs directory
cd docs

# Start development server with live reload
hugo server -D --bind 0.0.0.0

# Build site for production
hugo --gc --minify

# Build with specific destination
hugo --gc --minify -d public

# Check Hugo version
hugo version
```

### Local Testing

After making changes, always test the build locally:

```bash
cd docs
hugo --gc --minify
```

Successful output should show:
```
Start building sites … 
                  │ EN 
──────────────────┼────
 Pages            │ 26 
 Paginator pages  │  0 
 Non-page files   │  0 
 Static files     │  0 
 Processed images │  0 
 Aliases          │  0 
 Cleaned          │  0 

Total in 94 ms
```

## Content Management

### Adding New Content

1. **Blog Posts**: Create new `.md` files in `docs/content/blog/`
2. **Guide Pages**: Create new `.md` files in `docs/content/guides/`
3. **Homepage**: Edit `docs/content/_index.md`

### Front Matter Format

```yaml
---
title: "Page Title"
description: "Page description for SEO"
date: 2025-07-13
tags: ["tag1", "tag2"]
categories: ["category"]
draft: false
---

# Content goes here
```

### Navigation

- **Main navigation** is automatically generated from content structure
- **Custom layouts** can be added in `docs/layouts/`
- **Menu configuration** can be added to `hugo.yaml` if needed

## Troubleshooting

### Common Issues

#### 1. Submodule Errors
**Problem**: `fatal: No url found for submodule path 'docs/themes/PaperMod'`

**Solution**:
```bash
# Remove broken submodule
git rm --cached docs/themes/PaperMod
rm -rf docs/themes/PaperMod
rm -rf .git/modules/docs/themes/PaperMod

# Re-add properly
git submodule add https://github.com/adityatelange/hugo-PaperMod.git docs/themes/PaperMod
git commit -m "fix: reinstall PaperMod theme submodule"
```

#### 2. Hugo Config Not Found
**Problem**: `Unable to locate config file or config directory`

**Solution**:
- Ensure you're running Hugo from the `docs/` directory
- Verify `hugo.yaml` exists in the `docs/` directory
- Check file permissions

#### 3. Theme Not Working
**Problem**: Site builds but theme doesn't apply

**Solution**:
```bash
# Update submodules
git submodule update --remote --recursive

# Verify theme installation
ls -la docs/themes/PaperMod/

# Check theme configuration in hugo.yaml
```

#### 4. Build Failures in CI
**Problem**: GitHub Actions build fails

**Solution**:
1. Check the [Actions tab](https://github.com/tranqy/zellij-utils/actions) for detailed error logs
2. Verify submodules are properly configured
3. Test build locally first
4. Check Hugo version compatibility

### Debugging Commands

```bash
# Check git submodule status
git submodule status

# Update all submodules
git submodule update --remote --recursive

# Force submodule reinitialization
git submodule deinit --all -f
git submodule update --init --recursive

# Check Hugo configuration
cd docs && hugo config

# Verbose Hugo build
cd docs && hugo --verbose --debug
```

## Maintenance

### Regular Updates

1. **Hugo Version**: Update `HUGO_VERSION` in `.github/workflows/hugo.yml`
2. **Theme Updates**: 
   ```bash
   git submodule update --remote docs/themes/PaperMod
   git add docs/themes/PaperMod
   git commit -m "update: PaperMod theme to latest version"
   ```
3. **Dependencies**: Check for GitHub Actions updates

### Monitoring

- **Deployment Status**: Monitor [GitHub Actions](https://github.com/tranqy/zellij-utils/actions)
- **Site Availability**: Check https://tranqy.github.io/zellij-utils/
- **Performance**: Use GitHub Pages insights and web tools

### Backup

The site source is automatically backed up in the git repository. The generated site can be recreated at any time from the source files.

## Security Considerations

- **Submodule Security**: PaperMod theme is from a trusted source
- **Build Security**: GitHub Actions runs in isolated environments
- **Content Security**: All content is static - no server-side execution
- **HTTPS**: GitHub Pages enforces HTTPS by default

## Performance

### Current Metrics
- **Build Time**: ~94ms locally, ~30s in CI
- **Page Count**: 26 pages generated
- **Size**: Optimized with `--gc --minify` flags
- **CDN**: Served via GitHub's global CDN

### Optimization Tips
- Use `--gc --minify` for production builds
- Optimize images before adding to content
- Keep dependencies minimal
- Regular theme updates for performance improvements

## Support

For issues related to:
- **Hugo Documentation**: https://gohugo.io/documentation/
- **PaperMod Theme**: https://github.com/adityatelange/hugo-PaperMod
- **GitHub Pages**: https://docs.github.com/en/pages
- **GitHub Actions**: https://docs.github.com/en/actions

---

*Last updated: 2025-07-13*
*Site URL: https://tranqy.github.io/zellij-utils/*
*Repository: https://github.com/tranqy/zellij-utils*