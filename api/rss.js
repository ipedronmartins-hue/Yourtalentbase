export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 's-maxage=300'); // cache 5 minutos no Vercel

  // Usar rss2json como proxy — resolve CORS e é gratuito
  const feeds = [
    {
      url: 'https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fwww.record.pt%2Ffutebol%2Ffutebol-nacional%2Ffeed%2F&api_key=free&count=20',
      source: 'Record'
    },
    {
      url: 'https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fwww.ojogo.pt%2Ffutebol%2Frss&api_key=free&count=20',
      source: 'O Jogo'
    },
    {
      url: 'https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fwww.abola.pt%2Frss%2Findex.ashx%3Ff%3DNOT&api_key=free&count=20',
      source: 'A Bola'
    }
  ];

  const keywords = [
    'junior','juniores','juvenis','iniciados','sub-','formação','formacao',
    'academia','campeonato de portugal','liga 3','segunda liga','2ª liga',
    'liga hyundai','af porto','af braga','gondomar','leixões','boavista',
    'seleção','sub-15','sub-16','sub-17','sub-18','sub-19','sub-21',
    'jovem','talento','promessa','revelação','formação'
  ];

  function isRelevant(title, desc) {
    const text = ((title||'') + ' ' + (desc||'')).toLowerCase();
    return keywords.some(k => text.includes(k));
  }

  function timeAgo(dateStr) {
    if (!dateStr) return '—';
    const diff = Date.now() - new Date(dateStr).getTime();
    const h = Math.floor(diff / 3600000);
    if (h < 1) return 'há poucos minutos';
    if (h < 24) return 'há ' + h + 'h';
    return 'há ' + Math.floor(h / 24) + 'd';
  }

  const results = [];

  await Promise.all(feeds.map(async feed => {
    try {
      const r = await fetch(feed.url, {
        signal: AbortSignal.timeout(8000)
      });
      if (!r.ok) return;
      const data = await r.json();
      if (!data.items) return;
      data.items.forEach(item => {
        const title = item.title || '';
        const desc = item.description ? item.description.replace(/<[^>]*>/g,'') : '';
        if (isRelevant(title, desc)) {
          results.push({
            source: feed.source,
            title: title.trim(),
            link: item.link || '#',
            time: timeAgo(item.pubDate),
            pubDate: item.pubDate || '',
            desc: desc.substring(0, 120)
          });
        }
      });
    } catch(e) {
      console.error(feed.source, e.message);
    }
  }));

  // Ordenar por data
  results.sort((a, b) => new Date(b.pubDate||0) - new Date(a.pubDate||0));

  // Se não houver resultados filtrados, devolver as mais recentes sem filtro
  if (results.length === 0) {
    return res.status(200).json({ items: [], message: 'Sem notícias de formação de momento.' });
  }

  return res.status(200).json({ items: results.slice(0, 20) });
}
