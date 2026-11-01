#version 300 es
// our vertex data
in vec3 aPosition;

// our texcoordinates
in vec2 aTexCoord;

// this is a variable that will be shared with the fragment shader
// we will assign the attribute texcoords to the varying texcoords to move them from the vert shader to the frag shader
// it can be called whatever you want but often people prefiv it with 'v' to indicate that it is a varying
out vec2 vTexCoord;


const mat3 Id = mat3(1.0);

// Bilinear Form and Conjugation
uniform vec3 K;
const int numSmalls = 10;

// < --- Coxeter Rep -- >//
  const float pi = 3.1415926535897932;
  out float p ;
  out float q ;
  out float r ;
  out float sp;

  out mat3  Bfm;

  out vec3  va ;
  out vec3  vb ;
  out vec3  vc ;

  out mat3  Q  ;
  out mat3  Qnv;

  // Coxeter Group element representatives
  out mat3 aM;
  out mat3 A;

  out mat3 bM;
  out mat3 B;

  out mat3 cM;
  out mat3 C;
// < --  --- > //
//
out mat2 Id2;

void initCoxeter(){
  p  = cos(pi / K.x);
  q  = cos(pi / K.y);
  r  = cos(pi / K.z);
  sp = sqrt(1.0 - p*p);
                                                                                        
  Bfm = mat3( 1.0,  -p,  -q,
                     -p, 1.0,  -r,
                     -q,  -r, 1.0);

  va  = vec3(1.0,0.0,0.0);
  vb  = vec3(p, 1.0, 0.0) / sp;
  vc  = vec3(q + r*p, r + p*q, sp*sp) / (sp * sqrt(p*p + q*q + r*r + 2.0*p*q*r - 1.0));

  Q   = mat3(va,vb,vc);
  Qnv = inverse(Q);

  aM = transpose(mat3(Id[0] - 2.0 * Bfm[0], Id[1], Id[2]));
  A = transpose(Qnv * aM * Q);
                                                           
  bM = transpose(mat3(Id[0], Id[1] - 2.0 * Bfm[1], Id[2]));
  B = transpose(Qnv * bM * Q);
                                                           
  cM = transpose(mat3(Id[0], Id[1], Id[2] - 2.0 * Bfm[2]));
  C = transpose(Qnv * cM * Q);

  Id2 = mat2(1.);
}


void main() {
  initCoxeter();
  // copy the texture coordinates
  vTexCoord = 2.0*aTexCoord - 1.0;

  // copy the position data into a vec4, using 1.0 as the w component
  vec4 positionVec4 = vec4(aPosition, 1.0);
  //positionVec4.xy = positionVec4.xy * 2.0 - 1.0;

  // send the vertex information on to the fragment shader
  gl_Position = positionVec4;
}
