#!/usr/bin/env python3
"""
analyzer.py

Parses downloaded Threat Intelligence sources (RSS, JSON),
matches content against defined keywords, and generates a unified HTML report.
"""

import json
import sys
import os
import re
import html
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta

class ThreatItem:
    """Represents a single threat intelligence finding."""
    def __init__(self, title, link, date_str, summary, source_name, keywords_found):
        self.title = title
        self.link = link
        self.date_str = date_str
        self.summary = summary
        self.source_name = source_name
        self.keywords_found = keywords_found

class IntelAnalyzer:
    """Core logic to parse sources and generate reports."""
    def __init__(self, config_path, data_dir, output_dir, css_path):
        self.config_path = config_path
        self.data_dir = data_dir
        self.output_dir = output_dir
        self.css_path = css_path
        self.config = self._load_config()
        self.keywords = [k.lower() for k in self.config.get('keywords', [])]
        self.exclusions = [e.lower() for e in self.config.get('exclusions', [])]
        self.inclusions = [i.lower() for i in self.config.get('inclusions', [])]
        self.lookback_days = self.config.get('parameters', {}).get('lookback_days', 7)
        self.cutoff_date = datetime.now() - timedelta(days=self.lookback_days)
        self.findings = []

        # Apply environment-based filtering if set from script-master
        filter_mode = os.environ.get('INTEL_FILTER', 'default')
        if filter_mode == 'general':
            self.inclusions.extend(['breach', 'attack', 'hacked', 'data leak', 'cyber', 'security'])
            self.exclusions.extend(['patch', 'update', 'cve', 'vulnerability', 'flaw'])
        elif filter_mode == 'patches':
            self.inclusions.extend(['patch', 'update', 'cve', 'vulnerability', 'flaw', 'zero-day', 'exploit', 'rce'])
            self.keywords = [] # Prioritize only patch/vuln inclusions
        elif filter_mode == 'other':
            self.inclusions.extend(['malware', 'ransomware', 'phishing', 'apt', 'botnet', 'ddos'])
            self.exclusions.extend(['patch', 'update'])

    def _load_config(self):
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading config: {e}", file=sys.stderr)
            sys.exit(1)

    def _sanitize_html(self, text):
        """Removes HTML tags and converts entities."""
        if not text:
            return ""
        clean = re.sub('<.*?>', '', text)
        return html.unescape(clean).strip()

    def _find_keywords(self, text):
        """Returns list of matched keywords in text."""
        if not text:
            return []
        text_lower = text.lower()
        return [kw for kw in self.keywords if kw.lower() in text_lower]

    def _find_inclusions(self, text):
        """Returns list of matched inclusions in text."""
        if not text:
            return []
        text_lower = text.lower()
        return [inc for inc in self.inclusions if inc.lower() in text_lower]

    def _has_exclusions(self, text):
        """Returns True if any exclusion words are found in the text."""
        if not text or not self.exclusions:
            return False
        text_lower = text.lower()
        return any(ex in text_lower for ex in self.exclusions)

    def _parse_date(self, date_str):
        """Attempts to parse standard date formats."""
        if not date_str:
            return datetime.now()
        # Clean up some common RSS date anomalies
        # e.g., "Tue, 16 Apr 2024 10:00:00 +0000"
        try:
            from dateutil.parser import parse
            return parse(date_str, fuzzy=True).replace(tzinfo=None)
        except ImportError:
            # Fallback if dateutil is not installed (using regex and basic parsing could be done here,
            # but we assume the environment might be minimal. A basic approach is best effort.)
            # For this exercise, we will assume all dates are valid if dateutil isn't there,
            # but we'll try a basic strptime fallback.
            pass

        try:
            # Try basic RSS format
            # e.g. Wed, 02 Oct 2002 13:00:00 GMT
            import email.utils
            parsed = email.utils.parsedate_to_datetime(date_str)
            return parsed.replace(tzinfo=None)
        except Exception:
            return datetime.now()

    def analyze_rss(self, file_path, source_name):
        try:
            tree = ET.parse(file_path)
            root = tree.getroot()

            # Basic RSS
            for item in root.findall('.//item'):
                title = item.findtext('title', '')
                link = item.findtext('link', '')
                pub_date = item.findtext('pubDate', '')
                desc = self._sanitize_html(item.findtext('description', ''))

                content = f"{title} {desc}"
                matches = self._find_keywords(content)
                inclusions_matches = self._find_inclusions(content)

                # Inclusions override exclusions.
                # Keep if there are inclusions OR (matches exist AND no exclusions).
                if inclusions_matches or (matches and not self._has_exclusions(content)):
                    # Use inclusions if they exist, otherwise use matched keywords
                    tags = inclusions_matches if inclusions_matches else matches

                    dt = self._parse_date(pub_date)
                    if dt >= self.cutoff_date:
                        self.findings.append(ThreatItem(
                            title=title, link=link, date_str=pub_date,
                            summary=desc, source_name=source_name, keywords_found=tags
                        ))
        except Exception as e:
            print(f"Error parsing RSS {file_path}: {e}", file=sys.stderr)

    def analyze_cisa_kev(self, file_path, source_name):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            for vuln in data.get('vulnerabilities', []):
                title = vuln.get('vulnerabilityName', '')
                desc = vuln.get('shortDescription', '')
                date_added = vuln.get('dateAdded', '')
                cve = vuln.get('cveID', '')
                link = f"https://nvd.nist.gov/vuln/detail/{cve}"

                content = f"{title} {desc}"
                matches = self._find_keywords(content)
                inclusions_matches = self._find_inclusions(content)

                # Inclusions override exclusions.
                if inclusions_matches or (matches and not self._has_exclusions(content)):
                    tags = inclusions_matches if inclusions_matches else matches

                    try:
                        dt = datetime.strptime(date_added, '%Y-%m-%d')
                    except ValueError:
                        dt = datetime.now()

                    if dt >= self.cutoff_date:
                        self.findings.append(ThreatItem(
                            title=title, link=link, date_str=date_added,
                            summary=desc, source_name=source_name, keywords_found=tags
                        ))
        except Exception as e:
            print(f"Error parsing JSON {file_path}: {e}", file=sys.stderr)

    def analyze_atom(self, file_path, source_name):
        try:
            tree = ET.parse(file_path)
            root = tree.getroot()
            # Atom namespace can be complex, use wildcard for basic tags
            ns = {'atom': 'http://www.w3.org/2005/Atom'}
            entries = root.findall('.//{http://www.w3.org/2005/Atom}entry')
            if not entries:
                 entries = root.findall('.//entry') # fallback without namespace

            for entry in entries:
                title_elem = entry.find('{http://www.w3.org/2005/Atom}title')
                if title_elem is None: title_elem = entry.find('title')
                title = title_elem.text if title_elem is not None else ''

                link = ''
                link_elems = entry.findall('{http://www.w3.org/2005/Atom}link')
                if not link_elems: link_elems = entry.findall('link')
                for l in link_elems:
                    if l.get('rel') == 'alternate' or not l.get('rel'):
                        link = l.get('href', '')
                        break

                updated_elem = entry.find('{http://www.w3.org/2005/Atom}updated')
                if updated_elem is None: updated_elem = entry.find('updated')
                pub_date = updated_elem.text if updated_elem is not None else ''

                content_elem = entry.find('{http://www.w3.org/2005/Atom}content')
                if content_elem is None: content_elem = entry.find('content')
                desc = self._sanitize_html(content_elem.text if content_elem is not None else '')

                if not desc:
                    summary_elem = entry.find('{http://www.w3.org/2005/Atom}summary')
                    if summary_elem is None: summary_elem = entry.find('summary')
                    desc = self._sanitize_html(summary_elem.text if summary_elem is not None else '')

                content = f"{title} {desc}"
                matches = self._find_keywords(content)
                inclusions_matches = self._find_inclusions(content)

                if inclusions_matches or (matches and not self._has_exclusions(content)):
                    tags = inclusions_matches if inclusions_matches else matches
                    dt = self._parse_date(pub_date)
                    if dt >= self.cutoff_date:
                        self.findings.append(ThreatItem(
                            title=title, link=link, date_str=pub_date,
                            summary=desc, source_name=source_name, keywords_found=tags
                        ))
        except Exception as e:
            print(f"Error parsing Atom {file_path}: {e}", file=sys.stderr)

    def analyze_html(self, file_path, source_name):
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # Naive HTML extraction: grab titles and links from <a> tags
            a_tags = re.findall(r'<a\s+(?:[^>]*?\s+)?href=(["\'])(.*?)\1[^>]*>(.*?)</a>', content, re.IGNORECASE | re.DOTALL)

            seen_links = set()
            for _, link, text in a_tags:
                if link in seen_links or link.startswith('#') or link.startswith('javascript'):
                    continue
                seen_links.add(link)

                title = self._sanitize_html(text)
                if not title:
                    continue

                # Expand relative links safely if it looks like a relative path
                if link.startswith('/'):
                    # Guess domain from source URL if available in config?
                    # For simplicity, just store the relative link.
                    pass

                full_content = f"{title}"
                matches = self._find_keywords(full_content)
                inclusions_matches = self._find_inclusions(full_content)

                if inclusions_matches or (matches and not self._has_exclusions(full_content)):
                    tags = inclusions_matches if inclusions_matches else matches

                    self.findings.append(ThreatItem(
                        title=title, link=link, date_str=datetime.now().strftime("%Y-%m-%d"),
                        summary="Parsed from HTML feed", source_name=source_name, keywords_found=tags
                    ))
        except Exception as e:
            print(f"Error parsing HTML {file_path}: {e}", file=sys.stderr)

    def process_all(self):
        """Iterates through downloaded files and delegates to specific parsers."""
        sources = self.config.get('sources', [])
        for i, source in enumerate(sources):
            # The shell script saves files as source_0.raw, source_1.raw, etc.
            raw_file = os.path.join(self.data_dir, f"source_{i}.raw")
            if not os.path.exists(raw_file):
                print(f"Skipping {source['name']}, file not found.", file=sys.stderr)
                continue

            if source.get('type') == 'rss':
                self.analyze_rss(raw_file, source['name'])
            elif source.get('type') == 'cisa_kev':
                self.analyze_cisa_kev(raw_file, source['name'])
            elif source.get('type') == 'atom':
                self.analyze_atom(raw_file, source['name'])
            elif source.get('type') == 'html':
                self.analyze_html(raw_file, source['name'])

    def generate_report(self):
        """Creates the final HTML report."""
        try:
            with open(self.css_path, 'r', encoding='utf-8') as f:
                css_content = f.read()
        except Exception:
            css_content = "/* CSS missing */"

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        file_timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = os.path.join(self.output_dir, f"intel_report_{file_timestamp}.html")

        # Group findings by source
        grouped_findings = {}
        for item in self.findings:
            if item.source_name not in grouped_findings:
                grouped_findings[item.source_name] = []
            grouped_findings[item.source_name].append(item)

        html_out = [
            "<!DOCTYPE html>",
            "<html lang='en'>",
            "<head>",
            "<meta charset='UTF-8'>",
            "<meta name='viewport' content='width=device-width, initial-scale=1.0'>",
            f"<title>Threat Intel Report - {timestamp}</title>",
            f"<style>\n{css_content}\n</style>",
            "</head>",
            "<body>",
            "<div class='container'>",
            "<header>",
            "<div>",
            "<h1>Threat Intelligence Report</h1>",
            f"<div class='timestamp'>Generated: {timestamp}</div>",
            "</div>",
            "</header>",

            "<div class='dashboard-stats'>",
            f"<div class='stat-card'><div class='stat-value'>{len(self.findings)}</div><div class='stat-label'>Total Matches</div></div>",
            f"<div class='stat-card'><div class='stat-value'>{len(grouped_findings)}</div><div class='stat-label'>Active Sources</div></div>",
            f"<div class='stat-card'><div class='stat-value'>{len(self.keywords)}</div><div class='stat-label'>Monitored Keywords</div></div>",
            "</div>"
        ]

        if not grouped_findings:
            html_out.append("<div class='no-data'>No active threats found matching your keywords in the configured timeframe.</div>")
        else:
            for source_name, items in grouped_findings.items():
                html_out.append(f"<details class='source-section' open>")
                html_out.append(f"<summary class='source-header'><h2>{html.escape(source_name)}</h2></summary>")
                html_out.append("<div class='threat-grid'>")

                for item in items:
                    html_out.append("<div class='threat-card'>")
                    html_out.append(f"<h3 class='threat-title'><a href='{html.escape(item.link)}' target='_blank' rel='noopener noreferrer'>{html.escape(item.title)}</a></h3>")
                    html_out.append(f"<div class='threat-date'>{html.escape(str(item.date_str))}</div>")
                    html_out.append(f"<div class='threat-summary'>{html.escape(item.summary)}</div>")

                    html_out.append("<div class='threat-keywords'>")
                    for kw in item.keywords_found:
                        html_out.append(f"<span class='keyword-tag'>{html.escape(kw)}</span>")
                    html_out.append("</div>")

                    html_out.append("</div>") # Close threat-card

                html_out.append("</div>") # Close threat-grid
                html_out.append("</details>") # Close source-section

        html_out.append("</div></body></html>")

        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("\n".join(html_out))

        print(report_path) # Print path so shell script knows where it is

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: analyzer.py <config_path> <data_dir> <output_dir> <css_path>", file=sys.stderr)
        sys.exit(1)

    config_path = sys.argv[1]
    data_dir = sys.argv[2]
    output_dir = sys.argv[3]
    css_path = sys.argv[4]

    analyzer = IntelAnalyzer(config_path, data_dir, output_dir, css_path)
    analyzer.process_all()
    analyzer.generate_report()
