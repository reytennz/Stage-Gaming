--
-- c_water.lua
--

local myShader22, tec = dxCreateShader ( "Ky_Ayarlar/hddeniz/water.fx" )
localPlayer = getLocalPlayer()

addEventHandler( "onClientResourceStart", resourceRoot,
        function()
			local textureVol = dxCreateTexture ( "Ky_Ayarlar/hddeniz/images/smallnoise3d.dds" );
			local textureCube = dxCreateTexture ( "Ky_Ayarlar/hddeniz/images/cube_env256.dds" );
			dxSetShaderValue ( myShader22, "sRandomTexture", textureVol );
			dxSetShaderValue ( myShader22, "sReflectionTexture", textureCube );

		end
)
	
function shader_water_enabled(shawat)

if shawat==1 then
			-- Apply to global txd 13
						timer = setTimer(	function()
							if myShader22 then
								local r,g,b,a = getWaterColor()
								dxSetShaderValue ( myShader22, "gWaterColor", r/255, g/255, b/255, a/255 );
							end
						end
						,100,0 )
						
			engineApplyShaderToWorldTexture ( myShader22, "waterclear256" )

end
		   

if shawat==0 then
                      if isTimer(timer) then killTimer(timer) end
                      engineRemoveShaderFromWorldTexture ( myShader22, "waterclear256" )
end
	
end
