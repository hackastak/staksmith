# Web Content Fetching Scripts

This directory contains scripts for fetching and converting web content to markdown.

## fetch-web-content.py

A Playwright-based web scraper that handles JavaScript-rendered content.

### Installation

```bash
pip3 install playwright html2text
playwright install chromium
```

### Usage

**Basic usage** (prints to stdout):
```bash
python3 fetch-web-content.py https://example.com
```

**Save to file**:
```bash
python3 fetch-web-content.py https://example.com output.md
```

**Wait for specific content to load**:
```bash
python3 fetch-web-content.py https://spa-app.com --wait-for "div.content"
```

**Increase timeout for slow sites**:
```bash
python3 fetch-web-content.py https://slow-site.com --timeout 60000 output.md
```

**Skip markdown cleaning**:
```bash
python3 fetch-web-content.py https://example.com --no-clean output.md
```

### Features

- **JavaScript Support**: Fully renders JavaScript-heavy sites (React, Vue, Angular, etc.)
- **Wait for Content**: Can wait for specific selectors before extracting
- **Network Idle**: Waits for network activity to settle
- **Clean Output**: Removes excessive blank lines and formats markdown nicely
- **Flexible Output**: Save to file or print to stdout
- **Error Handling**: Graceful error handling with informative messages

### Common Use Cases

**Single Page Application (SPA)**:
```bash
python3 fetch-web-content.py https://app.example.com --wait-for "main.loaded"
```

**Documentation Site**:
```bash
python3 fetch-web-content.py https://docs.example.com/api/reference api-reference.md
```

**Article Extraction**:
```bash
python3 fetch-web-content.py https://blog.example.com/post --wait-for "article" post.md
```

**Multiple Pages** (using bash loop):
```bash
for url in url1 url2 url3; do
  python3 fetch-web-content.py "$url" "$(basename $url).md"
  sleep 2  # Be respectful, add delay between requests
done
```

### Troubleshooting

**Import Error**:
If you see "Required package not found", run:
```bash
pip3 install playwright html2text
playwright install chromium
```

**Timeout Error**:
If the page takes too long to load, increase the timeout:
```bash
python3 fetch-web-content.py <url> --timeout 60000
```

**Incomplete Content**:
If content is missing, try waiting for a specific selector:
```bash
python3 fetch-web-content.py <url> --wait-for "div.main-content"
```

**Permission Denied**:
If you get a permission error, make the script executable:
```bash
chmod +x fetch-web-content.py
```

### Technical Details

- **Browser**: Chromium (headless mode)
- **Wait Strategy**: Network idle (waits for network activity to settle)
- **HTML to Markdown**: Uses html2text library with optimized settings
- **Character Encoding**: UTF-8
- **Line Wrapping**: Disabled (preserves original formatting)
