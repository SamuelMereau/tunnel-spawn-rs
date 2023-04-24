-- Register the behaviour
behaviour("TunnelSpawn")

local instance

-- Hold
local timer = 0
local holdDur = 5
local hasPressed

local swingCooldown = 1

local nodes = false
local creatingTunnel = false

local loadoutcanvas

local hiHiCount = 7

function TunnelSpawn:Awake()
	self.canCreateTunnel = true
	self.hihocount = 0

	_G.TunnelSpawn_allowTunnelSpawning = false

	if _G.TunnelSpawn_spawnDeployBtnCreated == false then
		_G.TunnelSpawn_tunnel = GameObject.Instantiate(self.targets.capturepoint).GetComponent(CapturePoint)
		_G.TunnelSpawn_tunnel.gameObject.SetActive(true)
		_G.TunnelSpawn_tunnel.transform.position = Vector3(0, -100, 0)
		self.targets.canvas.SetActive(true) 
	
		loadoutcanvas = GameObject.Find("Loadout UI Canvas").GetComponent(Canvas)

		_G.TunnelSpawn_spawnDeployBtn = GameObject.Instantiate(self.targets.spawndeploy).GetComponent(Button)
		_G.TunnelSpawn_spawnDeployBtn.gameObject.GetComponent(RectTransform).pivot = Vector2(1, 0)
		_G.TunnelSpawn_spawnDeployBtn.gameObject.GetComponent(RectTransform).anchoredPosition = Vector2(Screen.width - 75, Screen.height - 75)
		_G.TunnelSpawn_spawnDeployBtn.gameObject.GetComponent(RectTransform).anchorMin = Vector2(1, 0)
		_G.TunnelSpawn_spawnDeployBtn.gameObject.GetComponent(RectTransform).anchorMax = Vector2(1, 0)
		_G.TunnelSpawn_spawnDeployBtn.transform.SetParent(loadoutcanvas.transform)

		_G.TunnelSpawn_spawnDeployBtnCreated = true
	end
	
	GameEvents.onActorSpawn.AddListener(self, "OnActorSpawn")
	GameEvents.onActorDiedInfo.AddListener(self, "OnActorDiedInfo")
	if _G.TunnelSpawn_spawnDeployBtn then
		_G.TunnelSpawn_spawnDeployBtn.onClick.AddListener(self, "OnSpawnDeployClick")
	end

	if _G.TunnelSpawn_allowTunnelSpawning == false then
		self.targets.tunnelopen.gameObject.SetActive(false)
		self.targets.tunnelclosed.gameObject.SetActive(false)
	end

end

function TunnelSpawn:Start()
	instance = self

	self.mattock = self.gameObject.GetComponent(Weapon)
	
	self.mattock.isLoud = false

	self.cooldownTime = 1
	self.mattock.cooldown = self.cooldownTime

	self.spawn = 0
	self.maxspawn = 8

	self.canSwing = true

	timer = 0
	hasPressed = false
	creatingTunnel = false

	self.mattock.onFire.AddListener(self, "OnMattockSwing")
end

function TunnelSpawn:ToggleTunnelSpawn()
	if _G.TunnelSpawn_spawnAtTunnel then
		_G.TunnelSpawn_spawnAtTunnel = false
	else
		_G.TunnelSpawn_spawnAtTunnel = true
	end
end

-- Handles player spawning
function TunnelSpawn:OnSpawnDeployClick(actor)
	if 
		Player.team == _G.TunnelSpawn_tunnelTeam and 
		_G.TunnelSpawn_respawnPoint ~= Vector3(0,-100,0)
	then
		if Player.actor.isDead then
			Player.actor.SpawnAt(_G.TunnelSpawn_respawnPoint)
		else
			Player.actor.KillSilently()
			Player.actor.SpawnAt(_G.TunnelSpawn_respawnPoint)
		end
	end
end

-- Handles bot spawning
function TunnelSpawn:OnActorSpawn(actor)
	if 
		actor.isBot and 
		_G.TunnelSpawn_spawnAtTunnel and 
		actor.team == _G.TunnelSpawn_tunnelTeam and 
		_G.TunnelSpawn_respawnPoint ~= Vector3(0,-100,0)
	then
		actor.TeleportTo(_G.TunnelSpawn_respawnPoint, Quaternion(0,0,0,0))
	end
end

