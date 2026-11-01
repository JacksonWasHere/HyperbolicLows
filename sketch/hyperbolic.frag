#version 300 es
precision mediump float;

// Coordinates from unit square (-1,1)
in vec2 vTexCoord;

// -- Coxeter rep -- //
  in mat3  Bfm;

  in vec3  va ;
  in vec3  vb ;
  in vec3  vc ;

  in mat3  Q  ;
  in mat3  Qnv;



  // Coxeter Group element representatives
  in mat3 aM;
  in mat3 A;

  in mat3 bM;
  in mat3 B;

  in mat3 cM;
  in mat3 C;

  in mat2 Id2;
  mat3 Id = mat3(1.);
// -- end rep -- //


// == Uniforms == //
uniform vec2 resolution;
uniform vec2 mouse;
uniform int style;
uniform float sSty;
uniform float lowDraw;
uniform bool lowInv;

// === Set number of low elements === //
// the number of lows and the number of smalls must be set by hand.
const int numSmalls = 35;
const int numLows = 60;

uniform vec3[numSmalls] smallRoots;
uniform mat3[numLows] lowList;


// --- Color Output -- //
out vec4 FragColor;

// --- Useful Constants --- //
vec3 white = vec3(1.);
vec3 red = vec3(1.,0.1,0.);
vec3 blue = vec3(0.1,0.3,0.9);


// --- Conversion Functions --- //
  float tval(vec2 p){
    float r = p.x*p.x + p.y*p.y;
    return (r + 1.) / (1. - r);
  }

  vec3 inject(vec2 uv){
    float t = tval(uv);
    return vec3((t+1.)*uv.xy,t);
  }

  mat3 rotMat(vec2 mouse){
    vec3 jm = inject(mouse);
    float csh = jm.z / sqrt(jm.x*jm.x + 1.);
    float snh = jm.y / sqrt(jm.x*jm.x + 1.);
    mat3 matY = mat3(1. , 0., 0., 
                      0., csh, -snh,
                      0., -snh, csh);

    jm = matY * jm;
    return mat3(jm.z, 0., -jm.x, 0.,  1., 0., -jm.x, 0., jm.z) * matY;
  }
// --- end conv ---//

// --- Drawing --- //
  mat3 pick(float st, mat3 matA, mat3 other){
    return (st * matA) + (1. - st) * other;
  }

  vec3 pick(float st, vec3 matA, vec3 other){
    return (st * matA) + (1. - st) * other;
  }

  mat3 reduceM(vec3 gCoord){
    float stA = 1. - step(0.0, (dot(gCoord, Qnv[0])));
    float stB = 1. - step(0.0, (dot(gCoord, Qnv[1])));
    float stC = 1. - step(0.0, (dot(gCoord, Qnv[2])));
    float vg = (1.-stA)*(1. - stB)*(1. - stC);

    return pick(stA,A,pick(stB,B,pick(stC,C,Id)));
  }

  float smallIntx(vec3 hCoord){
    float smallMask = 1.;
    for(int i = 0; i < numSmalls; i ++){
      vec3 ts = smallRoots[i];
      if(!(ts.x == 0. && ts.y == 0. && ts.z == 0.)){
        smallMask = min(smallMask, abs(dot(hCoord, Qnv * smallRoots[i])));
      }
    }
    return 1. - smoothstep(0.,0.07,2. * smallMask);
  }

  float simples(vec3 hCoord){
    float smallMask = 1.;
    smallMask = min(abs(dot(hCoord, Qnv[0])), smallMask);
    smallMask = min(abs(dot(hCoord, Qnv[1])), smallMask);
    smallMask = min(abs(dot(hCoord, Qnv[2])), smallMask);

    return 1. - smoothstep(0.,0.07,2. * smallMask);
  }

  float gridIntx(vec3 gCoord){
    float gridMask = 1.;
    for(int i = 0; i < 40; i ++){
      float stepA = step(0.02, abs(dot(gCoord, Qnv[0])));
      float stepB = step(0.02, abs(dot(gCoord, Qnv[1])));
      float stepC = step(0.02, abs(dot(gCoord, Qnv[2])));

   
      gridMask *= stepA*stepB*stepC;
      mat3 simpleM = reduceM(gCoord);
      gCoord = simpleM * gCoord;
    }
    return 1. - gridMask;
  }


  float gridCheck(vec3 gCoord){
    float gridMask = 1.;
    for(int i = 0; i < 40; i ++){
      float stepA = step(0.02, abs(dot(gCoord, Qnv[0])));
      float stepB = step(0.02, abs(dot(gCoord, Qnv[1])));
      float stepC = step(0.02, abs(dot(gCoord, Qnv[2])));

      float stA = 1. - step(0.0, (dot(gCoord, Qnv[0])));
      float stB = 1. - step(0.0, (dot(gCoord, Qnv[1])));
      float stC = 1. - step(0.0, (dot(gCoord, Qnv[2])));
      float vg = (1.-stA)*(1. - stB)*(1. - stC);
   
      gridMask = (1. - gridMask)*(1.-vg) + vg * gridMask;
      mat3 simpleM = pick(stA,A,pick(stB,B,pick(stC,C,Id)));
      gCoord = simpleM * gCoord;
    }
    return gridMask;
  }

  float lowCol(vec3 pos){
    float offLow = 1.;

    for(int i = 0; i < numLows; i ++){
      vec3 tPos;
      if(lowInv){
        tPos = pos * inverse(Qnv * transpose(lowList[i]) * Q);
      } else {
        tPos = pos * (Qnv * transpose(lowList[i]) * Q);
      }

      float onA = smoothstep(0.0, 0.03, (dot(tPos, Qnv[0])));
      float onB = smoothstep(0.0, 0.03, (dot(tPos, Qnv[1])));
      float onC = smoothstep(0.0, 0.03, (dot(tPos, Qnv[2])));
      offLow *= 1. - onA * onB * onC;
    }

    return 1. - offLow;
  }
