// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// http://www.popekim.com/2012/10/siggraph-2012-screen-space-decals-in.html

Shader "Decal/DecalShader Diffuse+Normals"
{
	Properties
	{
		_MainTex ("Diffuse", 2D) = "white" {}
		_BumpMap ("Normals", 2D) = "bump" {}

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
			//Blend SrcAlpha OneMinusSrcAlpha

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
				half3 orientationX : TEXCOORD4;
				half3 orientationZ : TEXCOORD5;
			};

			v2f vert (float3 v : POSITION)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (float4(v,1));
				o.uv = v.xz+0.5;
				o.screenUV = ComputeScreenPos (o.pos);
				o.ray = mul (UNITY_MATRIX_MV, float4(v,1)).xyz * float3(-1,-1,1);
				o.orientation = mul ((float3x3)unity_ObjectToWorld, float3(0,1,0));
				o.orientationX = mul ((float3x3)unity_ObjectToWorld, float3(1,0,0));
				o.orientationZ = mul ((float3x3)unity_ObjectToWorld, float3(0,0,1));
				return o;
			}

			CBUFFER_START(UnityPerCamera2)
			// float4x4 _CameraToWorld;
			CBUFFER_END

			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D_float _CameraDepthTexture;
			sampler2D _NormalsCopy;

			sampler2D _DissolveTex;
			float _DissolveAmount;

			float3 _EdgeColor;
			float _EdgeRange;
			float _EdgeFalloff;

			void frag(v2f i, out half4 outDiffuse : COLOR0, out half4 outNormal : COLOR1)
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
				clip (col.a - 0.2);
				outDiffuse = col;

				fixed3 nor = UnpackNormal(tex2D(_BumpMap, i.uv));
				half3x3 norMat = half3x3(i.orientationX, i.orientationZ, i.orientation);
				nor = mul (nor, norMat);
				outNormal = fixed4(nor*0.5+0.5,1);

			}
			ENDCG
		}		

	}

	Fallback Off
}
