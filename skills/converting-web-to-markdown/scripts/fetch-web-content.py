#!/usr/bin/env python3
"""
Web Content to Markdown Converter using Playwright

This script fetches web content using Playwright (handles JavaScript-rendered content)
and converts it to clean markdown format.

Usage:
    python3 fetch-web-content.py <url> [output-file.md]

Examples:
    python3 fetch-web-content.py https://example.com
    python3 fetch-web-content.py https://example.com output.md
    python3 fetch-web-content.py https://spa-app.com --wait-for="div.content"
"""

import sys
import argparse
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright
    import html2text
except ImportError as e:
    print(f"Error: Required package not found: {e}")
    print("\nPlease install required packages:")
    print("  pip3 install playwright html2text")
    print("  playwright install chromium")
    sys.exit(1)


def fetch_web_content(url: str, wait_for_selector: str = None, timeout: int = 30000) -> str:
    """
    Fetch web content using Playwright.

    Args:
        url: The URL to fetch
        wait_for_selector: Optional CSS selector to wait for before extracting content
        timeout: Timeout in milliseconds (default: 30000)

    Returns:
        HTML content as string
    """
    with sync_playwright() as p:
        # Launch browser in headless mode
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        try:
            # Navigate to the URL
            print(f"Fetching: {url}", file=sys.stderr)
            page.goto(url, wait_until="networkidle", timeout=timeout)

            # Wait for specific selector if provided
            if wait_for_selector:
                print(f"Waiting for selector: {wait_for_selector}", file=sys.stderr)
                page.wait_for_selector(wait_for_selector, timeout=timeout)
            else:
                # Default wait for body to be loaded
                page.wait_for_selector("body", timeout=timeout)

            # Get the page content
            content = page.content()

            # Get page title for metadata
            title = page.title()
            print(f"Page title: {title}", file=sys.stderr)

            return content

        except Exception as e:
            print(f"Error fetching content: {e}", file=sys.stderr)
            raise
        finally:
            browser.close()


def html_to_markdown(html_content: str, base_url: str = None) -> str:
    """
    Convert HTML content to markdown.

    Args:
        html_content: HTML content as string
        base_url: Base URL for resolving relative links

    Returns:
        Markdown formatted string
    """
    h = html2text.HTML2Text()

    # Configure html2text options
    h.ignore_links = False
    h.ignore_images = False
    h.ignore_emphasis = False
    h.body_width = 0  # Don't wrap lines
    h.single_line_break = False
    h.wrap_links = False
    h.skip_internal_links = False
    h.inline_links = True
    h.protect_links = True
    h.images_to_alt = False
    h.unicode_snob = True  # Use unicode characters instead of ASCII
    h.escape_snob = False

    if base_url:
        h.baseurl = base_url

    # Convert to markdown
    markdown = h.handle(html_content)

    return markdown


def clean_markdown(markdown: str) -> str:
    """
    Clean up the markdown output.

    Args:
        markdown: Raw markdown string

    Returns:
        Cleaned markdown string
    """
    # Remove excessive blank lines (more than 2 consecutive)
    lines = markdown.split('\n')
    cleaned_lines = []
    blank_count = 0

    for line in lines:
        if line.strip() == '':
            blank_count += 1
            if blank_count <= 2:
                cleaned_lines.append(line)
        else:
            blank_count = 0
            cleaned_lines.append(line)

    return '\n'.join(cleaned_lines)


def main():
    parser = argparse.ArgumentParser(
        description='Fetch web content and convert to markdown using Playwright',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s https://example.com
  %(prog)s https://example.com output.md
  %(prog)s https://spa-app.com --wait-for "div.content"
  %(prog)s https://docs.example.com --timeout 60000 output.md
        """
    )

    parser.add_argument('url', help='URL to fetch')
    parser.add_argument('output', nargs='?', help='Output markdown file (optional, prints to stdout if not provided)')
    parser.add_argument('--wait-for', dest='wait_for', help='CSS selector to wait for before extracting content')
    parser.add_argument('--timeout', type=int, default=30000, help='Timeout in milliseconds (default: 30000)')
    parser.add_argument('--no-clean', action='store_true', help='Skip markdown cleaning step')

    args = parser.parse_args()

    try:
        # Fetch the content
        html_content = fetch_web_content(
            args.url,
            wait_for_selector=args.wait_for,
            timeout=args.timeout
        )

        # Convert to markdown
        print("Converting to markdown...", file=sys.stderr)
        markdown = html_to_markdown(html_content, base_url=args.url)

        # Clean markdown unless disabled
        if not args.no_clean:
            markdown = clean_markdown(markdown)

        # Output the markdown
        if args.output:
            output_path = Path(args.output)
            output_path.write_text(markdown, encoding='utf-8')
            print(f"\nMarkdown saved to: {output_path}", file=sys.stderr)
            print(f"File size: {len(markdown)} characters", file=sys.stderr)
        else:
            # Print to stdout
            print(markdown)

        return 0

    except KeyboardInterrupt:
        print("\nOperation cancelled by user", file=sys.stderr)
        return 130
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
