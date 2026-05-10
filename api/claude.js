// /api/claude.js — proxy para Claude API com rate limit por IP
//
// RATE LIMIT: 30 requests/hora por IP (in-memory)
// Reset automático a cada hora
// Adequado para volumes baixos. Para escala, usar Upstash Redis ou similar.

const RATE_LIMIT_PER_HOUR = 30;
const HOUR_MS = 60 * 60 * 1000;

// Map<ip, {count, windowStart}>
const ipUsage = new Map();

function getClientIp(req) {
  // Vercel envia o IP real em x-forwarded-for
  const fwd = req.headers['x-forwarded-for'];
  if (fwd) return fwd.split(',')[0].trim();
  return req.headers['x-real-ip'] || req.socket?.remoteAddress || 'unknown';
}

function checkRateLimit(ip) {
  const now = Date.now();
  const usage = ipUsage.get(ip);
  if (!usage || (now - usage.windowStart) > HOUR_MS) {
    // Janela nova
    ipUsage.set(ip, { count: 1, windowStart: now });
    return { allowed: true, remaining: RATE_LIMIT_PER_HOUR - 1 };
  }
  if (usage.count >= RATE_LIMIT_PER_HOUR) {
    const resetIn = Math.ceil((HOUR_MS - (now - usage.windowStart)) / 60000);
    return { allowed: false, remaining: 0, resetInMinutes: resetIn };
  }
  usage.count++;
  return { allowed: true, remaining: RATE_LIMIT_PER_HOUR - usage.count };
}

// Cleanup old entries cada 30 min para evitar memory leak
setInterval(() => {
  const now = Date.now();
  for (const [ip, usage] of ipUsage) {
    if ((now - usage.windowStart) > HOUR_MS) ipUsage.delete(ip);
  }
}, 30 * 60 * 1000);

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  // Rate limit por IP
  const ip = getClientIp(req);
  const rl = checkRateLimit(ip);
  if (!rl.allowed) {
    return res.status(429).json({
      error: 'Demasiados pedidos. Limite: ' + RATE_LIMIT_PER_HOUR + '/hora.',
      reset_in_minutes: rl.resetInMinutes
    });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'ANTHROPIC_API_KEY nao configurada' });

  try {
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

    // Header informativo (opcional, frontend pode usar)
    res.setHeader('X-RateLimit-Remaining', rl.remaining);
    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}
