# Pattern: Automated Publishing Without Official API

**Source:** bookcli-agent
**Date:** 2026-02-10
**Pattern Type:** Revenue Generation, Browser Automation

## Problem
Amazon KDP (Kindle Direct Publishing) has no official API for automated book publishing. Manual uploads are time-consuming and don't scale.

## Solution
Use **Playwright browser automation** to mimic human interaction with the KDP web interface.

## Implementation Pattern

### 1. Core Components

```python
# Browser automation with Playwright
from playwright.async_api import async_playwright

async with async_playwright().start() as p:
    browser = await p.chromium.launch(headless=False)
    page = await browser.new_page()

    # Navigate and interact
    await page.goto("https://kdp.amazon.com")
    # ... fill forms, upload files, click buttons
```

### 2. Authentication with 2FA Support

```python
async def login():
    # Enter credentials
    await page.fill('input[type="email"]', email)
    await page.click('button[type="submit"]')

    # Handle 2FA if required
    if "mfa" in page.url or "challenge" in page.url:
        logger.warning("2FA required - waiting for manual completion")
        await asyncio.sleep(60)  # Wait for user

    # Save session cookies
    cookies = await context.cookies()
    Path("~/.cookies.json").write_text(json.dumps(cookies))
```

### 3. File Uploads

```python
# Upload EPUB
manuscript_input = await page.wait_for_selector('input[type="file"][name="manuscript"]')
await manuscript_input.set_input_files(str(epub_path))

# Wait for upload confirmation
await page.wait_for_selector('.upload-success', timeout=120000)
```

### 4. Rate Limiting & Safety

```python
# Batch processing with delays
for book in books:
    await publish_book(book)
    if not last_book:
        await asyncio.sleep(300)  # 5 min delay
```

### 5. Error Handling

```python
try:
    await publish_book(metadata)
except Exception as e:
    # Take screenshot for debugging
    await page.screenshot(path=f"/tmp/error_{timestamp}.png")
    logger.error(f"Failed: {e}")
```

## Key Lessons

### ✅ DO
- Use realistic user agent strings
- Add delays between actions (mimic human behavior)
- Save session cookies to avoid re-authentication
- Implement dry-run mode for testing
- Take screenshots on errors
- Keep browser visible (headless=False) initially
- Respect rate limits

### ❌ DON'T
- Use headless mode without testing first
- Skip delays between book uploads
- Hardcode selectors without fallbacks
- Publish without testing on 1-2 books first
- Ignore errors - always log and screenshot

## Reusable for Other Platforms

This pattern works for ANY platform without an API:
- Etsy (product listings)
- Redbubble (print-on-demand)
- Teachable (course uploads)
- Gumroad (digital products)
- YouTube (video uploads with youtube-upload wrapper)

## Code Organization

```
publishing/
├── platform_uploader.py      # Core automation logic
├── batch_publisher.py         # Batch processing
├── README_AUTOMATION.md       # Documentation
scripts/
├── quick_start.sh            # User-friendly interface
```

## Dependencies
- `playwright` - Browser automation
- `asyncio` - Async/await pattern
- Standard lib only otherwise

## Security
- Store credentials in `.env` file
- Never commit credentials
- Use session cookies when possible
- Clear cookies on logout

## Testing Strategy
1. Dry-run mode (don't click "Publish")
2. Test with 1-2 items first
3. Keep browser visible to watch process
4. Validate uploads manually initially

## Metrics to Track
- Success rate
- Upload duration
- Error types
- Rate limit hits

## Real-World Results (bookcli)
- **Before:** 0 books published automatically
- **After:** Can publish 10 books/hour (with safety delays)
- **Revenue Impact:** $5-10K/month potential
- **Time Saved:** ~30 min per book = 5 hours per 10 books

## When NOT to Use
- Platform has official API (use that instead)
- Terms of Service explicitly forbid automation
- CAPTCHA on every action
- Platform actively blocks bots

## Alternative Approaches Considered
1. ❌ Scraping HTML → Too brittle
2. ❌ API reverse engineering → Violates ToS
3. ✅ Playwright automation → Works, maintainable

## Maintenance
- UI changes require selector updates
- Test after platform updates
- Monitor error logs
- Keep screenshots of UI for reference

---

**Use this pattern when building revenue-generating automation for platforms without APIs.**
