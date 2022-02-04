Shader "Unlit/Outline"
{
    Properties
    {
		_BaseColor("Color", Color) = (0, 0, 0, 0)
		_Outline("Outline", float) = 0.01	
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

		Cull Front

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float4 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

			float _Outline;
			float4 _BaseColor;

            v2f vert (appdata v)
			{	
                v2f o;

				float3 viewPos = UnityObjectToViewPos(v.vertex);
				float3 viewNormal = COMPUTE_VIEW_NORMAL;
				viewNormal.z = -0.5;
				viewNormal = normalize(viewNormal);				
				viewPos += viewNormal * _Outline;
				o.vertex = mul(UNITY_MATRIX_P, float4(viewPos, 1));

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				fixed4 col = _BaseColor;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
