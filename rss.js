export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  const feeds = [
    { url: 'https://www.record.pt/futebol/futebol-nacional/feed/', source: 'Record' },
    { url: 'https://www.ojogo.pt/futebol/rss', source: 'O Jogo' },
    { url: 'https://www.zerozero.pt/rss.php', source: 'ZeroZero' },
  ];

  // Palavras-chave relevantes para futebol jovem
  const keywords = [
    'juniores','juvenis','iniciados','sub-','formação','formacao',
    'academia','campeonato de portugal','liga 3','segunda liga','2ª liga',
    'liga hyundai','af porto','af braga','gondomar','leixões','boavista',
    'seleção nacional','sub-15','sub-16','sub-17','sub-18','sub-19','sub-21',
    'jovem','talento','promessa','revelação'
  ];

  function parseXML(xml) {
    const items = [];
    const itemMatches = xml.match(/<item>([\s\S]*?)<\/item>/gi) || [];
    itemMatches.forEach(function(item) {
      const title = (item.match(/<title><!\[CDATA\[(.*?)\]\]><\/title>/) ||
                     item.match(/<title>(.*?)<\/title>/) || [])[1] || '';
      const link  = (item.match(/<link>(.*?)<\/link>/) ||
                     item.match(/<link[^>]*>(.*?)<\/link>/) || [])[1] || '';
      const pubDate = (item.match(/<pubDate>(.*?)<\/pubDate>/) || [])[1] || '';
      const desc = (item.match(/<description><!\[CDATA\[([\s\S]*?)\]\]><\/description>/) ||
                    item.match(/<description>([\s\S]*?)<\/description>/) || [])[1] || '';
      if (title) items.push({ title: title.trim(), link: link.trim(), pubDate, desc: desc.replace(/<[^>]*>/g,'').substring(0,150) });
    });
    return items;
  }

  function isRelevant(item) {
    const text = (item.title + ' ' + item.desc).toLowerCase();
    return keywords.some(function(k){ return text.includes(k); });
  }

  function timeAgo(dateStr) {
    if (!dateStr) return '—';
    const diff = Date.now() - new Date(dateStr).getTime();
    const h = Math.floor(diff / 3600000);
    if (h < 1) return 'há poucos minutos';
    if (h < 24) return 'há ' + h + 'h';
    const d = Math.floor(h / 24);
    return 'há ' + d + 'd';
  }

  const results = [];

  await Promise.all(feeds.map(async function(feed) {
    try {
      const r = await fetch(feed.url, { headers: { 'User-Agent': 'YourTalentBase/1.0' }, signal: AbortSignal.timeout(5000) });
      if (!r.ok) return;
      const xml = await r.text();
      const items = parseXML(xml);
      items.forEach(function(item) {
        if (isRelevant(item)) {
          results.push({
            source: feed.source,
            title: item.title,
            link: item.link,
            time: timeAgo(item.pubDate),
            pubDate: item.pubDate,
            desc: item.desc
          });
        }
      });
    } catch(e) {}
  }));

  // Ordenar por data, mais recente primeiro
  results.sort(function(a, b) {
    return new Date(b.pubDate || 0) - new Date(a.pubDate || 0);
  });

  return res.status(200).json({ items: results.slice(0, 24) });
}
