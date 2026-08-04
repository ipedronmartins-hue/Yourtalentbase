/* ============================================================================
   YTB · BONEQUINHOS — demonstrações animadas 2D dos exercícios
   Cada exercício da biblioteca (ytb-pro-treinador.html) tem uma cena SVG
   animada estilo desenho animado: figuras "flipbook" de 2-4 frames (opacity
   em steps — o truque clássico do cartoon) + movimento suave de bolas/props
   (transform). Zero vídeo, zero rede: tudo inline, self-hosted, leve.

   API: window.YTBExAnim
     .svg(ex)        → string SVG da cena para {id,nome}
     .mount(el, ex)  → injeta a cena em el e ativa quando visível
     .mountAll(root) → monta todos os [data-exanim] dentro de root

   Regras:
   - prefers-reduced-motion: a animação não corre (fica a pose base) — o
     media query global trata disso.
   - As animações só correm com a classe .on (IntersectionObserver pausa o
     que está fora do ecrã — barato em telemóveis).
   - Resolução por id COM confirmação de nome: planos antigos gravados antes
     da biblioteca 51 têm ids que hoje apontam para exercícios diferentes;
     se o nome gravado não bater com o da biblioteca atual, tenta-se pelo
     nome e, em último caso, usa-se a cena genérica (bola a pulsar).
   Paleta: figura #ECEFEA · bola dourada #D4AF37 (a bola é o tesouro) ·
   props #5a615a · sinais verde/azul/vermelho. Fundo transparente.
   ============================================================================ */
(function(){
'use strict';

var LINHA='#ECEFEA', BOLA='#D4AF37', PROP='#5a615a', VERDE='#00D46A', AZUL='#4A9FE8', VERM='#ff5050';
var seq=0;

/* ── helpers de desenho ── */
function svgOpen(p){
  return '<svg class="exanim-svg" viewBox="0 0 120 90" xmlns="http://www.w3.org/2000/svg" role="img" aria-hidden="true" data-p="'+p+'">';
}
function chao(y){ y=y||78; return '<line x1="8" y1="'+y+'" x2="112" y2="'+y+'" stroke="'+PROP+'" stroke-width="1.5" stroke-linecap="round" opacity=".55"/>'; }
/* figura de pau numa pose: cabeça + tronco + 2 braços + 2 pernas (linhas simples).
   pose = {x, hy(anca y), sh(ombro y), hd[cx,cy], aL[x2,y2], aR, lL[x2,y2] via joelho?  simples: perna = anca→pé}
   Para o estilo flipbook chegam linhas diretas anca→pé com joelho implícito por quebra opcional. */
function boneco(pose){
  var x=pose.x, hy=pose.hy!=null?pose.hy:52, sh=pose.sh!=null?pose.sh:34;
  var hd=pose.hd||[x,26];
  var s='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">';
  s+='<circle cx="'+hd[0]+'" cy="'+hd[1]+'" r="5.5" fill="'+LINHA+'" stroke="none"/>';
  s+='<line x1="'+(pose.shx!=null?pose.shx:x)+'" y1="'+sh+'" x2="'+x+'" y2="'+hy+'"/>';               // tronco
  (pose.bracos||[]).forEach(function(b){ s+='<polyline points="'+b+'"/>'; });
  (pose.pernas||[]).forEach(function(p2){ s+='<polyline points="'+p2+'"/>'; });
  s+='</g>';
  return s;
}
/* flipbook: n frames alternados com steps(1) */
function flip(p,frames,dur){
  var n=frames.length, css='', html='';
  frames.forEach(function(f,i){
    html+='<g class="'+p+'-f'+i+'" opacity="'+(i===0?1:0)+'">'+f+'</g>';
    var kf=p+'kf'+i, pct=100/n;
    css+='@keyframes '+kf+'{';
    for(var j=0;j<=n;j++){
      var t=(j*pct).toFixed(2)+'%', on=(j%n)===i;
      css+=t+'{opacity:'+(on?1:0)+'}';
    }
    css+='}';
    css+='.on .'+p+'-f'+i+'{animation:'+kf+' '+dur+'s steps(1) infinite}';
  });
  return {html:html, css:css};
}
function wrap(p, innerHtml, css){
  return svgOpen(p)+'<style>'+css+'</style>'+innerHtml+'</svg>';
}

/* ════════ CENAS ════════ */
var CENAS={};

/* — parede + passe (te1 base; te3 orienta; te7 alvo; te11 em movimento) — */
function cenaParede(opts){
  return function(){
    var p='ep'+(seq++);
    var alvo=opts.alvo?'<rect x="99" y="52" width="9" height="9" fill="none" stroke="'+VERDE+'" stroke-width="1.5"/>':'';
    var f0=boneco({x:34,bracos:['34,36 26,44','34,36 42,42'],pernas:['34,52 28,66 26,78','34,52 40,64 38,78']});
    var f1=boneco({x:34,bracos:['34,36 24,40','34,36 44,38'],pernas:['34,52 28,66 26,78','34,52 46,58 52,66']}); // perna a rematar
    var fb=flip(p,[f0,f1],0.9);
    var css=fb.css
      +'@keyframes '+p+'b{0%,8%{transform:translateX(0)}45%{transform:translateX(52px)}50%{transform:translateX(52px)}90%,100%{transform:translateX(0)}}'
      +'.on .'+p+'-b{animation:'+p+'b 1.8s ease-in-out infinite}';
    var html='<rect x="106" y="20" width="5" height="58" fill="'+PROP+'"/>'+alvo+chao()
      +fb.html
      +'<g class="'+p+'-b"><circle cx="48" cy="73" r="4.5" fill="'+BOLA+'"/></g>';
    return wrap(p,html,css);
  };
}
CENAS.te1=cenaParede({});
CENAS.te3=cenaParede({});
CENAS.te7=cenaParede({alvo:true});
CENAS.te11=cenaParede({});

/* — te2 toques (juggling): bola salta no pé, perna bombeia — */
CENAS.te2=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,44','52,36 62,44'],pernas:['52,52 46,66 44,78','52,52 60,62 66,68']});
  var f1=boneco({x:52,bracos:['52,36 42,42','52,36 62,42'],pernas:['52,52 46,66 44,78','52,52 58,66 62,74']});
  var fb=flip(p,[f0,f1],0.7);
  var css=fb.css
    +'@keyframes '+p+'b{0%,100%{transform:translateY(0)}50%{transform:translateY(-18px)}}'
    +'.on .'+p+'-b{animation:'+p+'b .7s ease-in-out infinite}';
  var html=chao()+fb.html+'<g class="'+p+'-b"><circle cx="66" cy="64" r="4.5" fill="'+BOLA+'"/></g>';
  return wrap(p,html,css);
};

/* — te4 condução entre cones (ziguezague) — */
function cenaCones(opts){
  return function(){
    var p='ep'+(seq++);
    var cones='', xs=[30,52,74,96];
    xs.forEach(function(cx,i){
      var num=opts.numeros?'<text x="'+cx+'" y="60" font-size="7" fill="'+VERDE+'" text-anchor="middle" font-family="sans-serif">'+(i+1)+'</text>':'';
      cones+='<path d="M'+(cx-5)+' 76 L'+cx+' 64 L'+(cx+5)+' 76 Z" fill="'+PROP+'"/>'+num;
    });
    var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -8,42','0,34 8,40'],pernas:['0,50 -6,64 -8,76','0,50 8,62 12,70']});
    var f1=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -8,40','0,34 8,42'],pernas:['0,50 -8,62 -12,70','0,50 6,64 8,76']});
    var fb=flip(p,[f0,f1],0.5);
    var css=fb.css
      +'@keyframes '+p+'m{0%{transform:translate(18px,0)}25%{transform:translate(41px,-8px)}50%{transform:translate(63px,0)}75%{transform:translate(85px,-8px)}100%{transform:translate(104px,0)}}'
      +'.on .'+p+'-m{animation:'+p+'m 3s linear infinite alternate}';
    var html=chao()+cones
      +'<g class="'+p+'-m">'+fb.html+'<circle cx="8" cy="73" r="4" fill="'+BOLA+'"/></g>';
    return wrap(p,html,css);
  };
}
CENAS.te4=cenaCones({});

/* — te5 rolinhos com a sola — */
CENAS.te5=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 44,46','52,36 60,46'],pernas:['52,52 46,66 44,78','52,52 62,60 70,70']});
  var css='@keyframes '+p+'b{0%,100%{transform:translateX(-8px)}50%{transform:translateX(10px)}}'
    +'.on .'+p+'-b{animation:'+p+'b 1.4s ease-in-out infinite}';
  var html=chao()+f0+'<g class="'+p+'-b"><circle cx="70" cy="74" r="4.5" fill="'+BOLA+'"/><path d="M66 70 a5 5 0 0 1 8 0" stroke="'+PROP+'" stroke-width="1" fill="none"/></g>';
  return wrap(p,html,css);
};

/* — te6 tesoura: perna passa por cima da bola — */
CENAS.te6=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,44','52,36 62,44'],pernas:['52,52 44,64 42,78','52,52 60,64 62,78']});
  var f1=boneco({x:52,bracos:['52,36 40,40','52,36 64,40'],pernas:['52,52 44,64 42,78','52,52 66,56 76,62']}); // perna alta sobre a bola
  var f2=boneco({x:52,bracos:['52,36 42,44','52,36 62,44'],pernas:['52,52 44,64 42,78','52,52 64,66 70,78']});  // sai para o lado
  var fb=flip(p,[f0,f1,f2],1.5);
  var html=chao()+fb.html+'<circle cx="62" cy="73" r="4.5" fill="'+BOLA+'"/>';
  return wrap(p,fb.html?html:'',fb.css);
};

