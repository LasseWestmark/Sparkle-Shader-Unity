float _NoiseScale;
float _AnimSpeed;
float _SparkleDepth;
float Sparkles(float3 viewDir, float3 wPos)
{
	float noiseScale = _NoiseScale * 10;
	float sparkles = snoise(wPos * noiseScale + viewDir * _SparkleDepth - _Time.x * _AnimSpeed) * snoise(wPos * noiseScale + _Time.x * _AnimSpeed);
	sparkles = smoothstep(.5,.6, sparkles);
	return sparkles;
}