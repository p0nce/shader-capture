#version 110
// Lightning
// By: Brandon Fogerty
// bfogerty at gmail dot com 
// xdpixel.com


uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;


float Hash( vec2 p)
{
     vec3 p2 = vec3(p.xy,2.0);
    return fract(sin(dot(p2,vec3(27.1,20.7, 2.4)))*0.5453123);
}

float noise(in vec2 p)
{
    vec2 i = floor(p);
     vec2 f = fract(p);
     f *= f * (3.0-2.0*f);
    return mix(mix(Hash(i + vec2(0.,0.)), Hash(i + vec2(1.,0.)),f.x),
               mix(Hash(i + vec2(0.,1.)), Hash(i + vec2(1.,1.)),f.x),
               f.y);
}

float fbm(vec2 p)
{
     float v = 0.0;
     v += noise(p*1.0) * .5;
     v += noise(p*2.)  * .25;
     v += noise(p*4.)  * .15;
     return v;
}

void main( void ) 
{

	vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
	uv.x *= resolution.x/resolution.y;

	//vec2 tmp_uv;
	//tmp_uv.x = uv.y;
	//tmp_uv.y = uv.x;
	//uv = tmp_uv;
	//float timeVal = time;

	vec3 finalColor = vec3( 0.0 );
	for( int i=0; i < 3; ++i )
	{
		float indexAsFloat = float(i);
		float amp = 90.0 + (indexAsFloat*5.0);
		float period = 0.2 + (indexAsFloat+1.0);
		float thickness = mix( 0.9, 1.1, noise(uv*10.0) );
		float t = abs( 1.4 / (sin(uv.y + fbm( uv + time * period )) * amp) );
		
		//float show = fract(abs(sin(timeVal))) >= 0.0 ? 1.0 : 0.0;
		
		finalColor +=  t * vec3( 2.9, 1.5, .25 );
	}
	
	gl_FragColor = vec4( finalColor, 1.0 );
}
	