/* — te8 receção de bola alta — */
CENAS.te8=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 44,28','52,36 60,28'],pernas:['52,52 46,66 44,78','52,52 58,66 60,78']}); // braços no ar
  var f1=boneco({x:52,sh:36,hd:[52,28],bracos:['52,38 44,46','52,38 60,46'],pernas:['52,54 46,66 44,78','52,54 58,66 60,78']}); // amortece
  var fb=flip(p,[f0,f1],1.6);
  var css=fb.css
    +'@keyframes '+p+'b{0%{transform:translate(0,0)}45%{transform:translate(0,-46px)}50%{transform:translate(0,-46px)}95%,100%{transform:translate(0,0)}}'
    +'.on .'+p+'-b{animation:'+p+'b 1.6s cubic-bezier(.3,.7,.4,1) infinite}';
  var html=chao()+fb.html+'<g class="'+p+'-b"><circle cx="52" cy="70" r="4.5" fill="'+BOLA+'"/></g>';
  return wrap(p,html,css);
};

/* — te9 condução com mudança de ritmo (lento→rápido) — */
CENAS.te9=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -8,42','0,34 8,40'],pernas:['0,50 -6,64 -8,76','0,50 8,62 12,70']});
  var f1=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -8,40','0,34 8,42'],pernas:['0,50 -8,62 -12,70','0,50 6,64 8,76']});
  var fb=flip(p,[f0,f1],0.45);
  var css=fb.css
    +'@keyframes '+p+'m{0%{transform:translateX(16px)}55%{transform:translateX(48px)}100%{transform:translateX(106px)}}'
    +'.on .'+p+'-m{animation:'+p+'m 2.4s cubic-bezier(.6,0,.9,.4) infinite}'
    +'@keyframes '+p+'v{0%,55%{opacity:0}70%,90%{opacity:1}100%{opacity:0}}'
    +'.on .'+p+'-v{animation:'+p+'v 2.4s linear infinite}';
  var html=chao()
    +'<g class="'+p+'-v" opacity="0"><line x1="20" y1="40" x2="34" y2="40" stroke="'+VERDE+'" stroke-width="2" stroke-linecap="round"/><line x1="16" y1="46" x2="30" y2="46" stroke="'+VERDE+'" stroke-width="2" stroke-linecap="round"/></g>'
    +'<g class="'+p+'-m">'+fb.html+'<circle cx="8" cy="73" r="4" fill="'+BOLA+'"/></g>';
  return wrap(p,html,css);
};

/* — te10 remate colocado (baliza) / me3 respirar antes de rematar — */
function cenaRemate(opts){
  return function(){
    var p='ep'+(seq++);
    var f0=boneco({x:30,bracos:['30,36 22,44','30,36 38,42'],pernas:['30,52 24,66 22,78','30,52 36,64 34,78']});
    var f1=boneco({x:30,bracos:['30,36 20,40','30,36 40,38'],pernas:['30,52 24,66 22,78','30,52 44,58 50,64']});
    var fb=flip(p,[f0,f1],2.2);
    var resp=opts.respira
      ?'<circle class="'+p+'-r" cx="30" cy="40" r="8" fill="none" stroke="'+AZUL+'" stroke-width="1.5" opacity=".8"/>'
      :'';
    var css=fb.css
      +'@keyframes '+p+'b{0%,50%{transform:translate(0,0)}80%{transform:translate(56px,-12px)}82%,100%{transform:translate(56px,-12px);opacity:0}}'
      +'.on .'+p+'-b{animation:'+p+'b 2.2s ease-in infinite}'
      +(opts.respira?('@keyframes '+p+'r{0%{transform:scale(.6);opacity:.9}40%{transform:scale(1.3);opacity:.25}50%,100%{opacity:0}}'
        +'.on .'+p+'-r{transform-box:fill-box;transform-origin:center;animation:'+p+'r 2.2s ease-out infinite}'):'');
    var html='<g stroke="'+PROP+'" stroke-width="2.5" fill="none"><path d="M96 78 V34 H114"/></g>'+chao()
      +resp+fb.html
      +'<g class="'+p+'-b"><circle cx="42" cy="73" r="4.5" fill="'+BOLA+'"/></g>';
    return wrap(p,html,css);
  };
}
CENAS.te10=cenaRemate({});
CENAS.me3=cenaRemate({respira:true});

/* — te12 cabeceamento suave — */
CENAS.te12=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 44,28','52,36 60,28'],pernas:['52,52 46,66 44,78','52,52 58,66 60,78']});
  var css='@keyframes '+p+'b{0%{transform:translate(0,0)}40%{transform:translate(0,-34px)}55%{transform:translate(0,-30px)}100%{transform:translate(0,0)}}'
    +'.on .'+p+'-b{animation:'+p+'b 1.8s ease-in-out infinite}'
    +'@keyframes '+p+'h{0%,38%,62%,100%{transform:translateY(0)}50%{transform:translateY(-3px)}}'
    +'.on .'+p+'-h{animation:'+p+'h 1.8s ease-in-out infinite}';
  var html=chao()+'<g class="'+p+'-h">'+f0+'</g>'
    +'<g class="'+p+'-b"><circle cx="52" cy="64" r="4.5" fill="'+BOLA+'"/></g>';
  return wrap(p,html,css);
};

/* — fi1 mobilidade dinâmica: balanço de perna + braços — */
CENAS.fi1=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 40,30','52,36 64,30'],pernas:['52,52 46,66 44,78','52,52 62,58 70,52']});
  var f1=boneco({x:52,bracos:['52,36 42,46','52,36 62,46'],pernas:['52,52 46,66 44,78','52,52 58,66 56,78']});
  var f2=boneco({x:52,bracos:['52,36 40,30','52,36 64,30'],pernas:['52,52 46,66 44,78','52,52 60,64 66,76']});
  var fb=flip(p,[f0,f1,f2,f1],1.6);
  return wrap(p,chao()+fb.html,fb.css);
};

/* — fi2 alongamento (sentado, mãos aos pés) — */
CENAS.fi2=function(){
  var p='ep'+(seq++);
  var f0='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="40" cy="46" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="42" y1="52" x2="52" y2="66"/>'
    +'<polyline points="52,66 78,74"/>'
    +'<polyline points="44,54 62,66"/></g>';
  var f1='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="48" cy="52" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="50" y1="58" x2="56" y2="68"/>'
    +'<polyline points="56,68 78,74"/>'
    +'<polyline points="52,60 74,72"/></g>';
  var fb=flip(p,[f0,f1],2.4);
  return wrap(p,chao(76)+fb.html,fb.css);
};

/* — fi3 agachamento profundo + tornozelo — */
CENAS.fi3=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,40','52,36 62,40'],pernas:['52,52 44,64 44,78','52,52 60,64 60,78']});
  var f1=boneco({x:52,hy:62,sh:46,hd:[52,38],bracos:['52,48 40,50','52,48 64,50'],pernas:['52,62 42,70 42,78','52,62 62,70 62,78']});
  var fb=flip(p,[f0,f1,f1,f1],2.4); // fica em baixo mais tempo (hold)
  return wrap(p,chao()+fb.html,fb.css);
};

/* — fi4 skipping (joelhos altos, 2 frames clássicos) — */
CENAS.fi4=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,28','52,36 62,44'],pernas:['52,52 58,58 56,66','52,52 48,66 46,78']});
  var f1=boneco({x:52,bracos:['52,36 42,44','52,36 62,28'],pernas:['52,52 46,58 48,66','52,52 58,66 60,78']});
  var fb=flip(p,[f0,f1],0.5);
  return wrap(p,chao()+fb.html,fb.css);
};

/* — fi5 prancha / fi6 prancha lateral — */
CENAS.fi5=function(){
  var p='ep'+(seq++);
  var f0='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="28" cy="58" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="34" y1="60" x2="86" y2="66"/>'
    +'<polyline points="38,61 36,72 40,74"/>'
    +'<polyline points="86,66 94,78"/></g>';
  var css='@keyframes '+p+'r{0%,100%{transform:translateY(0)}50%{transform:translateY(-1.6px)}}'
    +'.on .'+p+'-r{animation:'+p+'r 1.6s ease-in-out infinite}';
  return wrap(p,chao()+'<g class="'+p+'-r">'+f0+'</g>',css);
};
CENAS.fi6=function(){
  var p='ep'+(seq++);
  var f0='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="30" cy="50" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="36" y1="54" x2="88" y2="70"/>'
    +'<polyline points="42,56 40,68 46,70"/>'
    +'<line x1="60" y1="61" x2="56" y2="42"/></g>'; // braço ao alto
  var css='@keyframes '+p+'r{0%,100%{transform:translateY(0)}50%{transform:translateY(-1.6px)}}'
    +'.on .'+p+'-r{animation:'+p+'r 1.8s ease-in-out infinite}';
  return wrap(p,chao()+'<g class="'+p+'-r">'+f0+'</g>',css);
};

/* — fi7 ponte de glúteos — */
CENAS.fi7=function(){
  var p='ep'+(seq++);
  var f0='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="26" cy="72" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<polyline points="32,73 58,73 70,60 74,76"/></g>';
  var f1='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="26" cy="72" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<polyline points="32,73 58,58 70,58 74,76"/></g>';
  var fb=flip(p,[f0,f1],1.4);
  return wrap(p,chao()+fb.html,fb.css);
};