// --- end draw ---//

float mag(vec3 p){
  return p.x*p.x + p.y*p.y + p.z*p.z;
}

float mag(vec2 p){
  return p.x*p.x + p.y*p.y;
}

float fundamental(vec3 pos){
  float onA = smoothstep(0.0, 0.03, (dot(pos, Qnv[0])));
  float onB = smoothstep(0.0, 0.03, (dot(pos, Qnv[1])));
  float onC = smoothstep(0.0, 0.03, (dot(pos, Qnv[2])));
  return 1. - onA * onB * onC;
}

float gridMagic(vec3 pos){
  float col = 0.;
  for(int i = 0; i < 60; i ++){
    float onA = smoothstep(0.0, 0.5, (dot(pos, Qnv[0])));
    float onB = smoothstep(0.0, 0.5, (dot(pos, Qnv[1])));
    float onC = smoothstep(0.0, 0.5, (dot(pos, Qnv[2])));
    col += onA*onB*onC;

    pos = reduceM(pos) * pos;
  }
  return col;
}


void main() {
  // copy the vTexCoord
  // vTexCoord is a value that goes from 0.0 - 1.0 depending on the pixels location
  // we can use it to access every pixel on the screen
  vec2 coord = vTexCoord;

  // correct the aspect ration on the x direction
  coord.x *= resolution.x / resolution.y;
  mat3[4] Simple = mat3[4](Id,A,B,C);

  float col = 0.;
  col += step(1.,coord.x*coord.x + coord.y*coord.y);

  vec3 hCoord = inject(coord);
  mat3 transform = rotMat(mouse);
  hCoord = (transform) * hCoord;

  
  float smallMask = sSty * simples(hCoord) + (1. - sSty)* smallIntx(hCoord);

  float lowMask = lowDraw * lowCol(hCoord);

  float gridMask;
  if (style == 0){
    gridMask = gridCheck(hCoord);
  } else if(style == 1) {
    gridMask = gridIntx(hCoord);
  } else{
    gridMask = gridMagic(hCoord);
  }
  float fund = fundamental(hCoord);

  vec3 smallColor = red * smallMask;

  vec3 lowFC = blue * (fund) + white * .8 * (1. - fund);

  vec3 nonSmall = pick(lowMask, lowFC, gridMask * white * 0.5);

  vec3 colV = pick(col , white , smallMask * red + (1.-smallMask) * nonSmall);
  
  FragColor = vec4(colV , 1.0 );
}
