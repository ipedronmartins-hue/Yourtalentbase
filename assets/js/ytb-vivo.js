// ytb-vivo.js — sistema de movimento partilhado da YTB (living platform).
// Padrão do ytb-export.js: IIFE → window.YTBVivo. Sem frameworks, sem cargas externas.
// Constituição: as partículas são SEMPRE decorativas — nunca representam dados reais
// em páginas públicas (menores). Tudo degrada para estático com prefers-reduced-motion.
(function(global){
  "use strict";

  var reduce=false;
  try{ reduce=global.matchMedia('(prefers-reduced-motion: reduce)').matches; }catch(e){}
  var lowEnd=false;
  try{ lowEnd=(navigator.deviceMemory&&navigator.deviceMemory<4); }catch(e){}

  // ── Partículas: rede de nós decorativa em canvas ──────────────────────────
  function particulas(el,opts){
    opts=opts||{};
    if(reduce||lowEnd||opts.disable) return null;
    var host=(typeof el==='string')?document.querySelector(el):el;
    if(!host||!host.getContext){ // aceita container OU canvas
      if(host){ var c=document.createElement('canvas'); c.className='vivo-canvas'; host.appendChild(c); host=c; }
      else return null;
    }
    var canvas=host, ctx=canvas.getContext('2d');
    if(!ctx) return null;
    var dpr=Math.min(global.devicePixelRatio||1,2);
    var W=0,H=0,nodes=[],running=false,visible=true,raf=null;
    var GOLD='212,175,55', GREEN='0,212,106', SLATE='154,163,154';

    function size(){
      var r=canvas.parentElement.getBoundingClientRect();
      W=Math.max(r.width,1); H=Math.max(r.height,1);
      canvas.width=W*dpr; canvas.height=H*dpr;
      canvas.style.width=W+'px'; canvas.style.height=H+'px';
      ctx.setTransform(dpr,0,0,dpr,0,0);
      seed();
    }
    function seed(){
      var alvo=Math.min(opts.max||70, Math.floor(W*H/18000));
      if(W<720) alvo=Math.min(alvo,28);
      nodes=[];
      for(var i=0;i<alvo;i++){
        nodes.push({
          x:Math.random()*W, y:Math.random()*H,
          vx:(Math.random()-.5)*.22, vy:(Math.random()-.5)*.22,
          r:1+Math.random()*1.6,
          gold:Math.random()<.06
        });
      }
    }
    function step(){
      if(!running||!visible){ raf=null; return; }
      ctx.clearRect(0,0,W,H);
      var i,j,a,b,dx,dy,d2,lim=110*110;
      for(i=0;i<nodes.length;i++){
        a=nodes[i];
        a.x+=a.vx; a.y+=a.vy;
        if(a.x<-8)a.x=W+8; if(a.x>W+8)a.x=-8;
        if(a.y<-8)a.y=H+8; if(a.y>H+8)a.y=-8;
      }
      ctx.lineWidth=1;
      for(i=0;i<nodes.length;i++){
        a=nodes[i];
        for(j=i+1;j<nodes.length;j++){
          b=nodes[j]; dx=a.x-b.x; dy=a.y-b.y; d2=dx*dx+dy*dy;
          if(d2<lim){
            var al=(1-d2/lim)*.16;
            ctx.strokeStyle='rgba('+GREEN+','+al.toFixed(3)+')';
            ctx.beginPath(); ctx.moveTo(a.x,a.y); ctx.lineTo(b.x,b.y); ctx.stroke();
          }
        }
      }
      for(i=0;i<nodes.length;i++){
        a=nodes[i];
        ctx.fillStyle=a.gold?'rgba('+GOLD+',.75)':'rgba('+SLATE+',.45)';
        ctx.beginPath(); ctx.arc(a.x,a.y,a.r,0,6.2832); ctx.fill();
      }
      raf=requestAnimationFrame(step);
    }
    function play(){ if(running&&!raf&&visible) raf=requestAnimationFrame(step); }
    function start(){ running=true; play(); }
    function stop(){ running=false; if(raf){cancelAnimationFrame(raf);raf=null;} }

    size();
    var rt=null;
    global.addEventListener('resize',function(){ clearTimeout(rt); rt=setTimeout(size,180); });
    document.addEventListener('visibilitychange',function(){
      if(document.hidden){ if(raf){cancelAnimationFrame(raf);raf=null;} }
      else play();
    });
    if('IntersectionObserver' in global){
      new IntersectionObserver(function(en){
        visible=en[0].isIntersecting;
        if(visible) play(); else if(raf){cancelAnimationFrame(raf);raf=null;}
      },{threshold:0}).observe(canvas);
    }
    start();
    return {stop:stop,start:start};
  }

  // ── Reveal ao entrar no viewport (.vivo-reveal → .in) ─────────────────────
  function revelar(root){
    root=root||document;
    var els=root.querySelectorAll('.vivo-reveal:not(.in)');
    if(!els.length) return;
    if(reduce||!('IntersectionObserver' in global)){
      els.forEach(function(el){el.classList.add('in');});
      return;
    }
    var io=new IntersectionObserver(function(entries){
      entries.forEach(function(en){
        if(!en.isIntersecting) return;
        en.target.classList.add('in');
        io.unobserve(en.target);
      });
    },{threshold:.15, rootMargin:'0px 0px -5% 0px'});
    els.forEach(function(el,i){ el.style.setProperty('--vivo-d',Math.min((i%4)*80,240)+'ms'); io.observe(el); });
  }

  // ── Mapa vivo da jornada ───────────────────────────────────────────────────
  // etapas: [{nome:'Inscrição', estado:'done'|'atual'|'futuro', href?, dica?}]
  function jornada(mount,etapas,opts){
    mount=(typeof mount==='string')?document.querySelector(mount):mount;
    if(!mount||!etapas||!etapas.length) return;
    opts=opts||{};
    var n=etapas.length, PAD=46, GAP_LBL=22;
    var W=Math.max(560,n*90), H=64, cy=24;
    var xs=etapas.map(function(_,i){ return PAD+(W-2*PAD)*(n===1?0:(i/(n-1))); });
    var lastDone=-1;
    etapas.forEach(function(e,i){ if(e.estado==='done'||e.estado==='atual') lastDone=i; });

    var s='<svg viewBox="0 0 '+W+' '+H+'" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="'+esc(opts.aria||'Jornada do atleta')+'">';
    s+='<line class="vivo-jn-line" x1="'+xs[0]+'" y1="'+cy+'" x2="'+xs[n-1]+'" y2="'+cy+'"/>';
    if(lastDone>0){
      var len=xs[lastDone]-xs[0];
      s+='<line class="vivo-jn-line-done" x1="'+xs[0]+'" y1="'+cy+'" x2="'+xs[lastDone]+'" y2="'+cy+'" stroke-dasharray="'+len+'" stroke-dashoffset="'+(reduce?0:len)+'"/>';
    }
    etapas.forEach(function(e,i){
      var x=xs[i], done=e.estado==='done', atual=e.estado==='atual';
      if(atual) s+='<circle class="vivo-jn-halo" cx="'+x+'" cy="'+cy+'" r="7"/>';
      s+='<circle class="vivo-jn-dot'+(done?' done':atual?' atual':'')+'" cx="'+x+'" cy="'+cy+'" r="'+(atual?6:4.5)+'">'+(e.dica?'<title>'+esc(e.dica)+'</title>':'')+'</circle>';
      s+='<text class="vivo-jn-lbl'+(done?' done':atual?' atual':'')+'" x="'+x+'" y="'+(cy+GAP_LBL)+'" text-anchor="middle">'+esc(e.nome)+'</text>';
    });
    s+='</svg>';
    var wrap=document.createElement('div');
    wrap.className='vivo-jornada';
    wrap.innerHTML=s;
    mount.innerHTML='';
    mount.appendChild(wrap);
    // liga cliques (etapas com href)
    var dots=wrap.querySelectorAll('.vivo-jn-dot');
    etapas.forEach(function(e,i){
      if(!e.href||!dots[i]) return;
      dots[i].style.cursor='pointer';
      dots[i].addEventListener('click',function(){ location.href=e.href; });
    });
    // linha "desenha-se" quando visível
    var ld=wrap.querySelector('.vivo-jn-line-done');
    if(ld&&!reduce){
      if('IntersectionObserver' in global){
        var io=new IntersectionObserver(function(en){
          if(en[0].isIntersecting){ ld.style.strokeDashoffset=0; io.disconnect(); }
        },{threshold:.3});
        io.observe(wrap);
      }else ld.style.strokeDashoffset=0;
    }
    // centra a etapa atual em ecrãs estreitos
    try{
      var atualIdx=etapas.findIndex(function(e){return e.estado==='atual';});
      if(atualIdx>2) wrap.scrollLeft=(xs[atualIdx]/W)*wrap.scrollWidth-wrap.clientWidth/2;
    }catch(e){}
  }

  // ── Ligações causa-efeito entre cards ─────────────────────────────────────
  // container: elemento posicionado (position:relative) que contém elA e elB.
  function ligar(container,pares){
    container=(typeof container==='string')?document.querySelector(container):container;
    if(!container||reduce) return null;
    var svg=container.querySelector(':scope > .vivo-liga-svg');
    if(!svg){
      svg=document.createElementNS('http://www.w3.org/2000/svg','svg');
      svg.setAttribute('class','vivo-liga-svg');
      if(getComputedStyle(container).position==='static') container.style.position='relative';
      container.appendChild(svg);
    }
    function draw(){
      var cr=container.getBoundingClientRect();
      svg.setAttribute('viewBox','0 0 '+cr.width+' '+cr.height);
      svg.setAttribute('width',cr.width); svg.setAttribute('height',cr.height);
      var out='';
      pares.forEach(function(p){
        var a=(typeof p[0]==='string')?container.querySelector(p[0]):p[0];
        var b=(typeof p[1]==='string')?container.querySelector(p[1]):p[1];
        if(!a||!b) return;
        var ra=a.getBoundingClientRect(), rb=b.getBoundingClientRect();
        var x1=ra.left-cr.left+ra.width/2, y1=ra.bottom-cr.top;
        var x2=rb.left-cr.left+rb.width/2, y2=rb.top-cr.top;
        if(y2<y1){ y1=ra.top-cr.top; y2=rb.bottom-cr.top; }
        var my=(y1+y2)/2;
        out+='<path class="vivo-liga" d="M'+x1.toFixed(1)+' '+y1.toFixed(1)+' C'+x1.toFixed(1)+' '+my.toFixed(1)+' '+x2.toFixed(1)+' '+my.toFixed(1)+' '+x2.toFixed(1)+' '+y2.toFixed(1)+'"/>';
      });
      svg.innerHTML=out;
    }
    draw();
    var t=null;
    function redraw(){ clearTimeout(t); t=setTimeout(draw,120); }
    if('ResizeObserver' in global){ new ResizeObserver(redraw).observe(container); }
    else global.addEventListener('resize',redraw);
    return {redraw:draw};
  }

  // ── Marco: flash dourado one-shot num elemento ────────────────────────────
  function marco(el){
    el=(typeof el==='string')?document.querySelector(el):el;
    if(!el||reduce) return;
    el.classList.remove('vivo-marco');
    void el.offsetWidth; // reinicia a animação
    el.classList.add('vivo-marco');
    el.addEventListener('animationend',function h(){ el.classList.remove('vivo-marco'); el.removeEventListener('animationend',h); });
  }

  function esc(s){ return String(s==null?'':s).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];}); }

  global.YTBVivo={ particulas:particulas, revelar:revelar, jornada:jornada, ligar:ligar, marco:marco, reduzido:reduce };
})(window);
