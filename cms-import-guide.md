# CMS Implementation Guide - 391 Article Import

**Created**: March 3, 2026
**Target CMS**: WordPress, Ghost, Webflow, Contentful, or any markdown-compatible CMS
**Total Articles**: 391
**Estimated Setup Time**: 2-4 hours

---

## Quick Start (5 Minutes)

### For WordPress Users
1. **Install Plugin**: Search for "Markdown Importer" or "Really Simple CSV Importer"
2. **Prepare CSV**: Use `articles_metadata.csv` (already created)
3. **Import**: Follow plugin instructions to import all 391 articles
4. **Verify**: Check 5-10 articles to ensure proper import

### For Other CMS
1. **Check Compatibility**: Your CMS should support markdown
2. **Use Migration Script**: See "Bulk Import Scripts" section below
3. **Test Import**: Do 5-10 articles first
4. **Full Import**: Run complete batch import

---

## Prerequisites

Before importing, ensure you have:

- ✅ All 391 markdown files (in respective directories)
- ✅ `articles_metadata.csv` (included)
- ✅ CMS admin access
- ✅ Category structure created in CMS
- ✅ Featured image directories prepared (optional)
- ✅ SEO plugin installed (Yoast, Rank Math, etc.)

---

## File Structure

### Directory Organization

```
/mnt/e/projects/
├── credit/generated-articles/          (96 articles)
│   ├── credit-utilization-ratio.md
│   ├── does-applying-for-credit-card-hurt.md
│   └── ... (94 more)
├── calc/generated-articles/            (94 articles)
│   ├── dividend-investing-101.md
│   ├── dividend-yield-explained.md
│   └── ... (92 more)
├── affiliate/thestackguide/generated-articles/  (98 articles)
│   ├── best-email-marketing-tools.md
│   ├── best-project-management-tools.md
│   └── ... (96 more)
├── quant/generated-articles/           (103 articles)
│   ├── quantitative-trading-101.md
│   ├── rsi-relative-strength-index.md
│   └── ... (101 more)
├── articles_metadata.csv               (Metadata for all 391)
├── ARTICLES_MASTER_INDEX.md           (Complete guide)
├── 12-week-content-calendar.md        (Publication schedule)
└── qa-report-articles.md              (Quality assurance)
```

---

## WordPress Import (Step-by-Step)

### Option 1: Using Really Simple CSV Importer (Recommended)

#### Step 1: Install Plugin
1. Go to **Plugins → Add New**
2. Search for "Really Simple CSV Importer"
3. Install and activate the plugin

#### Step 2: Prepare CSV
The `articles_metadata.csv` file is already formatted. No changes needed.

#### Step 3: Import Articles
1. Go to **Tools → Import → CSV Importer**
2. Upload `articles_metadata.csv`
3. Map columns:
   - Title → title
   - Description → post_excerpt (or skip)
   - Slug → post_name
   - Category → category
   - Content → (handled separately)
4. Run import

#### Step 4: Import Content Body
Since CSV importer doesn't include full content, you'll need to:

1. **Option A - Bulk Upload Markdown**:
   - Use "WP Markdown Import" plugin
   - Upload all markdown files at once
   - Plugin converts markdown to WordPress content

2. **Option B - Manual Assignment**:
   - Use the Python script in "Bulk Import Scripts" section
   - Automates content body assignment to posts

### Option 2: Using WP-CLI (Advanced)

For technical users with WP-CLI installed:

```bash
# Create posts from markdown files
python3 << 'EOF'
import os
import subprocess
import frontmatter

def import_articles(directory, site):
    for filename in os.listdir(directory):
        if not filename.endswith('.md'):
            continue

        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            post = frontmatter.load(f)

        # Create WordPress post
        cmd = [
            'wp', 'post', 'create',
            '--post_type=post',
            f'--post_title={post["title"]}',
            f'--post_name={post["slug"]}',
            f'--post_content={post.content}',
            f'--post_excerpt={post["description"]}',
            f'--post_category={post["category"]}',
            '--post_status=draft',
        ]

        subprocess.run(cmd)
        print(f"✅ Created: {post['title']}")

# Run for each site
import_articles('/mnt/e/projects/credit/generated-articles', 'credit')
import_articles('/mnt/e/projects/calc/generated-articles', 'calc')
import_articles('/mnt/e/projects/affiliate/thestackguide/generated-articles', 'affiliate')
import_articles('/mnt/e/projects/quant/generated-articles', 'quant')

print("✅ Import complete!")
EOF
```

