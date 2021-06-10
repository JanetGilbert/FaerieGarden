// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Edited by Janet Gilbert
// Lots of stuff ripped from "UnityBuiltin3xTreeLibrary.cginc" and "TerrainEngine.cginc"
Shader "Custom/Nature/Tree Creator Leaves Optimized" {
Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    _TranslucencyColor ("Translucency Color", Color) = (0.73,0.85,0.41,1) // (187,219,106,255)
    _Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
    _TranslucencyViewDependency ("View dependency", Range(0,1)) = 0.7
    _ShadowStrength("Shadow Strength", Range(0,1)) = 0.8
   // _ShadowOffsetScale ("Shadow Offset Scale", Float) = 1
	
    _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
    //_ShadowTex ("Shadow (RGB)", 2D) = "white" {}
   // _BumpSpecMap ("Normalmap (GA) Spec (R) Shadow Offset (B)", 2D) = "bump" {}
   // _TranslucencyMap ("Trans (B) Gloss(A)", 2D) = "white" {}

    // These are here only to provide default values
    [HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
    [HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
    [HideInInspector] _SquashAmount ("Squash", Float) = 1
}

SubShader {
    Tags {
        "IgnoreProjector"="True"
        "RenderType"="TreeLeaf"
    }
    LOD 200

CGPROGRAM
#pragma surface surf TreeLeaf alphatest:_Cutoff vertex:TreeVertLeaf nolightmap noforwardadd
#pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS
//#include "UnityBuiltin3xTreeLibrary.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"

sampler2D _MainTex;
//sampler2D _BumpSpecMap;
//sampler2D _TranslucencyMap;

struct Input {
    float2 uv_MainTex;
    fixed4 color : COLOR; // color.a = AO
#if defined(BILLBOARD_FACE_CAMERA_POS)
    float4 screenPos;
#endif
};

struct LeafSurfaceOutput {
	fixed3 Albedo;
	fixed3 Normal;
	fixed3 Emission;
	fixed Translucency;
	half Specular;
	fixed Gloss;
	fixed Alpha;
};

UNITY_INSTANCING_BUFFER_START(Props)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
UNITY_DEFINE_INSTANCED_PROP(float, _SquashAmount)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _TreeInstanceScale)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _TreeInstanceColor)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _TranslucencyColor)
UNITY_DEFINE_INSTANCED_PROP(float, _TranslucencyViewDependency)
UNITY_DEFINE_INSTANCED_PROP(float, _ShadowStrength)

UNITY_INSTANCING_BUFFER_END(Props)

float ScreenDitherToAlpha(float x, float y, float c0)
{
#if (SHADER_TARGET > 30) || defined(SHADER_API_D3D11) || defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3)
	//dither matrix reference: https://en.wikipedia.org/wiki/Ordered_dithering
	const float dither[64] = {
		0, 32, 8, 40, 2, 34, 10, 42,
		48, 16, 56, 24, 50, 18, 58, 26 ,
		12, 44, 4, 36, 14, 46, 6, 38 ,
		60, 28, 52, 20, 62, 30, 54, 22,
		3, 35, 11, 43, 1, 33, 9, 41,
		51, 19, 59, 27, 49, 17, 57, 25,
		15, 47, 7, 39, 13, 45, 5, 37,
		63, 31, 55, 23, 61, 29, 53, 21 };

	int xMat = int(x) & 7;
	int yMat = int(y) & 7;

	float limit = (dither[yMat * 8 + xMat] + 11.0) / 64.0;
	//could also use saturate(step(0.995, c0) + limit*(c0));
	//original step(limit, c0 + 0.01);

	return lerp(limit*c0, 1.0, c0);
#else
	return 1.0;
#endif
}


