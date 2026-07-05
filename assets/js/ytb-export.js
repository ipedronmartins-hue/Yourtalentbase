// ytb-export.js — módulo partilhado de exportação de PDF (família + treinador).
// Depende de html2pdf.bundle.min.js e qrcode.min.js já carregados (self-hosted em assets/js/vendor/).
(function(global){
  "use strict";

  function esc(s){ return String(s==null?'':s).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];}); }
  function fmtDataPT(d){
    try{ return new Date(d||Date.now()).toLocaleDateString('pt-PT',{day:'2-digit',month:'2-digit',year:'numeric'}); }
    catch(e){ return ''; }
  }

  // Função pura: normaliza dados soltos (do chamador) num contexto completo e
  // previsível para o template do PDF. Sem DOM, sem rede — testável isolada.
  function montarContexto(raw){
    raw = raw || {};
    var exercicios = (raw.exercicios||[]).map(function(e){
      return {
        nome: e.nome || 'Exercício',
        objetivo: e.objetivo || '',
        desc: e.desc || e.descricao || '',
        tempo: e.tempo != null ? e.tempo : null,
        material: e.material || null,
        sessao: e.sessao || null
      };
    });
    var tempoTotal = exercicios.reduce(function(s,e){ return s + (e.tempo||0); }, 0);
    return {
      atletaId: raw.atletaId || null,
      atletaNome: raw.atletaNome || 'Atleta',
      clube: raw.clube || '',
      escalao: raw.escalao || '',
      treinadorNome: raw.treinadorNome || null,
      semanaAtual: raw.semanaAtual || 1,
      totalSemanas: raw.totalSemanas || 4,
      cicloNome: raw.cicloNome || '',
      cicloDescricao: raw.cicloDescricao || '',
      exercicios: exercicios,
      tempoTotal: tempoTotal,
      proximoObjetivo: raw.proximoObjetivo || null,
      emitidoEm: raw.emitidoEm || new Date().toISOString(),
      passaporteUrl: raw.passaporteUrl || (raw.atletaId ? (global.location.origin + '/passaporte.html?atleta=' + raw.atletaId) : '')
    };
  }

  function template(ctx){
    var qrId = 'ytbexp-qr-' + Math.random().toString(36).slice(2);
    var exsHTML = ctx.exercicios.map(function(e,i){
      return '<div style="border:1px solid #ddd;border-radius:8px;padding:10px 12px;margin-bottom:8px;page-break-inside:avoid">'
        + '<div style="font-weight:700;font-size:13px;color:#111">' + (i+1) + '. ' + esc(e.nome) + (e.sessao?'  <span style="font-weight:400;font-size:10px;color:#999">· Sessão '+e.sessao+'</span>':'') + '</div>'
        + (e.objetivo ? '<div style="font-size:11px;color:#2a7a2a;margin-top:2px">🎯 ' + esc(e.objetivo) + '</div>' : '')
        + (e.desc ? '<div style="font-size:11px;color:#444;margin-top:3px;line-height:1.4">' + esc(e.desc) + '</div>' : '')
        + '<div style="font-size:10px;color:#777;margin-top:4px">' + (e.tempo!=null?'⏱ '+e.tempo+' min':'') + (e.material?'  ·  🎒 '+esc(e.material):'') + '</div>'
        + '</div>';
    }).join('');
    var html =
      '<div style="font-family:Arial,Helvetica,sans-serif;color:#111;width:720px;padding:28px 32px;background:#fff">'
        + '<div style="display:flex;justify-content:space-between;align-items:flex-start;border-bottom:3px solid #0A0D0A;padding-bottom:14px;margin-bottom:16px">'
          + '<div><div style="font-family:Georgia,serif;font-weight:900;font-size:22px;letter-spacing:.5px">Your<span style="color:#D4AF37">Talent</span>Base</div>'
          + '<div style="font-size:10px;color:#888;letter-spacing:1.5px;text-transform:uppercase;margin-top:2px">Plano de Treino Prescrito</div></div>'
          + '<div style="text-align:right;font-size:11px;color:#555">Emitido em ' + fmtDataPT(ctx.emitidoEm) + '</div>'
        + '</div>'
        + '<div style="display:flex;justify-content:space-between;margin-bottom:18px;font-size:12px">'
          + '<div><strong>Atleta:</strong> ' + esc(ctx.atletaNome) + '<br><strong>Clube:</strong> ' + esc(ctx.clube||'—') + ' · <strong>Escalão:</strong> ' + esc(ctx.escalao||'—') + '</div>'
          + '<div style="text-align:right"><strong>Treinador:</strong> ' + esc(ctx.treinadorNome||'—') + '<br><strong>Semana ' + ctx.semanaAtual + ' de ' + ctx.totalSemanas + '</strong></div>'
        + '</div>'
        + '<div style="background:#f7f5ec;border:1px solid #e5dfc8;border-radius:8px;padding:12px 14px;margin-bottom:16px">'
          + '<div style="font-size:11px;font-weight:800;letter-spacing:1px;text-transform:uppercase;color:#8a7a2a">Objetivo da semana' + (ctx.cicloNome?' · '+esc(ctx.cicloNome):'') + '</div>'
          + '<div style="font-size:12.5px;margin-top:4px">' + esc(ctx.cicloDescricao||'—') + '</div>'
        + '</div>'
        + '<div style="font-size:12px;font-weight:800;letter-spacing:1px;text-transform:uppercase;margin-bottom:8px">Exercícios prescritos <span style="font-weight:400;color:#777">(' + ctx.tempoTotal + ' min no total)</span></div>'
        + exsHTML
        + '<div style="display:flex;gap:14px;margin-top:18px">'
          + '<div style="flex:1;border:1px solid #ddd;border-radius:8px;padding:10px 12px;min-height:70px"><div style="font-size:10px;font-weight:800;text-transform:uppercase;color:#777;margin-bottom:6px">Notas dos pais</div></div>'
          + '<div style="flex:1;border:1px solid #ddd;border-radius:8px;padding:10px 12px;min-height:70px"><div style="font-size:10px;font-weight:800;text-transform:uppercase;color:#777;margin-bottom:6px">Comentários do atleta</div></div>'
        + '</div>'
        + (ctx.proximoObjetivo ? '<div style="margin-top:16px;background:#eef6ee;border:1px solid #cfe8cf;border-radius:8px;padding:10px 14px"><div style="font-size:10px;font-weight:800;text-transform:uppercase;color:#2a7a2a">Próximo objetivo</div><div style="font-size:12px;margin-top:3px">' + esc(ctx.proximoObjetivo) + '</div></div>' : '')
        + '<div style="display:flex;justify-content:space-between;align-items:flex-end;margin-top:24px;padding-top:14px;border-top:1px solid #ddd">'
          + '<div style="font-size:10.5px;color:#444"><div style="margin-bottom:6px">Prescrito por <strong>' + esc(ctx.treinadorNome||'treinador YTB') + '</strong> via YourTalentBase</div>'
          + '<div style="border-top:1px solid #999;width:170px;padding-top:3px;color:#999;font-size:9.5px">assinatura digital do treinador · não é uma assinatura criptográfica</div></div>'
          + '<div style="text-align:center"><div id="' + qrId + '"></div><div style="font-size:8.5px;color:#888;margin-top:3px">Abrir Passaporte Digital</div></div>'
        + '</div>'
        + '<div style="margin-top:18px;padding-top:10px;border-top:1px solid #eee;font-size:9.5px;color:#999;line-height:1.5;text-align:center">Plano gerado automaticamente pela YourTalentBase.<br>Toda a evolução do atleta fica registada no seu Passaporte Digital.</div>'
      + '</div>';
    return { html: html, qrId: qrId };
  }

  function planoPDF(raw){
    var ctx = montarContexto(raw);
    if(!global.html2pdf){ global.alert('Exportação indisponível (biblioteca de PDF não carregada).'); return Promise.reject(new Error('html2pdf ausente')); }
    var built = template(ctx);
    var host = document.createElement('div');
    host.style.cssText = 'position:fixed;left:-9999px;top:0;';
    host.innerHTML = built.html;
    document.body.appendChild(host);
    if(global.QRCode && ctx.passaporteUrl){
      try{
        new global.QRCode(document.getElementById(built.qrId), { text: ctx.passaporteUrl, width:70, height:70, correctLevel: global.QRCode.CorrectLevel.M });
      }catch(e){ /* segue sem QR se a biblioteca falhar */ }
    }
    var nomeArq = 'Plano-' + String(ctx.atletaNome||'atleta').replace(/[^a-z0-9]+/gi,'-') + '-semana' + ctx.semanaAtual + '.pdf';
    return global.html2pdf().set({
      margin: 0,
      filename: nomeArq,
      html2canvas: { scale: 2, backgroundColor: '#ffffff' },
      jsPDF: { unit:'pt', format:'a4', orientation:'portrait' }
    }).from(host).save().then(function(){ document.body.removeChild(host); }).catch(function(err){ document.body.removeChild(host); throw err; });
  }

  global.YTBExport = { planoPDF: planoPDF, montarContexto: montarContexto };
})(window);
