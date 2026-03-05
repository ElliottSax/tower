# GA4 Custom Event Tracking Code

## gtag.js_installation

```javascript

<!-- Google tag (gtag.js) - Place in <head> -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>

```

## email_signup_event

```javascript

<!-- Track email signup -->
<script>
document.getElementById('email-form').addEventListener('submit', function(e) {
  gtag('event', 'email_signup', {
    'article_slug': document.body.getAttribute('data-article-slug'),
    'form_type': 'exit_intent'
  });
});
</script>

```

## affiliate_click_event

```javascript

<!-- Track affiliate clicks -->
<script>
document.querySelectorAll('a[data-affiliate]').forEach(link => {
  link.addEventListener('click', function(e) {
    gtag('event', 'affiliate_click', {
      'article_slug': document.body.getAttribute('data-article-slug'),
      'affiliate_network': this.getAttribute('data-affiliate-network'),
      'tool_name': this.getAttribute('data-tool-name')
    });
  });
});
</script>

```

## scroll_depth_tracking

```javascript

<!-- Track scroll depth -->
<script>
let maxScroll = 0;
window.addEventListener('scroll', function() {
  const scrollPercent = Math.round((window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100);

  // Report at 25%, 50%, 75%, 100%
  if (scrollPercent > maxScroll) {
    if (scrollPercent >= 100 && maxScroll < 100) {
      gtag('event', 'scroll_to_100', {
        'article_slug': document.body.getAttribute('data-article-slug')
      });
    } else if (scrollPercent >= 75 && maxScroll < 75) {
      gtag('event', 'scroll_to_75', {
        'article_slug': document.body.getAttribute('data-article-slug')
      });
    } else if (scrollPercent >= 50 && maxScroll < 50) {
      gtag('event', 'scroll_to_50', {
        'article_slug': document.body.getAttribute('data-article-slug')
      });
    }
    maxScroll = scrollPercent;
  }
});
</script>

```

