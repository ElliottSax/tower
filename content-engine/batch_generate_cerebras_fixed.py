#!/usr/bin/env python3
"""
Batch Article Generation using Cerebras API (FIXED - gpt-oss-120b model)
"""

import json
import os
from pathlib import Path
from datetime import datetime
import requests
import time

CEREBRAS_API_KEY = "csk-8n6j6kynyjtm55j24mwdw6x2y9c24859fkddywyek3kdd85y"
CEREBRAS_API_URL = "https://api.cerebras.ai/v1/chat/completions"
MODEL = "gpt-oss-120b"

SITES = {
    'affiliate': {
        'count': 150,
        'output_dir': '/mnt/e/projects/affiliate/thestackguide/app/blog',
        'topics_file': '/mnt/e/projects/content-engine/config/topics/affiliate_topics.json'
    },
    'quant': {
        'count': 80,
        'output_dir': '/mnt/e/projects/quant/quant/frontend/src/app/blog',
        'topics_file': '/mnt/e/projects/content-engine/config/topics/quant_topics.json'
    }
}

def get_system_prompt(site_name: str) -> str:
    prompts = {
        "affiliate": """Write objective, detailed SaaS/tool reviews for theStackGuide.com.
Compare 3-5 alternatives with pricing, features, pros/cons. Use real data and examples.
Target: software developers. Format: markdown with H2 headers. 1,200-1,500 words.""",
        
        "quant": """Write educational trading strategy content for QuantTrading.vercel.app.
Explain strategies with historical data and backtesting results. Discuss risk management.
Target: retail traders, quants. Format: markdown with H2 headers. 1,200-1,500 words."""
    }
    return prompts.get(site_name, "")

def load_topics(site: str) -> list:
    topics_file = SITES[site]['topics_file']
    try:
        with open(topics_file) as f:
            data = json.load(f)
        return data.get('topics', [])[:SITES[site]['count']]
    except FileNotFoundError:
        return []

def generate_article(site: str, topic: dict) -> dict:
    try:
        system_prompt = get_system_prompt(site)
        user_prompt = f"Write article about: {topic.get('topic', topic)}\n\nRequirements: 1,200-1,500 words, markdown format with H1 title and H2 sections, specific examples and real data, publication-ready quality."

        headers = {
            "Authorization": f"Bearer {CEREBRAS_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": MODEL,
            "max_tokens": 2000,
            "temperature": 0.7,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        }
        
        response = requests.post(CEREBRAS_API_URL, headers=headers, json=payload, timeout=60)
        
        if response.status_code == 200:
            data = response.json()
            if 'choices' in data and len(data['choices']) > 0:
                text = data['choices'][0]['message']['content']
                if len(text) > 200:
                    return {'success': True, 'content': text, 'tokens_used': data.get('usage', {}).get('completion_tokens', 0)}
        
        return {'success': False, 'error': f"HTTP {response.status_code}", 'content': None}
    except Exception as e:
        return {'success': False, 'error': str(e)[:80], 'content': None}

def save_article(site: str, topic: dict, content: str, index: int) -> bool:
    output_dir = Path(SITES[site]['output_dir'])
    output_dir.mkdir(parents=True, exist_ok=True)
    
    slug = topic.get('topic', f'article-{index}').lower().replace(' ', '-')[:50]
    filename = f"{slug}.md"
    filepath = output_dir / filename
    
    frontmatter = f"""---
title: {topic.get('topic', 'Untitled')}
date: {datetime.now().strftime('%Y-%m-%d')}
author: {topic.get('author', 'Stack Guide')}
category: {topic.get('category', 'General')}
tags: {json.dumps(topic.get('tags', []))}
---

"""
    
    try:
        with open(filepath, 'w') as f:
            f.write(frontmatter + content)
        return True
    except Exception as e:
        return False

def main():
    total_articles = 0
    successful = 0
    failed = 0
    
    for site in ['affiliate', 'quant']:
        print(f"\n{'='*70}")
        print(f"🚀 Generating {SITES[site]['count']} articles for {site.upper()}")
        print(f"{'='*70}")
        
        topics = load_topics(site)
        count = SITES[site]['count']
        
        if not topics:
            print(f"⚠️  No topics found")
            continue
        
        print(f"Topics loaded: {len(topics)} | Model: {MODEL}\n")
        
        for i, topic in enumerate(topics[:count], 1):
            topic_name = topic.get('topic', 'Untitled')[:45]
            print(f"[{i:3d}/{count}] {topic_name:<45}", end=" ", flush=True)
            
            result = generate_article(site, topic)
            total_articles += 1
            
            if result['success'] and result['content'] and len(result['content']) > 200:
                if save_article(site, topic, result['content'], i):
                    successful += 1
                    print(f"✅")
                else:
                    failed += 1
                    print(f"❌ save")
            else:
                failed += 1
                error = result.get('error', 'empty')[:20]
                print(f"❌ {error}")
            
            time.sleep(1)  # Rate limiting
    
    print(f"\n{'='*70}")
    print(f"📊 GENERATION COMPLETE")
    print(f"{'='*70}")
    print(f"Total: {total_articles} | ✅ {successful} | ❌ {failed}")
    if total_articles > 0:
        print(f"Success rate: {(successful/total_articles)*100:.1f}%")

if __name__ == '__main__':
    main()
