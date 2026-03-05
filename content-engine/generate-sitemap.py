#!/usr/bin/env python3
"""
Sitemap Generator for All 4 Sites
Generates XML sitemaps with lastmod dates and priority weighting
Supports Google Search Console API submission
"""

import os
import sys
from pathlib import Path
from datetime import datetime
import xml.etree.ElementTree as ET
from typing import List, Tuple
import json

class SitemapGenerator:
    def __init__(self):
        self.sites = {
            'credit': {
                'domain': 'https://cardclassroom.com',
                'blog_path': '/mnt/e/projects/credit/app/blog',
                'output_path': '/mnt/e/projects/credit/public/sitemap.xml'
            },
            'calc': {
                'domain': 'https://calcrewardsmax.com',
                'blog_path': '/mnt/e/projects/calc/app/blog',
                'output_path': '/mnt/e/projects/calc/public/sitemap.xml'
            },
            'affiliate': {
                'domain': 'https://thestackguide.vercel.app',
                'blog_path': '/mnt/e/projects/affiliate/thestackguide/components',
                'output_path': '/mnt/e/projects/affiliate/thestackguide/public/sitemap.xml'
            },
            'quant': {
                'domain': 'https://quanttrading.vercel.app',
                'blog_path': '/mnt/e/projects/quant/quant/frontend/src/components',
                'output_path': '/mnt/e/projects/quant/quant/frontend/public/sitemap.xml'
            }
        }

    def get_article_slug(self, filename: str) -> str:
        """Convert filename to URL slug"""
        # Remove .md extension
        slug = filename.replace('.md', '')
        # Remove trailing numbers (duplicates)
        slug = slug.rsplit('_', 1)[0] if slug[-1].isdigit() else slug
        return slug

    def get_article_date(self, filepath: str) -> str:
        """Get article modification date"""
        try:
            mtime = os.path.getmtime(filepath)
            return datetime.fromtimestamp(mtime).strftime('%Y-%m-%d')
        except:
            return datetime.now().strftime('%Y-%m-%d')

    def calculate_priority(self, days_old: int) -> float:
        """
        Calculate priority based on article age
        Recent articles get higher priority
        """
        if days_old <= 7:
            return 0.9  # Last week
        elif days_old <= 30:
            return 0.8  # Last month
        elif days_old <= 90:
            return 0.7  # Last 3 months
        else:
            return 0.5  # Older

    def generate_sitemap(self, site: str) -> bool:
        """Generate sitemap for a single site"""
        config = self.sites[site]
        blog_path = config['blog_path']

        if not os.path.exists(blog_path):
            print(f"⚠️  Blog path not found: {blog_path}")
            return False

        # Find all markdown files
        articles = []
        for filename in os.listdir(blog_path):
            if filename.endswith('.md'):
                filepath = os.path.join(blog_path, filename)
                slug = self.get_article_slug(filename)
                date_str = self.get_article_date(filepath)

                # Calculate days old
                date_obj = datetime.strptime(date_str, '%Y-%m-%d')
                days_old = (datetime.now() - date_obj).days
                priority = self.calculate_priority(days_old)

                articles.append({
                    'slug': slug,
                    'date': date_str,
                    'priority': priority,
                    'filename': filename
                })

        if not articles:
            print(f"⚠️  No articles found in {blog_path}")
            return False

        # Create sitemap XML
        urlset = ET.Element('urlset')
        urlset.set('xmlns', 'http://www.sitemaps.org/schemas/sitemap/0.9')
        urlset.set('xmlns:mobile', 'http://www.google.com/schemas/sitemap-mobile/1.0')

        # Add homepage
        home_url = ET.SubElement(urlset, 'url')
        home_loc = ET.SubElement(home_url, 'loc')
        home_loc.text = config['domain']
        home_lastmod = ET.SubElement(home_url, 'lastmod')
        home_lastmod.text = datetime.now().strftime('%Y-%m-%d')
        home_priority = ET.SubElement(home_url, 'priority')
        home_priority.text = '1.0'
        home_changefreq = ET.SubElement(home_url, 'changefreq')
        home_changefreq.text = 'daily'

        # Remove duplicates by slug
        unique_articles = {}
        for article in articles:
            if article['slug'] not in unique_articles:
                unique_articles[article['slug']] = article

        # Add articles to sitemap
        for slug, article in unique_articles.items():
            url = ET.SubElement(urlset, 'url')

            loc = ET.SubElement(url, 'loc')
            loc.text = f"{config['domain']}/blog/{slug}"

            lastmod = ET.SubElement(url, 'lastmod')
            lastmod.text = article['date']

            priority = ET.SubElement(url, 'priority')
            priority.text = str(round(article['priority'], 1))

            changefreq = ET.SubElement(url, 'changefreq')
            changefreq.text = 'weekly'

        # Write XML file
        output_dir = os.path.dirname(config['output_path'])
        os.makedirs(output_dir, exist_ok=True)

        tree = ET.ElementTree(urlset)
        ET.indent(tree, space='  ')
        tree.write(
            config['output_path'],
            encoding='UTF-8',
            xml_declaration=True
        )

        article_count = len(unique_articles)
        print(f"✅ {site.upper():12} Sitemap generated: {article_count:3} articles → {config['output_path']}")
        return True

    def generate_all(self):
        """Generate sitemaps for all sites"""
        print("🗺️  GENERATING SITEMAPS FOR ALL 4 SITES")
        print("=" * 70)
        print()

        results = {}
        for site in self.sites.keys():
            results[site] = self.generate_sitemap(site)

        print()
        print("=" * 70)
        print("📊 SUMMARY")
        print("=" * 70)

        success_count = sum(1 for v in results.values() if v)
        print(f"Generated: {success_count}/4 sitemaps")

        if success_count == 4:
            print()
            print("✅ All sitemaps ready for Google Search Console submission")
            print()
            print("Next steps:")
            print("1. Go to Google Search Console")
            print("2. For each property, submit:")
            print("   - Credit: https://cardclassroom.com/sitemap.xml")
            print("   - Calc: https://calcrewardsmax.com/sitemap.xml")
            print("   - Affiliate: https://thestackguide.vercel.app/sitemap.xml")
            print("   - Quant: https://quanttrading.vercel.app/sitemap.xml")
            return True
        else:
            print("⚠️  Some sitemaps failed to generate")
            return False

if __name__ == '__main__':
    generator = SitemapGenerator()
    success = generator.generate_all()
    sys.exit(0 if success else 1)
