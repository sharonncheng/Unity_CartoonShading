#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// @Cyanilux | https://github.com/Cyanilux/URP_ShaderGraphCustomLighting

void MainLight_float(float3 WorldPos, out float3 Direction, out float3 Color, out float DistanceAtten, out float ShadowAtten) {
#ifdef SHADERGRAPH_PREVIEW
	Direction = normalize(float3(1, 1, -0.4));
	Color = float4(1, 1, 1, 1);
	DistanceAtten = 1;
	ShadowAtten = 1;
#else
	Light mainLight = GetMainLight();
	Direction = mainLight.direction;
	Color = mainLight.color;
	DistanceAtten = mainLight.distanceAttenuation;
	
	float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
	ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
	half4 shadowParams = GetMainLightShadowParams();
	ShadowAtten = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
#endif
}

void AdditionalLights_float(float3 SpecColor, float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView,
	out float3 Diffuse, out float3 Specular) {
	float3 diffuseColor = 0;
	float3 specularColor = 0;
	float shadowAtten = 1;	

#ifndef SHADERGRAPH_PREVIEW
	Smoothness = exp2(10 * Smoothness + 1);
	WorldNormal = normalize(WorldNormal);
	WorldView = SafeNormalize(WorldView);
	int pixelLightCount = GetAdditionalLightsCount();
	for (int i = 0; i < pixelLightCount; ++i) {
		Light light = GetAdditionalLight(i, WorldPosition);
		float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);		

		//@Yu-Wei Chang 增加可接收 Spot & Point Light 的即時陰影
		ShadowSamplingData shadowSamplingData = GetAdditionalLightShadowSamplingData();
		half4 shadowParams = GetAdditionalLightShadowParams(i);
		float shadowSliceIndex = shadowParams.w;
		if (shadowSliceIndex < 0)
			shadowAtten *= 1;
		half isPointLight = shadowParams.z;
		if (isPointLight)
		{
			// This is a point light, we have to find out which shadow slice to sample from
			float cubemapFaceId = CubeMapFaceID(-light.direction);
			shadowSliceIndex += cubemapFaceId;
		}		
		float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[shadowSliceIndex], float4(WorldPosition, 1.0));
		shadowAtten = SampleShadowmap(TEXTURE2D_ARGS(_AdditionalLightsShadowmapTexture, sampler_AdditionalLightsShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, true);
		
		diffuseColor += LightingLambert(attenuatedLightColor, light.direction, WorldNormal) * shadowAtten;
		specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, float4(SpecColor, 0), Smoothness) * shadowAtten;
	}
#endif

	Diffuse = diffuseColor;
	Specular = specularColor;
}


void AmbientSampleSH_float (float3 WorldNormal, out float3 Ambient){
	#ifdef SHADERGRAPH_PREVIEW
		Ambient = float3(0.1, 0.1, 0.1); // Default ambient colour for previews
	#else
		Ambient = SampleSH(WorldNormal);
	#endif
}

void MixFog_float (float3 Colour, float Fog, out float3 Out){
	#ifdef SHADERGRAPH_PREVIEW
		Out = Colour;
	#else
		Out = MixFog(Colour, Fog);
	#endif
}


#endif // CUSTOM_LIGHTING_INCLUDED
