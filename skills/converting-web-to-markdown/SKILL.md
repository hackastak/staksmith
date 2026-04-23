---
name: converting-web-to-markdown
description: Fetches content from a specified website URL and converts it to markdown format using WebFetch or Playwright for JavaScript-heavy sites. Use when the user wants to extract web page content, convert HTML to markdown, scrape dynamic websites, or save web content locally as markdown files.
---

# Converting Web to Markdown

This skill helps you fetch content from websites and convert it to clean, readable markdown format. It supports both simple static pages (using WebFetch) and complex JavaScript-rendered content (using Playwright).

## Instructions

When converting web content to markdown, follow these steps:

### Step 1: Validate the URL

Before fetching content, ensure:
- The URL is properly formatted (includes protocol: http:// or https://)
- The URL is accessible and not restricted
- Confirm with the user if the URL seems unusual or potentially sensitive

### Step 2: Choose the Appropriate Method

**Use WebFetch when**:
- The website is primarily static HTML content
- Quick extraction is needed
- The page doesn't require JavaScript to render content
- Authentication is not required

**Use Playwright when**:
- The website uses JavaScript to render content
- Content loads dynamically (infinite scroll, lazy loading)
- You need to interact with the page (click buttons, wait for elements)
- The page requires authentication or complex navigation
- WebFetch returns incomplete or missing content

### Step 3a: Fetch with WebFetch (Simple Method)

Use the WebFetch tool for static content:
```
WebFetch tool with:
- url: The target website URL
- prompt: "Extract all content from this page and convert it to clean markdown format. Preserve headings, paragraphs, lists, links, code blocks, and other important structural elements."
```

The WebFetch tool automatically:
- Fetches the HTML content
- Converts it to markdown format
- Returns the processed content

### Step 3b: Fetch with Playwright (Advanced Method)

For JavaScript-heavy sites, use the Playwright script:

1. **Check if Playwright is installed**:
   ```bash
   python3 -c "import playwright" 2>/dev/null && echo "Playwright installed" || echo "Playwright not installed"
   ```

2. **Install if needed**:
   ```bash
   pip3 install playwright html2text
   playwright install chromium
   ```

3. **Run the fetch script**:
   ```bash
   python3 scripts/fetch-web-content.py <url> [output-file.md]
   ```

The script will:
- Launch a headless browser
- Wait for JavaScript to render
- Extract the content
- Convert to markdown
- Save to file or print to stdout

### Step 4: Review and Clean the Content

After fetching:
- Review the markdown output for quality
- Note any formatting issues or missing content
- Check that important elements (headings, links, code) are preserved

### Step 5: Save to File (Optional)

If the user wants to save the markdown:
- Ask for a filename if not provided
- Use a descriptive name based on the page title or URL
- Save with `.md` extension
- Use the Write tool to save the content

Example filename patterns:
- `page-title.md`
- `website-name-page-topic.md`
- `extracted-content-YYYY-MM-DD.md`

### Step 6: Confirm Completion

Inform the user:
- Where the file was saved (if applicable)
- A brief summary of the content extracted
- Any issues encountered during extraction

## Best Practices

- **Start simple**: Try WebFetch first, fall back to Playwright if content is incomplete
- Always validate URLs before fetching to avoid errors
- For large websites, inform the user that only the specific page will be fetched (not entire site)
- If the WebFetch returns a redirect notification, make a new request with the redirect URL
- Preserve the original structure and hierarchy of the content
- Remove or note if advertisements or navigation elements clutter the output
- For pages requiring authentication, inform the user of the limitation
- If the content is very large (>500 lines), confirm with the user before saving
- **Use Playwright when**: Content is missing, page uses React/Vue/Angular, or user specifically requests it
- Be mindful of website terms of service and robots.txt when scraping
- Add delays between requests when fetching multiple pages to be respectful

## Examples

### Example 1: Simple Web Page Extraction

User request: "Convert https://example.com/article to markdown"

Steps:
1. Validate the URL format
2. Use WebFetch with url="https://example.com/article" and prompt asking for markdown conversion
3. Review the returned markdown content
4. Ask user if they want to save it to a file
5. If yes, save as `example-article.md`

### Example 2: Extracting Documentation

User request: "Get the content from https://docs.example.com/api/reference and save it as api-reference.md"

Steps:
1. Validate the URL
2. Use WebFetch to fetch and convert to markdown
3. Review the markdown for proper code block formatting
4. Save directly to `api-reference.md` as requested
5. Confirm the file was saved successfully

### Example 3: Multiple Pages

User request: "Convert these three URLs to markdown: [url1, url2, url3]"

Steps:
1. Validate all three URLs
2. Use WebFetch for each URL (can be done in parallel)
3. For each result, create a separate markdown file
4. Name files descriptively based on content
5. Provide summary of all files created

### Example 4: JavaScript-Heavy Site with Playwright

User request: "Extract content from https://spa-app.example.com that uses React"

Steps:
1. Try WebFetch first and notice incomplete content
2. Switch to Playwright approach
3. Check if Playwright is installed, install if needed
4. Run: `python3 scripts/fetch-web-content.py https://spa-app.example.com output.md`
5. Review the extracted markdown
6. Confirm successful extraction with complete content

### Example 5: Handling Redirects

If WebFetch returns a redirect notification:
1. Note the redirect URL provided
2. Make a new WebFetch request with the redirect URL
3. Proceed with the content from the final destination
4. Inform the user about the redirect

## Troubleshooting

**Issue**: URL is not accessible
- Verify the URL is correct and publicly accessible
- Check if the site requires authentication
- Try adding `https://` if protocol is missing

**Issue**: Content looks malformed or incomplete
- Some websites have complex layouts that may not convert cleanly
- Try Playwright instead of WebFetch for JavaScript-heavy sites
- Use `--wait-for` option with Playwright to wait for specific content to load
- Review the output and manually clean if needed

**Issue**: Content is too large
- Confirm with user before proceeding
- Consider if only specific sections are needed
- Save to file rather than displaying all content

**Issue**: Redirect to different host
- WebFetch will notify you about cross-host redirects
- Make a new WebFetch request with the provided redirect URL
- This is common for shortened URLs or CDN-served content

**Issue**: Playwright not installed
- Run: `pip3 install playwright html2text`
- Then: `playwright install chromium`
- See [scripts/README.md](scripts/README.md) for details

**Issue**: Playwright timeout error
- Increase timeout: `--timeout 60000` (60 seconds)
- Some sites load slowly or have heavy JavaScript

**Issue**: Missing content with Playwright
- Use `--wait-for` to wait for specific element: `--wait-for "div.content"`
- Inspect the page to find the right CSS selector
- Some content may load after initial page render

## Limitations

**WebFetch**:
- Fetches single pages, not entire websites
- JavaScript-heavy sites may not render completely (use Playwright instead)
- Authentication-protected content cannot be accessed
- Some dynamic content may not be captured

**Playwright**:
- Requires additional installation (playwright, html2text)
- Slower than WebFetch due to browser overhead
- May not work with sites that have bot detection
- Authentication-protected content still requires manual login

**General**:
- Both methods fetch single pages, not entire websites
- Rate limiting may apply for repeated requests
- Respect robots.txt and terms of service

## Quick Reference

**Basic WebFetch call**:
```
url: "https://example.com/page"
prompt: "Extract all content from this page and convert it to clean markdown format. Preserve headings, paragraphs, lists, links, and code blocks."
```

**Basic Playwright usage**:
```bash
python3 scripts/fetch-web-content.py https://example.com output.md
```

**Playwright with options**:
```bash
# Wait for specific content
python3 scripts/fetch-web-content.py https://spa.example.com --wait-for "div.content" output.md

# Increase timeout for slow sites
python3 scripts/fetch-web-content.py https://slow.example.com --timeout 60000 output.md
```

**Common WebFetch prompts for different needs**:
- Full content: "Extract all content and convert to markdown, preserving all structure."
- Article focus: "Extract the main article content, ignoring navigation and ads, convert to markdown."
- Documentation: "Extract documentation content with proper code block formatting in markdown."
- Summary: "Extract key headings and summarize main points in markdown format."

**Decision Tree**:
1. Start with WebFetch for speed
2. If content is incomplete → Use Playwright
3. If still incomplete → Use Playwright with `--wait-for`
4. If timeout occurs → Increase `--timeout`

**Additional Resources**:
- See [scripts/README.md](scripts/README.md) for detailed Playwright usage
- See [scripts/fetch-web-content.py](scripts/fetch-web-content.py) for script documentation
