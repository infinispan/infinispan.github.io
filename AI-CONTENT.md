# Content Instructions

## Blog Posts

### File Location and Naming
Blog posts live in `_posts/` and must follow the naming convention:
```
YYYY-MM-DD-kebab-case-title.adoc
```

### Front Matter
Every blog post requires YAML front matter:
```yaml
---
layout: blog
title: Your Blog Post Title
permalink: /blog/:year/:month/:day/kebab-case-title
date: 'YYYY-MM-DDTHH:MM:SS.SSS-TZ'
author: authorkey
tags: [ "infinispan", "relevant", "tags" ]
---
```

- **`layout`**: Always `blog`.
- **`title`**: The display title.
- **`permalink`**: Must match the pattern `/blog/:year/:month/:day/kebab-case-slug`. Use a short, descriptive slug.
- **`date`**: ISO 8601 format with timezone offset.
- **`author`**: A key from `_data/authors.yml` (e.g., `ttarrant`, `infinispan`).
- **`tags`**: Array of lowercase tags. Always include `"infinispan"` and a version tag if applicable (e.g., `"16.1"`).

### AsciiDoc Body
After the front matter closing `---`, add a separator `---` and then the AsciiDoc content:
```asciidoc
---

= Your Blog Post Title

Introductory paragraph text.

== Section Heading

Content with https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/[AsciiDoc syntax].
```

- Use `=` for the document title (matches the front matter title).
- Use `==` for section headings, `===` for subsections.
- Images go in `assets/images/blog/` and are referenced with `image::filename.png[Alt text]` (the `:imagesdir:` attribute is set globally in `_config.yml`).
- Source code blocks use AsciiDoc source syntax: `[source,java]` followed by a delimited block.

### Authors
Author profiles are defined in `_data/authors.yml`:
```yaml
authorkey:
  name: Full Name
  twitter: https://twitter.com/handle    # optional
  github: https://github.com/handle      # optional
  bio: Short biography text.             # optional
  image: /assets/images/blog/authors/authorkey.jpg
```

## Content Pages

### File Location
Content pages are Markdown files in the repository root (e.g., `features.md`, `community.md`, `download.md`).

### Front Matter
```yaml
---
layout: layout-name
title: Page Title
permalink: /custom-path/
---
```

- **`layout`**: Choose from existing layouts in `_layouts/` (e.g., `index`, `downloads`, `default`).
- **`permalink`**: Optional custom URL path.

### Markdown Body
Use standard Markdown (kramdown dialect). Liquid tags are available:
```liquid
{{ site.baseurl }}/path/to/resource
{% include some-include.html %}
```

## Release Data

### `_data/projects.yml`
This is the central release tracking file for all Infinispan components (server, clients, operator, helm charts). Each component has multiple version entries with:
```yaml
- version: "16.1.1"
  release_date: "2025-03-26"
  alias: "stable"
  codename: "Polly Want a Pilsner"
  docs: true
  assets:
    server:
      - name: zip
        url: https://...
    # ...
```

**Important:** This file is partially auto-managed by `_bin/update_releases.rb` and the GitHub Actions workflow. Asset URLs, release dates, and download links for existing versions are overwritten on each release event. When adding a *new* version entry manually (e.g., for an upcoming release), add just the `version`, `alias`, `codename`, and `docs` fields — the automation will fill in the rest.

## Documentation
Documentation is not authored in this repository. It is fetched from Maven Central and GitHub during the build process by `_plugins/fetch_docs.rb` and placed in the `docs/` directory (which is gitignored). To skip the download during local development:
```bash
export FORCE_DOCUMENTATION_DOWNLOAD=false
```
