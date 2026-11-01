let hShader;

let roots;
let lows;

let K_init;
let K = [];


let mPrev = [0,0];

let moving = false;
let style = 0;
let styles = 3;
let smallStyle = 0;
let lowInv = 0;

const arraysEq = (a,b) => K.every((val, index) => val === b[index]);

async function setup() {
  // put setup code here
  myData = await loadJSON('roots.json')

  roots = myData.roots;
  lows = myData.lows; 
  K_init = myData.kval;
  K = myData.kval;
  hShader = await loadShader('standard.vert','hyperbolic.frag');

  createCanvas(600,600,WEBGL);
  noStroke();

}
 
function draw() {
   // put drawing code here
   shader(hShader);
   let mx = map(mouseX, 0, width, -1, 1);
   let my = map(mouseY, 0, height, -1, 1);

   hShader.setUniform('K',K)
   if ((mx*mx + my*my) <= 1 && moving){
     hShader.setUniform('mouse',[-my,mx])
     mPrev = [-my,mx];
   } else {
     hShader.setUniform('mouse',mPrev);
   }

   hShader.setUniform('style',style);
   hShader.setUniform('sSty',smallStyle)
   hShader.setUniform('smallRoots',roots)
   if(arraysEq(K,K_init)){
     hShader.setUniform('lowDraw',1)
   } else {
     hShader.setUniform('lowDraw',0)
   }
   hShader.setUniform('lowInv',lowInv)
   hShader.setUniform('lowList',lows)
   hShader.setUniform('resolution',[width,height]);
   quad(-1,-1,-1,1,1,1,1,-1);
}

function keyPressed(){
  if (key === 'c'){
    moving = !moving;
  }
//else if (key === 'j'){
//  K[0] = K[0] - 1
//} else if (key === 'u'){
//  K[0] = K[0] + 1
//} else if (key === 'k'){
//  K[1] = K[1] - 1
//} else if (key === 'i'){
//  K[1] = K[1] + 1
//} else if (key === 'l'){
//  K[2] = K[2] - 1
//} else if (key === 'o'){
//  K[2] = K[2] + 1
//}

  if (key === 'b'){
    style = (style + 1) % styles;
    console.log("Styligh")
  } else if(key === 'n'){
    smallStyle = 1 - smallStyle;
  } else if(key === 'm'){
    lowInv = !lowInv;
  }
}

function windowResized(){
}