inline half4 LightingTreeLeaf(LeafSurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
{
	half3 h = normalize(lightDir + viewDir);

	half nl = dot(s.Normal, lightDir);

	half nh = max(0, dot(s.Normal, h));
	half spec = pow(nh, s.Specular * 128.0) * s.Gloss;

	// view dependent back contribution for translucency
	fixed backContrib = saturate(dot(viewDir, -lightDir));

	// normally translucency is more like -nl, but looks better when it's view dependent
	backContrib = lerp(saturate(-nl), backContrib, UNITY_ACCESS_INSTANCED_PROP(Props, _TranslucencyViewDependency));

	fixed3 translucencyColor = backContrib * s.Translucency * UNITY_ACCESS_INSTANCED_PROP(Props, _TranslucencyColor);

	// wrap-around diffuse
	nl = max(0, nl * 0.6 + 0.4);

	fixed4 c;
	/////@TODO: what is is this multiply 2x here???
	c.rgb = s.Albedo * (translucencyColor * 2 + nl);
	c.rgb = c.rgb * _LightColor0.rgb + spec;

	// For directional lights, apply less shadow attenuation
	// based on shadow strength parameter.
#if defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
	c.rgb *= lerp(1, atten, UNITY_ACCESS_INSTANCED_PROP(Props, _ShadowStrength));
#else
	c.rgb *= atten;
#endif

	c.a = s.Alpha;

	return c;
}


float ComputeAlphaCoverage(float4 screenPos, float fadeAmount)
{
#if (SHADER_TARGET > 30) || defined(SHADER_API_D3D11) || defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3)
	float2 pixelPosition = screenPos.xy / (screenPos.w + 0.00001);
	pixelPosition *= _ScreenParams;
	float coverage = ScreenDitherToAlpha(pixelPosition.x, pixelPosition.y, fadeAmount);
	return coverage;
#else
	return 1.0;
#endif
}

// Expand billboard and modify normal + tangent to fit
inline void ExpandBillboard(in float4x4 mat, inout float4 pos, inout float3 normal, inout float4 tangent)
{
	// tangent.w = 0 if this is a billboard
	float isBillboard = 1.0f - abs(tangent.w);

	// billboard normal
	float3 norb = normalize(mul(float4(normal, 0), mat)).xyz;

	// billboard tangent
	float3 tanb = normalize(mul(float4(tangent.xyz, 0.0f), mat)).xyz;

	pos += mul(float4(normal.xy, 0, 0), mat) * isBillboard;
	normal = lerp(normal, norb, isBillboard);
	tangent = lerp(tangent, float4(tanb, -1.0f), isBillboard);
}
void TreeVertLeaf(inout appdata_full v)
{
	ExpandBillboard(UNITY_MATRIX_IT_MV, v.vertex, v.normal, v.tangent);
	v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceScale).xyz;
	//v.vertex = AnimateVertex(v.vertex, v.normal, float4(v.color.xy, v.texcoord1.xy));

	//v.vertex = Squash(v.vertex);

	v.color.rgb = UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).rgb * UNITY_ACCESS_INSTANCED_PROP(Props, _Color).rgb;
	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz);
}

void surf (Input IN, inout LeafSurfaceOutput o) {
    fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
    o.Albedo = c.rgb * IN.color.rgb * IN.color.a;

   // fixed4 trngls = tex2D (_TranslucencyMap, IN.uv_MainTex);
  //  o.Translucency = trngls.b;
  //  o.Gloss = trngls.a * _Color.r;
    o.Alpha = c.a;
#if defined(BILLBOARD_FACE_CAMERA_POS)
    float coverage = 1.0;
    if (UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).a < 1.0)
    {
        coverage = ComputeAlphaCoverage(IN.screenPos, UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).a);
    }
    o.Alpha *= coverage;
#endif
  //  half4 norspc = tex2D (_BumpSpecMap, IN.uv_MainTex);
  //  o.Specular = norspc.r;
   // o.Normal = UnpackNormalDXT5nm(norspc);
}
ENDCG

    // Pass to render object as a shadow caster
   /* Pass {
        Name "ShadowCaster"
        Tags { "LightMode" = "ShadowCaster" }

        CGPROGRAM
        #pragma vertex vert_surf
        #pragma fragment frag_surf
        #pragma multi_compile_shadowcaster
        #include "HLSLSupport.cginc"
        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        #define INTERNAL_DATA
        #define WorldReflectionVector(data,normal) data.worldRefl

        #include "UnityBuiltin3xTreeLibrary.cginc"

        sampler2D _MainTex;

        struct Input {
            float2 uv_MainTex;
        };

        struct v2f_surf {
            V2F_SHADOW_CASTER;
            float2 hip_pack0 : TEXCOORD1;
            UNITY_VERTEX_OUTPUT_STEREO
        };
        float4 _MainTex_ST;
        v2f_surf vert_surf (appdata_full v) {
            v2f_surf o;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            TreeVertLeaf (v);
            o.hip_pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
            TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
            return o;
        }
        fixed _Cutoff;
        float4 frag_surf (v2f_surf IN) : SV_Target {
            half alpha = tex2D(_MainTex, IN.hip_pack0.xy).a;
            clip (alpha - _Cutoff);
            SHADOW_CASTER_FRAGMENT(IN)
        }
        ENDCG
    }*/

}

Dependency "BillboardShader" = "Hidden/Nature/Tree Creator Leaves Rendertex"
}
