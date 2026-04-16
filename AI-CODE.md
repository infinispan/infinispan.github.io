# Coding Instructions

## Tech Stack
* **Static Site Generator:** Jekyll 4.3.3 (Ruby)
* **Dependency Management:** Bundler (`Gemfile` / `Gemfile.lock`)
* **Templating:** Liquid (in `_layouts/` and `_includes/`)
* **Content Formats:** AsciiDoc (blog posts), Markdown (pages), HTML (layouts/includes)
* **Styling:** SCSS (`_sass/`), compiled by Jekyll's built-in Sass processor
* **JavaScript:** Vanilla JS + jQuery 2.1.4 (loaded from CDN)
* **Key Plugins:**
  - `jekyll-asciidoc` — AsciiDoc support for blog posts
  - `jekyll-paginate-v2` — blog pagination (8 posts per page)
  - `jekyll-archives` — tag-based blog archives
  - `jekyll-feed` — RSS feed generation
  - `jekyll-mermaid` — diagram support

## Project Architecture

* **`_posts/`** — Blog posts in AsciiDoc (645+ posts dating back to 2009)
* **`_layouts/`** — HTML layout templates (base, blog, downloads, etc.)
* **`_includes/`** — Reusable HTML components (header, footer, content bands, templates)
* **`_sass/`** — SCSS stylesheets (Red Hat color palette, responsive grid)
  - `core/` — base styles (colors, grid, global)
  - `includes/` — component-specific styles
  - `layouts/` — layout-specific styles
* **`_data/`** — YAML data files
  - `projects.yml` — release versions, download assets, Docker images for all Infinispan components
  - `authors.yml` — blog author profiles (name, bio, social links, avatar)
  - `cachestores.yml`, `hotrod.yml`, `integrations.yml` — feature data
* **`_plugins/`** — Custom Ruby plugins (`fetch_docs.rb` for documentation syncing)
* **`_bin/`** — Build and deployment scripts
  - `local.sh` — local development server
  - `publish.sh` — production build and deploy to `master` branch
  - `update_releases.rb` — GitHub API release data updater
* **`assets/`** — Static assets (CSS entry points, JavaScript, images)
* **Root `.md` files** — Content pages (blog, download, documentation, features, community, etc.)

## Common Build Commands
* **Install dependencies:** `bundle install`
* **Local dev server:** `bundle exec jekyll serve --incremental` (or `_bin/local.sh`)
* **Production build:** `bundle exec jekyll build`
* **Skip documentation download:** `export FORCE_DOCUMENTATION_DOWNLOAD=false` before building
* **Deploy to production:** `_bin/publish.sh` (builds site, pushes compiled output to `master` branch)

## Development Standards

### Layouts and Includes
* Layouts extend `base.html` which provides the HTML skeleton, header, footer, and analytics.
* Use `{{ site.baseurl }}` for URL prefixes in templates.
* Navigation is in `_includes/header-navigation.html`.
* Content sections use "band" includes (e.g., `_includes/bands/`).
* Grid classes follow `width-{n}-12` / `width-{n}-12-m` (mobile) convention.

### SCSS
* Color variables are defined in `_sass/core/colors.scss` (Red Hat palette: `$red`, `$dark-red`, `$accent-blue`, etc.).
* Responsive breakpoint: `@media screen and (max-width: 768px)`.
* Fonts: Montserrat (headings), Maitree (body), loaded from Google Fonts.
* Icons: Font Awesome 6.7.2 (loaded from jsDelivr CDN).
* Output style is `compressed` (configured in `_config.yml`).

### JavaScript
* Vanilla JS preferred for new code; jQuery is available but legacy.
* Scripts live in `assets/javascript/`.
* Vendor libraries are stored minified (e.g., `clipboard.min.js`).

### Ruby Plugins
* Plugins in `_plugins/` run during Jekyll build.
* `fetch_docs.rb` downloads documentation from Maven Central and GitHub for all tracked versions.

### Data Files
* `_data/projects.yml` is the central release tracking file. It is updated automatically by `_bin/update_releases.rb` and the GitHub Actions workflow.
* Do not manually edit auto-managed fields in `projects.yml` (assets, release dates) — they are overwritten by the automation.

### Commit Messages
* Short imperative format: "Add X", "Remove Y", "Fix Z", "Bump dependency"
* PR references in parentheses: `(#NNN)`

### Git Branches
* `develop` — source branch (all development happens here)
* `master` — compiled output only (managed by `_bin/publish.sh`)
* Feature branches should use `develop` as the upstream

### Build Exclusions
* AI instruction files (`AI.md`, `AI-CODE.md`, `AI-CONTENT.md`, `AI-ISSUES.md`) are listed in `_config.yml`'s `exclude:` to prevent them from appearing in the built site.

## Deployment Pipeline
* **GitHub Actions:** `.github/workflows/update_releases.yaml` automatically updates `_data/projects.yml` on release events and triggers a publish

## Related Projects
* **Server:** The Infinispan server source code is in `../infinispan`
* **Console:** The Infinispan Console source code is in `../infinispan-console`
* **Operator:** The Infinispan Operator source code is in `../infinispan-operator`
