// Vercel Serverless Function to trigger GitHub Actions scraper
// Deploy this to Vercel for free

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { category = 'all', count = 50 } = req.body;

  try {
    // Trigger GitHub Actions workflow
    const response = await fetch(
      'https://api.github.com/repos/musharrafhamraz/FIA-Preparation_App/dispatches',
      {
        method: 'POST',
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Authorization': `token ${process.env.GITHUB_PAT}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          event_type: 'scrape-questions',
          client_payload: {
            category: category,
            count: count,
          },
        }),
      }
    );

    if (response.status === 204) {
      // Wait a bit for the action to start
      await new Promise(resolve => setTimeout(resolve, 2000));

      return res.status(200).json({
        success: true,
        message: 'Scraping started! Questions will be updated in 2-3 minutes.',
        category: category,
        count: count,
      });
    } else {
      const error = await response.text();
      return res.status(500).json({
        success: false,
        error: 'Failed to trigger scraper',
        details: error,
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
}