---

## Ghost CMS Import

### Step 1: Export Format Preparation
Ghost prefers JSON format. Convert using:

```bash
python3 << 'EOF'
import os
import json
import frontmatter
from datetime import datetime

ghost_posts = []

for site in ['credit', 'calc', 'affiliate', 'quant']:
    directory = f'/mnt/e/projects/{site}/generated-articles'
    if site == 'affiliate':
        directory = '/mnt/e/projects/affiliate/thestackguide/generated-articles'

    for filename in os.listdir(directory):
        if not filename.endswith('.md'):
            continue

        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            post = frontmatter.load(f)

        ghost_post = {
            "title": post.get("title", ""),
            "slug": post.get("slug", ""),
            "markdown": post.content,
            "html": f"<p>{post.content[:100]}...</p>",
            "excerpt": post.get("description", ""),
            "status": "draft",
            "featured": False,
            "tags": [{"name": post.get("category", "")}],
            "created_at": datetime.now().isoformat(),
            "published_at": None,
            "meta_description": post.get("description", ""),
        }

        ghost_posts.append(ghost_post)

# Export as Ghost JSON
with open('/mnt/e/projects/ghost_import.json', 'w') as f:
    json.dump({"db": [{"data": {"posts": ghost_posts}}]}, f, indent=2)

print(f"✅ Created Ghost import file with {len(ghost_posts)} posts")
EOF
```

### Step 2: Import to Ghost
1. Go to **Settings → Labs → Import content**
2. Upload `ghost_import.json`
3. Follow Ghost's import wizard

---

## Webflow Import

### Step 1: Prepare for Webflow
Webflow uses a CSV-based import for collections:

```bash
# The articles_metadata.csv is already in correct format
# Additional fields needed:
# - featured_image (URL or path)
# - content_html (convert markdown to HTML)
# - seo_title
# - seo_description

python3 << 'EOF'
import csv
import os
import frontmatter
import markdown

# Read existing CSV
rows = []
with open('/mnt/e/projects/articles_metadata.csv', 'r') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

# Add additional fields
for row in rows:
    site = row['site']
    directory = f'/mnt/e/projects/{site}/generated-articles'
    if site == 'affiliate':
        directory = '/mnt/e/projects/affiliate/thestackguide/generated-articles'

    filepath = os.path.join(directory, row['filename'])
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            post = frontmatter.load(f)
            row['content_html'] = markdown.markdown(post.content)
            row['seo_title'] = post.get('title', '')
            row['seo_description'] = post.get('description', '')
            row['featured_image'] = f'/images/{row["slug"]}.jpg'

# Export enhanced CSV
with open('/mnt/e/projects/webflow_import.csv', 'w', newline='') as f:
    fieldnames = list(rows[0].keys())
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print("✅ Created Webflow-compatible CSV")
EOF
```

### Step 2: Import to Webflow
1. Go to your Webflow collection
2. **Import → Upload CSV**
3. Upload `webflow_import.csv`
4. Map fields accordingly
5. Complete import

---

## Contentful Import

### Step 1: Define Content Model
Create a "BlogPost" content type with fields:
- title (Text)
- slug (Text - unique)
- description (Text)
- content (Rich Text/Markdown)
- keywords (Text array)
- category (Link to Category model)
- seo_title (Text)
- seo_description (Text)
- featured_image (Media reference)

### Step 2: Export for Contentful
```bash
python3 << 'EOF'
import json
import os
import frontmatter

contentful_entries = []

for site in ['credit', 'calc', 'affiliate', 'quant']:
    directory = f'/mnt/e/projects/{site}/generated-articles'
    if site == 'affiliate':
        directory = '/mnt/e/projects/affiliate/thestackguide/generated-articles'

    for filename in os.listdir(directory):
        if not filename.endswith('.md'):
            continue

        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            post = frontmatter.load(f)

        entry = {
            "fields": {
                "title": {"en-US": post.get("title", "")},
                "slug": {"en-US": post.get("slug", "")},
                "description": {"en-US": post.get("description", "")},
                "content": {"en-US": post.content},
                "keywords": {"en-US": post.get("keywords", [])},
                "seo_title": {"en-US": post.get("title", "")},
                "seo_description": {"en-US": post.get("description", "")},
            }
        }
        contentful_entries.append(entry)

with open('/mnt/e/projects/contentful_import.json', 'w') as f:
    json.dump(contentful_entries, f, indent=2)

print(f"✅ Created Contentful import with {len(contentful_entries)} entries")
EOF
```

