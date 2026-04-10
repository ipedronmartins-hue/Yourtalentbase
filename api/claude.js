export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { messages, system } = req.body;

    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'Missing or invalid messages' });
    }

    const body = {
      model: 'claude-3-5-sonnet-20250219',
      max_tokens: 4096,
      messages: messages
    };

    if (system) body.system = system;

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify(body)
    });

    const responseText = await response.text();

    if (!response.ok) {
      console.error('Anthropic error:', response.status, responseText);
      return res.status(response.status).json({ error: responseText, status: response.status });
    }

    const data = JSON.parse(responseText);
    return res.status(200).json(data);

  } catch (error) {
    console.error('Erro Claude API:', error);
    return res.status(500).json({ error: error.message });
  }
}
