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

  // MOTOR v2: janela de impressão com TEXTO REAL (window.print → guardar como
  // PDF). O motor anterior (html2pdf/html2canvas) rasterizava o HTML para
  // imagem e falhava de formas diferentes em dispositivos diferentes — o
  // fundador reportou "PDF sem nada escrito" mesmo depois da correção do
  // wrapper fixo. Rasterização de canvas é frágil por natureza (fontes,
  // timing, memória em telemóveis); imprimir texto a sério não é. O PDF
  // resultante é selecionável e pesquisável. Em telemóvel, o diálogo de
  // impressão do sistema tem "Guardar como PDF".
  function abrirJanelaImpressao(ctx){
    var built = template(ctx);
    var win = global.open('', '_blank');
    if(!win){
      global.alert('O navegador bloqueou a janela de impressão. Permite pop-ups para exportar o plano.');
      return null;
    }
    var doc = win.document;
    doc.open();
    doc.write('<!DOCTYPE html><html lang="pt"><head><meta charset="utf-8">'
      + '<title>Plano de Treino · ' + esc(ctx.atletaNome) + ' · Semana ' + ctx.semanaAtual + '</title>'
      + '<style>'
      + '@page{size:A4;margin:12mm}'
      + 'html,body{margin:0;padding:0;background:#fff}'
      + '@media screen{body{background:#e8e8e8;padding:20px} .folha{max-width:760px;margin:0 auto;box-shadow:0 2px 14px rgba(0,0,0,.18)}}'
      + '.no-print{position:sticky;top:0;display:flex;gap:10px;justify-content:center;padding:12px;background:#111;}'
      + '.no-print button{font:700 14px Arial;padding:10px 18px;border-radius:8px;border:none;cursor:pointer;background:#D4AF37;color:#000}'
      + '.no-print span{color:#bbb;font:12px Arial;align-self:center}'
      + '@media print{.no-print{display:none}}'
      + '</style></head><body>'
      + '<div class="no-print"><button onclick="window.print()">🖨 Imprimir / Guardar PDF</button><span>No telemóvel: escolhe “Guardar como PDF” no diálogo.</span></div>'
      + '<div class="folha">' + built.html + '</div>'
      + '</body></html>');
    doc.close();
    if(global.QRCode && ctx.passaporteUrl){
      try{
        // qrcodejs desenha no documento da NOVA janela (elemento vive lá)
        new global.QRCode(doc.getElementById(built.qrId), { text: ctx.passaporteUrl, width:70, height:70, correctLevel: global.QRCode.CorrectLevel.M });
      }catch(e){ /* segue sem QR se a biblioteca falhar */ }
    }
    return win;
  }

  function planoPDF(raw){
    var ctx = montarContexto(raw);
    var win = abrirJanelaImpressao(ctx);
    if(!win) return Promise.reject(new Error('popup bloqueado'));
    // dá um instante ao layout/QR antes de abrir o diálogo de impressão
    return new Promise(function(resolve){
      setTimeout(function(){
        try{ win.focus(); win.print(); }catch(e){ /* o utilizador ainda tem o botão na janela */ }
        resolve();
      }, 350);
    });
  }

  global.YTBExport = { planoPDF: planoPDF, montarContexto: montarContexto, _abrirJanelaImpressao: abrirJanelaImpressao };
})(window);