/* — fi8 escada de coordenação (pés rápidos na linha) — */
CENAS.fi8=function(){
  var p='ep'+(seq++);
  var escada='';
  for(var i=0;i<6;i++){ escada+='<line x1="'+(22+i*14)+'" y1="70" x2="'+(22+i*14)+'" y2="78" stroke="'+PROP+'" stroke-width="1.5"/>'; }
  var f0=boneco({x:0,hy:48,sh:30,hd:[0,22],bracos:['0,32 -8,40','0,32 8,38'],pernas:['0,48 -7,60 -9,70','0,48 7,60 9,70']});
  var f1=boneco({x:0,hy:48,sh:30,hd:[0,22],bracos:['0,32 -8,38','0,32 8,40'],pernas:['0,48 -4,60 -3,70','0,48 4,60 3,70']});
  var fb=flip(p,[f0,f1],0.36);
  var css=fb.css
    +'@keyframes '+p+'m{0%{transform:translateX(20px)}100%{transform:translateX(100px)}}'
    +'.on .'+p+'-m{animation:'+p+'m 2.2s linear infinite alternate}';
  return wrap(p,chao()+escada+'<g class="'+p+'-m">'+fb.html+'</g>',css);
};

/* — fi9 agachamento / fi13 com salto / fi12 gémeos / fi10 afundo / fi11 flexões — */
CENAS.fi9=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 40,34','52,36 64,34'],pernas:['52,52 44,64 44,78','52,52 60,64 60,78']});
  var f1=boneco({x:52,hy:60,sh:44,hd:[52,36],bracos:['52,46 40,44','52,46 64,44'],pernas:['52,60 42,68 42,78','52,60 62,68 62,78']});
  var fb=flip(p,[f0,f1],1.3);
  return wrap(p,chao()+fb.html,fb.css);
};
CENAS.fi13=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,hy:60,sh:44,hd:[52,36],bracos:['52,46 40,44','52,46 64,44'],pernas:['52,60 42,68 42,78','52,60 62,68 62,78']});
  var f1=boneco({x:52,hy:46,sh:28,hd:[52,20],bracos:['52,30 42,20','52,30 62,20'],pernas:['52,46 46,58 44,68','52,46 58,58 60,68']});
  var f2=boneco({x:52,bracos:['52,36 42,40','52,36 62,40'],pernas:['52,52 46,64 44,78','52,52 58,64 60,78']});
  var fb=flip(p,[f0,f1,f2],1.5);
  return wrap(p,chao()+fb.html,fb.css);
};
CENAS.fi12=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 44,44','52,36 60,44'],pernas:['52,52 47,64 46,78','52,52 57,64 58,78']});
  var f1=boneco({x:52,hy:48,sh:30,hd:[52,22],bracos:['52,32 44,40','52,32 60,40'],pernas:['52,48 47,60 46,73','52,48 57,60 58,73']});
  var fb=flip(p,[f0,f1],1.1);
  return wrap(p,chao()+fb.html,fb.css);
};
CENAS.fi10=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,42','52,36 62,42'],pernas:['52,52 46,64 44,78','52,52 58,64 60,78']});
  var f1=boneco({x:54,hy:58,sh:40,hd:[54,32],bracos:['54,42 44,48','54,42 64,48'],pernas:['54,58 38,64 36,78','54,58 66,70 74,76']});
  var f2=boneco({x:50,hy:58,sh:40,hd:[50,32],bracos:['50,42 40,48','50,42 60,48'],pernas:['50,58 66,64 68,78','50,58 38,70 30,76']});
  var fb=flip(p,[f0,f1,f0,f2],2.4);
  return wrap(p,chao()+fb.html,fb.css);
};
CENAS.fi11=function(){
  var p='ep'+(seq++);
  var f0='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="30" cy="52" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="36" y1="56" x2="88" y2="66"/>'
    +'<polyline points="42,58 42,78"/>'
    +'<polyline points="88,66 96,78"/></g>';
  var f1='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="30" cy="66" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="36" y1="68" x2="88" y2="70"/>'
    +'<polyline points="42,70 36,78"/>'
    +'<polyline points="88,70 96,78"/></g>';
  var fb=flip(p,[f0,f1],1.4);
  return wrap(p,chao()+fb.html,fb.css);
};

/* — corrida (fi14) / com bola (fi15) / rampa (fi19) / sprint-anda (fi23) — */
function cenaCorrida(opts){
  return function(){
    var p='ep'+(seq++);
    var incl=opts.rampa?-10:0;
    var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -10,40','0,34 10,38'],pernas:['0,50 -10,60 -14,72','0,50 10,60 16,68']});
    var f1=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 10,40','0,34 -10,38'],pernas:['0,50 8,62 6,74','0,50 -8,58 -14,64']});
    var fb=flip(p,[f0,f1],opts.lento?0.8:0.4);
    var chaoEl=opts.rampa
      ?'<line x1="8" y1="84" x2="112" y2="58" stroke="'+PROP+'" stroke-width="1.5" stroke-linecap="round" opacity=".55"/>'
      :chao();
    var trans=opts.rampa
      ?'@keyframes '+p+'m{0%{transform:translate(16px,6px)}100%{transform:translate(100px,-16px)}}'
      :'@keyframes '+p+'m{0%{transform:translateX(14px)}100%{transform:translateX(104px)}}';
    var dur=opts.sprintAnda?3.2:(opts.lento?3.4:2.2);
    var ease=opts.sprintAnda?'cubic-bezier(.2,.8,.9,1)':'linear';
    var css=fb.css+trans+'.on .'+p+'-m{animation:'+p+'m '+dur+'s '+ease+' infinite}';
    var bola=opts.bola?'<circle cx="9" cy="73" r="4" fill="'+BOLA+'"/>':'';
    return wrap(p,chaoEl+'<g class="'+p+'-m" '+(incl? 'transform="rotate('+incl+' 60 70)"':'')+'>'+fb.html+bola+'</g>',css);
  };
}
CENAS.fi14=cenaCorrida({lento:true});
CENAS.fi15=cenaCorrida({bola:true,lento:true});
CENAS.fi19=cenaCorrida({rampa:true});
CENAS.fi23=cenaCorrida({sprintAnda:true});

/* — fi20 sprint com mudança de direção (vai-vem com viragem) — */
CENAS.fi20=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -10,40','0,34 10,38'],pernas:['0,50 -10,60 -14,72','0,50 10,60 16,68']});
  var f1=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 10,40','0,34 -10,38'],pernas:['0,50 8,62 6,74','0,50 -8,58 -14,64']});
  var fb=flip(p,[f0,f1],0.4);
  var css=fb.css
    +'@keyframes '+p+'m{0%{transform:translateX(24px) scaleX(1)}46%{transform:translateX(96px) scaleX(1)}50%{transform:translateX(96px) scaleX(-1)}96%{transform:translateX(24px) scaleX(-1)}100%{transform:translateX(24px) scaleX(1)}}'
    +'.on .'+p+'-m{animation:'+p+'m 2.4s linear infinite}';
  var cones='<path d="M18 76 L22 66 L26 76 Z" fill="'+PROP+'"/><path d="M94 76 L98 66 L102 76 Z" fill="'+PROP+'"/>';
  return wrap(p,chao()+cones+'<g class="'+p+'-m">'+fb.html+'</g>',css);
};

/* — fi17 saltos laterais sobre a linha — */
CENAS.fi17=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -9,42','0,34 9,42'],pernas:['0,50 -6,62 -6,74','0,50 6,62 6,74']});
  var css='@keyframes '+p+'m{0%,42%{transform:translateX(38px)}50%{transform:translate(52px,-10px)}58%,92%{transform:translateX(68px)}100%{transform:translate(52px,-10px)}}'
    +'.on .'+p+'-m{animation:'+p+'m 1.1s ease-in-out infinite}';
  return wrap(p,chao()+'<line x1="53" y1="64" x2="53" y2="78" stroke="'+VERDE+'" stroke-width="2"/>'
    +'<g class="'+p+'-m">'+f0+'</g>',css);
};

/* — fi18 tabata/burpee (4 poses) — */
CENAS.fi18=function(){
  var p='ep'+(seq++);
  var fPe=boneco({x:52,bracos:['52,36 42,42','52,36 62,42'],pernas:['52,52 46,64 44,78','52,52 58,64 60,78']});
  var fAg=boneco({x:52,hy:62,sh:48,hd:[52,40],bracos:['52,50 44,60','52,50 60,60'],pernas:['52,62 44,70 44,78','52,62 60,70 60,78']});
  var fPr='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="30" cy="58" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="36" y1="60" x2="86" y2="68"/>'
    +'<polyline points="40,62 40,78"/><polyline points="86,68 94,78"/></g>';
  var fSalto=boneco({x:52,hy:44,sh:26,hd:[52,18],bracos:['52,28 42,16','52,28 62,16'],pernas:['52,44 46,56 44,66','52,44 58,56 60,66']});
  var fb=flip(p,[fPe,fAg,fPr,fAg,fSalto],1.8);
  return wrap(p,chao()+fb.html,fb.css);
};

/* — fi21 salto ao caixote — */
CENAS.fi21=function(){
  var p='ep'+(seq++);
  var caixa='<rect x="72" y="58" width="30" height="20" fill="none" stroke="'+PROP+'" stroke-width="2.5"/>';
  var f0=boneco({x:0,hy:52,sh:34,hd:[0,26],bracos:['0,36 -10,44','0,36 10,44'],pernas:['0,52 -6,64 -6,76','0,52 6,64 6,76']});
  var f1=boneco({x:0,hy:46,sh:28,hd:[0,20],bracos:['0,30 -10,18','0,30 10,18'],pernas:['0,46 -6,56 -4,64','0,46 6,56 4,64']});
  var fb=flip(p,[f0,f1,f0,f0],2);
  var css=fb.css
    +'@keyframes '+p+'m{0%,20%{transform:translate(40px,2px)}45%{transform:translate(70px,-26px)}55%,75%{transform:translate(86px,-20px)}90%,100%{transform:translate(40px,2px)}}'
    +'.on .'+p+'-m{animation:'+p+'m 2s ease-in-out infinite}';
  return wrap(p,chao()+caixa+'<g class="'+p+'-m">'+fb.html+'</g>',css);
};

