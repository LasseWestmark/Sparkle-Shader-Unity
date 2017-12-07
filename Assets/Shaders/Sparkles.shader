Shader "Westmark/Sparkles"
{
	Properties
	{
        [Header(Sparkles)]
		_SparkleDepth ("Sparkle Depth", Range (0, 5)) = 1
		_NoiseScale ("noise Scale", Range (0, 5)) = 1
		_AnimSpeed ("Animation Speed", Range (0, 5)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 100

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Simplex3D.cginc"
			#include "SparklesCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 wPos : TEXCOORD1;
				float3 pos : TEXCOORD3;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color, _SpecColor;
			float _SpecPow, _GlitterPow;

			v2f vert (appdata v)
			{
				v2f o;
				
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = v.vertex;
				o.normal = mul(unity_ObjectToWorld, float4(v.normal,0)).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//Sparkles
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.wPos));
				float sparkles = Sparkles(viewDir,i.wPos);

				return sparkles;
			}
			ENDCG
		}
	}
}