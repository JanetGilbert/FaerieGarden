// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Messed about with by Janet to make batching work (by cannibalizsing the Terrain library code)
Shader "Custom/Nature/Janet's Tree Creator Bark" {
Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    [PowerSlider(5.0)] _Shininess ("Shininess", Range (0.01, 1)) = 0.078125
    _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
   // _BumpMap ("Normalmap", 2D) = "bump" {}
  //  _GlossMap ("Gloss (A)", 2D) = "black" {}

    // These are here only to provide default values
    _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
    [HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
    [HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
    [HideInInspector] _SquashAmount ("Squash", Float) = 1
}

SubShader {
    Tags { "IgnoreProjector"="True" "RenderType"="TreeBark" }
    LOD 200

CGPROGRAM
#pragma surface surf BlinnPhong vertex:TreeVertBark addshadow nolightmap
//#include "UnityBuiltin3xTreeLibrary.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"
//#include "TerrainEngine.cginc"

sampler2D _MainTex;
//sampler2D _BumpMap;
//sampler2D _GlossMap;
half _Shininess;


UNITY_INSTANCING_BUFFER_START(Props)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _TreeInstanceScale)
UNITY_DEFINE_INSTANCED_PROP(fixed4, _TreeInstanceColor)
UNITY_DEFINE_INSTANCED_PROP(float, _SquashAmount)
UNITY_INSTANCING_BUFFER_END(Props)

// From TerrainEngine.cginc
float4 SmoothCurve(float4 x) {
	return x * x *(3.0 - 2.0 * x);
}
float4 TriangleWave(float4 x) {
	return abs(frac(x + 0.5) * 2.0 - 1.0);
}
float4 SmoothTriangleWave(float4 x) {
	return SmoothCurve(TriangleWave(x));
}

// Detail bending
inline float4 AnimateVertex(float4 pos, float3 normal, float4 animParams)
{
	// animParams stored in color
	// animParams.x = branch phase
	// animParams.y = edge flutter factor
	// animParams.z = primary factor
	// animParams.w = secondary factor

	float fDetailAmp = 0.1f;
	float fBranchAmp = 0.3f;

	// Phases (object, vertex, branch)
	float fObjPhase = dot(unity_ObjectToWorld._14_24_34, 1);
	float fBranchPhase = fObjPhase + animParams.x;

	float fVtxPhase = dot(pos.xyz, animParams.y + fBranchPhase);

	// x is used for edges; y is used for branches
	float2 vWavesIn = _Time.yy + float2(fVtxPhase, fBranchPhase);

	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac(vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193)) * 2.0 - 1.0);

	vWaves = SmoothTriangleWave(vWaves);
	float2 vWavesSum = vWaves.xz + vWaves.yw;

	// Edge (xz) and branch bending (y)
	float3 bend = animParams.y * fDetailAmp * normal.xyz;
	bend.y = animParams.w * fBranchAmp;
	//janet no wind pos.xyz += ((vWavesSum.xyx * bend) + (_Wind.xyz * vWavesSum.y * animParams.w)) * _Wind.w;

	// Primary bending
	// Displace position
	pos.xyz += animParams.z;// janet no wind *_Wind.xyz;

	return pos;
}



// From UnityBuiltin3xTreeLibrary.cginc
void TreeVertBark(inout appdata_full v)
{
	v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceScale).xyz;
	v.vertex = AnimateVertex(v.vertex, v.normal, float4(v.color.xy, v.texcoord1.xy));

	//janet no squash v.vertex = Squash(v.vertex);

	v.color.rgb = UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).rgb * UNITY_ACCESS_INSTANCED_PROP(Props, _Color).rgb;
	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz);
}


struct Input {
    float2 uv_MainTex;
    fixed4 color : COLOR;
};


void surf (Input IN, inout SurfaceOutput o) {
    fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
    o.Albedo = c.rgb * IN.color.rgb * IN.color.a;
   // o.Gloss = tex2D(_GlossMap, IN.uv_MainTex).a;
    o.Alpha = c.a;
    o.Specular = _Shininess;
  //  o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
}
ENDCG
}

Dependency "OptimizedShader" = "Hidden/Nature/Tree Creator Bark Optimized"
FallBack "Diffuse"
}