/* — fi16/fi22 circuito (sequência de 3 estações) — */
function cenaCircuito(){
  return function(){
    var p='ep'+(seq++);
    var fJoelhos=boneco({x:52,bracos:['52,36 42,28','52,36 62,44'],pernas:['52,52 58,58 56,66','52,52 48,66 46,78']});
    var fAgacha=boneco({x:52,hy:60,sh:44,hd:[52,36],bracos:['52,46 40,44','52,46 64,44'],pernas:['52,60 42,68 42,78','52,60 62,68 62,78']});
    var fPrancha='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
      +'<circle cx="30" cy="58" r="5.5" fill="'+LINHA+'" stroke="none"/>'
      +'<line x1="36" y1="60" x2="86" y2="66"/>'
      +'<polyline points="40,62 40,78"/><polyline points="86,66 94,78"/></g>';
    var fb=flip(p,[fJoelhos,fAgacha,fPrancha],3);
    var css=fb.css
      +'@keyframes '+p+'d{0%,32%{opacity:1}33%,100%{opacity:0}}'
      +'.on .'+p+'-d1{animation:'+p+'d 3s steps(1) infinite}'
      +'.on .'+p+'-d2{animation:'+p+'d 3s steps(1) 1s infinite}'
      +'.on .'+p+'-d3{animation:'+p+'d 3s steps(1) 2s infinite}';
    var dots='<circle class="'+p+'-d1" cx="48" cy="14" r="3" fill="'+VERDE+'"/><circle class="'+p+'-d2" cx="58" cy="14" r="3" fill="'+VERDE+'" opacity="0"/><circle class="'+p+'-d3" cx="68" cy="14" r="3" fill="'+VERDE+'" opacity="0"/>';
    return wrap(p,chao()+dots+fb.html,css);
  };
}
CENAS.fi16=cenaCircuito();
CENAS.fi22=cenaCircuito();

/* — de1 cores ao sinal: pinta pisca, sola toca a bola nessa direção — */
CENAS.de1=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,44','52,36 62,44'],pernas:['52,52 46,66 44,78','52,52 62,60 70,70']});
  var css='@keyframes '+p+'s{0%,28%{opacity:1}33%,100%{opacity:.18}}'
    +'.on .'+p+'-s1{animation:'+p+'s 2.7s steps(1) infinite}'
    +'.on .'+p+'-s2{animation:'+p+'s 2.7s steps(1) .9s infinite}'
    +'.on .'+p+'-s3{animation:'+p+'s 2.7s steps(1) 1.8s infinite}'
    +'@keyframes '+p+'b{0%,100%{transform:translateX(0)}50%{transform:translateX(6px)}}'
    +'.on .'+p+'-b{animation:'+p+'b .9s ease-in-out infinite}';
  var sinais='<circle class="'+p+'-s1" cx="20" cy="18" r="5" fill="'+VERDE+'" opacity=".18"/>'
    +'<circle class="'+p+'-s2" cx="52" cy="14" r="5" fill="'+AZUL+'" opacity=".18"/>'
    +'<circle class="'+p+'-s3" cx="84" cy="18" r="5" fill="'+VERM+'" opacity=".18"/>';
  return wrap(p,chao()+sinais+f0+'<g class="'+p+'-b"><circle cx="70" cy="74" r="4.5" fill="'+BOLA+'"/></g>',css);
};

/* — de2 espelho: duas figuras, a da direita imita com atraso — */
CENAS.de2=function(){
  var p='ep'+(seq++);
  function par(x,delay){
    var f0=boneco({x:x,bracos:[x+',36 '+(x-10)+',28',x+',36 '+(x+8)+',44'],pernas:[x+',52 '+(x-6)+',66 '+(x-8)+',78',x+',52 '+(x+6)+',66 '+(x+8)+',78']});
    var f1=boneco({x:x,bracos:[x+',36 '+(x-8)+',44',x+',36 '+(x+10)+',28'],pernas:[x+',52 '+(x-6)+',66 '+(x-8)+',78',x+',52 '+(x+6)+',66 '+(x+8)+',78']});
    var name=p+'e'+x;
    var css='@keyframes '+name+'a{0%,49%{opacity:1}50%,100%{opacity:0}}'
      +'@keyframes '+name+'b{0%,49%{opacity:0}50%,100%{opacity:1}}'
      +'.on .'+name+'-0{animation:'+name+'a 2s steps(1) '+delay+'s infinite}'
      +'.on .'+name+'-1{animation:'+name+'b 2s steps(1) '+delay+'s infinite}';
    var html='<g class="'+name+'-0">'+f0+'</g><g class="'+name+'-1" opacity="0">'+f1+'</g>';
    return {html:html,css:css};
  }
  var a=par(34,0), b=par(84,0.25);
  var meio='<line x1="60" y1="24" x2="60" y2="76" stroke="'+PROP+'" stroke-width="1" stroke-dasharray="3 4" opacity=".6"/>';
  return wrap(p,chao()+meio+a.html+b.html+'<circle cx="26" cy="74" r="4" fill="'+BOLA+'"/>',a.css+b.css);
};

/* — de3 números ao sinal: cones numerados, número acende, condução até lá — */
CENAS.de3=cenaCones({numeros:true});

/* — de4 passe à cor certa: dois alvos, um acende, a bola vai para esse — */
CENAS.de4=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:30,bracos:['30,36 22,44','30,36 38,42'],pernas:['30,52 24,66 22,78','30,52 40,60 46,66']});
  var css='@keyframes '+p+'t1{0%,44%{opacity:1}50%,100%{opacity:.2}}'
    +'@keyframes '+p+'t2{0%,44%{opacity:.2}50%,94%{opacity:1}100%{opacity:.2}}'
    +'.on .'+p+'-t1{animation:'+p+'t1 3s steps(1) infinite}'
    +'.on .'+p+'-t2{animation:'+p+'t2 3s steps(1) infinite}'
    +'@keyframes '+p+'b{0%,10%{transform:translate(0,0)}40%{transform:translate(58px,-38px)}49%{transform:translate(58px,-38px);opacity:0}50%{transform:translate(0,0);opacity:0}60%{opacity:1}88%{transform:translate(58px,10px)}96%{transform:translate(58px,10px);opacity:0}100%{transform:translate(0,0);opacity:0}}'
    +'.on .'+p+'-b{animation:'+p+'b 3s ease-in-out infinite}';
  var alvos='<rect class="'+p+'-t1" x="94" y="26" width="12" height="12" fill="'+VERDE+'"/>'
    +'<rect class="'+p+'-t2" x="94" y="60" width="12" height="12" fill="'+AZUL+'" opacity=".2"/>';
  return wrap(p,chao()+alvos+f0+'<g class="'+p+'-b"><circle cx="44" cy="70" r="4.5" fill="'+BOLA+'"/></g>',css);
};

/* — de5 1v1: defesa parado, atacante escolhe o lado livre — */
CENAS.de5=function(){
  var p='ep'+(seq++);
  var defesa=boneco({x:76,bracos:['76,36 66,42','76,36 86,42'],pernas:['76,52 68,64 66,78','76,52 84,64 86,78']});
  var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -8,42','0,34 8,40'],pernas:['0,50 -6,64 -8,76','0,50 8,62 12,70']});
  var f1=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -8,40','0,34 8,42'],pernas:['0,50 -8,62 -12,70','0,50 6,64 8,76']});
  var fb=flip(p,[f0,f1],0.5);
  var css=fb.css
    +'@keyframes '+p+'m{0%{transform:translate(20px,0)}45%{transform:translate(62px,0)}70%{transform:translate(80px,-14px)}100%{transform:translate(106px,-6px)}}'
    +'.on .'+p+'-m{animation:'+p+'m 2.6s ease-in-out infinite}';
  return wrap(p,chao()+'<g opacity=".55">'+defesa+'</g>'
    +'<g class="'+p+'-m">'+fb.html+'<circle cx="8" cy="73" r="4" fill="'+BOLA+'"/></g>',css);
};

/* — de6 scan: cabeça vira para trás com "!", depois a bola chega — */
CENAS.de6=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,44','52,36 62,44'],pernas:['52,52 46,66 44,78','52,52 58,66 60,78']});
  var f1=boneco({x:52,hd:[46,26],bracos:['52,36 42,44','52,36 62,44'],pernas:['52,52 46,66 44,78','52,52 58,66 60,78']}); // cabeça virada
  var fb=flip(p,[f0,f1,f1,f0],2.4);
  var css=fb.css
    +'@keyframes '+p+'x{0%,28%{opacity:0}34%,58%{opacity:1}64%,100%{opacity:0}}'
    +'.on .'+p+'-x{animation:'+p+'x 2.4s steps(1) infinite}'
    +'@keyframes '+p+'b{0%,58%{transform:translateX(0)}92%,100%{transform:translateX(-46px)}}'
    +'.on .'+p+'-b{animation:'+p+'b 2.4s ease-out infinite}';
  var alerta='<text class="'+p+'-x" x="36" y="18" font-size="12" fill="'+VERDE+'" font-family="sans-serif" font-weight="bold" opacity="0">!</text>';
  return wrap(p,chao()+alerta+fb.html+'<g class="'+p+'-b"><circle cx="106" cy="74" r="4.5" fill="'+BOLA+'"/></g>',css);
};

