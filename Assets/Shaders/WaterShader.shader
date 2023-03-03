﻿Shader "Tecnocampus/WaterShader"
{
	Properties
	{
		_MainTex("_MainTex", 2D) = " " {}
		_WaterDepthTex("_WaterDepthTex", 2D) = " " {}
		_FoamTex("_FoamTex", 2D) = " " {}
		_NoiseTex("_NoiseTex", 2D) = "Noise texture" {}
		_WaterHeightMapTex("_WaterHeightMapTex", 2D) = " " {}

		_DeepWaterColor("_DeepWaterColor", Color) = (1, 1, 0, 0) //R: 46, G: 54, B: 183, A: 246
		_WaterColor("_WaterColor", Color) = (1, 1, 0, 0) //R: 71, G: 83, B: 255, A: 237

		_SpeedWater1("_SpeedWater1", Float) = 0.05
		_DirectionWater1("_DirectionWater1", Vector) = (0.3, -0.1, 1.0, 1.0)
		_SpeedWater2("_SpeedWater2", Float) = 0.01
		_DirectionWater2("_DirectionWater2", Vector) = (-0.4, 0.02, 1.0, 1.0)
		
		_DirectionNoise("_DirectionNoise", Vector) = (-0.18, 0.3, 1.0, 1.0)

		_FoamDistance("_FoamDistance", Range(0.0, 1.0)) = 0.5
		_SpeedFoam("_SpeedFoam", Float) = 0.03
		_DirectionFoam("_DirectionFoam", Vector) = (1.5, 0, -0.3, 0.4)
		
		_FoamMultiplier("_FoamMultiplier", Range(0.0, 5.0)) = 2.5
		_MaxHeightWater("_MaxHeightWater", Float) = 0.02
		_WaterDirection("_WaterDirection", Vector) = (0.01, 0, -0.005, 0.03)
		
		_Cutoff("_Cutoff", Range(0.0, 1.0)) = 0.5
		//_Seed("_Seed", Float) = 500.0
		//_NoiseAmmount("_NoiseAmmount", Range(0.0, 1.0)) = 0.001
	}
	SubShader
	{
		//Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
		Tags{ "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			//ZWrite Off

			CGPROGRAM
			#pragma vertex MyVS
			#pragma fragment MyPS

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaterDepthTex;
			float4 _WaterDepthTex_ST;
			sampler2D _FoamTex;
			float4 _FoamTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			sampler2D _WaterHeightMapTex;
			float4 _WaterHeightMapTex_ST;

			float4 _DeepWaterColor;
			float4 _WaterColor;
			
			float _SpeedWater1;
			float4 _DirectionWater1;
			
			float _SpeedWater2;
			float4 _DirectionWater2;
			
			float4 _DirectionNoise;

			float _FoamDistance;
			float _SpeedFoam;
			float4 _DirectionFoam;

			float _FoamMultiplier;
			float _MaxHeightWater;
			float4 _WaterDirection;

			float _Cutoff;
			//float _Seed;
			//float _NoiseAmmount;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 waterUV1 : TEXCOORD1;
				float2 waterUV2 : TEXCOORD2;
				float2 depthUV: TEXCOORD3;
				float2 heightUV: TEXCOORD4;
				float2 foamUV: TEXCOORD5;
				float2 noiseUV: TEXCOORD6;
			};
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 waterUV1 : TEXCOORD1;
				float2 waterUV2 : TEXCOORD2;
				float2 depthUV: TEXCOORD3;
				float2 heightUV: TEXCOORD4;
				float2 foamUV: TEXCOORD5;
				float2 noiseUV: TEXCOORD6;
			};
			

			v2f MyVS(appdata v)
			{
				v2f o;
			
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
				
				/////////////////FROM HERE/////////////////////
				v.waterUV1 = v.uv;
				v.waterUV2 = v.uv;

				v.depthUV = v.uv;

				v.foamUV = v.uv;
				v.noiseUV = v.uv;

				//This one controls the x movement --> Dunno if it should work like this ????
				float3 l_WaterDirection = _DirectionWater1.x * cos(v.uv.x * _DirectionWater1.y + _Time.y * _SpeedWater1) - _DirectionWater1.x * sin(_Time.y * _SpeedWater1);
				v.waterUV1 += l_WaterDirection;

				//This one controls the y movement --> Dunno if it should work like this ????
				float3 l_WaterDirection2 = _DirectionWater2.x * sin(v.uv.y * _DirectionWater2.y + _Time.y * _SpeedWater1)  - _DirectionWater2.x * cos(_Time.y * _SpeedWater2);
				v.waterUV2 -= l_WaterDirection2;
				
				//float3 l_FoamDirection = _DirectionFoam.x * cos(v.uv.y * _DirectionFoam.z + _Time.y * _SpeedFoam);
				float3 l_FoamDirection = _DirectionFoam.x * _Time.y * _SpeedFoam;
				v.foamUV += l_FoamDirection;
				
				//float3 l_NoiseDirection = _DirectionFoam.z * cos(v.uv.y * _DirectionFoam.w + _Time.y * _SpeedFoam);
				float3 l_NoiseDirection = _DirectionFoam.x * _Time.y * _SpeedFoam;
				v.noiseUV += l_NoiseDirection;

				float3 l_WaterHeightDirection1 =_WaterDirection.x * _Time.y;
				float3 l_WaterHeightDirection2 =_WaterDirection.z * _Time.y;
				v.heightUV += l_WaterHeightDirection1 + l_WaterHeightDirection2;

				float l_HeightNormalized = tex2Dlod(_WaterHeightMapTex, float4(v.heightUV, 0, 0)).x;
				float l_Height = l_HeightNormalized *_MaxHeightWater;
				o.vertex.y += l_Height;

				/////////////////TO HERE IT'S TEST/////////////////////
				o.vertex = mul(UNITY_MATRIX_V, o.vertex);
				o.vertex = mul(UNITY_MATRIX_P, o.vertex);
				
				o.uv = o.vertex;

				o.waterUV1 = TRANSFORM_TEX(v.waterUV1, _MainTex);
				o.waterUV2 = TRANSFORM_TEX(v.waterUV2, _MainTex);
				o.depthUV = TRANSFORM_TEX(v.depthUV, _WaterDepthTex);
				o.foamUV = TRANSFORM_TEX(v.foamUV, _FoamTex);
				o.noiseUV = TRANSFORM_TEX(v.noiseUV, _NoiseTex);

				return o;
			}

			fixed4 MyPS(v2f i) : SV_Target
			{
				float4 l_MainTex1 = tex2D(_MainTex, i.waterUV1);
				float4 l_MainTex2 = tex2D(_MainTex, i.waterUV2);
				float4 l_MainTex = l_MainTex1 * l_MainTex2;

				float4 l_DepthTex = tex2D(_WaterDepthTex, i.depthUV);
				float4 l_DeepWaterColor = _DeepWaterColor; //black texture
				float4 l_WaterColor = _WaterColor; //white texture
				float4 l_FinalWaterColor = float4((l_DeepWaterColor.xyz * (1.0 - l_DepthTex)) + (l_WaterColor.xyz * l_DepthTex), 1.0);

				float4 l_FoamTex = tex2D(_FoamTex, i.foamUV);
				float4 l_Noise = tex2D(_NoiseTex, i.noiseUV);

				//if (l_DepthTex.x < _FoamDistance)
				//{
					//l_FoamTex = float4((l_DepthTex.xyz * l_FoamTex.xyz), 1.0);

					
					//float NoiseX = _Seed * _Time.y * sin(i.noiseUV.x * i.noiseUV.y + _Time.y);
					//float NoiseY = _Seed * _Time.y * sin(i.noiseUV.x * i.noiseUV.y + _Time.y);
					//NoiseX = fmod(NoiseX, 8) * fmod(NoiseX, 4);
					//float DistortX = fmod(NoiseX, _NoiseAmmount);
					//float DistortY = fmod(NoiseY, _NoiseAmmount + 0.002);
					//float2 l_UV = i.noiseUV + float2(DistortX, DistortY);

					//float4 l_Noise = tex2D(_NoiseTex, l_UV);
				
					
					l_FoamTex = float4((l_FoamTex.xyz * (1.0 - l_DepthTex) * (l_FoamTex * l_DepthTex)), 1.0);
					l_Noise = l_Noise > _FoamDistance ? (l_Noise - _FoamDistance) / (1.0 - _FoamDistance) : 0;
					//l_FoamTex = (l_FoamTex - _FoamDistance) > l_FoamTex ? float4(l_Noise.xxx, 0) * _FoamMultiplier : 0;
					l_FoamTex *= float4(l_Noise.xxx, 0) * _FoamMultiplier;

					l_MainTex = l_MainTex + l_FoamTex;
					//clip(l_FoamTex - _Cutoff);
				//}

				//return l_MainTex;
				//return float4(0,0,1, 0.6) + l_MainTex2;
				//return (l_MainTex1 * l_MainTex2) + float4((l_DeepWaterColor.xyz * (1.0 - l_DepthTex)) + (l_WaterColor.xyz * l_DepthTex), 1.0) + l_FoamTex;
				//return float4((l_DeepWaterColor.xyz * (1.0 - l_DepthTex)) + (l_WaterColor.xyz * l_DepthTex), 1.0);
				//return l_MainTex + float4((l_DeepWaterColor.xyz * (1.0 - l_DepthTex)) + (l_WaterColor.xyz * l_DepthTex), 1.0);
				return l_MainTex + l_FinalWaterColor;
				//return float4((l_FoamTex.xyz * (1.0 - l_DepthTex))	, 1.0);
				//return l_FoamTex;
			}
			ENDCG
		}
	}
}
