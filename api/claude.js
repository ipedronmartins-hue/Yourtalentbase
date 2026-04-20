export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'ANTHROPIC_API_KEY nao configurada' });
  try {
    const body = req.body;
    let messages, system, max_tokens;
    if (body.prompt) {
      messages = [{ role: 'user', content: body.prompt }];
      system = null;
      max_tokens = body.max_tokens || 1400;
    } else {
      messages = body.messages;
      system = body.system || null;
      max_tokens = body.max_tokens || 2048;
    }
    if (!messages?.length) return res.status(400).json({ error: 'messages em falta' });
    const payload = { model: 'claude-sonnet-4-6', max_tokens, messages };
    if (system) payload.system = system;
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
      body: JSON.stringify(payload),
    });
    const data = await response.json();
    if (!response.ok) return res.status(response.status).json(data);
    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}