/* — ta1 vídeo + perguntas: ecrã com play e "?" a saltar — */
CENAS.ta1=function(){
  var p='ep'+(seq++);
  var fig='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="34" cy="44" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<polyline points="36,50 40,62 34,62 34,74"/><polyline points="40,62 46,74"/>'
    +'<line x1="37" y1="53" x2="46" y2="56"/></g>';
  var css='@keyframes '+p+'q{0%,60%{opacity:0;transform:translateY(3px)}70%,90%{opacity:1;transform:translateY(0)}100%{opacity:0}}'
    +'.on .'+p+'-q{animation:'+p+'q 2.6s ease-out infinite}'
    +'@keyframes '+p+'pl{0%,100%{opacity:.9}50%{opacity:.4}}'
    +'.on .'+p+'-pl{animation:'+p+'pl 1.6s ease-in-out infinite}';
  var ecra='<rect x="62" y="34" width="42" height="28" rx="2" fill="none" stroke="'+PROP+'" stroke-width="2.5"/>'
    +'<path class="'+p+'-pl" d="M78 42 L92 48 L78 54 Z" fill="'+VERDE+'"/>'
    +'<line x1="83" y1="62" x2="83" y2="70" stroke="'+PROP+'" stroke-width="2.5"/><line x1="72" y1="72" x2="94" y2="72" stroke="'+PROP+'" stroke-width="2.5"/>';
  var pergunta='<text class="'+p+'-q" x="50" y="30" font-size="11" fill="'+BOLA+'" font-family="sans-serif" font-weight="bold" opacity="0">?</text>';
  return wrap(p,chao(76)+fig+ecra+pergunta,css);
};

/* — ta2 sombra posicional / ta5 basculação: mini-campo, bola mexe, jogador acompanha — */
function cenaMiniCampo(opts){
  return function(){
    var p='ep'+(seq++);
    var campo='<rect x="16" y="18" width="88" height="54" fill="none" stroke="'+PROP+'" stroke-width="1.5" opacity=".7"/>'
      +'<line x1="60" y1="18" x2="60" y2="72" stroke="'+PROP+'" stroke-width="1" opacity=".5"/>'
      +'<circle cx="60" cy="45" r="7" fill="none" stroke="'+PROP+'" stroke-width="1" opacity=".5"/>';
    var css='@keyframes '+p+'b{0%{transform:translate(0,0)}33%{transform:translate(28px,18px)}66%{transform:translate(50px,-6px)}100%{transform:translate(0,0)}}'
      +'.on .'+p+'-b{animation:'+p+'b 4s ease-in-out infinite}'
      +'@keyframes '+p+'j{0%{transform:translate(0,0)}33%{transform:translate(20px,12px)}66%{transform:translate(36px,-4px)}100%{transform:translate(0,0)}}'
      +'.on .'+p+'-j{animation:'+p+'j 4s ease-in-out .25s infinite}';
    var liga=opts.defensivo
      ?'<line x1="0" y1="0" x2="0" y2="0"/>'
      :'';
    return wrap(p,campo
      +'<g class="'+p+'-b"><circle cx="34" cy="32" r="4" fill="'+BOLA+'"/></g>'
      +'<g class="'+p+'-j"><circle cx="44" cy="52" r="5" fill="'+VERDE+'"/></g>'+liga,css);
  };
}
CENAS.ta2=cenaMiniCampo({});
CENAS.ta5=cenaMiniCampo({defensivo:true});

/* — ta3 mapa da posição: lápis marca X no campo — */
CENAS.ta3=function(){
  var p='ep'+(seq++);
  var campo='<rect x="20" y="22" width="80" height="48" fill="none" stroke="'+PROP+'" stroke-width="1.5" opacity=".7"/>'
    +'<line x1="60" y1="22" x2="60" y2="70" stroke="'+PROP+'" stroke-width="1" opacity=".5"/>';
  var css='@keyframes '+p+'l{0%{transform:translate(0,0)}30%{transform:translate(24px,14px)}60%{transform:translate(46px,-6px)}100%{transform:translate(0,0)}}'
    +'.on .'+p+'-l{animation:'+p+'l 3.6s ease-in-out infinite}'
    +'@keyframes '+p+'x1{0%,8%{opacity:0}12%,100%{opacity:1}}@keyframes '+p+'x2{0%,38%{opacity:0}42%,100%{opacity:1}}@keyframes '+p+'x3{0%,68%{opacity:0}72%,96%{opacity:1}100%{opacity:0}}'
    +'.on .'+p+'-x1{animation:'+p+'x1 3.6s steps(1) infinite}.on .'+p+'-x2{animation:'+p+'x2 3.6s steps(1) infinite}.on .'+p+'-x3{animation:'+p+'x3 3.6s steps(1) infinite}';
  function xis(cx,cy,cls){ return '<g class="'+cls+'" stroke="'+VERDE+'" stroke-width="2" opacity="0"><line x1="'+(cx-3)+'" y1="'+(cy-3)+'" x2="'+(cx+3)+'" y2="'+(cy+3)+'"/><line x1="'+(cx+3)+'" y1="'+(cy-3)+'" x2="'+(cx-3)+'" y2="'+(cy+3)+'"/></g>'; }
  var lapis='<g class="'+p+'-l"><path d="M34 44 L42 36 L45 39 L37 47 Z" fill="'+BOLA+'"/><path d="M34 44 L36 46 L33 47 Z" fill="'+LINHA+'"/></g>';
  return wrap(p,campo+xis(32,46,p+'-x1')+xis(56,58,p+'-x2')+xis(78,40,p+'-x3')+lapis,css);
};

/* — ta4 apoio e ângulo: colega desloca-se e abre linha de passe tracejada — */
CENAS.ta4=function(){
  var p='ep'+(seq++);
  var portador=boneco({x:26,bracos:['26,36 18,44','26,36 34,44'],pernas:['26,52 20,66 18,78','26,52 32,66 34,78']});
  var css='@keyframes '+p+'c{0%,25%{transform:translate(0,0)}55%,100%{transform:translate(0,-22px)}}'
    +'.on .'+p+'-c{animation:'+p+'c 3s ease-in-out infinite alternate}'
    +'@keyframes '+p+'l{0%,50%{opacity:0}70%,100%{opacity:.9}}'
    +'.on .'+p+'-l{animation:'+p+'l 3s linear infinite alternate}';
  var colega=boneco({x:88,hy:70,sh:52,hd:[88,44],bracos:['88,54 80,62','88,54 96,62'],pernas:['88,70 82,76 80,84','88,70 94,76 96,84']});
  var linha='<line class="'+p+'-l" x1="34" y1="66" x2="80" y2="48" stroke="'+VERDE+'" stroke-width="2" stroke-dasharray="4 4" opacity="0"/>';
  return wrap(p,chao(86)+portador+'<circle cx="34" cy="81" r="4" fill="'+BOLA+'"/>'
    +'<g class="'+p+'-c">'+colega+'</g>'+linha,css);
};

/* — me1 diário / me4 três coisas boas: lápis escreve; me4 acrescenta ✓✓✓ — */
function cenaEscrever(opts){
  return function(){
    var p='ep'+(seq++);
    var papel='<rect x="34" y="26" width="52" height="44" rx="2" fill="none" stroke="'+PROP+'" stroke-width="2"/>'
      +'<line x1="42" y1="38" x2="78" y2="38" stroke="'+PROP+'" stroke-width="1.5" opacity=".6"/>'
      +'<line x1="42" y1="48" x2="78" y2="48" stroke="'+PROP+'" stroke-width="1.5" opacity=".6"/>'
      +'<line x1="42" y1="58" x2="78" y2="58" stroke="'+PROP+'" stroke-width="1.5" opacity=".6"/>';
    var css='@keyframes '+p+'e{0%{transform:translate(0,0)}30%{transform:translate(24px,0)}33%{transform:translate(0,10px)}63%{transform:translate(24px,10px)}66%{transform:translate(0,20px)}96%{transform:translate(24px,20px)}100%{transform:translate(0,0)}}'
      +'.on .'+p+'-e{animation:'+p+'e 3.6s linear infinite}';
    var checks='';
    if(opts.checks){
      css+='@keyframes '+p+'c1{0%,28%{opacity:0}32%,100%{opacity:1}}@keyframes '+p+'c2{0%,60%{opacity:0}64%,100%{opacity:1}}@keyframes '+p+'c3{0%,92%{opacity:0}96%,100%{opacity:1}}'
        +'.on .'+p+'-c1{animation:'+p+'c1 3.6s steps(1) infinite}.on .'+p+'-c2{animation:'+p+'c2 3.6s steps(1) infinite}.on .'+p+'-c3{animation:'+p+'c3 3.6s steps(1) infinite}';
      checks='<text class="'+p+'-c1" x="92" y="41" font-size="10" fill="'+VERDE+'" font-family="sans-serif" opacity="0">✓</text>'
        +'<text class="'+p+'-c2" x="92" y="52" font-size="10" fill="'+VERDE+'" font-family="sans-serif" opacity="0">✓</text>'
        +'<text class="'+p+'-c3" x="92" y="63" font-size="10" fill="'+VERDE+'" font-family="sans-serif" opacity="0">✓</text>';
    }
    var lapis='<g class="'+p+'-e"><path d="M44 34 L52 26 L55 29 L47 37 Z" fill="'+BOLA+'"/><path d="M44 34 L46 36 L43 37 Z" fill="'+LINHA+'"/></g>';
    return wrap(p,papel+lapis+checks,css);
  };
}
CENAS.me1=cenaEscrever({});
CENAS.me4=cenaEscrever({checks:true});