### Step 3: Use Contentful Import
1. Use Contentful CLI: `contentful space import --content-file contentful_import.json`
2. Or use the Contentful UI migration tools

---

## Universal Markdown Import (All CMS)

### Step 1: File Organization
The markdown files are already organized by site. Simply:

1. **Copy to your CMS**:
   ```bash
   cp -r /mnt/e/projects/credit/generated-articles/* /your/cms/content/credit/
   cp -r /mnt/e/projects/calc/generated-articles/* /your/cms/content/calc/
   cp -r /mnt/e/projects/affiliate/thestackguide/generated-articles/* /your/cms/content/affiliate/
   cp -r /mnt/e/projects/quant/generated-articles/* /your/cms/content/quant/
   ```

2. **Your CMS will automatically parse**:
   - YAML frontmatter (metadata)
   - Markdown content body
   - Internal links and formatting

### Step 2: Verify Import
1. Check 5-10 articles in your CMS
2. Verify metadata (title, description, keywords)
3. Check markdown rendering (headings, lists, etc.)
4. Test internal links are preserved

---

## Post-Import Configuration

### Step 1: Category Setup
Ensure these categories exist in your CMS:

**Credit Card Site**:
- strategies
- guides
- credit-building
- tax

**Dividend Calculator**:
- strategies
- analysis
- retirement
- tax
- tools

**TheStackGuide**:
- tools
- technical
- business
- tutorials
- integration
- use-cases

**Quant Trading**:
- strategies
- indicators
- ml
- options
- risk
- backtesting

### Step 2: SEO Plugin Configuration
If using WordPress with Yoast/Rank Math:

1. **Enable XML Sitemap**
2. **Configure Meta Tags**:
   - Title tag: `[Post Title] | [Site Name]`
   - Meta description: Use the description field
3. **Set Keywords** from the keywords field
4. **Internal Linking**: Use "Link Suggestions" feature
5. **Readability**: Check for optimal length

### Step 3: Featured Images
Optional but recommended:

1. **Create placeholder images** for each article
2. **Use image naming convention**: `{slug}.jpg`
3. **Upload to**: `/wp-content/uploads/articles/`
4. **Bulk assign** using CMS bulk tools

### Step 4: Publication Schedule
1. **Set initial status**: Draft (not published)
2. **Bulk schedule** using 12-week calendar
3. **Recommended tool**: Editorial Calendar plugin
4. **Schedule times**: 9am, 2pm, 5pm UTC

---

## Verification Checklist

After import, verify:

- [ ] All 391 articles imported
- [ ] Metadata correctly assigned
- [ ] Categories properly set
- [ ] Content body is readable
- [ ] Markdown formatting intact (headings, lists, etc.)
- [ ] Internal links preserved
- [ ] No duplicate articles
- [ ] Search functionality works
- [ ] Mobile rendering correct
- [ ] SEO plugin recognizes articles

---

## Bulk Import Python Script

### Universal Import Script

