Shader "Westmark/GlassSparkles"
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
		[Header(Reflection and Refraction)]
		_ReflId ("Reflection Index", Range (1, 5)) = 1
		_RefrId ("Refraction Index", Range (1, 5)) = 1
		_ReflRoughness ("Reflection Roughness", Range (0, 9)) = 0
		_RefrRoughness ("Refraction Roughness", Range (0, 9)) = 0
		[Toggle(USE_CUBE_REFRACTION)]
        _UseCubeRefr ("Use Refraction Probe", Float) = 0
        [Header(Sparkles)]
		_SparkleDepth ("Sparkle Depth", Range (0, 5)) = 1
		_NoiseScale ("noise Scale", Range (0, 5)) = 1
		_AnimSpeed ("Animation Speed", Range (0, 5)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		GrabPass 
		{
			"_BackgroundTexture"
		}

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature USE_CUBE_REFRACTION
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
				float4 grabPos : TEXCOORD4;
				float4 scrPos : TEXCOORD5;
			};

			sampler2D _MainTex;
			sampler2D _BackgroundTexture;
			float4 _MainTex_ST;
			float4 _Color, _SpecColor;
			float _SpecPow, _GlitterPow, _ReflId, _RefrId, _ReflRoughness, _RefrRoughness;
			
			v2f vert (appdata v)
			{
				v2f o;
				
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = v.vertex;
				o.normal = mul(unity_ObjectToWorld, float4(v.normal,0)).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);// + v.normal * snoise(o.wPos * .03 + _Time.y*.5) * .05);
				o.grabPos = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex*-5));
				o.scrPos = o.vertex;
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
				lightDirection = normalize( _WorldSpaceLightPos0.xyz );
				float diffuse = max( 0.0, dot(normal, lightDirection) * .5 + .5);
				float specular = saturate(dot(reflDir, lightDirection));				
				float glitterSpecular = pow(specular,_GlitterPow);
				specular = pow(specular,_SpecPow);

				//Rim
				float rim = 1-saturate(dot(viewDir, normal));
				rim = pow(rim, _ReflId);

				//Sample reflection cube
				half4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, _ReflRoughness);
                half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR) * (1+diffuse);

                half3 refrColor;
                //Decide whether to use grabpass(inaccurate) or a cube map(can be realtime too) for refractions
                #ifdef USE_CUBE_REFRACTION
                //Refraction based on cubemap
                	//Calculate refraction direction
		            float3 refrDir = refract( viewDir, normal, 1/_RefrId );
		            //Sample refraction cube
					half4 refrData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, refrDir,_RefrRoughness);
		            refrColor = DecodeHDR (refrData, unity_SpecCube0_HDR);
                #else
				//Refraction calculation based on GrabPass
		            //Get screenspace uv for GrabPass
					float4 screenPos = i.grabPos;
					//Create lookup offset based on viewspace normals
					float2 offset = normalize(mul(UNITY_MATRIX_V,float4(normal, 0))).xy * _RefrId * 10;
					//Make sure the offset is in square aspect
					offset.x *= _ScreenParams.y/_ScreenParams.x;
					//Apply offset
					screenPos.xy += offset;
					//Sample GrabPass
					refrColor = tex2Dproj(_BackgroundTexture, screenPos).rgb;
				#endif

				//Sparkles
				float sparkles = Sparkles(viewDir,i.wPos);

				//Sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				//Apply refractions
				col.rgb *= refrColor.rgb;
				//Apply reflections
				col.rgb =  lerp(skyColor * _SpecColor, col, 1-rim);
				//Apply Specular and sparkles
				col += _SpecColor * (saturate(sparkles * glitterSpecular * 5) + specular);
				//Apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				
				return col;
			}
			ENDCG
		}
	}
}