/* — me2 repetir após erro: remate falha (✗), respira, remate acerta (✓) — */
CENAS.me2=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:28,bracos:['28,36 20,44','28,36 36,42'],pernas:['28,52 22,66 20,78','28,52 40,58 46,64']});
  var alvo='<rect x="98" y="48" width="10" height="14" fill="none" stroke="'+PROP+'" stroke-width="2"/>';
  var css='@keyframes '+p+'b1{0%{transform:translate(0,0);opacity:1}20%{transform:translate(48px,-24px);opacity:1}22%,100%{opacity:0}}'
    +'.on .'+p+'-b1{animation:'+p+'b1 4s ease-in infinite}'
    +'@keyframes '+p+'x{0%,20%{opacity:0}24%,42%{opacity:1}46%,100%{opacity:0}}'
    +'.on .'+p+'-x{animation:'+p+'x 4s steps(1) infinite}'
    +'@keyframes '+p+'b2{0%,50%{transform:translate(0,0);opacity:0}52%{opacity:1}72%{transform:translate(58px,-14px);opacity:1}74%,100%{opacity:0}}'
    +'.on .'+p+'-b2{animation:'+p+'b2 4s ease-in infinite}'
    +'@keyframes '+p+'v{0%,72%{opacity:0}76%,96%{opacity:1}100%{opacity:0}}'
    +'.on .'+p+'-v{animation:'+p+'v 4s steps(1) infinite}';
  return wrap(p,chao()+alvo+f0
    +'<g class="'+p+'-b1"><circle cx="40" cy="70" r="4.5" fill="'+BOLA+'"/></g>'
    +'<text class="'+p+'-x" x="86" y="34" font-size="12" fill="'+VERM+'" font-family="sans-serif" font-weight="bold" opacity="0">✗</text>'
    +'<g class="'+p+'-b2" opacity="0"><circle cx="40" cy="70" r="4.5" fill="'+BOLA+'"/></g>'
    +'<text class="'+p+'-v" x="100" y="44" font-size="12" fill="'+VERDE+'" font-family="sans-serif" font-weight="bold" opacity="0">✓</text>',css);
};

/* — me5 foco 5-4-3-2-1: números aparecem à volta da cabeça calma — */
CENAS.me5=function(){
  var p='ep'+(seq++);
  var fig=boneco({x:60,bracos:['60,36 50,46','60,36 70,46'],pernas:['60,52 52,66 50,78','60,52 68,66 70,78']});
  var pos=[[34,26],[46,14],[62,10],[78,14],[88,26]];
  var css='',html='';
  pos.forEach(function(xy,i){
    var kf=p+'n'+i, ini=(i*16), fim=(ini+14);
    css+='@keyframes '+kf+'{0%,'+ini+'%{opacity:0}'+ (ini+3) +'%,'+fim+'%{opacity:1}'+(fim+4)+'%,100%{opacity:0}}'
      +'.on .'+p+'-n'+i+'{animation:'+kf+' 4s steps(1) infinite}';
    html+='<text class="'+p+'-n'+i+'" x="'+xy[0]+'" y="'+xy[1]+'" font-size="9" fill="'+AZUL+'" font-family="sans-serif" font-weight="bold" opacity="0" text-anchor="middle">'+(5-i)+'</text>';
  });
  return wrap(p,chao()+fig+html,css);
};

/* — de7 passe ou finta: obstáculo fixo, bola vai para um lado ou outro (alterna) — */
CENAS.de7=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:26,bracos:['26,36 18,44','26,36 34,42'],pernas:['26,52 20,66 18,78','26,52 32,60 38,66']});
  var obst='<path d="M74 76 L79 62 L84 76 Z" fill="'+PROP+'"/>';
  var css='@keyframes '+p+'b{0%,8%{transform:translate(0,0)}42%{transform:translate(46px,0)}46%,50%{transform:translate(46px,-16px)}88%{transform:translate(92px,-16px)}92%,100%{transform:translate(0,0)}}'
    +'.on .'+p+'-b{animation:'+p+'b 3s ease-in-out infinite}'
    +'@keyframes '+p+'b2{0%,50%{transform:translate(0,0);opacity:0}54%{opacity:1}88%{transform:translate(92px,20px);opacity:1}92%,100%{transform:translate(0,0);opacity:0}}'
    +'.on .'+p+'-b2{animation:'+p+'b2 6s ease-in-out infinite}';
  return wrap(p,chao()+obst+f0
    +'<g class="'+p+'-b"><circle cx="40" cy="73" r="4.5" fill="'+BOLA+'"/></g>',css);
};

/* — de8 reagir ao sinal: palmas piscam, o pé toca a bola logo a seguir — */
CENAS.de8=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 44,44','52,36 60,44'],pernas:['52,52 46,66 44,78','52,52 62,60 70,68']});
  var css='@keyframes '+p+'p{0%,20%{opacity:.25;transform:scale(1)}24%{opacity:1;transform:scale(1.3)}30%,100%{opacity:.25;transform:scale(1)}}'
    +'.on .'+p+'-p{transform-box:fill-box;transform-origin:center;animation:'+p+'p 1.6s ease-out infinite}'
    +'@keyframes '+p+'b{0%,30%{transform:translateX(0)}55%{transform:translateX(14px)}100%{transform:translateX(0)}}'
    +'.on .'+p+'-b{animation:'+p+'b 1.6s ease-in-out infinite}';
  var maos='<g class="'+p+'-p"><path d="M22 26 L28 20 M22 20 L28 26" stroke="'+VERDE+'" stroke-width="2" stroke-linecap="round"/></g>';
  return wrap(p,chao()+maos+f0+'<g class="'+p+'-b"><circle cx="70" cy="74" r="4.5" fill="'+BOLA+'"/></g>',css);
};

/* — de9 espaço livre: 4 cones, corre sempre para o que está mais isolado — */
CENAS.de9=function(){
  var p='ep'+(seq++);
  var cones='<path d="M25 76 L29 66 L33 76 Z" fill="'+PROP+'"/><path d="M87 76 L91 66 L95 76 Z" fill="'+PROP+'"/>'
    +'<path d="M56 22 L60 12 L64 22 Z" fill="'+PROP+'"/><path d="M56 76 L60 66 L64 76 Z" fill="'+PROP+'"/>';
  var f0=boneco({x:0,hy:46,sh:28,hd:[0,20],bracos:['0,30 -8,38','0,30 8,36'],pernas:['0,46 -6,58 -8,70','0,46 6,58 8,70']});
  var f1=boneco({x:0,hy:46,sh:28,hd:[0,20],bracos:['0,30 -8,36','0,30 8,38'],pernas:['0,46 -8,58 -6,70','0,46 8,58 6,70']});
  var fb=flip(p,[f0,f1],0.42);
  var css=fb.css
    +'@keyframes '+p+'m{0%,20%{transform:translate(29,50)}45%,65%{transform:translate(91,50)}90%,100%{transform:translate(60,16)}}'
    +'.on .'+p+'-m{animation:'+p+'m 3s ease-in-out infinite}';
  return wrap(p,chao()+cones+'<g class="'+p+'-m">'+fb.html+'</g>',css);
};

/* — de10 remate ou passe: baliza de um lado, colega do outro, decide sob tempo — */
CENAS.de10=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:36,bracos:['36,36 28,44','36,36 44,42'],pernas:['36,52 30,66 28,78','36,52 42,64 40,78']});
  var baliza='<g stroke="'+PROP+'" stroke-width="2.5" fill="none"><path d="M96 74 V38 H114"/></g>';
  var colega=boneco({x:70,hy:66,sh:50,hd:[70,42],bracos:['70,52 62,60','70,52 78,60'],pernas:['70,66 64,72 62,80','70,66 76,72 78,80']});
  var css='@keyframes '+p+'v{0%,30%{opacity:0;transform:translateY(2px)}40%,70%{opacity:1;transform:translateY(0)}80%,100%{opacity:0}}'
    +'.on .'+p+'-v{animation:'+p+'v 2.6s steps(1) infinite}'
    +'@keyframes '+p+'b1{0%,68%{transform:translate(0,0);opacity:0}72%{opacity:1}98%{transform:translate(58px,-24px);opacity:1}100%{opacity:0}}'
    +'.on .'+p+'-b1{animation:'+p+'b1 5.2s ease-out infinite}'
    +'@keyframes '+p+'b2{0%{transform:translate(0,0);opacity:0}50%,68%{transform:translate(0,0);opacity:0}72%{opacity:1}98%{transform:translate(34px,14px);opacity:1}100%{opacity:0}}'
    +'.on .'+p+'-b2{animation:'+p+'b2 2.6s ease-out infinite}';
  var relogio='<text class="'+p+'-v" x="20" y="20" font-size="10" fill="'+AZUL+'" font-family="sans-serif" font-weight="bold" opacity="0">⏱</text>';
  return wrap(p,chao()+baliza+relogio+f0+colega
    +'<g class="'+p+'-b1"><circle cx="40" cy="73" r="4.5" fill="'+BOLA+'"/></g>'
    +'<g class="'+p+'-b2" opacity="0"><circle cx="40" cy="73" r="4.5" fill="'+BOLA+'"/></g>',css);
};

