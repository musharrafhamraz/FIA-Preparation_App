#!/usr/bin/env python3
"""
TestPoint PK On-Demand MCQ Scraper
===================================
Fetches fresh questions on-demand from testpointpk.com.
Falls back to questions.json only if scraping fails.

Usage:
    python scraper_ondemand.py --count 10 --category general-knowledge
    python scraper_ondemand.py --count 30 --category all
    python scraper_ondemand.py --count 50  # defaults to 'all' category
"""

import requests
from bs4 import BeautifulSoup
import json
import time
import random
import argparse
from datetime import datetime

# ── CONFIG ──────────────────────────────────────────────────────────────────
FALLBACK_FILE = "questions.json"
TIMEOUT = 20
DELAY_MIN = 0.5
DELAY_MAX = 1.2

CATEGORIES = {
    "all": "https://testpointpk.com/important-mcqs",
    "islamic-studies-mcqs": "https://testpointpk.com/important-mcqs/islamic-studies-mcqs",
    "pak-study": "https://testpointpk.com/important-mcqs/pak-study",
    "computer": "https://testpointpk.com/important-mcqs/computer",
    "english": "https://testpointpk.com/important-mcqs/english",
    "general-knowledge": "https://testpointpk.com/important-mcqs/general-knowledge",
    "general-science": "https://testpointpk.com/important-mcqs/general-science",
    "everyday-science": "https://testpointpk.com/important-mcqs/everyday-science",
    "pedagogy": "https://testpointpk.com/important-mcqs/pedagogy",
    "maths-mcqs": "https://testpointpk.com/important-mcqs/maths-mcqs",
    "urdu-mcqs": "https://testpointpk.com/important-mcqs/urdu-mcqs",
    "monthly-current-affairs": "https://testpointpk.com/important-mcqs/monthly-current-affairs",
    "yearly-current-affairs": "https://testpointpk.com/important-mcqs/yearly-current-affairs",
    "pakistan-current-affairs": "https://testpointpk.com/important-mcqs/pakistan-current-affairs",
    "international-current-affairs": "https://testpointpk.com/important-mcqs/international-current-affairs",
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,ur;q=0.8",
    "Connection": "keep-alive",
}


# ── PARSER ──────────────────────────────────────────────────────────────────
def parse_page(html, category_slug=""):
    """Parse a single page and extract all questions."""
    soup = BeautifulSoup(html, "html.parser")
    questions = []

    q_links = soup.find_all("a", class_="theme-color")
    
    for q_link in q_links:
        try:
            q_text = q_link.get_text(strip=True)
            if not q_text or len(q_text) < 5:
                continue

            container = q_link.find_parent("div")
            while container and not container.find("ol"):
                container = container.find_parent("div")
            
            if not container:
                continue

            urdu = ""
            for h6 in container.find_all("h6"):
                t = h6.get_text(strip=True)
                if any("\u0600" <= c <= "\u06ff" for c in t):
                    urdu = t
                    break

            ol = container.find("ol", type="A") or container.find("ol")
            if not ol:
                continue
            
            options = []
            correct_idx = 0
            
            for li_idx, li in enumerate(ol.find_all("li", recursive=False)):
                opt_text = li.get_text(strip=True)
                options.append(opt_text)
                
                if "correct" in li.get("class", []):
                    correct_idx = li_idx
            
            if len(options) < 2:
                continue

            expl_html = ""
            expl_div = container.find("div", class_="question-explanation")
            if expl_div:
                expl_content = expl_div.find("p")
                if expl_content:
                    expl_html = str(expl_content)

            questions.append({
                "q": q_text,
                "urdu": urdu,
                "options": options,
                "correct": correct_idx,
                "explanation": expl_html,
                "category": category_slug,
            })

        except Exception:
            continue

    return questions


def fetch_page(session, url):
    """Fetch a single page and return HTML."""
    try:
        headers_copy = HEADERS.copy()
        if 'Accept-Encoding' in headers_copy:
            del headers_copy['Accept-Encoding']
        
        r = session.get(url, headers=headers_copy, timeout=TIMEOUT)
        if r.status_code == 200:
            return r.text
        return None
    except Exception:
        return None


def scrape_on_demand(count, category="all"):
    """Scrape fresh questions on-demand."""
    if category not in CATEGORIES:
        print(f"Error: Unknown category: {category}")
        return None

    base_url = CATEGORIES[category]
    session = requests.Session()
    
    print(f"Fetching {count} fresh questions from {category}...")
    
    all_questions = []
    page = 1
    max_pages = (count // 10) + 2
    
    try:
        session.get("https://testpointpk.com/", headers=HEADERS, timeout=TIMEOUT)
        time.sleep(0.5)
    except Exception:
        pass
    
    while len(all_questions) < count and page <= max_pages:
        url = f"{base_url}?page={page}"
        print(f"   Page {page}... ({len(all_questions)}/{count})", end="\r")
        
        html = fetch_page(session, url)
        if html is None:
            print(f"\n   Warning: Failed to fetch page {page}")
            break
        
        parsed = parse_page(html, category)
        if not parsed:
            print(f"\n   Warning: No questions on page {page}")
            break
        
        all_questions.extend(parsed)
        page += 1
        
        if len(all_questions) < count:
            time.sleep(random.uniform(DELAY_MIN, DELAY_MAX))
    
    print(f"\n   Fetched {len(all_questions)} questions")
    return all_questions[:count] if all_questions else None


def load_from_fallback(count, category="all"):
    """Load questions from the fallback JSON file."""
    try:
        with open(FALLBACK_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        questions = data.get("questions", [])
        
        if category != "all":
            questions = [q for q in questions if q.get("category") == category]
        
        random.shuffle(questions)
        return questions[:count]
    
    except Exception as e:
        print(f"Error: Failed to load fallback: {e}")
        return []


def main():
    parser = argparse.ArgumentParser(description="TestPoint PK On-Demand Scraper")
    parser.add_argument("--count", type=int, default=50,
                        help="Number of questions (default: 50)")
    parser.add_argument("--category", default="all",
                        help="Category to scrape (default: all)")
    parser.add_argument("--output", default="quiz_questions.json",
                        help="Output file (default: quiz_questions.json)")
    args = parser.parse_args()

    print("=" * 40)
    print("  TestPoint PK On-Demand Scraper")
    print("=" * 40)
    print(f"\nRequested: {args.count} questions")
    print(f"Category: {args.category}")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    questions = scrape_on_demand(args.count, args.category)
    
    if not questions or len(questions) < args.count:
        print(f"\nWarning: Scraping incomplete. Using fallback...")
        questions = load_from_fallback(args.count, args.category)
        if not questions:
            print("Error: No questions available!")
            return
    
    output_data = {
        "meta": {
            "count": len(questions),
            "requested": args.count,
            "category": args.category,
            "fetched_at": datetime.now().isoformat(),
            "source": "live_scrape"
        },
        "questions": questions
    }
    
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)
    
    print(f"\nSaved {len(questions)} questions to {args.output}")
    print(f"Category: {args.category}")
    print(f"Ready to use!\n")


if __name__ == "__main__":
    main()
