#!/usr/bin/env python3
"""
Simple API server to bridge the quiz app with the on-demand scraper.
Runs on http://localhost:8000

Usage:
    pip install flask flask-cors
    python api_server.py
"""

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import subprocess
import json
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for local development

@app.route('/')
def index():
    """Serve the quiz app"""
    return send_from_directory('.', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    """Serve static files"""
    return send_from_directory('.', path)

@app.route('/api/scrape')
def scrape():
    """
    Scrape fresh questions on-demand.
    Query params:
        - count: number of questions (10, 15, 30, 50)
        - category: category slug (default: all)
    """
    try:
        count = int(request.args.get('count', 10))
        
        # Map any count to valid values for the scraper
        if count <= 10:
            scraper_count = 10
        elif count <= 15:
            scraper_count = 15
        elif count <= 30:
            scraper_count = 30
        else:
            scraper_count = 50
        
        category = request.args.get('category', 'all')
        
        print(f"📥 Scraping {scraper_count} questions from {category}...")
        
        # Run the on-demand scraper
        result = subprocess.run(
            ['python', 'scraper_ondemand.py', '--count', str(scraper_count), '--category', category, '--output', 'temp_quiz.json'],
            capture_output=True,
            text=True,
            timeout=120  # 2 minute timeout
        )
        
        if result.returncode != 0:
            print(f"❌ Scraper error: {result.stderr}")
            # Try to load from fallback
            if os.path.exists('questions.json'):
                print(f"📂 Using fallback from questions.json")
                with open('questions.json', 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    questions = data.get('questions', [])
                    if category != 'all':
                        questions = [q for q in questions if q.get('category') == category]
                    
                    # Shuffle and limit to requested count
                    import random
                    random.shuffle(questions)
                    questions = questions[:count]
                    
                    return jsonify({
                        'questions': questions,
                        'meta': {
                            'count': len(questions),
                            'source': 'fallback',
                            'category': category
                        }
                    })
            return jsonify({'error': 'Scraping failed and no fallback available'}), 500
        
        # Load the scraped questions
        if os.path.exists('temp_quiz.json'):
            with open('temp_quiz.json', 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Limit to exact requested count if needed
            if len(data.get('questions', [])) > count:
                data['questions'] = data['questions'][:count]
                data['meta']['count'] = count
            
            # Clean up temp file
            os.remove('temp_quiz.json')
            print(f"✅ Scraped {len(data.get('questions', []))} questions successfully")
            return jsonify(data)
        else:
            return jsonify({'error': 'Scraper did not produce output'}), 500
            
    except subprocess.TimeoutExpired:
        print(f"⏰ Scraping timeout")
        return jsonify({'error': 'Scraping timeout. Try cached mode.'}), 504
    except Exception as e:
        print(f"❌ API error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'message': 'API server is running'})

if __name__ == '__main__':
    print("╔══════════════════════════════════════╗")
    print("║   TestPoint Quiz API Server          ║")
    print("╚══════════════════════════════════════╝")
    print("\n🚀 Starting server on http://localhost:8000")
    print("📱 Open http://localhost:8000 in your browser")
    print("🔄 Fresh questions will be scraped on-demand\n")
    
    app.run(host='0.0.0.0', port=8000, debug=True)
