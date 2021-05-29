Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal map", 2D) = "bump" {}
		_OverlayMap("Overlay (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_NormalSpeed("FlowSpeed", Range(0,1)) = 0.1
		_OscillateSpeed("OscillateSpeed", Range(0,0.1)) = 0.01
		_Extrude("ExtrudeAmount", Range(0,1)) = 0.5
    }
    SubShader
    {
		Tags {"Queue" = "Transparent"  "RenderType" = "Transparent" } // Transparency
		Blend SrcAlpha OneMinusSrcAlpha // Transparent blending
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:fade vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _OverlayTex;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_NormalMap;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		half _NormalSpeed;
		half _OscillateSpeed;
		half _Extrude;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v) {
			// Waves wash in and out
			/*float3 p = v.vertex.xyz;
			p.y = sin(p.x) * _SinTime.w;
			v.vertex.xyz = p;*/
			//v.vertex.xyz += v.normal * tex2Dlod(_NormalMap, float4(v.texcoord.xy, 0, 0)).r * _Extrude;
		//	v.vertex.y += tex2Dlod(_NormalMap, float4(v.texcoord.xy, 0, 0)).rg * _Extrude * _SinTime.w;
			v.vertex.y += tex2Dlod(_NormalMap, float4(0, v.texcoord.x + v.texcoord.y, 0, 0)).r * _Extrude * (sin(_SinTime.y) - 0.5f);

		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float oscillate = (sin(_SinTime.w) - 0.5f) * _OscillateSpeed;
			float oscillate2 = (sin(_SinTime.z + 0.5f) - 0.5f) * _OscillateSpeed;
			float2 mainTexScrollUV = IN.uv_MainTex + fixed2(oscillate, oscillate);
			float2 mainTexScrollUV2 = IN.uv_MainTex - fixed2(oscillate2, oscillate2);

			//fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            fixed4 c = tex2D(_MainTex, mainTexScrollUV) * tex2D(_OverlayTex, mainTexScrollUV2) * _Color;

			float2 uvScrollNormal = IN.uv_NormalMap + fixed2(oscillate, oscillate);
	//		float2 uvScrollNormal = IN.uv_NormalMap;
			//o.Normal = UnpackNormal(tex2D(_NormalMap, uvScrollNormal)) * 10.0f;
            o.Albedo = c.rgb;

            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