/* — ta6 ler o passe seguinte: ecrã pausa, seta de previsão aparece antes da confirmação — */
CENAS.ta6=function(){
  var p='ep'+(seq++);
  var ecra='<rect x="30" y="24" width="60" height="38" rx="2" fill="none" stroke="'+PROP+'" stroke-width="2.5"/>';
  var css='@keyframes '+p+'pl{0%,55%{opacity:.9}60%,100%{opacity:.9}}'
    +'@keyframes '+p+'seta{0%,30%{opacity:0}38%,68%{opacity:1;stroke-dashoffset:0}72%,100%{opacity:0}}'
    +'.on .'+p+'-seta{stroke-dasharray:20;stroke-dashoffset:20;animation:'+p+'seta 3s ease-out infinite}'
    +'@keyframes '+p+'ok{0%,66%{opacity:0}72%,92%{opacity:1}100%{opacity:0}}'
    +'.on .'+p+'-ok{animation:'+p+'ok 3s steps(1) infinite}';
  var bola='<circle cx="46" cy="46" r="4" fill="'+BOLA+'"/>';
  var seta='<line class="'+p+'-seta" x1="50" y1="46" x2="74" y2="38" stroke="'+VERDE+'" stroke-width="2" stroke-linecap="round" opacity="0"/>';
  var ok='<text class="'+p+'-ok" x="78" y="34" font-size="10" fill="'+VERDE+'" font-family="sans-serif" font-weight="bold" opacity="0">✓</text>';
  return wrap(p,chao(76)+ecra+bola+seta+ok,css);
};

/* — ta7 zonas de perigo: mapa, 3 zonas acendem em sequência (o próprio ta3, com zonas maiores) — */
CENAS.ta7=function(){
  var p='ep'+(seq++);
  var campo='<rect x="20" y="20" width="80" height="50" fill="none" stroke="'+PROP+'" stroke-width="1.5" opacity=".7"/>';
  var css='@keyframes '+p+'z1{0%,10%{opacity:.15}18%,42%{opacity:.7}50%,100%{opacity:.15}}'
    +'@keyframes '+p+'z2{0%,42%{opacity:.15}50%,74%{opacity:.7}82%,100%{opacity:.15}}'
    +'@keyframes '+p+'z3{0%,74%{opacity:.15}82%,96%{opacity:.7}100%{opacity:.15}}'
    +'.on .'+p+'-z1{animation:'+p+'z1 4.2s ease-in-out infinite}'
    +'.on .'+p+'-z2{animation:'+p+'z2 4.2s ease-in-out infinite}'
    +'.on .'+p+'-z3{animation:'+p+'z3 4.2s ease-in-out infinite}';
  var zonas='<rect class="'+p+'-z1" x="70" y="26" width="24" height="18" fill="'+VERM+'" opacity=".15"/>'
    +'<rect class="'+p+'-z2" x="70" y="46" width="24" height="18" fill="'+VERM+'" opacity=".15"/>'
    +'<rect class="'+p+'-z3" x="46" y="34" width="20" height="20" fill="'+VERM+'" opacity=".15"/>';
  return wrap(p,chao(74)+campo+zonas,css);
};

/* — ta8 transição rápida: perde a bola, corre atrás e recupera nos primeiros segundos — */
CENAS.ta8=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -9,42','0,34 9,40'],pernas:['0,50 -7,64 -9,76','0,50 9,62 13,70']});
  var f1=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 9,40','0,34 -9,42'],pernas:['0,50 7,60 5,74','0,50 -7,58 -13,64']});
  var fb=flip(p,[f0,f1],0.36);
  var css=fb.css
    +'@keyframes '+p+'m{0%,10%{transform:translateX(16px)}42%{transform:translateX(70px)}48%{transform:translateX(70px)}92%,100%{transform:translateX(16px)}}'
    +'.on .'+p+'-m{animation:'+p+'m 2.4s cubic-bezier(.5,0,.5,1) infinite}'
    +'@keyframes '+p+'b{0%,10%{transform:translateX(0)}40%{transform:translateX(70px)}48%,90%{transform:translateX(66px)}100%{transform:translateX(0)}}'
    +'.on .'+p+'-b{animation:'+p+'b 2.4s ease-out infinite}';
  return wrap(p,chao()+'<g class="'+p+'-m">'+fb.html+'</g>'
    +'<g class="'+p+'-b"><circle cx="10" cy="73" r="4" fill="'+BOLA+'"/></g>',css);
};

/* — ta9 superioridade 2x1: dois companheiros disponíveis, decide consoante o espaço — */
CENAS.ta9=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:0,hy:50,sh:32,hd:[0,24],bracos:['0,34 -8,42','0,34 8,40'],pernas:['0,50 -6,64 -8,76','0,50 8,62 12,70']});
  var comp1=boneco({x:96,hy:36,sh:20,hd:[96,14],bracos:['96,24 88,32','96,24 104,32'],pernas:['96,36 90,48 88,60','96,36 102,48 104,60']});
  var comp2=boneco({x:96,hy:70,sh:54,hd:[96,48],bracos:['96,58 88,66','96,58 104,66'],pernas:['96,70 90,78 88,86','96,70 102,78 104,86']});
  var css='@keyframes '+p+'m{0%,25%{transform:translate(18px,44px)}55%{transform:translate(60px,44px)}100%{transform:translate(60px,44px)}}'
    +'.on .'+p+'-m{animation:'+p+'m 3s ease-out infinite}'
    +'@keyframes '+p+'b{0%,55%{transform:translate(0,0);opacity:0}60%{opacity:1}92%{transform:translate(36px,-14px);opacity:1}100%{opacity:0}}'
    +'.on .'+p+'-b{animation:'+p+'b 3s ease-out infinite}';
  return wrap(p,chao(90)+comp1+comp2
    +'<g class="'+p+'-m">'+f0+'</g>'
    +'<g class="'+p+'-b"><circle cx="18" cy="66" r="4" fill="'+BOLA+'"/></g>',css);
};

/* — ta10 comunicação: balão de fala aparece por cima do boneco, curto e repetido — */
CENAS.ta10=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 42,42','52,36 62,42'],pernas:['52,52 46,66 44,78','52,52 60,64 66,72']});
  var css='@keyframes '+p+'f{0%,15%{opacity:0;transform:translateY(3px)}25%,55%{opacity:1;transform:translateY(0)}65%,100%{opacity:0}}'
    +'.on .'+p+'-f{animation:'+p+'f 2s ease-out infinite}';
  var balao='<g class="'+p+'-f" opacity="0"><path d="M64 12 h30 a3 3 0 0 1 3 3 v10 a3 3 0 0 1 -3 3 h-20 l-6 6 v-6 h-4 a3 3 0 0 1 -3 -3 v-10 a3 3 0 0 1 3 -3 Z" fill="'+VERDE+'"/>'
    +'<text x="79" y="22" font-size="7" fill="#052" font-family="sans-serif" font-weight="bold" text-anchor="middle">VIRA!</text></g>';
  return wrap(p,chao()+f0+'<circle cx="66" cy="74" r="4" fill="'+BOLA+'"/>'+balao,css);
};

/* — me6 rotina em 3 passos: três ícones acendem em sequência antes de jogar — */
CENAS.me6=function(){
  var p='ep'+(seq++);
  var fig=boneco({x:60,bracos:['60,36 50,44','60,36 70,44'],pernas:['60,52 52,66 50,78','60,52 68,66 70,78']});
  var css='@keyframes '+p+'1{0%,4%{opacity:.2}10%,28%{opacity:1}34%,100%{opacity:.2}}'
    +'@keyframes '+p+'2{0%,34%{opacity:.2}40%,58%{opacity:1}64%,100%{opacity:.2}}'
    +'@keyframes '+p+'3{0%,64%{opacity:.2}70%,88%{opacity:1}94%,100%{opacity:.2}}'
    +'.on .'+p+'-1{animation:'+p+'1 4s ease-in-out infinite}'
    +'.on .'+p+'-2{animation:'+p+'2 4s ease-in-out infinite}'
    +'.on .'+p+'-3{animation:'+p+'3 4s ease-in-out infinite}';
  var passos='<circle class="'+p+'-1" cx="26" cy="18" r="6" fill="none" stroke="'+AZUL+'" stroke-width="1.5" opacity=".2"/><text x="26" y="21" font-size="7" fill="'+AZUL+'" text-anchor="middle" font-family="sans-serif">1</text>'
    +'<circle class="'+p+'-2" cx="46" cy="18" r="6" fill="none" stroke="'+AZUL+'" stroke-width="1.5" opacity=".2"/><text x="46" y="21" font-size="7" fill="'+AZUL+'" text-anchor="middle" font-family="sans-serif">2</text>'
    +'<circle class="'+p+'-3" cx="66" cy="18" r="6" fill="none" stroke="'+AZUL+'" stroke-width="1.5" opacity=".2"/><text x="66" y="21" font-size="7" fill="'+AZUL+'" text-anchor="middle" font-family="sans-serif">3</text>';
  return wrap(p,chao()+passos+fig,css);
};

/* — me7 fala contigo mesmo: erro (✗), seguido de balão de incentivo (não de remate falhado) — */
CENAS.me7=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:52,bracos:['52,36 44,44','52,36 60,44'],pernas:['52,52 46,66 44,78','52,52 60,66 58,78']});
  var css='@keyframes '+p+'x{0%,10%{opacity:0}16%,40%{opacity:1}46%,100%{opacity:0}}'
    +'.on .'+p+'-x{animation:'+p+'x 3s steps(1) infinite}'
    +'@keyframes '+p+'f{0%,46%{opacity:0;transform:translateY(3px)}54%,86%{opacity:1;transform:translateY(0)}94%,100%{opacity:0}}'
    +'.on .'+p+'-f{animation:'+p+'f 3s ease-out infinite}';
  var x='<text class="'+p+'-x" x="38" y="20" font-size="11" fill="'+VERM+'" font-family="sans-serif" font-weight="bold" opacity="0">✗</text>';
  var balao='<g class="'+p+'-f" opacity="0"><path d="M62 8 h34 a3 3 0 0 1 3 3 v10 a3 3 0 0 1 -3 3 h-24 l-6 6 v-6 h-4 a3 3 0 0 1 -3 -3 v-10 a3 3 0 0 1 3 -3 Z" fill="'+VERDE+'"/>'
    +'<text x="79" y="18" font-size="6.5" fill="#052" font-family="sans-serif" font-weight="bold" text-anchor="middle">CONSIGO!</text></g>';
  return wrap(p,chao()+f0+x+balao,css);
};

