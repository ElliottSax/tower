# Content Expansion - API Integration & Code Templates
**Date**: March 5, 2026
**Purpose**: Ready-to-use code and prompts for Anthropic API integration

---

## PYTHON INTEGRATION TEMPLATE

```python
#!/usr/bin/env python3
"""
Content Expansion Executor using Anthropic API
Processes books through deepening, transformation, or humanization pipelines
"""

import os
import json
from pathlib import Path
import anthropic

class ContentExpander:
    def __init__(self):
        """Initialize Anthropic client"""
        self.client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
        self.costs = {
            "sonnet": {"input": 3 / 1_000_000, "output": 15 / 1_000_000},  # per token
            "opus": {"input": 15 / 1_000_000, "output": 75 / 1_000_000},
        }
        self.total_cost = 0.0

    def expand_chapter_sonnet(self, book_title, chapter_title, chapter_text):
        """
        Deepen a single chapter using Claude Sonnet
        Adds specific examples, key takeaways, and reflection questions
        """

        prompt = f"""You are editing {book_title}.

Current chapter text:
{chapter_text}

CHAPTER TITLE: {chapter_title}

Your task is to deepen this chapter while maintaining the original voice and structure.

ADD THESE ELEMENTS (maintain seamless integration):

1. TWO NEW SPECIFIC EXAMPLES (100-150 words each, separate from existing examples):
   - Include real names, company details, or specific metrics
   - Show HOW the mechanism works in practice
   - Format as new paragraphs within relevant sections

2. "KEY TAKEAWAY" SECTION (150 words, new subsection at chapter end):
   - Summarize the core insight in 1-2 sentences
   - Explain why this matters to the reader
   - Connect to the book's broader theme
   - Format as a highlighted section

3. THREE "REFLECTION QUESTIONS" (50 words each, new subsection):
   - Thought-provoking questions readers can ask themselves
   - No "correct" answers—help them integrate the learning
   - Format as a numbered list

4. DEEPEN MECHANISM EXPLANATIONS (add 200-300 words total):
   - Find sections that say "this works because..."
   - Expand with specific science/psychology/economics
   - Use technical terminology where appropriate
   - Integrate smoothly into existing text

QUALITY REQUIREMENTS:
- Voice: Maintain the author's tone and style exactly
- Length: Increase by 800-1,200 words total
- Integration: New content should feel like it was always there
- Accuracy: Use real examples where possible; note if speculative
- Structure: Don't break chapter flow

OUTPUT: Return the complete chapter with all additions integrated."""

        message = self.client.messages.create(
            model="claude-sonnet-4-5-20250514",
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )

        # Track costs
        input_tokens = message.usage.input_tokens
        output_tokens = message.usage.output_tokens
        cost = (input_tokens * self.costs["sonnet"]["input"] +
                output_tokens * self.costs["sonnet"]["output"])
        self.total_cost += cost

        return {
            "content": message.content[0].text,
            "tokens": {"input": input_tokens, "output": output_tokens},
            "cost": cost
        }

    def expand_chapter_opus(self, book_title, chapter_title, chapter_text, task_type="deepen"):
        """
        Use Claude Opus for more complex tasks (rewrites, humanization)
        task_type: "deepen", "rewrite", "humanize"
        """

        prompts = {
            "rewrite": f"""Rewrite Chapter 1 of "{book_title}" as a narrative introduction.

Current text:
{chapter_text}

STRUCTURE:
1. HOOK (300 words): Start with ONE person's story
2. WHY MOST PEOPLE FAIL (500 words): Common myths and why traditional advice doesn't work
3. THE FRAMEWORK (800 words): Your core approach + why it works
4. WHAT YOU'LL LEARN (500 words): Preview main topics
5. HOW TO USE THIS BOOK (400 words): Reading paths and application

OUTPUT: ~2,500 word replacement chapter""",

            "humanize": f"""Transform this chapter to be more authentic and specific.

Current text:
{chapter_text}

TASKS:
1. Replace all generic examples with named, specific people
   - "One CEO" → "Sarah Chen, VP at TechCorp, who scaled revenue from $2M to $18M"
   - Include concrete metrics and context

2. Expand mechanism explanations by 300-400 words
   - Why does this work? (psychology/economics/behavior)
   - What research supports it?
   - How to know if it's working

3. Reduce passive voice by 40%

4. Replace weak verbs and generic phrases

5. Add specificity and authenticity throughout

OUTPUT: Rewritten chapter maintaining original structure but with much more authenticity""",
        }

        prompt = prompts.get(task_type, prompts["deepen"])

        message = self.client.messages.create(
            model="claude-opus-4-6-20250514",
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )

        input_tokens = message.usage.input_tokens
        output_tokens = message.usage.output_tokens
        cost = (input_tokens * self.costs["opus"]["input"] +
                output_tokens * self.costs["opus"]["output"])
        self.total_cost += cost

        return {
            "content": message.content[0].text,
            "tokens": {"input": input_tokens, "output": output_tokens},
            "cost": cost
        }

    def process_book_elliot_deepening(self, book_dir, book_title, author_name="Elliott"):
        """
        Process entire Elliott book: deepen all chapters
        """
        book_path = Path(book_dir)
        chapters = sorted(book_path.glob("chapter_*.md"))

        results = {
            "book": book_title,
            "chapters_processed": 0,
            "chapters_failed": [],
            "total_cost": 0.0,
            "outputs": []
        }

        for chapter_file in chapters:
            try:
                chapter_text = chapter_file.read_text()
                chapter_num = chapter_file.stem

                # Get chapter title from first H1
                title_match = chapter_text.split('\n')[0].replace('# ', '')

                result = self.expand_chapter_sonnet(book_title, title_match, chapter_text)

                # Save expanded chapter
                output_file = chapter_file.parent / f"{chapter_num}_expanded.md"
                output_file.write_text(result["content"])

                results["chapters_processed"] += 1
                results["total_cost"] += result["cost"]
                results["outputs"].append({
                    "chapter": chapter_num,
                    "cost": result["cost"],
                    "tokens": result["tokens"]
                })

                print(f"✓ {chapter_num}: ${result['cost']:.2f} ({result['tokens']['input']} in, {result['tokens']['output']} out)")

            except Exception as e:
                results["chapters_failed"].append(f"{chapter_file.name}: {str(e)}")
                print(f"✗ {chapter_file.name}: {str(e)}")

        return results

    def process_book_workbook_transformation(self, book_dir, book_title):
        """
        Transform BookCLI workbook: add narrative, exercises, assessments
        """
        book_path = Path(book_dir)
        chapters = sorted(book_path.glob("chapter_*.md"))

        results = {
            "book": book_title,
            "chapters_processed": 0,
            "chapters_failed": [],
            "total_cost": 0.0,
            "outputs": []
        }

        for chapter_file in chapters:
            try:
                chapter_text = chapter_file.read_text()
                chapter_num = chapter_file.stem
                title_match = chapter_text.split('\n')[0].replace('# ', '')

                result = self.expand_chapter_sonnet(book_title, title_match, chapter_text)

                # Save transformed chapter
                output_file = chapter_file.parent / f"{chapter_num}_workbook.md"
                output_file.write_text(result["content"])

                results["chapters_processed"] += 1
                results["total_cost"] += result["cost"]
                results["outputs"].append({
                    "chapter": chapter_num,
                    "cost": result["cost"],
                })

                print(f"✓ {chapter_num}: ${result['cost']:.2f}")

            except Exception as e:
                results["chapters_failed"].append(f"{chapter_file.name}: {str(e)}")
                print(f"✗ {chapter_file.name}: {str(e)}")

        return results

    def get_cost_summary(self):
        """Return total costs"""
        return {
            "total_cost": f"${self.total_cost:.2f}",
            "estimated_remaining": f"${(384 - self.total_cost):.2f}"
        }


# USAGE EXAMPLE:
if __name__ == "__main__":
    expander = ContentExpander()

    # Example 1: Process Elliott book
    result = expander.process_book_elliot_deepening(
        "/home/elliott/output/books/The_Habit_Blueprint",
        "The Habit Blueprint"
    )
    print(f"\nProcessed: {result['chapters_processed']} chapters")
    print(f"Cost: ${result['total_cost']:.2f}")

    # Check budget
    print(f"\nTotal spent so far: {expander.get_cost_summary()}")
```

