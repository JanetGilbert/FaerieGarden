Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal map", 2D) = "bump" {}
		_WaveMap("Wave map", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_FlowSpeed("FlowSpeed", Range(0,1)) = 0.1
		_WaveHeight("WaveHeight", Range(0,1)) = 0.5
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
		sampler2D _WaveMap;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_NormalMap;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		half _FlowSpeed;
		half _WaveHeight;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v) {
			// Waves wash in and out
			float variation = tex2Dlod(_WaveMap, float4(0, v.texcoord.x + v.texcoord.y, 0, 0)).r;

			v.vertex.y += _WaveHeight * (sin(_Time.y * variation) - 0.5);
			
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float oscillate = (_SinTime.y - 0.5f) * _FlowSpeed;
			float2 mainTexScrollUV = IN.uv_MainTex + fixed2(oscillate, oscillate);
            fixed4 c = tex2D(_MainTex, mainTexScrollUV) * _Color;
			float2 uvScrollNormal = IN.uv_NormalMap + fixed2(oscillate, oscillate);

			o.Normal = UnpackNormal(tex2D(_NormalMap, uvScrollNormal));
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
