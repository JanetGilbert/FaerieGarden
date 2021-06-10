// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/Nature/Tree Creator Bark Optimized" {
Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
  //  _BumpSpecMap ("Normalmap (GA) Spec (R)", 2D) = "bump" {}
   // _TranslucencyMap ("Trans (RGB) Gloss(A)", 2D) = "white" {}
   // _Cutoff("Alpha cutoff", Range(0,1)) = 0.3

    // These are here only to provide default values
   // _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
    [HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
   [HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
    //[HideInInspector] _SquashAmount ("Squash", Float) = 1
}

SubShader {
    Tags { "IgnoreProjector"="True" "RenderType"="TreeBark" }
    LOD 200

CGPROGRAM
#pragma surface surf BlinnPhong vertex:TreeVertBark addshadow nolightmap
#pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS
//#include "UnityBuiltin3xTreeLibrary.cginc"
//#include "TerrainEngine.cginc"
sampler2D _MainTex;
//sampler2D _BumpSpecMap;
//sampler2D _TranslucencyMap;


struct Input {
    float2 uv_MainTex;
    fixed4 color : COLOR;
#if defined(BILLBOARD_FACE_CAMERA_POS)
    float4 screenPos;
#endif
};

UNITY_INSTANCING_BUFFER_START(Props)
	UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
	UNITY_DEFINE_INSTANCED_PROP(fixed4, _TreeInstanceScale)
	UNITY_DEFINE_INSTANCED_PROP(fixed4, _TreeInstanceColor)
UNITY_INSTANCING_BUFFER_END(Props)

// From UnityBuiltin3xTreeLibrary.cginc

void TreeVertBark(inout appdata_full v)
{
	v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceScale).xyz;
//	v.vertex = AnimateVertex(v.vertex, v.normal, float4(v.color.xy, v.texcoord1.xy));

//	v.vertex = Squash(v.vertex);

	fixed4 accessColor = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

	v.color.rgb = UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).rgb * accessColor.rgb;
	v.normal = normalize(v.normal);
	v.tangent.xyz = normalize(v.tangent.xyz);
}

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
/*
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
}*/

void surf (Input IN, inout SurfaceOutput o) {
    fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
    o.Albedo = c.rgb * IN.color.rgb * IN.color.a;

    //fixed4 trngls = tex2D (_TranslucencyMap, IN.uv_MainTex);
    //o.Gloss = trngls.a * _Color.r;
    o.Alpha = c.a;
/*#if defined(BILLBOARD_FACE_CAMERA_POS)
    float coverage = 1.0;
    if (_TreeInstanceColor.a < 1.0)
        coverage = ComputeAlphaCoverage(IN.screenPos, _TreeInstanceColor.a);
    o.Alpha *= coverage;
#endif*/
    //half4 norspc = tex2D (_BumpSpecMap, IN.uv_MainTex);
   // o.Specular = norspc.r;
  //  o.Normal = UnpackNormalDXT5nm(norspc);
}
ENDCG
}

Dependency "BillboardShader" = "Hidden/Nature/Tree Creator Bark Rendertex"
}
