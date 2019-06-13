// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Smkgames/SimpleSurface" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _GlossMap("GlossMap",2D) = "white"{}
        _Glossiness ("Smoothness", Float) = 1.5
        _Metallic ("Metallic", Float) = 0.5
        _MetallicMap("MetallicMap",2D) = "white"{}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        sampler2D _MainTex;

        struct Input {
            float2 uv_MainTex;
        };

        half _Glossiness,_Metallic;
        fixed4 _Color;
        sampler2D _GlossMap,_MetallicMap;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o) {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic*tex2D(_MetallicMap,IN.uv_MainTex);
            o.Smoothness = _Glossiness*tex2D(_GlossMap,IN.uv_MainTex);
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}