function TunnelSpawn:OnActorDiedInfo(actor, info, isSilentKill)
	if actor.isPlayer then
		self.hihocount = 0
	end
	if info.sourceActor then
		if 
			info.sourceActor.isPlayer 
			and actor.team ~= info.sourceActor.team
			and info.sourceWeapon == self.mattock 
		then
			self.hihocount = self.hihocount + 1

			if self.hihocount >= hiHiCount then
				-- HEEEIIIIIGGHH HOOOOOOOOO
				self.targets.hiho.Play()
			end
		end
	end

end

function TunnelSpawn:OnMattockSwing(actor)
	if self.canSwing == false and not digging then
		self.canSwing = true
	end
	if digging then 
		self.targets.groundhit.GetComponent(AudioSource).Play()
		self.targets.dust.GetComponent(ParticleSystem).Play()
	end
end

function TunnelSpawn:SwingCooldown(actor)
	return function()
	   coroutine.yield(WaitForSeconds(swingCooldown))
	   actor.canSwing = true
	end
 end
 

function TunnelSpawn:Update()
	if instance ~= self then
		return
	end

	if (Input.GetKeyBindButton(KeyBinds.Fire) and self.canSwing) then
		self.mattock.Shoot(true)
		self.canSwing = false
		self.script.StartCoroutine(TunnelSpawn:SwingCooldown(self))
	end

	if 
		self.mattock.isHoldingFire 
		and Player.actor ~= nil 
		and not Player.actor.isDead 
		and not Player.actor.isFallenOver 
		and not Player.actor.isSwimming 
		and not Player.actor.isSeated 
		and not creatingTunnel
		and _G.TunnelSpawn_allowTunnelSpawning
	then
		if timer < swingCooldown then
			timer = Time.time
		end

		digging = true

		if (Time.time - timer) >= (holdDur + 0.25) and not hasPressed then
			TunnelSpawn:CreatingTunnel(self)
		end
		if (Time.time - timer) > (holdDur + 0.25) then
			timer = 0
			hasPressed = false
		end
	else
		timer = 0
		digging = false
	end

	if creatingTunnel and not self.mattock.isHoldingFire then
		creatingTunnel = false
	end

	if _G.TunnelSpawn_allowTunnelSpawning then
		if _G.TunnelSpawn_spawnAtTunnel then
			self.targets.tunnelopen.gameObject.SetActive(true)
			self.targets.tunnelclosed.gameObject.SetActive(false)
		else
			self.targets.tunnelopen.gameObject.SetActive(false)
			self.targets.tunnelclosed.gameObject.SetActive(true)
		end
	end

	if (Input.GetKeyUp(KeyCode.X)) 
		and Player.actor ~= nil 
		and not Player.actor.isDead 
		and not Player.actor.isFallenOver 
		and not Player.actor.isSwimming 
		and not Player.actor.isSeated 
	then
		TunnelSpawn:ToggleTunnelSpawn()
	end
end

function TunnelSpawn:CreatingTunnel(actor)
	creatingTunnel = true
	hasPressed = true
	TunnelSpawn:OnCreateTunnel(actor)
end

function TunnelSpawn:OnCreateTunnel(actor)
	if not actor.isDead and _G.TunnelSpawn_allowTunnelSpawning then
		_G.TunnelSpawn_tunnel.transform.position = Vector3(Player.actor.transform.position.x, Player.actor.transform.position.y - 0.1, Player.actor.transform.position.z)

		local ray = Ray(Player.actor.transform.position + Player.actor.transform.position.up * 5.0, Player.actor.transform.position.down)
		local target = RaycastTarget.Opaque
		local hit = Physics.Raycast(ray, 10, target)
		if hit ~= nil then
			_G.TunnelSpawn_tunnel.transform.rotation = Quaternion.FromToRotation(Player.actor.transform.position.up, hit.normal) * Player.actor.transform.rotation
		end

		_G.TunnelSpawn_tunnelPos = Vector3(Player.actor.transform.position.x, Player.actor.transform.position.y - 0.1, Player.actor.transform.position.z)
		_G.TunnelSpawn_tunnelTeam = Player.team
		_G.TunnelSpawn_respawnPoint = _G.TunnelSpawn_tunnelPos

		_G.TunnelSpawn_spawnDeployBtn.interactable = true

		creatingTunnel = false
	end
end
