Shader "Test/Dissolve Shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        [HDR]_Emission ("Emission", color) = (0,0,0)

        [Header(Dissolve)]
        _DissolveTex ("Dissolve Texture (R)", 2D) = "black" {}
        _DissolveAmount ("Dissolve Amount", Range(0, 1)) = 0.5

        [Header(Glow)]
        [HDR]_GlowColor ("Color", Color) = (1,1,1,1)
        _GlowRange ("Range", Range(0, 0.3)) = 0.1
        _GlowFalloff ("Falloff", Range(0.001, 0.3)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        fixed4 _Color;

        sampler2D _DissolveTex;
        float _DissolveAmount;

        half _Glossiness;
        half _Metallic;
        half3 _Emission;

        float3 _GlowColor;
        float _GlowRange;
        float _GlowFalloff;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_DissolveTex;
        };      

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float dissolve = tex2D(_DissolveTex, IN.uv_DissolveTex).r;
            dissolve = dissolve * 0.999; //make whites be a bit less than 1 so it can be cliped as well
            float isVisible = dissolve - _DissolveAmount;
            clip(isVisible);

            //Glowing edges
            float isGlowing = smoothstep(_GlowRange + _GlowFalloff, _GlowRange, isVisible);
            float3 glow = _GlowColor * isGlowing;

            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
    
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = _Emission + glow; 
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
