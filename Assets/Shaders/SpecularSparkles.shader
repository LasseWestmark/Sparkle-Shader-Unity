Shader "Westmark/SpecularSparkles"
{
	Properties
	{
		[Header(Colors)]
		_Color ("Color", Color) = (.5,.5,.5,1)
		_SpecColor ("Specular Color", Color) = (.5,.5,.5,1)
		_MainTex ("Texture", 2D) = "white" {}
		[Header(Specular)]
		_SpecPow ("Specular Power", Range (1, 50)) = 24
		_GlitterPow ("Glitter Power", Range (1, 50)) = 5
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
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Simplex3D.cginc"

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
			float _SparkleDepth, _NoiseScale, _AnimSpeed, _SpecPow, _GlitterPow;

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
				//Light Calculation
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.wPos));
				float3 reflDir = reflect(-viewDir, normal);
				float3 lightDirection;
				float atten = 1.0;
				lightDirection = normalize( -_WorldSpaceLightPos0.xyz );
				float diffuse = max( 0.0, dot(normal, lightDirection) * .5 + .5);
				float specular = saturate(dot(reflDir, lightDirection));				
				float glitterSpecular = pow(specular,_GlitterPow);
				specular = pow(specular,_SpecPow);

				//Sparkles
				float noiseScale = _NoiseScale;
				float noise = snoise(i.wPos * noiseScale + viewDir * _SparkleDepth - _Time.x * _AnimSpeed) * snoise(i.wPos * noiseScale + _Time.x * _AnimSpeed);
				noise = smoothstep(.5,.6, noise);

				//Sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * _Color * diffuse;
				//Apply Specular and sparkles
				col += _SpecColor * (saturate(noise * glitterSpecular * 5) + specular);
				//Apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				
				return col;
			}
			ENDCG
		}
	}
}