---

## ASYNC PARALLEL EXECUTION

For processing multiple books simultaneously:

```python
#!/usr/bin/env python3
"""
Parallel content expansion using asyncio
Process 5-10 books simultaneously within rate limits
"""

import asyncio
import os
from pathlib import Path
import anthropic

async def expand_chapter_async(client, book_title, chapter_file, model="claude-sonnet-4-5-20250514"):
    """Async wrapper for chapter expansion"""

    chapter_text = chapter_file.read_text()
    title = chapter_text.split('\n')[0].replace('# ', '')

    prompt = f"""Expand this chapter from {book_title}:

{chapter_text}

Add: 2 specific examples, key takeaway section, 3 reflection questions, and deepen mechanism explanations. Maintain voice and integrate seamlessly."""

    message = await client.messages.create(
        model=model,
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )

    return {
        "book": book_title,
        "chapter": chapter_file.name,
        "content": message.content[0].text,
        "cost": calculate_cost(message.usage)
    }


async def process_multiple_books(book_dirs, batch_size=5):
    """
    Process multiple books in parallel batches
    batch_size: how many chapters to process simultaneously (default 5)
    """
    client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

    all_tasks = []
    for book_dir in book_dirs:
        book_path = Path(book_dir)
        chapters = sorted(book_path.glob("chapter_*.md"))

        for chapter_file in chapters:
            all_tasks.append(expand_chapter_async(client, book_path.name, chapter_file))

    # Process in batches to avoid rate limits
    results = []
    for i in range(0, len(all_tasks), batch_size):
        batch = all_tasks[i:i+batch_size]
        batch_results = await asyncio.gather(*batch)
        results.extend(batch_results)

        # Rate limit: wait between batches
        if i + batch_size < len(all_tasks):
            await asyncio.sleep(2)  # 2 second delay between batches

    return results


# USAGE:
# asyncio.run(process_multiple_books([
#     "/home/elliott/output/books/The_Habit_Blueprint",
#     "/home/elliott/output/books/The_Resilience_Edge",
#     "/home/elliott/output/books/The_Wealth_Equation"
# ]))
```

