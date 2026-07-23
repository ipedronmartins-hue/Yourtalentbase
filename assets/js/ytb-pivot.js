/* YTB Pivot — navegação estilo Windows Phone 8 (títulos grandes, o seguinte espreita,
   deslize lateral). Partilhado pelas páginas com tabs. Uso:
     YTBPivot.titulos(el, [{rotulo:'atletas', ir:fn}, ...], idxAtivo)
     YTBPivot.deslize(alvo, function(direcao){ ... })  // direcao: +1 esq→dir, -1 dir→esq
   O deslize ignora gestos que começam dentro de elementos com scroll horizontal
   próprio (tabelas, chips), para não os sequestrar. */
(function(){
  var CSS = ''
    + '.ytb-pivo-head{display:flex;gap:24px;overflow-x:auto;position:sticky;top:0;z-index:60;background:var(--bg,#080C08);padding:14px 2px 10px;scrollbar-width:none;-webkit-overflow-scrolling:touch}'
    + '.ytb-pivo-head::-webkit-scrollbar{display:none}'
    + ".ytb-pivo-head button{flex:0 0 auto;font-family:'Barlow Condensed',sans-serif;font-weight:900;font-size:30px;line-height:1;letter-spacing:-.3px;color:var(--muted,#6B756C);background:none;border:none;padding:0;cursor:pointer;white-space:nowrap;transition:color .18s}"
    + '.ytb-pivo-head button.on{color:var(--text,#ECEFEA)}'
    + '.ytb-pivo-head .badge{font-family:inherit;font-size:13px;vertical-align:super}'
    /* animação de entrada (estilo WP8: o painel desliza do lado de onde vens) */
    + '.ytb-pivo-in-dir{animation:ytbPivoDir .3s cubic-bezier(.2,.7,.3,1)}'
    + '.ytb-pivo-in-esq{animation:ytbPivoEsq .3s cubic-bezier(.2,.7,.3,1)}'
    + '@keyframes ytbPivoDir{from{opacity:0;transform:translateX(38px)}to{opacity:1;transform:none}}'
    + '@keyframes ytbPivoEsq{from{opacity:0;transform:translateX(-38px)}to{opacity:1;transform:none}}'
    /* dica de deslize lateral */
    + '.ytb-pivo-dica{font-size:11px;font-weight:700;letter-spacing:1px;color:var(--muted,#6B756C);text-transform:uppercase;padding:2px 2px 8px;animation:ytbPivoDica 4s ease forwards;pointer-events:none}'
    + '@keyframes ytbPivoDica{0%{opacity:0}12%{opacity:1}80%{opacity:1}100%{opacity:0;height:0;padding:0;margin:0}}'
    + '@media (prefers-reduced-motion:reduce){.ytb-pivo-in-dir,.ytb-pivo-in-esq{animation:none}}';

  function css(){
    if(document.getElementById('ytb-pivot-css')) return;
    var s=document.createElement('style'); s.id='ytb-pivot-css'; s.textContent=CSS;
    document.head.appendChild(s);
  }

  function scrollHoriz(el, raiz){
    // algum antepassado (até raiz) tem scroll horizontal próprio?
    while(el && el!==raiz && el.nodeType===1){
      try{
        var cs=getComputedStyle(el);
        if((cs.overflowX==='auto'||cs.overflowX==='scroll') && el.scrollWidth>el.clientWidth+4) return true;
      }catch(e){}
      el=el.parentNode;
    }
    return false;
  }

  window.YTBPivot={
    titulos:function(el, itens, ativo){
      css();
      el.classList.add('ytb-pivo-head');
      el.innerHTML=itens.map(function(it,i){
        return '<button type="button" class="'+(i===ativo?'on':'')+'" data-i="'+i+'">'+it.rotulo+'</button>';
      }).join('');
      Array.prototype.forEach.call(el.querySelectorAll('button'), function(b){
        b.onclick=function(){ var it=itens[parseInt(b.getAttribute('data-i'),10)]; if(it&&it.ir) it.ir(); };
      });
      var on=el.querySelector('button.on');
      if(on&&on.scrollIntoView){ try{ on.scrollIntoView({inline:'start',block:'nearest'}); }catch(e){} }
      window.YTBPivot.dica(el);
    },
    anima:function(painel, direcao){
      if(!painel) return;
      css();
      var c=direcao>0?'ytb-pivo-in-dir':'ytb-pivo-in-esq';
      painel.classList.remove('ytb-pivo-in-dir','ytb-pivo-in-esq');
      void painel.offsetWidth; /* reinicia a animação */
      painel.classList.add(c);
      setTimeout(function(){ painel.classList.remove(c); }, 360);
    },
    dica:function(head){
      try{ if(sessionStorage.getItem('ytb-pivo-dica')) return; }catch(e){}
      if(document.getElementById('ytb-pivo-dica')) return;
      css();
      var d=document.createElement('div');
      d.id='ytb-pivo-dica'; d.className='ytb-pivo-dica';
      d.textContent='↔ desliza para os lados para mudar de secção';
      if(head&&head.parentNode) head.parentNode.insertBefore(d, head.nextSibling);
      try{ sessionStorage.setItem('ytb-pivo-dica','1'); }catch(e){}
    },
    deslize:function(alvo, aoLado){
      var x0=null,y0=null,ign=false;
      alvo.addEventListener('touchstart',function(e){
        var t=e.touches[0]; x0=t.clientX; y0=t.clientY;
        ign=scrollHoriz(e.target, alvo);
      },{passive:true});
      alvo.addEventListener('touchend',function(e){
        if(x0===null||ign){ x0=null; return; }
        var t=e.changedTouches[0], dx=t.clientX-x0, dy=t.clientY-y0; x0=null;
        if(Math.abs(dx)>70 && Math.abs(dx)>Math.abs(dy)*1.6) aoLado(dx<0?1:-1);
      },{passive:true});
    }
  };
})();