```python
#!/usr/bin/env python3
"""
Universal CMS article importer
Supports WordPress, Ghost, Webflow, Contentful
"""

import os
import csv
import json
import frontmatter
import argparse
from pathlib import Path

class UniversalImporter:
    def __init__(self, cms_type):
        self.cms_type = cms_type
        self.articles = []

    def load_articles(self):
        """Load all articles from directories"""
        dirs = {
            '/mnt/e/projects/credit/generated-articles': 'credit',
            '/mnt/e/projects/calc/generated-articles': 'calc',
            '/mnt/e/projects/affiliate/thestackguide/generated-articles': 'affiliate',
            '/mnt/e/projects/quant/generated-articles': 'quant',
        }

        for directory, site in dirs.items():
            for filename in os.listdir(directory):
                if not filename.endswith('.md'):
                    continue

                filepath = os.path.join(directory, filename)
                with open(filepath, 'r', encoding='utf-8') as f:
                    post = frontmatter.load(f)

                article = {
                    'site': site,
                    'filename': filename,
                    'title': post.get('title', ''),
                    'slug': post.get('slug', ''),
                    'description': post.get('description', ''),
                    'keywords': post.get('keywords', []),
                    'category': post.get('category', ''),
                    'content': post.content,
                }
                self.articles.append(article)

        print(f"✅ Loaded {len(self.articles)} articles")

    def export_for_wordpress(self):
        """Export as CSV for WordPress import"""
        with open('/mnt/e/projects/articles_for_wordpress.csv', 'w', newline='') as f:
            fieldnames = ['title', 'slug', 'post_type', 'post_status', 'category', 'post_excerpt']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for article in self.articles:
                writer.writerow({
                    'title': article['title'],
                    'slug': article['slug'],
                    'post_type': 'post',
                    'post_status': 'draft',
                    'category': article['category'],
                    'post_excerpt': article['description'],
                })

        print("✅ Created WordPress import CSV")

    def export_for_ghost(self):
        """Export as Ghost JSON"""
        posts = []
        for article in self.articles:
            posts.append({
                'title': article['title'],
                'slug': article['slug'],
                'markdown': article['content'],
                'status': 'draft',
                'excerpt': article['description'],
            })

        with open('/mnt/e/projects/articles_for_ghost.json', 'w') as f:
            json.dump({'db': [{'data': {'posts': posts}}]}, f)

        print("✅ Created Ghost import JSON")

    def export_for_webflow(self):
        """Export as Webflow CSV"""
        with open('/mnt/e/projects/articles_for_webflow.csv', 'w', newline='') as f:
            fieldnames = ['name', 'slug', 'description', 'category', 'keywords']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for article in self.articles:
                writer.writerow({
                    'name': article['title'],
                    'slug': article['slug'],
                    'description': article['description'],
                    'category': article['category'],
                    'keywords': ', '.join(article['keywords']),
                })

        print("✅ Created Webflow import CSV")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Import articles to CMS')
    parser.add_argument('cms', choices=['wordpress', 'ghost', 'webflow', 'all'],
                       help='Target CMS platform')

    args = parser.parse_args()

    importer = UniversalImporter(args.cms)
    importer.load_articles()

    if args.cms == 'wordpress' or args.cms == 'all':
        importer.export_for_wordpress()

    if args.cms == 'ghost' or args.cms == 'all':
        importer.export_for_ghost()

    if args.cms == 'webflow' or args.cms == 'all':
        importer.export_for_webflow()

    print(f"\n✅ Export complete! Ready for {args.cms.upper()} import")
```

### Run Import
```bash
# Export for WordPress
python3 cms_importer.py wordpress

# Export for Ghost
python3 cms_importer.py ghost

# Export for Webflow
python3 cms_importer.py webflow

# Export for all
python3 cms_importer.py all
```

---

## Troubleshooting

### Articles Not Importing
- **Check**: Markdown files are valid
- **Check**: YAML frontmatter is properly formatted
- **Check**: CSV has correct column headers
- **Solution**: Re-validate files using the QA report

### Metadata Not Showing
- **Check**: SEO plugin is installed and activated
- **Check**: Meta tags are configured in plugin settings
- **Solution**: Map CSV columns to your CMS fields

### Internal Links Broken
- **Check**: Slugs match across articles
- **Check**: Link format is correct `[text](/slug)`
- **Solution**: Verify slugs in articles_metadata.csv

### Markdown Not Rendering
- **Check**: Your CMS supports markdown
- **Check**: Markdown syntax is valid
- **Solution**: Use markdown validation tool

### Characters Encoding Issues
- **Check**: File encoding is UTF-8
- **Solution**: Re-save files as UTF-8:
  ```bash
  iconv -f ISO-8859-1 -t UTF-8 file.md > file_utf8.md
  ```

---

## Support Resources

- **WordPress**: https://wordpress.org/support/
- **Ghost**: https://ghost.org/docs/
- **Webflow**: https://webflow.com/help
- **Contentful**: https://www.contentful.com/developers/
- **Markdown Guide**: https://www.markdownguide.org/

---

## Next Steps After Import

1. **Configure Categories** in your CMS
2. **Set SEO Plugin Settings**
3. **Create Content Calendar** (use 12-week schedule)
4. **Set First Batch** to publish (Week 1)
5. **Configure Analytics** tracking
6. **Submit Sitemap** to Google
7. **Monitor Rankings** after publication

---

## Timeline

- **Setup**: 1-2 hours
- **Import**: 0.5-1 hour (automated)
- **Verification**: 1-2 hours
- **Configuration**: 1-2 hours
- **Total**: 3.5-7 hours

---

**Support**: For issues, refer to ARTICLES_MASTER_INDEX.md or qa-report-articles.md
**Last Updated**: March 3, 2026
**Status**: Ready for immediate import