/* — me8 visualizar antes de dormir: boneco quieto, balão de pensamento com uma bola dentro — */
CENAS.me8=function(){
  var p='ep'+(seq++);
  var f0='<g stroke="'+LINHA+'" stroke-width="3" stroke-linecap="round" fill="none">'
    +'<circle cx="34" cy="62" r="5.5" fill="'+LINHA+'" stroke="none"/>'
    +'<line x1="40" y1="64" x2="70" y2="70"/><polyline points="70,70 78,66"/></g>'; // deitado
  var css='@keyframes '+p+'b{0%,100%{transform:scale(1);opacity:1}50%{transform:scale(1.06);opacity:.85}}'
    +'.on .'+p+'-b{transform-box:fill-box;transform-origin:center;animation:'+p+'b 2.6s ease-in-out infinite}'
    +'@keyframes '+p+'z{0%,100%{opacity:.3}50%{opacity:1}}'
    +'.on .'+p+'-z{animation:'+p+'z 2.6s ease-in-out infinite}';
  var pensamento='<circle cx="46" cy="42" r="3" fill="none" stroke="'+PROP+'" stroke-width="1" opacity=".6"/>'
    +'<circle cx="54" cy="34" r="4" fill="none" stroke="'+PROP+'" stroke-width="1" opacity=".6"/>'
    +'<circle class="'+p+'-b" cx="68" cy="22" r="14" fill="none" stroke="'+PROP+'" stroke-width="1.5"/>'
    +'<circle class="'+p+'-b" cx="68" cy="22" r="5" fill="'+BOLA+'"/>'
    +'<text class="'+p+'-z" x="86" y="14" font-size="8" fill="'+AZUL+'" font-family="sans-serif">z</text>';
  return wrap(p,chao(78)+f0+pensamento,css);
};

/* — me9 escala de esforço: reaproveita a cena de escrever, com um "medidor" 1-5 em vez de check-list — */
CENAS.me9=function(){
  var p='ep'+(seq++);
  var papel='<rect x="34" y="26" width="52" height="44" rx="2" fill="none" stroke="'+PROP+'" stroke-width="2"/>';
  var css='@keyframes '+p+'bar{0%,100%{transform:scaleY(0)}60%,90%{transform:scaleY(1)}}'
    +'.on .'+p+'-bar{transform-box:fill-box;transform-origin:bottom;animation:'+p+'bar 3s ease-in-out infinite}';
  var barras='';
  for(var i=0;i<5;i++){
    barras+='<rect class="'+p+'-bar" x="'+(41+i*8)+'" y="'+(64-i*4)+'" width="5" height="'+(6+i*4)+'" fill="'+(i<3?VERDE:BOLA)+'" style="animation-delay:'+(i*0.12)+'s"/>';
  }
  return wrap(p,papel+barras,css);
};

/* — me10 contar até 5: erro simulado, contagem visual, repete calmo — */
CENAS.me10=function(){
  var p='ep'+(seq++);
  var f0=boneco({x:30,bracos:['30,36 22,44','30,36 38,42'],pernas:['30,52 24,66 22,78','30,52 40,60 46,66']});
  var css='@keyframes '+p+'x{0%,8%{opacity:0}12%,26%{opacity:1}30%,100%{opacity:0}}'
    +'.on .'+p+'-x{animation:'+p+'x 4s steps(1) infinite}';
  var nums='';
  for(var i=0;i<5;i++){
    var ini=30+i*8, fim=ini+7;
    css+='@keyframes '+p+'n'+i+'{0%,'+ini+'%{opacity:0}'+(ini+2)+'%,'+fim+'%{opacity:1}'+(fim+2)+'%,100%{opacity:0}}'
      +'.on .'+p+'-n'+i+'{animation:'+p+'n'+i+' 4s steps(1) infinite}';
    nums+='<text class="'+p+'-n'+i+'" x="'+(66+i*8)+'" y="24" font-size="8" fill="'+AZUL+'" font-family="sans-serif" font-weight="bold" opacity="0">'+(i+1)+'</text>';
  }
  var x='<text class="'+p+'-x" x="46" y="20" font-size="10" fill="'+VERM+'" font-family="sans-serif" font-weight="bold" opacity="0">✗</text>';
  return wrap(p,chao()+f0+'<circle cx="40" cy="73" r="4" fill="'+BOLA+'"/>'+x+nums,css);
};

/* — cena genérica (fallback): bola a pulsar com setas de movimento — */
CENAS.__generico=function(){
  var p='ep'+(seq++);
  var fig=boneco({x:46,bracos:['46,36 36,44','46,36 56,44'],pernas:['46,52 40,66 38,78','46,52 54,64 60,72']});
  var css='@keyframes '+p+'b{0%,100%{transform:scale(1)}50%{transform:scale(1.18)}}'
    +'.on .'+p+'-b{transform-box:fill-box;transform-origin:center;animation:'+p+'b 1.2s ease-in-out infinite}';
  return wrap(p,chao()+fig+'<g class="'+p+'-b"><circle cx="62" cy="73" r="4.5" fill="'+BOLA+'"/></g>',css);
};

/* ── resolução exercício → cena ── */
/* nomes atuais → id (para planos gravados em que o id divirja da biblioteca
   atual, incluindo nomes da biblioteca antiga pré-51) */
var NOMES={
  'Pé fraco · passe à parede':'te1','Toques alternados (juggling)':'te2','Toques alternados':'te2',
  'Domínio orientado curto':'te3','Condução entre cones':'te4','Rolinhos com a sola':'te5',
  'Fintas no lugar (tesoura)':'te6','Passe de precisão ao alvo':'te7','Receção de bola alta':'te8',
  'Condução com mudança de ritmo':'te9','Remate colocado (baixo)':'te10','Primeiro toque em movimento':'te11',
  'Cabeceamento de segurança':'te12',
  'Mobilidade dinâmica de aquecimento':'fi1','Alongamento de recuperação':'fi2','Mobilidade de tornozelo e anca':'fi3',
  'Skipping no lugar':'fi4','Prancha':'fi5','Prancha lateral':'fi6','Ponte de glúteos':'fi7',
  'Escada de coordenação (linha)':'fi8','Agachamentos':'fi9','Afundos (lunges)':'fi10',
  'Flexões (adaptadas)':'fi11','Elevação de gémeos':'fi12','Agachamento com salto suave':'fi13',
  'Corrida contínua leve':'fi14','Corrida com bola em ritmo':'fi15','Circuito contínuo (base)':'fi16',
  'Saltos laterais explosivos':'fi17','Saltos laterais':'fi17','Tabata (cardio HIIT)':'fi18',
  'Acelerações em rampa':'fi19','Sprints com mudança de direção':'fi20','Pliometria: saltos ao caixote':'fi21',
  'Circuito de força sénior':'fi22','Sprints de resistência (repetidos)':'fi23',
  'Cores ao sinal':'de1','Espelho com bola':'de2','Espelho':'de2','Números ao sinal':'de3',
  'Passe à cor certa':'de4','1v1 ao sinal':'de5','Scan: olhar antes de receber':'de6',
  'Vídeo + 3 perguntas':'ta1','Sombra posicional':'ta2','Mapa da posição':'ta3',
  'Apoio e ângulo':'ta4','Basculação (defesa)':'ta5',
  'Diário de 1 objetivo':'me1','Repetir após erro':'me2','Respiração antes de rematar':'me3',
  '3 coisas boas':'me4','Foco 5-4-3-2-1':'me5'
};

function resolver(ex){
  if(!ex) return null;
  var id=ex.id||ex.exercicio_id||null, nome=(ex.nome||'').trim();
  // o NOME manda: planos gravados antes da biblioteca-51 têm ids que hoje
  // apontam para exercícios diferentes (ex.: fi1 era Skipping, hoje é
  // Mobilidade). O nome gravado é a verdade do que a família vai fazer.
  if(nome && NOMES[nome]) return NOMES[nome];
  if(id && CENAS[id]) return id;
  return null;
}

function svgDe(ex){
  var id=resolver(ex);
  var f=id?CENAS[id]:null;
  if(!f) f=CENAS.__generico;
  return f();
}

/* ── montagem + observador ── */
var io=null;
function observar(el){
  if(!('IntersectionObserver' in window)){ el.classList.add('on'); return; }
  if(!io){
    io=new IntersectionObserver(function(es){
      es.forEach(function(e){ e.target.classList.toggle('on', e.isIntersecting); });
    },{rootMargin:'60px'});
  }
  io.observe(el);
}
var cssGlobal=false;
function garantirCSS(){
  if(cssGlobal) return; cssGlobal=true;
  var st=document.createElement('style');
  st.textContent='.exanim{display:block;background:rgba(0,0,0,.18);border-radius:9px;margin-bottom:8px;overflow:hidden}'
    +'.exanim .exanim-svg{display:block;width:100%;height:auto;max-height:96px}'
    +'@media (prefers-reduced-motion: reduce){.exanim *{animation:none!important}}';
  document.head.appendChild(st);
}
function mount(el, ex){
  garantirCSS();
  el.classList.add('exanim');
  el.innerHTML=svgDe(ex);
  observar(el);
}
function mountAll(root){
  (root||document).querySelectorAll('[data-exanim]').forEach(function(el){
    if(el.__exanim) return; el.__exanim=true;
    var ex={id:el.getAttribute('data-exid')||null, nome:el.getAttribute('data-exnome')||''};
    mount(el, ex);
  });
}

window.YTBExAnim={svg:svgDe, mount:mount, mountAll:mountAll, _cenas:CENAS};
})();