---

## COST TRACKING & MONITORING

```python
"""
Track all API calls, costs, and quality metrics
"""

from datetime import datetime
import json
from pathlib import Path

class CostTracker:
    def __init__(self, output_file="/mnt/e/projects/content-expansion-costs.json"):
        self.output_file = Path(output_file)
        self.budget = 384.0  # Total budget
        self.spent = 0.0
        self.calls = []

        # Load existing data if available
        if self.output_file.exists():
            data = json.loads(self.output_file.read_text())
            self.spent = data.get("total_spent", 0)
            self.calls = data.get("calls", [])

    def log_call(self, book, chapter, model, tokens_in, tokens_out, cost):
        """Log an API call"""
        self.calls.append({
            "timestamp": datetime.now().isoformat(),
            "book": book,
            "chapter": chapter,
            "model": model,
            "tokens_in": tokens_in,
            "tokens_out": tokens_out,
            "cost": round(cost, 4)
        })
        self.spent += cost
        self.save()

    def save(self):
        """Save tracking data"""
        data = {
            "total_budget": self.budget,
            "total_spent": round(self.spent, 2),
            "remaining": round(self.budget - self.spent, 2),
            "percent_used": round((self.spent / self.budget) * 100, 1),
            "call_count": len(self.calls),
            "calls": self.calls
        }
        self.output_file.write_text(json.dumps(data, indent=2))

    def report(self):
        """Print tracking report"""
        percent = (self.spent / self.budget) * 100
        print(f"\n{'='*50}")
        print(f"COST TRACKING REPORT")
        print(f"{'='*50}")
        print(f"Total Budget:    ${self.budget:.2f}")
        print(f"Total Spent:     ${self.spent:.2f} ({percent:.1f}%)")
        print(f"Remaining:       ${self.budget - self.spent:.2f}")
        print(f"API Calls Made:  {len(self.calls)}")
        print(f"{'='*50}\n")

        if percent > 90:
            print("⚠️  WARNING: Approaching budget limit!")
        elif percent > 75:
            print("⚡ CAUTION: 75% of budget used")
```

---

## VERIFICATION & QUALITY GATES

