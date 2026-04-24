export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'ANTHROPIC_API_KEY nao configurada' });
  try {
    // Parse body — Vercel may send it as string in some configs
    let body = req.body;
    if (typeof body === 'string') {
      try { body = JSON.parse(body); } catch(e) { return res.status(400).json({ error: 'Body invalido' }); }
    }

    let messages;
    let max_tokens = body.max_tokens || 1400;

    if (body.prompt && typeof body.prompt === 'string' && body.prompt.trim()) {
      messages = [{ role: 'user', content: body.prompt.trim() }];
    } else if (Array.isArray(body.messages) && body.messages.length > 0) {
      messages = body.messages;
    } else {
      return res.status(400).json({ error: 'prompt ou messages em falta' });
    }

    const payload = {
      model: 'claude-sonnet-4-6',
      max_tokens: max_tokens,
      messages: messages,
    };

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(payload),
    });
    const data = await response.json();
    if (!response.ok) return res.status(response.status).json(data);
    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}
