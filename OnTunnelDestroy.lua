-- Register the behaviour
behaviour("OnTunnelDestroy")

local currentlyExploding = false

function OnTunnelDestroy:Start()
	-- Run when tunnel is destroyed
	OnTunnelDestroy:InitTunnelDestroy(self)
end

function OnTunnelDestroy:InitTunnelDestroy(actor)
	if _G.TunnelSpawn_tunnel ~= nil and _G.TunnelSpawn_tunnelPos ~= Vector3(0,-100,0) then
		currentlyExploding = true

		_G.TunnelSpawn_tunnelPos = Vector3(0,0,0)
		_G.TunnelSpawn_respawnPoint = Vector3(0,0,0)
		_G.TunnelSpawn_spawnDeployBtn.interactable = false
		Overlay.ShowMessage("Tunnel destroyed!", 5)
		actor.script.StartCoroutine(OnTunnelDestroy:Explode(actor))
	end
end

function OnTunnelDestroy:Explode(actor)
	return function()
		actor.targets.explodesound.Play()
		actor.targets.explodeparticles.Play()
		actor.targets.explodeparticlessparks.GetComponent(ParticleSystem).Play()
		coroutine.yield(WaitForSeconds(2))
		_G.TunnelSpawn_tunnel.transform.position = Vector3(0,-100,0)
		actor.targets.tunnelalive.SetActive(true)
		actor.targets.tunneldead.SetActive(false)
		currentlyExploding = false
	end
end

function OnTunnelDestroy:Update()
	-- Run every frame once destroyed
	if self.targets.tunnelalive.activeSelf ~= true and not currentlyExploding then
		OnTunnelDestroy:InitTunnelDestroy(self)
	end
end