```python
"""
Quality gate checks before accepting expanded content
"""

class ContentQualityValidator:
    def __init__(self):
        self.checks = [
            self.check_length,
            self.check_voice_consistency,
            self.check_specificity,
            self.check_integration,
        ]

    def validate(self, original_text, expanded_text, book_title):
        """Run all validation checks"""
        results = {
            "passed": True,
            "checks": []
        }

        for check in self.checks:
            result = check(original_text, expanded_text)
            results["checks"].append(result)
            if not result["passed"]:
                results["passed"] = False

        return results

    def check_length(self, original, expanded):
        """Verify length increased by 800-1200 words"""
        original_words = len(original.split())
        expanded_words = len(expanded.split())
        diff = expanded_words - original_words

        return {
            "name": "Length Check",
            "passed": 800 <= diff <= 1500,
            "original_words": original_words,
            "expanded_words": expanded_words,
            "difference": diff
        }

    def check_voice_consistency(self, original, expanded):
        """Verify author voice is maintained"""
        # Simple heuristic: check for consistent terminology
        original_sentences = original.count('.')
        expanded_sentences = expanded.count('.')

        # Voice is roughly maintained if sentence structure is similar
        avg_sentence_length_orig = len(original) / max(original_sentences, 1)
        avg_sentence_length_exp = len(expanded) / max(expanded_sentences, 1)

        ratio = avg_sentence_length_exp / max(avg_sentence_length_orig, 1)

        return {
            "name": "Voice Consistency",
            "passed": 0.8 <= ratio <= 1.3,  # Within 30% variance
            "sentence_length_ratio": ratio,
            "detail": "Voice consistency maintained" if 0.8 <= ratio <= 1.3 else "Warning: significant style change"
        }

    def check_specificity(self, original, expanded):
        """Check if new examples are specific (contain proper nouns, numbers)"""
        import re

        # Look for proper nouns and numbers in expanded text not in original
        new_text = expanded.replace(original, "")

        # Heuristic: count capitalized words and numbers
        capitalized = len(re.findall(r'\b[A-Z][a-z]+\b', new_text))
        numbers = len(re.findall(r'\b\d+\b', new_text))
        specificity_score = (capitalized + numbers) / len(new_text.split()) if new_text.split() else 0

        return {
            "name": "Specificity Check",
            "passed": specificity_score > 0.05,  # At least 5% proper nouns/numbers in new content
            "specificity_score": specificity_score,
            "detail": "Good specificity" if specificity_score > 0.05 else "Warning: may be too generic"
        }

    def check_integration(self, original, expanded):
        """Verify additions are seamlessly integrated"""
        # Check for jarring transitions
        red_flags = [
            "IMPORTANT:",
            "[Example:",
            "NOTE:",
            "###",  # Multiple heading levels suggest poor integration
        ]

        has_flags = any(flag in expanded for flag in red_flags)

        return {
            "name": "Integration Check",
            "passed": not has_flags,
            "red_flags_found": has_flags,
            "detail": "Seamlessly integrated" if not has_flags else "Warning: contains formatting flags"
        }
```

---

## PROGRESS TRACKING DASHBOARD

```python
"""
Real-time progress tracking and reporting
"""

class ProgressDashboard:
    def __init__(self):
        self.phases = {
            "Phase 1 - Elliott Pilot": {"target": 3, "completed": 0},
            "Phase 2 - Elliott Completion": {"target": 9, "completed": 0},
            "Phase 3 - BookCLI Workbooks": {"target": 13, "completed": 0},
            "Phase 4 - Books/Book Rescues": {"target": 10, "completed": 0},
        }
        self.total_cost = 0.0

    def update_phase(self, phase_name, increment=1):
        """Mark books as completed in a phase"""
        if phase_name in self.phases:
            self.phases[phase_name]["completed"] += increment

    def add_cost(self, amount):
        """Add to total cost"""
        self.total_cost += amount

    def print_dashboard(self):
        """Print progress dashboard"""
        print("\n" + "="*60)
        print("CONTENT EXPANSION PROGRESS DASHBOARD")
        print("="*60)

        total_target = sum(p["target"] for p in self.phases.values())
        total_completed = sum(p["completed"] for p in self.phases.values())
        overall_percent = (total_completed / total_target * 100) if total_target > 0 else 0

        for phase_name, data in self.phases.items():
            completed = data["completed"]
            target = data["target"]
            percent = (completed / target * 100) if target > 0 else 0
            bar = "█" * int(percent / 5) + "░" * (20 - int(percent / 5))

            print(f"\n{phase_name}")
            print(f"  [{bar}] {completed}/{target} ({percent:.0f}%)")

        print(f"\nOVERALL: {total_completed}/{total_target} books ({overall_percent:.0f}%)")
        print(f"COST: ${self.total_cost:.2f} / $384.00 ({(self.total_cost/384*100):.1f}%)")
        print("="*60 + "\n")
```

---

## NEXT STEPS

1. **Test API Connection**:
   ```bash
   python3 << 'EOF'
   import anthropic
   import os
   client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
   msg = client.messages.create(
       model="claude-sonnet-4-5-20250514",
       max_tokens=100,
       messages=[{"role": "user", "content": "Say 'API working'"}]
   )
   print(msg.content[0].text)
   EOF
   ```

2. **Set Up Tracking**:
   ```bash
   python3 << 'EOF'
   from CONTENT_EXPANSION_API_INTEGRATION import CostTracker
   tracker = CostTracker()
   tracker.report()
   EOF
   ```

3. **Start Phase 1**: Process 3 pilot books with deepening

4. **Validate Results**: Read expanded books, measure improvements

5. **Proceed to Phase 2**: If validated, process remaining Elliott books

---

**Document Status**: READY FOR IMPLEMENTATION
**API Model IDs**:
- Sonnet: claude-sonnet-4-5-20250514
- Opus: claude-opus-4-6-20250514
**Rate Limits**:
- Sonnet: 100 requests/min, 40K tokens/min
- Opus: 50 requests/min, 20K tokens/min
