-- Register the behaviour
behaviour("TunnelMutator")

function TunnelMutator:Start()
	_G.TunnelSpawn_tunnel = nil
	_G.TunnelSpawn_spawnAtTunnel = false
	_G.TunnelSpawn_respawnPoint = Vector3(0,-100,0)
	_G.TunnelSpawn_tunnelPos = Vector3(0,-100,0)
	_G.TunnelSpawn_tunnelTeam = ""
	_G.TunnelSpawn_spawnDeployBtnCreated = false
	_G.TunnelSpawn_spawnDeployBtn = nil
end

function TunnelMutator:Update()
	_G.TunnelSpawn_allowTunnelSpawning = true
end
