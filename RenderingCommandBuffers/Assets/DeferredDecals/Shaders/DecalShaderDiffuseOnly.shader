﻿// http://www.popekim.com/2012/10/siggraph-2012-screen-space-decals-in.html

Shader "Decal/DecalShader"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Diffuse", 2D) = "white" {}

        [Header(Dissolve)]
        _DissolveTex ("Dissolve Texture (R)", 2D) = "black" {}
        _DissolveAmount ("Dissolve Amount", Range(0, 1)) = 0.5

        [Header(Edges)]
        [HDR]_EdgeColor ("Color", Color) = (1,1,1,1)
        _EdgeRange ("Range", Range(0, 0.3)) = 0.1
        _EdgeFalloff ("Falloff", Range(0.001, 0.3)) = 0.1
	}
	SubShader
	{
		Pass
		{
			Fog { Mode Off } // no fog in g-buffers pass
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers nomrt
			
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				float4 screenUV : TEXCOORD1;
				float3 ray : TEXCOORD2;
				half3 orientation : TEXCOORD3;
			};

			float4 _DissolveTex_ST;

			v2f vert (float3 v : POSITION)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (float4(v,1));
				o.uv = v.xz+0.5;
				o.screenUV = ComputeScreenPos (o.pos);
				o.ray = mul (UNITY_MATRIX_MV, float4(v,1)).xyz * float3(-1,-1,1);
				o.orientation = mul ((float3x3)unity_ObjectToWorld, float3(0,1,0));
				return o;
			}

			CBUFFER_START(UnityPerCamera2)
			// float4x4 _CameraToWorld;
			CBUFFER_END

			sampler2D _MainTex;
			fixed4 _Color;
			sampler2D_float _CameraDepthTexture;
			sampler2D _NormalsCopy;

			sampler2D _DissolveTex;
			float _DissolveAmount;

			float3 _EdgeColor;
			float _EdgeRange;
			float _EdgeFalloff;

			//void frag(
			//	v2f i,
			//	out half4 outDiffuse : COLOR0,			// RT0: diffuse color (rgb), --unused-- (a)
			//	out half4 outSpecRoughness : COLOR1,	// RT1: spec color (rgb), roughness (a)
			//	out half4 outNormal : COLOR2,			// RT2: normal (rgb), --unused-- (a)
			//	out half4 outEmission : COLOR3			// RT3: emission (rgb), --unused-- (a)
			//)
			fixed4 frag(v2f i) : SV_TARGET
			{
				//==== Decal effect ====//
				i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
				float2 uv = i.screenUV.xy / i.screenUV.w;
				// read depth and reconstruct world position
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = Linear01Depth (depth);
				float4 vpos = float4(i.ray * depth,1);
				float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
				float3 opos = mul (unity_WorldToObject, float4(wpos,1)).xyz;

				clip (float3(0.5,0.5,0.5) - abs(opos.xyz));


				i.uv = opos.xz+0.5;

				half3 normal = tex2D(_NormalsCopy, uv).rgb;
				fixed3 wnormal = normal.rgb * 2.0 - 1.0;
				clip (dot(wnormal, i.orientation) - 0.3);

				//==== Dissolve effect ====//
				float dissolve = tex2D(_DissolveTex, i.uv).r;
				dissolve = dissolve * 0.999; //make whites be a bit less than 1 so it can be cliped as well
				float isVisible = dissolve - _DissolveAmount;
				clip(isVisible);

				//Edges
				float isEdge = smoothstep(_EdgeRange + _EdgeFalloff, _EdgeRange, isVisible);
				float4 edge = isEdge == 0 ? 1 : float4(_EdgeColor * isEdge, 1); //if condition so that section that is not on the edge does not blend with edge color


				fixed4 col = tex2D (_MainTex, i.uv) * edge;
				return col;
			}
			ENDCG
		}		

	}

	Fallback Off
}
