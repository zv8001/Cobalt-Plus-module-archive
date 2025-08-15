local module = {
	start = function(ref,cfg)		
		--/ CobaltPLUS /--
		if ref.Parent:FindFirstChild("Cabinet") then
			local val = ref.Parent.Cabinet.API:Invoke("config",cfg)
			if val then
				cfg = val
			end
		end
		--/ Variables /--
		local tweenService = game:GetService("TweenService")
		local runService = game:GetService("RunService")
		local emergencyStop = false
		local initialSafety = true
		local travelling = false
		local quickClose = false
		local doorState = "Closed"
		local doorTimer = 0
		local nudgeCounter = 0
		local floor = 1
		local motor = 0
		local velocity = 0
		local nextstop = 0
		local DoorAmount = 2
		local dholdTimer = 0
		local DCPitch = 1
		local motorMode = "idle"
		local releveling = false
		local doorHold = false
		local inService = true
		local safety = true
		local doors = false
		local reopen = false
		local callbuttontrigger = false
		local ignoreFrontDoor = false
		local ignoreRearDoor = false
		local ignoreLeftDoor = false
		local ignoreRightDoor = false
		local shaft = ref.Parent.Shaft
		local car = ref.Parent.Car
		local pdsftybypass = false
		local sftybypass = false
		local allowhandlecall = true
		local inputs = ""
		local mode = "auto"
		local screens = {}
		local welds = {}
		local calls = {}
		local floorcalls = {}
		local callcancel = {}
		local callcanceltimer = {}
		local doorDir = {}
		local floorDirs = {}
		local allFloors = {}
		local direction = 0
		local idleTimer = 0
		local bodyvelocity
		local bodyposition
		local bodygyro		
		local sequences = {
			["XOXOOXXOOXOOXXOX"] = function()
				doorHold = not doorHold
			end,
			["OOXXOOXOXOOXOOXO"] = function()
				if mode == "priority" then
					mode = "auto"
					doorHold = false
					inService = true
				elseif mode ~= "manual" then
					mode = "priority"
					inService = false
				end
			end,
			["XXOXOOXOOXOXOOOX"] = function()
				if inService then
					inService = false
					task.wait(0.1)
					inService = true
				end
				if motor ~= 0 and mode == "auto" then
					mode = "manual"
					task.wait(0.1)
					mode = "auto"
				end
				if motor ~= 0 and mode == "priority" then
					mode = "manual"
					task.wait(0.1)
					mode = "priority"
				end
			end,
		}

		--/ Initialization /--
		local CA = Instance.new("Part", ref)
		CA.Name = "Cable_Attachment"
		CA.Size = Vector3.new(1, 1, 1)
		if not cfg.cframe and not cfg.constraintEngine then
			CA.CFrame = car.Platform.CFrame * CFrame.new(0, 1000, 0)
		elseif not cfg.cframe and cfg.constraintEngine then
			CA.Rotation = car.Platform.Rotation
			CA.Position = car.Platform.Position
		else
			CA.CFrame = car.Platform.CFrame * CFrame.new(0, -1000, 0)
		end
		CA.Anchored = true
		CA.Transparency = 1
		CA.CanCollide = false

		car.PrimaryPart = car.Platform
		if ref.Parent:FindFirstChild("Weight") then
			ref.Parent.Weight.PrimaryPart = ref.Parent.Weight.Platform
		end

		if not ref.Parent:FindFirstChild("Calls") then
			local val = Instance.new("Folder",ref.Parent)
			val.Name = "Calls"
		end

		if car.Platform:FindFirstChild("DoorClose") then
			DCPitch = car.Platform.DoorClose.PlaybackSpeed
		end		

		for i,v in pairs(car:GetChildren()) do
			if v.Name == "DestPanel" then
				if v:FindFirstChild("SurfaceGui") then
					for k,z in pairs(v.SurfaceGui:GetChildren()) do
						if tonumber(z.Name) then
							z.Visible = true
						end
					end
				end
			end
		end

		if not car:FindFirstChild("Sensor") and cfg.weldPlayers then
			cfg.weldPlayers = false
			print("Cobalt: No weld sensor, disabling weld")
		end

		spawn(function()
			local hubApi = game.ReplicatedStorage:WaitForChild("QTHubAPI",5)
			if hubApi then
				hubApi:Invoke("CobaltSync",ref.Parent)
			end
		end)

		if cfg.PitchMotor and not car.Platform:FindFirstChild("Motor") then
			local sound = Instance.new("Sound",car.Platform)
			sound.Name = "Motor"
			sound.SoundId = "rbxassetid://982718352"
			sound.Looped = true
			sound.Volume = 0.25
			sound.MaxDistance = 32
		end
		if not cfg.PitchMotor and not car.Platform:FindFirstChild("Start") then
			local sound = Instance.new("Sound",car.Platform)
			sound.Name = "Start"
			sound.SoundId = "rbxassetid://157769886"
			sound.Volume = 0.5
			sound.MaxDistance = 32
		end
		if not cfg.PitchMotor and not car.Platform:FindFirstChild("Run") then
			local sound = Instance.new("Sound",car.Platform)
			sound.Name = "Run"
			sound.SoundId = "rbxassetid://157769893"
			sound.Looped = true
			sound.Volume = 0.5
			sound.MaxDistance = 32
		end
		if not cfg.PitchMotor and not car.Platform:FindFirstChild("Stop") then
			local sound = Instance.new("Sound",car.Platform)
			sound.Name = "Stop"
			sound.SoundId = "rbxassetid://157769907"
			sound.Volume = 0.5
			sound.MaxDistance = 32
		end
		cfg.narrator = cfg.narrator or false
		local voice
		if cfg.narrator then
			voice = Instance.new("Sound",car.Platform)
			voice.SoundId = "rbxassetid://2125274250"
			voice.Volume = cfg.VoiceVolume
			voice.MaxDistance = 20
		end
		local csflrvoice
		if cfg.narrator and (cfg.CustomVoice == true or cfg.CustomVoice == 1) then
			csflrvoice = Instance.new("Sound",car.Platform)
			csflrvoice.SoundId = cfg.VoiceID
			csflrvoice.Volume = cfg.VoiceVolume
			csflrvoice.MaxDistance = 20
		end
		local csdirvoice
		if cfg.narrator and (cfg.CustomVoice == true or cfg.CustomVoice == 1) then
			csdirvoice = Instance.new("Sound",car.Platform)
			csdirvoice.SoundId = cfg.VoiceID
			csdirvoice.Volume = cfg.VoiceVolume
			csdirvoice.MaxDistance = 20
		end
		local csdovoice
		if cfg.narrator and (cfg.CustomVoice == true or cfg.CustomVoice == 1) then
			csdovoice = Instance.new("Sound",car.Platform)
			csdovoice.SoundId = cfg.VoiceID
			csdovoice.Volume = cfg.VoiceVolume
			csdovoice.MaxDistance = 20
		end
		local csdcvoice
		if cfg.narrator and (cfg.CustomVoice == true or cfg.CustomVoice == 1) then
			csdcvoice = Instance.new("Sound",car.Platform)
			csdcvoice.SoundId = cfg.VoiceID
			csdcvoice.Volume = cfg.VoiceVolume
			csdcvoice.MaxDistance = 20
		end
		if car:FindFirstChild("FrontDoor") then
			for i,v in pairs(car.FrontDoor:GetChildren()) do
				if cfg.ScalerDoor and v:FindFirstChild("LED") then
					for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
						if b:isA("BasePart") then
							b.BrickColor = BrickColor.new("Really black")
						end
					end
				elseif not cfg.ScalerDoor and v.Name == "LED" then
					v.Door.BrickColor = BrickColor.new("Really black")
				end
			end
		end
		if car:FindFirstChild("RearDoor") then
			for i,v in pairs(car.RearDoor:GetChildren()) do
				if cfg.ScalerDoor and v:FindFirstChild("LED") then
					for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
						if b:isA("BasePart") then
							b.BrickColor = BrickColor.new("Really black")
						end
					end
				elseif not cfg.ScalerDoor and v.Name == "LED" then
					v.Door.BrickColor = BrickColor.new("Really black")
				end
			end
		end
		if car:FindFirstChild("LeftDoor") then
			for i,v in pairs(car.LeftDoor:GetChildren()) do
				if cfg.ScalerDoor and v:FindFirstChild("LED") then
					for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
						if b:isA("BasePart") then
							b.BrickColor = BrickColor.new("Really black")
						end
					end
				elseif not cfg.ScalerDoor and v.Name == "LED" then
					v.Door.BrickColor = BrickColor.new("Really black")
				end
			end
		end
		if car:FindFirstChild("RightDoor") then
			for i,v in pairs(car.RightDoor:GetChildren()) do
				if cfg.ScalerDoor and v:FindFirstChild("LED") then
					for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
						if b:isA("BasePart") then
							b.BrickColor = BrickColor.new("Really black")
						end
					end
				elseif not cfg.ScalerDoor and v.Name == "LED" then
					v.Door.BrickColor = BrickColor.new("Really black")
				end
			end
		end
		if not cfg.ScalerDoor then
			for _,z in pairs(shaft:GetChildren()) do
				if z:FindFirstChild("FrontDoor") then
					for i,v in pairs(z.FrontDoor:GetChildren()) do
						v.Door.CFrame = v.Closed.CFrame
					end
				end
				if z:FindFirstChild("RearDoor") then
					for i,v in pairs(z.RearDoor:GetChildren()) do
						v.Door.CFrame = v.Closed.CFrame
					end
				end
				if z:FindFirstChild("LeftDoor") then
					for i,v in pairs(z.LeftDoor:GetChildren()) do
						v.Door.CFrame = v.Closed.CFrame
					end
				end
				if z:FindFirstChild("RightDoor") then
					for i,v in pairs(z.RightDoor:GetChildren()) do
						v.Door.CFrame = v.Closed.CFrame
					end
				end
			end
			if car:FindFirstChild("FrontDoor") then
				for i,v in pairs(car.FrontDoor:GetChildren()) do
					v.Door.CFrame = v.Closed.CFrame
				end
			end
			if car:FindFirstChild("RearDoor") then
				for i,v in pairs(car.RearDoor:GetChildren()) do
					v.Door.CFrame = v.Closed.CFrame
				end
			end
			if car:FindFirstChild("LeftDoor") then
				for i,v in pairs(car.LeftDoor:GetChildren()) do
					v.Door.CFrame = v.Closed.CFrame
				end
			end
			if car:FindFirstChild("RightDoor") then
				for i,v in pairs(car.RightDoor:GetChildren()) do
					v.Door.CFrame = v.Closed.CFrame
				end
			end
		end
		for i,v in pairs(car:GetDescendants()) do
			if v.Name == "UpIND" or v.Name == "MidIND" or v.Name == "DownIND" then
				local initMat = Instance.new("StringValue",v)
				initMat.Name = "InitMaterial"
				initMat.Value = string.gsub(tostring(v.Material),"Enum.Material.","")
			end
		end
		for _,k in pairs(shaft:GetChildren()) do
			for i,v in pairs(k:GetDescendants()) do 
				if v.Name == "UpIND" or v.Name == "MidIND" or v.Name == "DownIND" then
					local initMat = Instance.new("StringValue",v)
					initMat.Name = "InitMaterial"
					initMat.Value = string.gsub(tostring(v.Material),"Enum.Material.","")
				end
			end
		end
		if cfg.liftMusic and car.Platform:FindFirstChild("Music") and cfg.MusicPlaylist == false then
			car.Platform.Music:Play()
		elseif cfg.liftMusic and car.Platform:FindFirstChild("Music") and cfg.MusicPlaylist and cfg.MusicConfig and not cfg.BuiltinMusicPlayer then
			spawn(cfg.MusicConfig)
		elseif cfg.liftMusic and car.Platform:FindFirstChild("Music") and cfg.MusicPlaylist and cfg.BuiltinMusicPlayer then
			spawn(function()
				while task.wait() do
					local currentsong = cfg.Songs[math.random(#cfg.Songs)]

					if cfg.CustomMusicPitch[currentsong] then
						car.Platform.Music.PlaybackSpeed = cfg.CustomMusicPitch[currentsong]
					else
						car.Platform.Music.PlaybackSpeed = 1
					end

					car.Platform.Music.SoundId = "rbxassetid://"..currentsong

					car.Platform.Music:Play()
					task.wait(1)
					task.wait(math.ceil(car.Platform.Music.TimeLength - 1))
					car.Platform.Music:Stop()
				end
			end)
		end

		for i,v in pairs(shaft:GetChildren()) do
			calls[tonumber(v.Name)] = false
			floorcalls[tonumber(v.Name)] = false
			callcancel[tonumber(v.Name)] = 0
			callcanceltimer[tonumber(v.Name)] = 0
			floorDirs[tonumber(v.Name)] = false
			allFloors[i] = tonumber(v.Name)
			local callVal = Instance.new("BoolValue",ref.Parent.Calls)
			callVal.Name = v.Name
			callVal.Value = false
		end

		local function Sorter(a, b) -- Sorting Floors for Handicap
			return tonumber(a) < tonumber(b)
		end
		table.sort(allFloors, Sorter)

		local bottomFloor = allFloors[1]
		local topFloor = allFloors[#allFloors]

		floor = bottomFloor - 1
		nextstop = bottomFloor - 1

		if cfg.weldPlayers then
			car.Sensor.Touched:connect(function() end)
		end
		if not cfg.cframe and not cfg.constraintEngine and not car.Platform:FindFirstChild("BodyVelocity") then
			bodyvelocity = Instance.new("BodyVelocity",car.Platform)
			bodyvelocity.MaxForce = Vector3.new(0,cfg.maxForce,0)
			bodyvelocity.Velocity = Vector3.new(0,0,0)
			bodyposition = Instance.new("BodyPosition",car.Platform)
			bodyposition.MaxForce = Vector3.new(cfg.maxForce,0,cfg.maxForce)
			bodyposition.Position = car.Platform.Position
			bodygyro = Instance.new("BodyGyro",car.Platform)
			bodygyro.CFrame = car.Platform.CFrame
			bodygyro.MaxTorque = Vector3.new(cfg.maxForce,cfg.maxForce,cfg.maxForce)
		elseif not cfg.cframe and not cfg.constraintEngine then
			bodyvelocity = car.Platform.BodyVelocity
			bodyposition = car.Platform.BodyPosition
			bodygyro = car.Platform.BodyGyro
		elseif not cfg.cframe and cfg.constraintEngine then
			local CABLE = Instance.new("PrismaticConstraint",ref.Cable_Attachment)
			local ATTACH0 = Instance.new("Attachment",car.Platform)
			ATTACH0.Orientation = Vector3.new(0,0,-90)
			local ATTACH1 = Instance.new("Attachment",ref.Cable_Attachment)
			ATTACH1.Orientation = Vector3.new(0,0,-90)
			CABLE.ActuatorType = "Motor"
			CABLE.MotorMaxForce = math.huge
			CABLE.Attachment0 = ATTACH0
			CABLE.Attachment1 = ATTACH1
		else
			local CABLE = Instance.new("ManualWeld", ref.Cable_Attachment)
			CABLE.Part0 = ref.Cable_Attachment
			CABLE.C0 = ref.Cable_Attachment.CFrame:Inverse()
			CABLE.C1 = car.Platform.CFrame:Inverse()
			CABLE.Part1 = car.Platform
			CABLE.Name = "Cable_Main"
		end		

		if cfg.DoorAmount then DoorAmount = cfg.DoorAmount end

		--/ Functions /--
		local function weld(p1)
			local w = Instance.new("ManualWeld", car.Welds)
			w.Name = p1.Name.."_Weld"
			w.C0 = car.Platform.CFrame:inverse() * p1.CFrame
			w.Part0 = car.Platform
			w.Part1 = p1
			welds[#welds+1] = w
			p1.Anchored = false
		end

		local function weldWeight(p1)
			local w = Instance.new("ManualWeld", ref.Parent.Weight.Welds)
			w.Name = p1.Name.."_Weld"
			w.C0 = ref.Parent.Weight.Platform.CFrame:inverse() * p1.CFrame
			w.Part0 = ref.Parent.Weight.Platform
			w.Part1 = p1
			p1.Anchored = false
		end

		local function weldDoors(p1)
			local w = Instance.new("ManualWeld", p1.Parent)
			w.Name = "Weld"
			w.C0 = car.Platform.CFrame:inverse() * p1.CFrame
			w.Part0 = car.Platform
			w.Part1 = p1
			p1.Anchored = false
		end

		local function WeldDoorScaler(obj)
			local D = {"DR","DL","DU","DD","RDR","RDL"}
			for _,x in pairs(D) do
				for i=1,DoorAmount do
					local GetDoor = obj:FindFirstChild(x..i)
					if GetDoor then
						if GetDoor:FindFirstChild("Size") == nil then
							Instance.new("NumberValue",GetDoor).Name = "Size"
							GetDoor.Size.Value = (
								GetDoor.Name:sub(1,2) == "DL" and GetDoor.Engine.Size.X or 
									GetDoor.Name:sub(1,2) == "DR" and GetDoor.Engine.Size.X or 
									GetDoor.Name:sub(1,2) == "DU" and GetDoor.Engine.Size.Y or 
									GetDoor.Name:sub(1,2) == "DD" and GetDoor.Engine.Size.Y
							)
						end


						if GetDoor:FindFirstChild("EngineWeld") == nil then 
							local w = Instance.new("ManualWeld", GetDoor)
							w.Name = "EngineWeld"
							w.C0 = car.Platform.CFrame:inverse() * GetDoor.Engine.CFrame
							w.Part0 = car.Platform
							w.Part1 = GetDoor.Engine
							GetDoor.Engine.Anchored = false
						end

						if GetDoor:FindFirstChild("DoorWelds") == nil then
							Instance.new("Model",GetDoor).Name = "DoorWelds"
							for _,v in pairs(GetDoor:GetDescendants()) do
								if v:IsA("BasePart") then
									if v.Name ~= "Engine" then
										local w = Instance.new("ManualWeld", GetDoor.DoorWelds)
										w.Name = "Weld"
										w.C0 = GetDoor.Engine.CFrame:inverse() * v.CFrame
										w.Part0 = GetDoor.Engine
										w.Part1 = v
										v.Anchored = false
									end
								end
							end
						end
					end
				end
			end
		end

		local function WeldFlrDoorScaler(obj)
			local D = {"DR","DL","DU","DD","RDR","RDL"}
			for _,x in pairs(D) do
				for i=1,DoorAmount do
					local GetDoor = obj:FindFirstChild(x..i)
					if GetDoor then
						if GetDoor:FindFirstChild("Size") == nil then
							Instance.new("NumberValue",GetDoor).Name = "Size"
							GetDoor.Size.Value = (
								GetDoor.Name:sub(1,2) == "DL" and GetDoor.Engine.Size.X or 
									GetDoor.Name:sub(1,2) == "DR" and GetDoor.Engine.Size.X or 
									GetDoor.Name:sub(1,2) == "DU" and GetDoor.Engine.Size.Y or 
									GetDoor.Name:sub(1,2) == "DD" and GetDoor.Engine.Size.Y
							)
						end

						if GetDoor:FindFirstChild("EngineWeld") == nil then 
							local w = Instance.new("ManualWeld", GetDoor)
							w.Name = "EngineWeld"
							w.C0 = obj.Parent.Level.CFrame:inverse() * GetDoor.Engine.CFrame
							w.Part0 = obj.Parent.Level
							w.Part1 = GetDoor.Engine
							GetDoor.Engine.Anchored = false
						end

						if GetDoor:FindFirstChild("DoorWelds") == nil then 
							Instance.new("Model",GetDoor).Name = "DoorWelds"
							for _,v in pairs(GetDoor:GetDescendants()) do
								if v:IsA("BasePart") then
									if v.Name ~= "Engine" then
										local w = Instance.new("ManualWeld", GetDoor.DoorWelds)
										w.Name = "Weld"
										w.C0 = GetDoor.Engine.CFrame:inverse() * v.CFrame
										w.Part0 = GetDoor.Engine
										w.Part1 = v
										v.Anchored = false
									end
								end
							end
						end
					end
				end
			end
		end

		local function weldRecursive(obj)
			for _,v in pairs(obj:GetChildren()) do
				if v:IsA("BasePart") or v:IsA("Seat") or v:IsA("VehicleSeat") then
					if v.Name == "Door" then
						if not cfg.ScalerDoor and v.Parent.Parent.Name == "FrontDoor" or v.Parent.Parent.Name == "RearDoor" or v.Parent.Parent.Name == "LeftDoor" or v.Parent.Parent.Name == "RightDoor" and not v.Parent:FindFirstChild("Weld") then
							weldDoors(v)
						else
							weld(v)
						end
					elseif v.Name ~= "Platform"  then
						weld(v)
					end
				end
				if not cfg.ScalerDoor and #v:GetChildren() > 0 and v.Name ~= "Welds" then
					weldRecursive(v)
				elseif cfg.ScalerDoor and #v:GetChildren() > 0 and v.Name ~= "Welds" and v.Name ~= "FrontDoor" and v.Name ~= "RearDoor" and v.Name ~= "LeftDoor" and v.Name ~= "RightDoor" then
					weldRecursive(v)
				elseif cfg.ScalerDoor and v.Name == "FrontDoor" or v.Name == "RearDoor" or v.Name == "LeftDoor" or v.Name == "RightDoor" then
					WeldDoorScaler(v)
				end
			end
		end

		if car:FindFirstChild("Controls") then
			local clone = car.Controls.Stop:Clone()
			clone.Parent = car.Controls
			clone.Name = "StopPressed"
			clone.ClickDetector:Destroy()
			clone.Transparency = 1
			clone.CanCollide = false
			clone.CFrame = clone.CFrame * CFrame.new(0.05,0,0)
			if clone:FindFirstChild("SurfaceGui") then
				clone.SurfaceGui.Enabled = false
			end
			local clone = car.Controls.Switch:Clone()
			clone.Parent = car.Controls
			clone.Name = "SwitchTurned"
			clone.ClickDetector:Destroy()
			clone.Transparency = 1
			clone.CanCollide = false
			clone.CFrame = clone.CFrame * CFrame.Angles(math.rad(90),0,0)
		end
		if car:FindFirstChild("CabinetControls") then
			local clone = car.CabinetControls.Stop:Clone()
			clone.Parent = car.CabinetControls
			clone.Name = "StopPressed"
			clone.ClickDetector:Destroy()
			clone.Transparency = 1
			clone.CanCollide = false
			clone.CFrame = clone.CFrame * CFrame.new(0.05,0,0)
			if clone:FindFirstChild("SurfaceGui") then
				clone.SurfaceGui.Enabled = false
			end
			local clone = car.CabinetControls.Switch:Clone()
			clone.Parent = car.CabinetControls
			clone.Name = "SwitchTurned"
			clone.ClickDetector:Destroy()
			clone.Transparency = 1
			clone.CanCollide = false
			clone.CFrame = clone.CFrame * CFrame.Angles(math.rad(90),0,0)
		end
		if car:FindFirstChild("Welds") == nil then
			local a = Instance.new("Model")
			a.Name = "Welds"
			a.Parent = car
			weldRecursive(car)
		end
		for _,k in pairs(shaft:GetChildren()) do
			for i,v in pairs(k:GetChildren()) do 
				if cfg.ScalerDoor and v.Name == "FrontDoor" or v.Name == "RearDoor" or v.Name == "LeftDoor" or v.Name == "RightDoor" then
					WeldFlrDoorScaler(v)
				end
			end
		end
		if ref.Parent:FindFirstChild("Weight") then
			if (not cfg.cframe or cfg.newWeightWeld) and ref.Parent.Weight:FindFirstChild("Welds") == nil then
				local a = Instance.new("Model")
				a.Name = "Welds"
				a.Parent = ref.Parent.Weight

				for _,v in pairs(ref.Parent.Weight:GetDescendants()) do
					if v:IsA("BasePart") then
						if v.Name ~= "Platform"  then
							weldWeight(v)
						end
					end
				end
			end
			if not cfg.cframe then
				for i,v in pairs(ref.Parent.Motor.Motor:GetChildren()) do
					if v.Name == "Rope" then
						v:Destroy()
					end
				end
				Instance.new("BodyGyro",ref.Parent.Weight.Platform)
				ref.Parent.Weight.Platform.BodyGyro.MaxTorque = Vector3.new(cfg.maxForce,cfg.maxForce,cfg.maxForce)
				ref.Parent.Weight.Platform.BodyGyro.CFrame = ref.Parent.Weight.Platform.CFrame
				Instance.new("BodyPosition",ref.Parent.Weight.Platform)
				ref.Parent.Weight.Platform.BodyPosition.Position = ref.Parent.Weight.Platform.Position
				ref.Parent.Weight.Platform.BodyPosition.MaxForce = Vector3.new(cfg.maxForce,0,cfg.maxForce)
			end
		end
		local function roundoff(num,offset)
			local newnumber
			newnumber = num * (10^offset)
			newnumber = math.floor(newnumber)
			newnumber = newnumber / (10^offset)
			return newnumber
		end
		local function playSound(...)
			local csmodvoice
			csmodvoice = Instance.new("Sound",car.Platform)
			csmodvoice.Name = "ModularVoiceTemp"
			csmodvoice.SoundId = cfg.VoiceID
			csmodvoice.Volume = cfg.VoiceVolume
			csmodvoice.MaxDistance = 20
			for i,v in pairs({...}) do
				if not cfg["VOICEV2BASE"]["VOICEDATA"][v] then return end
				if cfg["VOICEV2BASE"]["VOICEDATA"][v]["ID"] then
					csmodvoice.SoundId = "rbxassetid://" .. cfg["VOICEV2BASE"]["VOICEDATA"][v]["ID"]
					if not csmodvoice.IsLoaded then csmodvoice.Loaded:Wait() end
					csmodvoice.Volume = cfg["VOICEV2BASE"]["VOICEDATA"][v]["VOLUME"]
					csmodvoice.TimePosition = 0
					if cfg["VOICEV2BASE"]["VOICEDATA"][v]["START"] and cfg["VOICEV2BASE"]["VOICEDATA"][v]["END"] then
						csmodvoice.TimePosition = cfg["VOICEV2BASE"]["VOICEDATA"][v]["START"]
						csmodvoice:Play();wait(cfg["VOICEV2BASE"]["VOICEDATA"][v]["END"]);csmodvoice:Stop()
					else
						csmodvoice:Play()
					end
				elseif cfg["VOICEV2BASE"]["VOICEDATA"][v]["START"] and cfg["VOICEV2BASE"]["VOICEDATA"][v]["END"] then
					csmodvoice.SoundId = "rbxassetid://" .. cfg["VOICEV2BASE"]["VOICEDATA"]["VOICEID"] 
					if not csmodvoice.IsLoaded then csmodvoice.Loaded:Wait() end
					csmodvoice.TimePosition = cfg["VOICEV2BASE"]["VOICEDATA"][v]["START"]
					csmodvoice.Volume = cfg["VOICEV2BASE"]["VOICEDATA"][v]["VOLUME"]
					csmodvoice:Play();task.wait(cfg["VOICEV2BASE"]["VOICEDATA"][v]["END"]);csmodvoice:Stop()
				end
			end
			csmodvoice:destroy()
		end

		local function voiceRoutine(Mode,Dir)
			task.wait()
			if cfg.CustomVoice == true or cfg.CustomVoice == 1 then	
				csflrvoice:Stop()
				csdirvoice:Stop()
				csdovoice:Stop()
				csdcvoice:Stop()
				if Mode == 1 then
					if cfg["F"..floor] or cfg["F"..floor.."Start"] or cfg["F"..floor.."Delay"] then
						if cfg["F"..floor] ~= nil then
							csflrvoice.SoundId = cfg["F"..floor]
						else
							csflrvoice.SoundId = cfg.VoiceID
						end
						if cfg["F"..floor.."Start"] ~= nil then
							csflrvoice.TimePosition = cfg["F"..floor.."Start"]
						else
							csflrvoice.TimePosition = 0
						end
						csflrvoice:Play()
						if cfg.VoiceDelay ~= nil then
							task.wait(cfg["F"..floor.."Delay"]+cfg.VoiceDelay)
						else
							task.wait(cfg["F"..floor.."Delay"]+0.3)
						end
						csflrvoice:Stop()
						if cfg.StandClear then
							if cfg.StDoorVoice ~= nil then
								csdovoice.SoundId = cfg.StDoorVoice
							else
								csdovoice.SoundId = cfg.VoiceID
							end
							if cfg.StDoorStart ~= nil then
								csdovoice.TimePosition = cfg.StDoorStart
							else
								csdovoice.TimePosition = 0
							end
							csdovoice:Play()
							if cfg.VoiceDelay ~= nil then
								task.wait(cfg.StDoorDelay+cfg.VoiceDelay)
							else
								task.wait(cfg.StDoorDelay+0.3)
							end
							csdovoice:Stop()
						end
						task.wait()
						if not cfg.DirSoundWhenMove and not cfg.VoiceBeforeDoor and not cfg.DoorOpeningSound then
							if Dir == 1 then
								if cfg.UpVoice ~= nil then
									csdirvoice.SoundId = cfg.UpVoice
									if cfg.UpVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.UpVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil and cfg.UpVoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								elseif cfg.UpVoice == nil and cfg.UpVoiceDelay ~= nil then
									csdirvoice.SoundId = cfg.VoiceID
									if cfg.UpVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.UpVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								end
							elseif Dir == -1 then
								if cfg.DownVoice ~= nil then
									csdirvoice.SoundId = cfg.DownVoice
									if cfg.DownVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.DownVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								elseif cfg.DownVoice == nil and cfg.DownVoiceDelay ~= nil then
									csdirvoice.SoundId = cfg.VoiceID
									if cfg.DownVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.DownVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								end
							end
						end
					else
						if cfg.StandClear then
							if cfg.StDoorVoice ~= nil then
								csdovoice.SoundId = cfg.StDoorVoice
							else
								csdovoice.SoundId = cfg.VoiceID
							end
							if cfg.StDoorStart ~= nil then
								csdovoice.TimePosition = cfg.StDoorStart
							else
								csdovoice.TimePosition = 0
							end
							csdovoice:Play()
							if cfg.VoiceDelay ~= nil then
								task.wait(cfg.StDoorDelay+cfg.VoiceDelay)
							else
								task.wait(cfg.StDoorDelay+0.3)
							end
							csdovoice:Stop()
						end
						task.wait()
						if not cfg.DirSoundWhenMove and not cfg.VoiceBeforeDoor and not cfg.DoorOpeningSound then
							if Dir == 1 then
								if cfg.UpVoice ~= nil then
									csdirvoice.SoundId = cfg.UpVoice
									if cfg.UpVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.UpVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil and cfg.UpVoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								elseif cfg.UpVoice == nil and cfg.UpVoiceDelay ~= nil then
									csdirvoice.SoundId = cfg.VoiceID
									if cfg.UpVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.UpVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
										task.wait(cfg.UpVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								end
							elseif Dir == -1 then
								if cfg.DownVoice ~= nil then
									csdirvoice.SoundId = cfg.DownVoice
									if cfg.DownVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.DownVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								elseif cfg.DownVoice == nil and cfg.DownVoiceDelay ~= nil then
									csdirvoice.SoundId = cfg.VoiceID
									if cfg.DownVoiceStart ~= nil then
										csdirvoice.TimePosition = cfg.DownVoiceStart
									else
										csdirvoice.TimePosition = 0
									end
									csdirvoice:Play()
									if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
										csdirvoice:Stop()
									elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
										task.wait(cfg.DownVoiceDelay+0.3)
										csdirvoice:Stop()
									end
								end
							end
						end
					end
				elseif Mode == 2 then
					csflrvoice:Stop()
					csdirvoice:Stop()
					csdovoice:Stop()
					csdcvoice:Stop()
					if cfg.DoorOpeningSound then
						if cfg.OpeningSoundID ~= nil then
							csdovoice.SoundId = cfg.OpeningSoundID
						else
							csdovoice.SoundId = cfg.VoiceID
						end
						if cfg.OpeningSoundStart ~= nil then
							csdovoice.TimePosition = cfg.OpeningSoundStart
						else
							csdovoice.TimePosition = 0
						end
						csdovoice:Play()
						if cfg.VoiceDelay ~= nil then
							task.wait(cfg.OpeningSoundDelay+cfg.VoiceDelay)
						else
							task.wait(cfg.OpeningSoundDelay+0.3)
						end
						csdovoice:Stop()
					end
					task.wait()
					if not cfg.DirSoundWhenMove then
						if Dir == 1 then
							if cfg.UpVoice ~= nil then
								csdirvoice.SoundId = cfg.UpVoice
								if cfg.UpVoiceStart ~= nil then
									csdirvoice.TimePosition = cfg.UpVoiceStart
								else
									csdirvoice.TimePosition = 0
								end
								csdirvoice:Play()
								if cfg.VoiceDelay ~= nil and cfg.UpVoiceDelay ~= nil then
									task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
									csdirvoice:Stop()
								elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
									task.wait(cfg.UpVoiceDelay+0.3)
									csdirvoice:Stop()
								end
							elseif cfg.UpVoice == nil and cfg.UpVoiceDelay ~= nil then
								csdirvoice.SoundId = cfg.VoiceID
								if cfg.UpVoiceStart ~= nil then
									csdirvoice.TimePosition = cfg.UpVoiceStart
								else
									csdirvoice.TimePosition = 0
								end
								csdirvoice:Play()
								if cfg.VoiceDelay ~= nil then
									task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
									csdirvoice:Stop()
								elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
									task.wait(cfg.UpVoiceDelay+0.3)
									csdirvoice:Stop()
								end
							end
						elseif Dir == -1 then
							if cfg.DownVoice ~= nil then
								csdirvoice.SoundId = cfg.DownVoice
								if cfg.DownVoiceStart ~= nil then
									csdirvoice.TimePosition = cfg.DownVoiceStart
								else
									csdirvoice.TimePosition = 0
								end
								csdirvoice:Play()
								if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
									task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
									csdirvoice:Stop()
								elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
									task.wait(cfg.DownVoiceDelay+0.3)
									csdirvoice:Stop()
								end
							elseif cfg.DownVoice == nil and cfg.DownVoiceDelay ~= nil then
								csdirvoice.SoundId = cfg.VoiceID
								if cfg.DownVoiceStart ~= nil then
									csdirvoice.TimePosition = cfg.DownVoiceStart
								else
									csdirvoice.TimePosition = 0
								end
								csdirvoice:Play()
								if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
									task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
									csdirvoice:Stop()
								elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
									task.wait(cfg.DownVoiceDelay+0.3)
									csdirvoice:Stop()
								end
							end
						end
					end
				elseif Mode == 3 then
					if cfg.DoorClosingSound then
						if cfg.ClosingSoundID ~= nil then
							csdcvoice.SoundId = cfg.ClosingSoundID
						else
							csdcvoice.SoundId = cfg.VoiceID
						end
						if cfg.ClosingSoundStart ~= nil then
							csdcvoice.TimePosition = cfg.ClosingSoundStart
						else
							csdcvoice.TimePosition = 0
						end
						csdcvoice:Play()
						if cfg.VoiceDelay ~= nil then
							task.wait(cfg.ClosingSoundDelay+cfg.VoiceDelay)
						else
							task.wait(cfg.ClosingSoundDelay+0.3)
						end
						csdcvoice:Stop()
					end
				elseif Mode == 4 then
					if Dir == 1 then
						if cfg.UpVoice ~= nil then
							csdirvoice.SoundId = cfg.UpVoice
							if cfg.UpVoiceStart ~= nil then
								csdirvoice.TimePosition = cfg.UpVoiceStart
							else
								csdirvoice.TimePosition = 0
							end
							csdirvoice:Play()
							if cfg.VoiceDelay ~= nil and cfg.UpVoiceDelay ~= nil then
								task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
								csdirvoice:Stop()
							elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
								task.wait(cfg.UpVoiceDelay+0.3)
								csdirvoice:Stop()
							end
						elseif cfg.UpVoice == nil and cfg.UpVoiceDelay ~= nil then
							csdirvoice.SoundId = cfg.VoiceID
							if cfg.UpVoiceStart ~= nil then
								csdirvoice.TimePosition = cfg.UpVoiceStart
							else
								csdirvoice.TimePosition = 0
							end
							csdirvoice:Play()
							if cfg.VoiceDelay ~= nil then
								task.wait(cfg.UpVoiceDelay+cfg.VoiceDelay)
								csdirvoice:Stop()
							elseif cfg.VoiceDelay == nil and cfg.UpVoiceDelay ~= nil then
								task.wait(cfg.UpVoiceDelay+0.3)
								csdirvoice:Stop()
							end
						end
					elseif Dir == -1 then
						if cfg.DownVoice ~= nil then
							csdirvoice.SoundId = cfg.DownVoice
							if cfg.DownVoiceStart ~= nil then
								csdirvoice.TimePosition = cfg.DownVoiceStart
							else
								csdirvoice.TimePosition = 0
							end
							csdirvoice:Play()
							if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
								task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
								csdirvoice:Stop()
							elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
								task.wait(cfg.DownVoiceDelay+0.3)
								csdirvoice:Stop()
							end
						elseif cfg.DownVoice == nil and cfg.DownVoiceDelay ~= nil then
							csdirvoice.SoundId = cfg.VoiceID
							if cfg.DownVoiceStart ~= nil then
								csdirvoice.TimePosition = cfg.DownVoiceStart
							else
								csdirvoice.TimePosition = 0
							end
							csdirvoice:Play()
							if cfg.VoiceDelay ~= nil and cfg.DownVoiceDelay ~= nil then
								task.wait(cfg.DownVoiceDelay+cfg.VoiceDelay)
								csdirvoice:Stop()
							elseif cfg.VoiceDelay == nil and cfg.DownVoiceDelay ~= nil then
								task.wait(cfg.DownVoiceDelay+0.3)
								csdirvoice:Stop()
							end
						end
					end
				end
			elseif cfg.CustomVoice == 2 then
				for _,v in pairs(car.Platform:GetChildren()) do
					if v.Name == "ModularVoiceTemp" then
						v:Destroy()
					end
				end
				if Mode == 1 then
					if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS[tostring(floor)] then
						playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS[tostring(floor)]))
					else
						playSound(tostring(floor))
					end
					if cfg.StandClear then
						if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["StandClear"] then
							playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["StandClear"]))
						else
							playSound("StandClear")
						end
					end
					if not cfg.DirSoundWhenMove and not cfg.VoiceBeforeDoor and not cfg.DoorOpeningSound then
						if Dir == 1 then
							if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["UP"] then
								playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["UP"]))
							else
								playSound("UP")
							end
						elseif Dir == -1 then
							if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DOWN"] then
								playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DOWN"]))
							else
								playSound("DOWN")
							end
						end
					end
				elseif Mode == 2 then
					if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["AltDoorVoice"] ~= nil then
						for _,v in pairs(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["AltDoorVoice"]) do
							if v == floor then
								if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["RDO"] then
									playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["RDO"]))
								else
									playSound("RDO")
								end
							else
								if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DO"] then
									playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DO"]))
								else
									playSound("DO")
								end
							end
						end
					else
						if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DO"] then
							playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DO"]))
						else
							playSound("DO")
						end
					end
					if not cfg.DirSoundWhenMove then
						if Dir == 1 then
							if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["UP"] then
								playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["UP"]))
							else
								playSound("UP")
							end
						elseif Dir == -1 then
							if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DOWN"] then
								playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DOWN"]))
							else
								playSound("DOWN")
							end
						end
					end
				elseif Mode == 3 then
					if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["AltDoorVoice"] ~= nil then
						for _,v in pairs(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["AltDoorVoice"]) do
							if v == floor then
								if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["RDC"] then
									playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["RDC"]))
								else
									playSound("RDC")
								end
							else
								if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DC"] then
									playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DC"]))
								else
									playSound("DC")
								end
							end
						end
					else
						if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DC"] then
							playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DC"]))
						else
							playSound("DC")
						end
					end
				elseif Mode == 4 then
					if Dir == 1 then
						if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["UP"] then
							playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["UP"]))
						else
							playSound("UP")
						end
					elseif Dir == -1 then
						if cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DOWN"] then
							playSound(unpack(cfg.VOICEV2BASE.CUSTOMANNOUNCMENTS["DOWN"]))
						else
							playSound("DOWN")
						end
					end
				end
			else
				voice.TimePosition = voice.TimeLength
				if floor == -1 then
					voice.TimePosition = 0
				elseif floor == 1 then
					voice.TimePosition = 0.5
				elseif floor == 2 then
					voice.TimePosition = 1.25
				elseif floor == 3 then
					voice.TimePosition = 1.9
				elseif floor == 4 then
					voice.TimePosition = 2.4
				elseif floor == 5 then
					voice.TimePosition = 3
				elseif floor == 6 then
					voice.TimePosition = 3.6
				elseif floor == 7 then
					voice.TimePosition = 4.2
				elseif floor == 8 then
					voice.TimePosition = 4.7
				elseif floor == 9 then
					voice.TimePosition = 5.3
				elseif floor == 10 then
					voice.TimePosition = 5.8
				elseif floor == 11 then
					voice.TimePosition = 6.4
				elseif floor == 12 then
					voice.TimePosition = 7
				elseif floor == 13 then
					voice.TimePosition = 7.7
				elseif floor == 14 then
					voice.TimePosition = 8.6
				elseif floor == 15 then
					voice.TimePosition = 9.4
				elseif floor == 16 then
					voice.TimePosition = 10.2
				elseif floor == 17 then
					voice.TimePosition = 11
				elseif floor == 18 then
					voice.TimePosition = 11.8
				elseif floor == 19 then
					voice.TimePosition = 12.5
				elseif floor == 20 then
					voice.TimePosition = 13.2
				elseif floor == 21 then
					voice.TimePosition = 13.95
				elseif floor == 22 then
					voice.TimePosition = 14.9
				elseif floor == 23 then
					voice.TimePosition = 15.9
				elseif floor == 24 then
					voice.TimePosition = 16.8
				end
				if voice.TimePosition ~= voice.TimeLength then
					voice:Play()
					task.wait(0.65)
					voice:Stop()
					voice.TimePosition = 17.6
					voice:Play()
					task.wait(0.45)
					voice:Stop()
					task.wait(0.25)
				end
				task.wait()
				if Dir == 1 then
					voice.TimePosition = 18.05
					voice:Play()
					task.wait(0.75)
					voice:Stop()
				elseif Dir == -1 then
					voice.TimePosition = 18.8
					voice:Play()
					task.wait(0.75)
					voice:Stop()
				end
			end
		end

		local function DoorDirBin(num)
			local toBinary = tostring(math.floor(num/8%2)) .. tostring(math.floor(num/4%2)) .. tostring(math.floor(num/2%2)) .. num%2

			ignoreFrontDoor = true
			ignoreRearDoor = true
			ignoreLeftDoor = true
			ignoreRightDoor = true

			if toBinary:sub(4,4) == "1" and shaft[tostring(floor)]:FindFirstChild("FrontDoor") then
				ignoreFrontDoor = false
			elseif toBinary:sub(4,4) == "1" and not shaft[tostring(floor)]:FindFirstChild("FrontDoor") then
				ignoreFrontDoor = false
				ignoreRearDoor = false
				ignoreLeftDoor = false
				ignoreRightDoor = false
			end

			if toBinary:sub(3,3) == "1" and shaft[tostring(floor)]:FindFirstChild("RearDoor") then
				ignoreRearDoor = false
			elseif toBinary:sub(3,3) == "1" and not shaft[tostring(floor)]:FindFirstChild("RearDoor") then
				ignoreFrontDoor = false
				ignoreRearDoor = false
				ignoreLeftDoor = false
				ignoreRightDoor = false
			end

			if toBinary:sub(2,2) == "1" and shaft[tostring(floor)]:FindFirstChild("LeftDoor") then
				ignoreLeftDoor = false
			elseif toBinary:sub(2,2) == "1" and not shaft[tostring(floor)]:FindFirstChild("LeftDoor") then
				ignoreFrontDoor = false
				ignoreRearDoor = false
				ignoreLeftDoor = false
				ignoreRightDoor = false
			end

			if toBinary:sub(1,1) == "1" and shaft[tostring(floor)]:FindFirstChild("RightDoor") then
				ignoreRightDoor = false
			elseif toBinary:sub(1,1) == "1" and not shaft[tostring(floor)]:FindFirstChild("RightDoor") then
				ignoreFrontDoor = false
				ignoreRearDoor = false
				ignoreLeftDoor = false
				ignoreRightDoor = false
			end
		end

		local function ButtonLightOn(v)
			for i,l in pairs(v:GetDescendants()) do
				if l.Name == "Light" then					
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							l.Color = v.ActiveColor.Value
						else
							l.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.ButtonLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.ButtonLit) == "string" then
							l.BrickColor = BrickColor.new(cfg.ButtonLit)
						else
							l.Color = cfg.ButtonLit
						end
					else
						l.BrickColor = BrickColor.new("Cyan")
					end
					l.Material = "Neon"
				end
			end
		end

		local function ButtonLightOff(v)
			for i,l in pairs(v:GetDescendants()) do
				if l.Name == "Light" then	
					if v:FindFirstChild("InactiveColor") then
						if v.InactiveColor.ClassName == "Color3Value" then
							l.Color = v.InactiveColor.Value
						else
							l.BrickColor = v.InactiveColor.Value
						end				
					elseif cfg.ButtonUnLit and not v:FindFirstChild("InactiveColor") then
						if typeof(cfg.ButtonUnLit) == "string" then
							l.BrickColor = BrickColor.new(cfg.ButtonUnLit)
						else
							l.Color = cfg.ButtonUnLit
						end
					else
						l.BrickColor = BrickColor.new("White")
					end
					l.Material = v.InitMaterial.Value
				end
			end
		end

		local function LanternLitU()
			for i,v in pairs(car:GetDescendants()) do
				if v.Name == "UpIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("ActiveColorU") then
						if v.ActiveColorU.ClassName == "Color3Value" then
							v.Color = v.ActiveColorU.Value
						else
							v.BrickColor = v.ActiveColorU.Value
						end
					elseif v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "U"
				end
			end
			for i,v in pairs(shaft[tostring(floor)]:GetDescendants()) do
				if v.Name == "UpIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("ActiveColorU") then
						if v.ActiveColorU.ClassName == "Color3Value" then
							v.Color = v.ActiveColorU.Value
						else
							v.BrickColor = v.ActiveColorU.Value
						end
					elseif v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "U"
				end
			end
		end

		local function LanternLitD()
			for i,v in pairs(car:GetDescendants()) do
				if v.Name == "DownIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("ActiveColorD") then
						if v.ActiveColorD.ClassName == "Color3Value" then
							v.Color = v.ActiveColorD.Value
						else
							v.BrickColor = v.ActiveColorD.Value
						end
					elseif v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "D"
				end
			end
			for i,v in pairs(shaft[tostring(floor)]:GetDescendants()) do
				if v.Name == "DownIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("ActiveColorD") then
						if v.ActiveColorD.ClassName == "Color3Value" then
							v.Color = v.ActiveColorD.Value
						else
							v.BrickColor = v.ActiveColorD.Value
						end
					elseif v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "D"
				end
			end
		end

		local function LanternLitN()
			for i,v in pairs(car:GetDescendants()) do
				if v.Name == "UpIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "DownIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("ActiveColorU") then
						if v.ActiveColorU.ClassName == "Color3Value" then
							v.Color = v.ActiveColorU.Value
						else
							v.BrickColor = v.ActiveColorU.Value
						end
					elseif v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "UD"
				end
			end
			for i,v in pairs(shaft[tostring(floor)]:GetDescendants()) do
				if v.Name == "UpIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "DownIND" then
					if v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("ActiveColorU") then
						if v.ActiveColorU.ClassName == "Color3Value" then
							v.Color = v.ActiveColorU.Value
						else
							v.BrickColor = v.ActiveColorU.Value
						end
					elseif v:FindFirstChild("ActiveColor") then
						if v.ActiveColor.ClassName == "Color3Value" then
							v.Color = v.ActiveColor.Value
						else
							v.BrickColor = v.ActiveColor.Value
						end
					elseif cfg.LanternLit and not v:FindFirstChild("ActiveColor") then
						if typeof(cfg.LanternLit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternLit)
						else
							v.Color = cfg.LanternLit
						end
					else
						v.BrickColor = BrickColor.new("Institutional white")
					end
					v.Material = "Neon"
					if v:FindFirstChild("ActiveTransparency") then
						v.Transparency = v.ActiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "UD"
				end
			end
		end

		local function LanternUnlit()
			for i,v in pairs(car:GetDescendants()) do
				if v.Name == "UpIND" then
					if v:FindFirstChild("InactiveColor") then
						if v.InactiveColor.ClassName == "Color3Value" then
							v.Color = v.InactiveColor.Value
						else
							v.BrickColor = v.InactiveColor.Value
						end
					elseif cfg.LanternUnlit and not v:FindFirstChild("InactiveColor") then
						if typeof(cfg.LanternUnlit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternUnlit)
						else
							v.Color = cfg.LanternUnlit
						end
					else
						v.BrickColor = BrickColor.new("White")
					end
					v.Material = v.InitMaterial.Value
					if v:FindFirstChild("InactiveTransparency") then
						v.Transparency = v.InactiveTransparency.Value
					end
				elseif v.Name == "DownIND" then
					if v:FindFirstChild("InactiveColor") then
						if v.InactiveColor.ClassName == "Color3Value" then
							v.Color = v.InactiveColor.Value
						else
							v.BrickColor = v.InactiveColor.Value
						end
					elseif cfg.LanternUnlit and not v:FindFirstChild("InactiveColor") then
						if typeof(cfg.LanternUnlit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternUnlit)
						else
							v.Color = cfg.LanternUnlit
						end
					else
						v.BrickColor = BrickColor.new("White")
					end
					v.Material = v.InitMaterial.Value
					if v:FindFirstChild("InactiveTransparency") then
						v.Transparency = v.InactiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("InactiveColor") then
						if v.InactiveColor.ClassName == "Color3Value" then
							v.Color = v.InactiveColor.Value
						else
							v.BrickColor = v.InactiveColor.Value
						end
					elseif cfg.LanternUnlit and not v:FindFirstChild("InactiveColor") then
						if typeof(cfg.LanternUnlit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternUnlit)
						else
							v.Color = cfg.LanternUnlit
						end
					else
						v.BrickColor = BrickColor.new("White")
					end
					v.Material = v.InitMaterial.Value
					if v:FindFirstChild("InactiveTransparency") then
						v.Transparency = v.InactiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "N"
				end
			end
			for i,v in pairs(shaft[tostring(floor)]:GetDescendants()) do
				if v.Name == "UpIND" then
					if v:FindFirstChild("InactiveColor") then
						if v.InactiveColor.ClassName == "Color3Value" then
							v.Color = v.InactiveColor.Value
						else
							v.BrickColor = v.InactiveColor.Value
						end
					elseif cfg.LanternUnlit and not v:FindFirstChild("InactiveColor") then
						if typeof(cfg.LanternUnlit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternUnlit)
						else
							v.Color = cfg.LanternUnlit
						end
					else
						v.BrickColor = BrickColor.new("White")
					end
					v.Material = v.InitMaterial.Value
					if v:FindFirstChild("InactiveTransparency") then
						v.Transparency = v.InactiveTransparency.Value
					end
				elseif v.Name == "DownIND" then
					if v:FindFirstChild("InactiveColor") then
						if v.InactiveColor.ClassName == "Color3Value" then
							v.Color = v.InactiveColor.Value
						else
							v.BrickColor = v.InactiveColor.Value
						end
					elseif cfg.LanternUnlit and not v:FindFirstChild("InactiveColor") then
						if typeof(cfg.LanternUnlit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternUnlit)
						else
							v.Color = cfg.LanternUnlit
						end
					else
						v.BrickColor = BrickColor.new("White")
					end
					v.Material = v.InitMaterial.Value
					if v:FindFirstChild("InactiveTransparency") then
						v.Transparency = v.InactiveTransparency.Value
					end
				elseif v.Name == "MidIND" then
					if v:FindFirstChild("InactiveColor") then
						if v.InactiveColor.ClassName == "Color3Value" then
							v.Color = v.InactiveColor.Value
						else
							v.BrickColor = v.InactiveColor.Value
						end
					elseif cfg.LanternUnlit and not v:FindFirstChild("InactiveColor") then
						if typeof(cfg.LanternUnlit) == "string" then
							v.BrickColor = BrickColor.new(cfg.LanternUnlit)
						else
							v.Color = cfg.LanternUnlit
						end
					else
						v.BrickColor = BrickColor.new("White")
					end
					v.Material = v.InitMaterial.Value
					if v:FindFirstChild("InactiveTransparency") then
						v.Transparency = v.InactiveTransparency.Value
					end
				elseif v.Name == "Lantern" and v:IsA("StringValue") then
					v.Value = "N"
				end
			end
		end

		local function LanternHandler(flr)
			if floorDirs[flr] then
				if floorDirs[flr] == 1 then
					LanternLitU()
				elseif floorDirs[flr] == -1 then
					LanternLitD()
				else
					LanternLitN()
				end
			elseif flr == bottomFloor then
				LanternLitU()
			elseif flr == topFloor then
				LanternLitD()
			elseif direction == 1 then
				LanternLitU()
			elseif direction == -1 then
				LanternLitD()
			else
				LanternLitN()
			end
		end

		local function GenerateCFrameData(D)

			local X
			local Y

			X = (D.Name:sub(2,2) == "R" and (-(D.Size.Value * tonumber(D.Name:sub(3)))) or D.Name:sub(2,2) == "L" and (D.Size.Value * tonumber(D.Name:sub(3))) or 0)
			Y = (D.Name:sub(2,2) == "U" and ((D.Size.Value * tonumber(D.Name:sub(3)))) or D.Name:sub(2,2) == "D" and -(D.Size.Value * tonumber(D.Name:sub(3))) or 0)

			return CFrame.new(X,Y,0)
		end

		local function carDoorsOpen(D,S)
			for i,v in pairs(car:FindFirstChild(D):GetChildren()) do
				--[[if cfg.cframe then
					for i,v in pairs(car.Welds:GetChildren()) do
						v.Part1.Anchored = true
					end
				else
				v.Door.Anchored = true
				end]]
				if cfg.ScalerDoor and cfg.CustomDoorTween then
					tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorOpenEasing,cfg.OpenEasingInOut),{
						["C1"] = GenerateCFrameData(v),
					}):Play()
				elseif cfg.ScalerDoor and not cfg.CustomDoorTween then
					tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorOpenEasing,Enum.EasingDirection.InOut),{
						["C1"] = GenerateCFrameData(v),
					}):Play()
				elseif not cfg.ScalerDoor and cfg.CustomDoorTween then
					tweenService:Create(v.Weld,TweenInfo.new(S,cfg.DoorOpenEasing,cfg.OpenEasingInOut),{
						["C1"] = v.Open.CFrame:inverse() * v.Closed.CFrame,
					}):Play()
				elseif not cfg.ScalerDoor and not cfg.CustomDoorTween then
					tweenService:Create(v.Weld,TweenInfo.new(S,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{
						["C1"] = v.Open.CFrame:inverse() * v.Closed.CFrame,
					}):Play()
				end
			end
		end

		local function floorDoorsOpen(D,S)
			if not sftybypass then
				for i,v in pairs(shaft[tostring(floor)]:FindFirstChild(D):GetChildren()) do
					if cfg.ScalerDoor and cfg.CustomDoorTween then
						tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorOpenEasing,cfg.OpenEasingInOut),{
							["C1"] = GenerateCFrameData(v),
						}):Play()
					elseif cfg.ScalerDoor and not cfg.CustomDoorTween then
						tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorOpenEasing,Enum.EasingDirection.InOut),{
							["C1"] = GenerateCFrameData(v),
						}):Play()
					elseif not cfg.ScalerDoor and cfg.CustomDoorTween then
						tweenService:Create(v.Door,TweenInfo.new(S,cfg.DoorOpenEasing,cfg.OpenEasingInOut),{
							["CFrame"] = v.Open.CFrame,
						}):Play()
					elseif not cfg.ScalerDoor and not cfg.CustomDoorTween then
						tweenService:Create(v.Door,TweenInfo.new(S,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{
							["CFrame"] = v.Open.CFrame,
						}):Play()
					end
				end
			end
		end

		local function carDoorsClose(D,S)
			if not sftybypass then
				for i,v in pairs(car:FindFirstChild(D):GetChildren()) do
					if cfg.ScalerDoor and cfg.CustomDoorTween then
						tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorCloseEasing,cfg.OpenEasingInOut),{
							["C1"] = CFrame.new(0,0,0),
						}):Play()
					elseif cfg.ScalerDoor and not cfg.CustomDoorTween then
						tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorCloseEasing,Enum.EasingDirection.InOut),{
							["C1"] = CFrame.new(0,0,0),
						}):Play()
					elseif not cfg.ScalerDoor and cfg.CustomDoorTween then
						tweenService:Create(v.Weld,TweenInfo.new(S,cfg.DoorCloseEasing,cfg.CloseEasingInOut),{
							["C1"] = v.Closed.CFrame:inverse() * v.Closed.CFrame,
						}):Play()
					elseif not cfg.ScalerDoor and not cfg.CustomDoorTween then
						tweenService:Create(v.Weld,TweenInfo.new(S,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{
							["C1"] = v.Closed.CFrame:inverse() * v.Closed.CFrame,
						}):Play()
					end
				end
			end
		end

		local function floorDoorsClose(D,S)
			for i,v in pairs(shaft[tostring(floor)]:FindFirstChild(D):GetChildren()) do
				if cfg.ScalerDoor and cfg.CustomDoorTween then
					tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorCloseEasing,cfg.OpenEasingInOut),{
						["C1"] = CFrame.new(0,0,0),
					}):Play()
				elseif cfg.ScalerDoor and not cfg.CustomDoorTween then
					tweenService:Create(v.EngineWeld,TweenInfo.new(S,cfg.DoorCloseEasing,Enum.EasingDirection.InOut),{
						["C1"] = CFrame.new(0,0,0),
					}):Play()
				elseif not cfg.ScalerDoor and cfg.CustomDoorTween then
					tweenService:Create(v.Door,TweenInfo.new(S,cfg.DoorCloseEasing,cfg.CloseEasingInOut),{
						["CFrame"] = v.Closed.CFrame,
					}):Play()
				elseif not cfg.ScalerDoor and not cfg.CustomDoorTween then
					tweenService:Create(v.Door,TweenInfo.new(S,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{
						["CFrame"] = v.Closed.CFrame,
					}):Play()
				end
			end
		end

		local function openDoors(bypass)
			--/ Safety Checks /--
			if pdsftybypass or bypass then
				-- Safety checks bypassed
			elseif math.abs(roundoff(shaft[tostring(floor)].Level.Position.Y,3) - roundoff(car.Platform.Position.Y,3)) > (cfg.levelTolerance*10) then
				-- We are too far from the door zone, it is unsafe to open the doors
				return
			elseif nudgeCounter > cfg.reopenLimit then
				-- The door is nudging closed
				return
			elseif travelling == true then
				-- The lift is moving
				return
			elseif mode == "manual" then
				-- We are in manual
				return
			end
			if doors then
				doorTimer = cfg.openTime
				return
			end
			doorState = "Opening"
			ref.Parent.DoorState.Value = "Opening"
			if mode == "auto" then allowhandlecall = true end
			doors = true
			doorTimer = cfg.openTime

			--/ Sound Chime /--
			if floorDirs[floor] then
				direction = floorDirs[floor]
			elseif floor == bottomFloor then
				direction = 1
			elseif floor == topFloor then
				direction = -1
			end
			if (not cfg.ChimeBeforeDoor and not cfg.NoChimeReopen) and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
				if direction == 1 or direction == 0 then
					if cfg.upChime then
						spawn(cfg.upChime)
					end
				elseif direction == -1 then
					if cfg.downChime then
						spawn(cfg.downChime)
					end
				end
			end

			--/ Light Lamps /--
			if not (cfg.CallOnlyLantern and floorcalls[floor] == false) then
				LanternHandler(floor)
			end

			--/ Narrator /--
			if cfg.narrator and not (cfg.NoVoiceReopen and reopen == true) then
				spawn(function() 
					if (cfg.CustomVoice ~= nil and cfg.CustomVoice ~= false) and cfg.DoorOpeningSound then
						coroutine.resume(coroutine.create(voiceRoutine), 2, direction)
					elseif ((not cfg.NoVoiceWhenCall and not (cfg.VoiceBeforeDoor and callbuttontrigger == false)) or (not cfg.NoVoiceReopen and reopen == true)) and not cfg.DoorOpeningSound then
						coroutine.resume(coroutine.create(voiceRoutine), 1, direction)
					end
				end)
			end
			if car.Platform:FindFirstChild("DoorOpen") then
				if not sftybypass then
					car.Platform.DoorOpen:Play()
					car.Platform.DoorClose:Stop()
					car.Platform.DoorClose.TimePosition = 0
				end
			end
			--/ Open Doors /--
			if cfg.OpenOutDoorFirst then
				if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
					shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("FrontDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("FrontDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
				if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
					shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("RearDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("RearDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
				if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
					shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("LeftDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("LeftDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
				if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
					shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("RightDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("RightDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
			else
				if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
					car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("FrontDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("FrontDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
				if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
					car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("RearDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("RearDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
				if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
					car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("LeftDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("LeftDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
				if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
					car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Opening")
					carDoorsOpen("RightDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
					if cfg.DoorDelay then
						task.wait(cfg.DoorDelay)
					end
					shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Opening")
					floorDoorsOpen("RightDoor",(cfg.doorOpenTime ~= nil and cfg.doorOpenTime or cfg.doorMoveTime))
				end
			end
			--/ Flash Green /--
			for i=1,(cfg.doorOpenTime and cfg.doorOpenTime*2.5 or cfg.doorMoveTime*2.5) do
				if i % 2 == 1 then
					if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
						for i,v in pairs(car.FrontDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Lime green")
							end
						end
					end
					if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
						for i,v in pairs(car.RearDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Lime green")
							end
						end
					end
					if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
						for i,v in pairs(car.LeftDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Lime green")
							end
						end
					end
					if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
						for i,v in pairs(car.RightDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Lime green")
							end
						end
					end
				else
					if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
						for i,v in pairs(car.FrontDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Really black")
							end
						end
					end
					if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
						for i,v in pairs(car.RearDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Really black")
							end
						end
					end
					if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
						for i,v in pairs(car.LeftDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Really black")
							end
						end
					end
					if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
						for i,v in pairs(car.RightDoor:GetChildren()) do
							if cfg.ScalerDoor and v:FindFirstChild("LED") then
								for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
									if b:isA("BasePart") then
										b.BrickColor = BrickColor.new("Lime green")
									end
								end
							elseif not cfg.ScalerDoor and v.Name == "LED" then
								v.Door.BrickColor = BrickColor.new("Really black")
							end
						end
					end
				end
				if not doors then return end
				task.wait(0.47)
			end
			--/ Solid Green /--
			if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
				for i,v in pairs(car.FrontDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Lime green")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Lime green")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
				for i,v in pairs(car.RearDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Lime green")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Lime green")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
				for i,v in pairs(car.LeftDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Lime green")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Lime green")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
				for i,v in pairs(car.RightDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Lime green")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Lime green")
					end
				end
			end
			if cfg.narrator and not cfg.DirSoundWhenMove and not (cfg.NoVoiceReopen and reopen == true) and cfg.VoiceBeforeDoor and not cfg.DoorOpeningSound then
				coroutine.resume(coroutine.create(voiceRoutine), 4, direction)
			end
			reopen = false
			doorState = "Open"
			ref.Parent.DoorState.Value = "Open"				
			if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
				car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Open")
				shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Open")
			end
			if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
				car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Open")
				shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Open")
			end
			if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
				car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Open")
				shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Open")
			end
			if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
				car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Open")
				shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Open")
			end
			--/ Door Timer /--
			while (doorTimer > 0 or doorHold) and not (mode == "manual") do
				task.wait(1)
				doorTimer = doorTimer - 1
			end
			--/ Unlight Lamps /--
			if not cfg.LanternUnlitAfterDoor then
				LanternUnlit()
			end

			--/ Close Doors /--
			ref.Parent.DoorState.Value = "Closing"
			if cfg.DoorClosingSound == true and cfg.narrator and (cfg.CustomVoice ~= nil and cfg.CustomVoice ~= false) then
				coroutine.resume(coroutine.create(voiceRoutine), 3)
			end
			if (nudgeCounter > cfg.reopenLimit or (mode ~= "auto" and mode ~= "priority")) and not quickClose then
				doors = false
				doorState = "Closing"
				if car.Platform:FindFirstChild("DoorClose") then
					car.Platform.DoorClose.PlaybackSpeed = DCPitch * 0.5
					car.Platform.DoorClose:Play()
				end		
				if cfg.CloseInDoorFirst then
					if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
						car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
					if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
						car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
					if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
						car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
					if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
						car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RightDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RightDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
				else
					if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
						shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
					if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
						shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
					if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
						shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
					if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
						shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RightDoor",cfg.doorCloseTime*2)
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RightDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2)
					end
				end
			else
				task.wait(cfg.DelayBeforeClose ~= nil and cfg.DelayBeforeClose or 0)
				doors = false
				doorState = "Closing"
				if car.Platform:FindFirstChild("DoorClose") then
					car.Platform.DoorClose.PlaybackSpeed = DCPitch
					car.Platform.DoorClose:Play()
				end	
				if cfg.CloseInDoorFirst then
					if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
						car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
					if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
						car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
					if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
						car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
					if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
						car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RightDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RightDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
				else
					if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
						shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("FrontDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
					if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
						shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RearDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
					if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
						shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("LeftDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
					if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
						shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						floorDoorsClose("RightDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
						if cfg.DoorDelay then
							task.wait(cfg.DoorDelay)
						end
						car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closing")
						carDoorsClose("RightDoor",(cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime))
					end
				end
			end

			--/ Ignored Sensor /--
			if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and ignoreFrontDoor then
				for i,v in pairs(car.FrontDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and ignoreRearDoor then
				for i,v in pairs(car.RearDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and ignoreLeftDoor then
				for i,v in pairs(car.LeftDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and ignoreRightDoor then
				for i,v in pairs(car.RightDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end

			--/ Flash Red /--
			if (nudgeCounter > cfg.reopenLimit or (mode ~= "auto" and mode ~= "priority")) and not quickClose then
				if car.Platform:FindFirstChild("Nudge") then
					car.Platform.Nudge:Play()
				end
				for i=1,(cfg.doorCloseTime and cfg.doorCloseTime*4 or cfg.doorMoveTime*4) do
					if not car.Platform:FindFirstChild("Nudge") then
						car.Platform.Beep.PlaybackSpeed = 2
						car.Platform.Beep:Play()
					end
					if i % 2 == 1 then
						if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
							for i,v in pairs(car.FrontDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
							for i,v in pairs(car.RearDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
							for i,v in pairs(car.LeftDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
							for i,v in pairs(car.RightDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
					else
						if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
							for i,v in pairs(car.FrontDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
							for i,v in pairs(car.RearDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
							for i,v in pairs(car.LeftDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
							for i,v in pairs(car.RightDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
					end
					if doors then 
						nudgeCounter = nudgeCounter + 1
						return 
					end
					task.wait(0.47)
				end
				if car.Platform:FindFirstChild("Nudge") then
					car.Platform.Nudge:Stop()
				end
			else
				for i=1,(cfg.doorCloseTime and cfg.doorCloseTime*2 or cfg.doorMoveTime*2) do
					if i % 2 == 1 then
						if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
							for i,v in pairs(car.FrontDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
							for i,v in pairs(car.RearDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
							for i,v in pairs(car.LeftDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
							for i,v in pairs(car.RightDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really red")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really red")
								end
							end
						end
					else
						if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") and not ignoreFrontDoor then
							for i,v in pairs(car.FrontDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") and not ignoreRearDoor then
							for i,v in pairs(car.RearDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") and not ignoreLeftDoor then
							for i,v in pairs(car.LeftDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
						if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") and not ignoreRightDoor then
							for i,v in pairs(car.RightDoor:GetChildren()) do
								if cfg.ScalerDoor and v:FindFirstChild("LED") then
									for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
										if b:isA("BasePart") then
											b.BrickColor = BrickColor.new("Really black")
										end
									end
								elseif not cfg.ScalerDoor and v.Name == "LED" then
									v.Door.BrickColor = BrickColor.new("Really black")
								end
							end
						end
					end
					if doors then 
						nudgeCounter = nudgeCounter + 1
						return 
					end
					task.wait(0.47)
				end
			end
			--/ Turn Off /--
			if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
				for i,v in pairs(car.FrontDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
				for i,v in pairs(car.RearDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
				for i,v in pairs(car.LeftDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end
			if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
				for i,v in pairs(car.RightDoor:GetChildren()) do
					if cfg.ScalerDoor and v:FindFirstChild("LED") then
						for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
							if b:isA("BasePart") then
								b.BrickColor = BrickColor.new("Really black")
							end
						end
					elseif not cfg.ScalerDoor and v.Name == "LED" then
						v.Door.BrickColor = BrickColor.new("Really black")
					end
				end
			end
			task.wait(((cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2.5-math.floor((cfg.doorCloseTime ~= nil and cfg.doorCloseTime or cfg.doorMoveTime)*2.5))*0.4)

			if cfg.LanternUnlitAfterDoor then
				LanternUnlit()
			end

			quickClose = false
			doorState = "Closed"
			ref.Parent.DoorState.Value = "Closed"

			if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
				car:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closed")
				shaft[tostring(floor)]:FindFirstChild("FrontDoor"):SetAttribute("DoorState", "Closed")
			end
			if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
				car:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closed")
				shaft[tostring(floor)]:FindFirstChild("RearDoor"):SetAttribute("DoorState", "Closed")
			end
			if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
				car:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closed")
				shaft[tostring(floor)]:FindFirstChild("LeftDoor"):SetAttribute("DoorState", "Closed")
			end
			if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
				car:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closed")
				shaft[tostring(floor)]:FindFirstChild("RightDoor"):SetAttribute("DoorState", "Closed")
			end

			if mode == "auto" then allowhandlecall = true end
		end
		local function forceOpenDoors()
			openDoors(true)
		end
		local function closeDoors()
			doorTimer = 0
		end
		local function realisticStop() --Implemented by Program_T042
			coroutine.resume(coroutine.create(function()
				local val = (cfg.RealStopInitialize ~= nil and -cfg.RealStopInitialize or -.4)
				local div = 1
				for i=1,40 do
					task.wait()
					val = val + (cfg.RealStopOffset ~= nil and cfg.RealStopOffset or .4)
					div = div + .5
					motor = ((math.sin(val)/div))*1.07
				end
				motor = 0
			end))
		end
		local function toFloor(lvl,override)
			--/ Conditions /--
			if lvl == floor and not override then
				-- We're already on this floor.
				calls[floor] = false
				floorcalls[floor] = false
				return false
			end
			if not safety and not override then
				-- Safety is broken.
				return true
			end
			local height = roundoff(shaft[tostring(lvl)].Level.Position.Y,3)
			travelling = true
			nextstop = lvl
			ref.Parent.NextStop.Value = nextstop
			nudgeCounter = 0
			if cfg.FastInd and mode == "auto" then
				if ref.Parent.Floor.Value < nextstop then
					for i, v in pairs(allFloors) do
						if v == floor then
							ref.Parent.Floor.Value = allFloors[i+1]
						end
					end
				elseif ref.Parent.Floor.Value > nextstop then
					for i, v in pairs(allFloors) do
						if v == floor then
							ref.Parent.Floor.Value = allFloors[i-1]
						end
					end
				end
			end
			--/ Weld /--
			local function Weld(a, b)
				local v = Instance.new("ManualWeld")
				v.Part0 = a 
				v.Part1 = b 
				v.C0 = CFrame.new()  
				v.C1 = b.CFrame:inverse() * a.CFrame
				return v;
			end
			if cfg.weldPlayers then
				for i,v in pairs(car.Sensor:GetTouchingParts()) do
					if v.Name == "HumanoidRootPart" and v.Parent:FindFirstChild("Humanoid") then
						if not v:FindFirstChild("ManualWeld") then
							v.Parent.Humanoid.PlatformStand = true
							--local w = Instance.new("ManualWeld",v)
							--w.Part0 = car.Platform
							--w.Part1 = v
							--w.C0 = car.Platform.CFrame:inverse() * v.CFrame
							Weld(car.Platform,v).Parent = car.Sensor
						end
					end
				end
			end
			local lastAlt = car.Platform.Position.Y

			if cfg.DirSoundWhenMove and cfg.narrator and (cfg.CustomVoice ~= nil and cfg.CustomVoice ~= false) then
				coroutine.resume(coroutine.create(voiceRoutine), 4, direction)
			end

			if cfg.NewMotorPlay and cfg.MotorStartDelay and not cfg.PitchMotor then
				motorMode = "start"
				ref.Parent.MotorMode.Value = "start"
				car.Platform.Start:Play()
				task.wait(cfg.MotorStartDelay)
			elseif cfg.NewMotorPlay and not cfg.MotorStartDelay and not cfg.PitchMotor then
				motorMode = "start"
				ref.Parent.MotorMode.Value = "start"
				car.Platform.Start:Play()
			elseif cfg.NewMotorPlay and cfg.MotorStartDelay and cfg.PitchMotor then
				motorMode = "start"
				ref.Parent.MotorMode.Value = "start"
				task.wait(cfg.MotorStartDelay)
			end
			--/ Cruising /--
			if cfg.NewMotorPlay then
				motorMode = "run"
				ref.Parent.MotorMode.Value = "run"
				if not cfg.PitchMotor then
					car.Platform.Run:Play()
				end
			end
			while math.abs((height-car.Platform.Position.Y)/velocity) >= ((math.abs(velocity)/cfg.braking)/10)+(cfg.levelMargin or 0.5) and (mode == "auto" or mode == "fire" or mode == "priority") do
				if height - car.Platform.Position.Y > 0 then
					motor = cfg.maxSpeed
				else
					motor = 0-cfg.maxSpeed
				end
				runService.Heartbeat:wait()
			end

			--/ Leveling /-- (Predoor added by DiamondDoesStuff)
			local spd = velocity
			local dist = math.abs(height-car.Platform.Position.Y)
			local lanternDone = false
			local preDoorChime = false
			while math.abs(height-car.Platform.Position.Y) >= cfg.levelTolerance and (mode == "auto" or mode == "fire" or mode == "priority") do
				if not cfg["levelingType"] or cfg["levelingType"] == "Legacy" then
					motor = (height-car.Platform.Position.Y) / (cfg.braking*0.65)--Lantern
				elseif cfg["levelingType"] == "Intelligent" then
					motor = (math.abs(spd)/dist)*(height-car.Platform.Position.Y)
				end
				if not lanternDone and mode == "auto" and floor == lvl then
					if cfg.ChimeBeforeDoor and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
						--Chime Before Doors
						if floorDirs[floor] then
							if floorDirs[floor] == 1 then
								spawn(cfg.upChime)
							elseif floorDirs[floor] == -1 then
								spawn(cfg.downChime)
							end
						elseif floor == bottomFloor then
							if cfg.upChime then
								spawn(cfg.upChime)
							end
						elseif floor == topFloor then
							if cfg.downChime then
								spawn(cfg.downChime)
							end
						elseif direction == 1 then
							if cfg.upChime then
								spawn(cfg.upChime)
							end
						elseif direction == -1 then
							if cfg.downChime then
								spawn(cfg.downChime)
							end
						end
					end
					if cfg.LanternBeforeDoor and not (cfg.CallOnlyLantern and floorcalls[floor] == false) then
						--Chime Before Doors
						LanternHandler(floor)
					end
					if cfg.narrator and (cfg.VoiceBeforeDoor or cfg.DoorOpeningSound) then
						if floorDirs[floor] then
							if floorDirs[floor] == 1 then
								coroutine.resume(coroutine.create(voiceRoutine), 1, 1)
							elseif floorDirs[floor] == -1 then
								coroutine.resume(coroutine.create(voiceRoutine), 1, -1)
							end
						elseif floor == bottomFloor then
							coroutine.resume(coroutine.create(voiceRoutine), 1, 1)
						elseif floor == topFloor then
							coroutine.resume(coroutine.create(voiceRoutine), 1, -1)
						elseif direction == 1 then
							coroutine.resume(coroutine.create(voiceRoutine), 1, 1)
						elseif direction == -1 then
							coroutine.resume(coroutine.create(voiceRoutine), 1, -1)
						end
					end
					lanternDone = true
				end
				if cfg.PreDoorOffset and cfg.PreDoorOffset > 0 and mode == "auto" then
					if math.abs(height-car.Platform.Position.Y) <= cfg.PreDoorOffset then
						if safety == true then
							pdsftybypass = true
							if cfg.weldPlayers then
								for i,v in pairs(car.Sensor:GetChildren()) do
									if v.Name == "ManualWeld" then	
										spawn(function()
											if v.Part1.Parent ~= nil then
												v.Part1.Parent.Humanoid.PlatformStand = false
											end
											v:Destroy()	
										end)		
									end
								end
							end
							if floorDirs[floor] then
								direction = floorDirs[floor]
							elseif floor == bottomFloor then
								direction = 1
							elseif floor == topFloor then
								direction = -1
							end
							if not cfg.ChimeBeforeDoor and cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) and not preDoorChime then
								if direction == 1 or direction == 0 then
									if cfg.upChime then
										spawn(cfg.upChime)
									end
								elseif direction == -1 then
									if cfg.downChime then
										spawn(cfg.downChime)
									end
								end
							end
							preDoorChime = true
							if doorDir[floor] then
								DoorDirBin(doorDir[floor])
								spawn(openDoors)
							else
								DoorDirBin(15)
								spawn(openDoors)
							end
						end
					end
				end
				if cfg.NewMotorPlay and cfg.LevelSoundBDoor and cfg.motorCutoff ~= nil then
					if math.abs(height-car.Platform.Position.Y) <= cfg.motorCutoff and motorMode ~= "stop" then
						motorMode = "stop"
						ref.Parent.MotorMode.Value = "stop"
						if not cfg.PitchMotor then
							car.Platform.Start:Stop()
							car.Platform.Run:Stop()
							car.Platform.Stop:Play()
						end
					end
				end
				if math.abs(motor) < cfg.minSpeed then
					if motor > 0 then
						motor = cfg.minSpeed
					else
						motor = 0-cfg.minSpeed
					end
				end
				if motor > cfg.maxSpeed then
					motor = cfg.maxSpeed
				elseif motor < 0-cfg.maxSpeed then
					motor = 0-cfg.maxSpeed
				end
				runService.Heartbeat:wait()
			end			
			pdsftybypass=false
			if cfg.NewMotorPlay and cfg.LevelSoundBDoor then
				motorMode = "stop"
				ref.Parent.MotorMode.Value = "stop"
				if not cfg.PitchMotor then
					car.Platform.Start:Stop()
					car.Platform.Run:Stop()
				end
			elseif cfg.NewMotorPlay and not cfg.LevelSoundBDoor then
				motorMode = "stop"
				ref.Parent.MotorMode.Value = "stop"
				if not cfg.PitchMotor then
					car.Platform.Start:Stop()
					car.Platform.Run:Stop()
					car.Platform.Stop:Play()
				end
			end
			--/ Unweld /--
			if cfg.weldPlayers then
				for i,v in pairs(car.Sensor:GetChildren()) do
					if v.Name == "ManualWeld" then	
						spawn(function()
							if v.Part1.Parent ~= nil then
								v.Part1.Parent.Humanoid.PlatformStand = false
							end
							v:Destroy()	
						end)		
					end
				end
			end
			--/ Stop Lift /--
			if mode == "auto" then
				allowhandlecall = false
			end
			if floorDirs[floor] then
				direction = floorDirs[floor]
			elseif floor == bottomFloor then
				direction = 1
			elseif floor == topFloor then
				direction = -1
			elseif direction == 1 then
				direction = 1
			elseif direction == -1 then
				direction = -1
			end
			motor = 0
			velocity = 0
			for i,v in pairs(shaft[tostring(floor)]:GetChildren()) do
				if v.Name == "Call" or v.Name == "UpCall" or v.Name == "DownCall" then
					ButtonLightOff(v)
				end
			end
			for _,p in pairs(car:GetChildren()) do
				if p.Name == "Panel" then
					for i,v in pairs(p:GetChildren()) do
						if tonumber(v.Name) == floor then
							ButtonLightOff(v)
						end
					end
				end
			end
			runService.Heartbeat:wait()
			local callsComplete = true
			for i,v in pairs(calls) do
				if v then
					callsComplete = false
				end
			end
			--[[if callsComplete then
				direction = 0
			end]]

			--/ Relevel /--
			if cfg.NewMotorPlay and (cfg.PreOpen and cfg.PreOpen ~= 0) then
				if not releveling then
					releveling = true
					while (math.abs(roundoff(car.Platform.Position.Y,3)-height) > 0 and motor == 0) and (mode == "auto" or mode == "fire" or mode == "priority") do
						local dist = height-roundoff(car.Platform.Position.Y,3)
						if dist > 0.01 then
							dist = 0.01
						elseif dist < -0.01 then
							dist = -0.01
						end
						if not cfg.cframe then
							car:SetPrimaryPartCFrame(car.Platform.CFrame * CFrame.new(0,dist,0))
							--elseif cfg.cframe and cfg.TweenLeveling then
							--tweenService:Create(ref.Cable_Attachment.Cable_Main.Part1, TweenInfo.new(0.1), {CFrame = ref.Cable_Attachment.Cable_Main.Part1.CFrame * CFrame.new(0, dist, 0)}):Play()
						else
							ref.Cable_Attachment.Cable_Main.Part1.CFrame = ref.Cable_Attachment.Cable_Main.Part1.CFrame * CFrame.new(0, dist, 0)
							--car.Platform.CFrame = car.Platform.CFrame * CFrame.new(0, dist, 0)
						end
						runService.Heartbeat:wait()
					end
					releveling = false
				end
				if not cfg.DisableRealisticStop then
					realisticStop()
				end
			end

			if cfg.NewMotorPlay then
				motorMode = "idle"
				ref.Parent.MotorMode.Value = "idle"
			end

			if cfg.PreOpen and (not cfg.PreDoorOffset or cfg.PreDoorOffset <= 0) then
				task.wait(cfg.PreOpen)
			end

			--/ Open Doors /--
			if mode == "auto" then
				if cfg.idleHold then
					doorHold = true
				end
				if not cfg.PreDoorOffset or cfg.PreDoorOffset <= 0 then
					if floorDirs[floor] then
						direction = floorDirs[floor]
					elseif floor == bottomFloor then
						direction = 1
					elseif floor == topFloor then
						direction = -1
					end
					if not cfg.ChimeBeforeDoor and cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
						if direction == 1 or direction == 0 then
							if cfg.upChime then
								spawn(cfg.upChime)
							end
						elseif direction == -1 then
							if cfg.downChime then
								spawn(cfg.downChime)
							end
						end
					end
					if doorDir[floor] then
						DoorDirBin(doorDir[floor])
						spawn(openDoors)
					else
						DoorDirBin(15)
						spawn(openDoors)
					end
				end
			end

			if not cfg.NewMotorPlay or (not cfg.PreOpen or cfg.PreOpen == 0) then
				if not releveling then
					releveling = true
					while (math.abs(roundoff(car.Platform.Position.Y,3)-height) > 0 and motor == 0) and (mode == "auto" or mode == "fire" or mode == "priority") do
						local dist = height-roundoff(car.Platform.Position.Y,3)
						if dist > 0.01 then
							dist = 0.01
						elseif dist < -0.01 then
							dist = -0.01
						end
						if not cfg.cframe then
							car:SetPrimaryPartCFrame(car.Platform.CFrame * CFrame.new(0,dist,0))
							--elseif cfg.cframe and cfg.TweenLeveling then
							--tweenService:Create(ref.Cable_Attachment.Cable_Main.Part1, TweenInfo.new(0.1), {CFrame = ref.Cable_Attachment.Cable_Main.Part1.CFrame * CFrame.new(0, dist, 0)}):Play()
						else
							ref.Cable_Attachment.Cable_Main.Part1.CFrame = ref.Cable_Attachment.Cable_Main.Part1.CFrame * CFrame.new(0, dist, 0)
							--car.Platform.CFrame = car.Platform.CFrame * CFrame.new(0, dist, 0)
						end
						runService.Heartbeat:wait()
					end
					releveling = false
				end
				if not cfg.DisableRealisticStop then
					realisticStop()
				end
			end
			safety = false
			travelling = false
			return true
		end
		local function handleCalls()
			idleTimer = idleTimer + 0.25
			--[[if floor == bottomFloor then
				direction = 1
			elseif floor == topFloor then
				direction = -1
			end]]
			local nearDist = 4096
			local nearCall = false
			for i,v in pairs(calls) do
				if math.abs(i-floor) < nearDist and v then
					if i == floor then
						-- Call is on current floor. Ignore call
					elseif direction == -1 and i-floor > 0 then
						-- Call is above, direction is down. Ignore call
					elseif direction == 1 and i-floor < 0 then
						-- Call is below, direction is up. Ignore call
					else
						-- Passed all direction checks, we can add it now
						nearDist = math.abs(i-floor)
						nearCall = i
					end
				end
			end
			if nearCall then
				-- Set direction if not set.
				local callsBelow = false
				local callsAbove = false
				for i,v in pairs(calls) do
					if v then
						if i > floor then
							callsAbove = true
						elseif i < floor then
							callsBelow = true
						end
					end
				end
				if not callsAbove then
					if callsBelow then
						direction = -1
					else
						direction = 0
					end
				elseif not callsBelow then
					if callsAbove then
						direction = 1
					else
						direction = 0
					end
				end
				if direction == 0 then
					if nearCall-floor > 0 then
						direction = 1
					elseif nearCall-floor < 0 then
						direction = -1
					end
				end
				if doors and cfg.idleHold and doorHold and mode == "auto" then
					doorHold = false
				end
				if not doors and safety and motor == 0 and not travelling then
					toFloor(nearCall)
					calls[nearCall] = false
					floorcalls[nearCall] = false
				end
				return
			else
				if doorState == "Closed" and idleTimer > 1 then
					-- Reset direction
					direction = 0
					for i,v in pairs(floorDirs) do
						floorDirs[i] = false
					end
					for i,v in pairs(floorDirs) do
						doorDir[i] = false
					end
					nudgeCounter = 0
				end
				return
			end
		end

		--/ Events /--
		if not ref.Parent:FindFirstChild("DestCall") then
			local val = Instance.new("NumberValue",ref.Parent)
			val.Name = "DestCall"
			val.Value = bottomFloor-1
		end
		if not ref.Parent:FindFirstChild("NextStop") then
			local val = Instance.new("NumberValue",ref.Parent)
			val.Name = "NextStop"
			val.Value = nextstop
		end
		if not ref.Parent:FindFirstChild("Floor") then
			local val = Instance.new("NumberValue",ref.Parent)
			val.Name = "Floor"
			val.Value = floor
		end
		if not ref.Parent:FindFirstChild("SurfLocked") then
			local val = Instance.new("BoolValue",ref.Parent)
			val.Name = "SurfLocked"
			val.Value = cfg.SurfLocked ~= nil and cfg.SurfLocked or false
		end
		if not ref.Parent:FindFirstChild("Direction") then
			local val = Instance.new("NumberValue",ref.Parent)
			val.Name = "Direction"
		end
		if not ref.Parent:FindFirstChild("MaxSpeed") then
			local val = Instance.new("NumberValue",ref.Parent)
			val.Name = "MaxSpeed"
			val.Value = cfg.maxSpeed
		end
		if not ref.Parent:FindFirstChild("Velocity") then
			local val = Instance.new("NumberValue",ref.Parent)
			val.Name = "Velocity"
		end
		if not ref.Parent:FindFirstChild("MotorMode") then
			local val = Instance.new("StringValue",ref.Parent)
			val.Name = "MotorMode"
			val.Value = "idle"
		end
		if not ref.Parent:FindFirstChild("DoorState") then
			local val = Instance.new("StringValue",ref.Parent)
			val.Name = "DoorState"
			val.Value = "Closed"
		end
		if not ref.Parent:FindFirstChild("Mode") then
			local val = Instance.new("StringValue",ref.Parent)
			val.Name = "Mode"
			val.Value = "auto"
		end
		if not ref.Parent:FindFirstChild("ScriptCall") then
			local val = Instance.new("StringValue",ref.Parent)
			val.Name = "ScriptCall"
			val.Value = ""
		end
		if not ref.Parent:FindFirstChild("CardReader") then
			local val = Instance.new("BoolValue",ref.Parent)
			val.Name = "CardReader"
			val.Value = false
		end
		if not ref.Parent:FindFirstChild("eStop") then
			local val = Instance.new("BoolValue",ref.Parent)
			val.Name = "eStop"
			val.Value = false
		end
		if not car:FindFirstChild("Lantern") then
			local val = Instance.new("StringValue",car)
			val.Name = "Lantern"
			val.Value = "N"
		end
		if not ref.Parent:FindFirstChild("API") then
			local api = Instance.new("BindableFunction",ref.Parent)
			api.Name = "API"
		end

		for i,k in pairs(shaft:GetChildren()) do
			if not k:FindFirstChild("Lantern") then
				local val = Instance.new("StringValue",k)
				val.Name = "Lantern"
				val.Value = "N"
			end
		end

		for i,k in pairs(shaft:GetChildren()) do
			if cfg.CallLock ~= nil then
				for i = 1, #cfg.CallLock do
					if tonumber(k.Name) == cfg.CallLock[i] then
						local val = Instance.new("BoolValue",k)
						val.Name = "CardReader"
						val.Value = false
					end
				end
			end
		end

		ref.Parent.DestCall.Changed:connect(function(val)
			if shaft:FindFirstChild(tostring(val)) then
				ref.Parent.DestCall.Value = bottomFloor-1
				if val == floor and mode == "auto" and travelling == false then 
					if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
						if direction == 1 or direction == 0 then
							if cfg.upChime then
								spawn(cfg.upChime)
							end
						elseif direction == -1 then
							if cfg.downChime then
								spawn(cfg.downChime)
							end
						end
					end
					reopen = true
					DoorDirBin(15)
					openDoors()
				else
					calls[val] = true
					floorcalls[val] = true
				end
			end
		end)
		ref.Parent.ScriptCall.Changed:connect(function(val)
			if shaft:FindFirstChild(tostring(val)) then
				ref.Parent.ScriptCall.Value = ""
				if floor ~= tonumber(val) then
					if cfg.LockedFloors ~= nil then
						for i = 1, #cfg.LockedFloors do
							if tonumber(val) == cfg.LockedFloors[i] then
								if ref.Parent.CardReader.Value == true then
									calls[tonumber(val)] = true
									floorcalls[tonumber(val)] = true
								else return end
							else
								calls[tonumber(val)] = true
								floorcalls[tonumber(val)] = true
							end
						end
					else
						calls[tonumber(val)] = true
						floorcalls[tonumber(val)] = true
					end
				elseif not doors and not calls[floor] and motor == 0 and mode == "auto" and travelling == false then
					if mode == "auto" and motor == 0 then
						if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen then
							if direction == 1 or direction == 0 and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
								if cfg.upChime then
									spawn(cfg.upChime)
								end
							elseif direction == -1 then
								if cfg.downChime then
									spawn(cfg.downChime)
								end
							end
						end
						reopen = true
						DoorDirBin(15)
						openDoors()
					end
				end
			end
		end)
		if car:FindFirstChild("FrontDoor") then
			for i,v in pairs(car.FrontDoor:GetChildren()) do
				if cfg.ScalerDoor then
					for x,x in pairs(v:GetDescendants()) do
						if x:IsA("Part") and x:IsA("WedgePart") or x:IsA("CornerWedgePart") or x:IsA("UnionOperation") or x:IsA("MeshPart") then 
							x.Touched:connect(function(obj)
								if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
									-- Reopening Front Foors
									if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										spawn(function()
											for i,v in pairs(car.FrontDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Gold")
														end
													end
												end
											end
											task.wait(0.5)
											for i,v in pairs(car.FrontDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Lime green")
														end
													end
												end
											end
										end)
										reopen = true
										DoorDirBin(1)
										openDoors()
									end

								end
							end)
						end
					end
				else	
					v.Door.Touched:connect(function(obj)
						if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
							-- Reopening Front Foors
							if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
								if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
									if direction == 1 or direction == 0 then
										if cfg.upChime then
											spawn(cfg.upChime)
										end
									elseif direction == -1 then
										if cfg.downChime then
											spawn(cfg.downChime)
										end
									end
								end
								spawn(function()
									for i,v in pairs(car.FrontDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Gold")
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.FrontDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Lime green")
										end
									end
								end)
								reopen = true
								DoorDirBin(1)
								openDoors()
							end

						end
					end)
				end
			end
		end	
		if car:FindFirstChild("RearDoor") then
			for i,v in pairs(car.RearDoor:GetChildren()) do
				if cfg.ScalerDoor then
					for x,x in pairs(v:GetDescendants()) do
						if x:IsA("Part") and x:IsA("WedgePart") or x:IsA("CornerWedgePart") or x:IsA("UnionOperation") or x:IsA("MeshPart") then 
							x.Touched:connect(function(obj)
								if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
									-- Reopening Front Foors
									if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										spawn(function()
											for i,v in pairs(car.RearDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Gold")
														end
													end
												end
											end
											task.wait(0.5)
											for i,v in pairs(car.RearDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Lime green")
														end
													end
												end
											end
										end)
										reopen = true
										DoorDirBin(2)
										openDoors()
									end

								end
							end)
						end						
					end
				else					
					v.Door.Touched:connect(function(obj)
						if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
							-- Reopening Front Foors
							if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
								if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen then
									if direction == 1 or direction == 0 and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if cfg.upChime then
											spawn(cfg.upChime)
										end
									elseif direction == -1 then
										if cfg.downChime then
											spawn(cfg.downChime)
										end
									end
								end
								spawn(function()
									for i,v in pairs(car.RearDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Gold")
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.RearDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Lime green")
										end
									end
								end)
								reopen = true
								DoorDirBin(2)
								openDoors()
							end

						end
					end)
				end
			end
		end
		if car:FindFirstChild("LeftDoor") then
			for i,v in pairs(car.LeftDoor:GetChildren()) do
				if cfg.ScalerDoor then
					for x,x in pairs(v:GetDescendants()) do
						if x:IsA("Part") and x:IsA("WedgePart") or x:IsA("CornerWedgePart") or x:IsA("UnionOperation") or x:IsA("MeshPart") then 
							x.Touched:connect(function(obj)
								if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
									-- Reopening Front Foors
									if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen then
											if direction == 1 or direction == 0 and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										spawn(function()
											for i,v in pairs(car.LeftDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Gold")
														end
													end
												end
											end
											task.wait(0.5)
											for i,v in pairs(car.LeftDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Lime green")
														end
													end
												end
											end
										end)
										reopen = true
										DoorDirBin(4)
										openDoors()
									end

								end
							end)
						end	
					end
				else
					v.Door.Touched:connect(function(obj)
						if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
							-- Reopening Front Foors
							if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
								if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen then
									if direction == 1 or direction == 0 and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if cfg.upChime then
											spawn(cfg.upChime)
										end
									elseif direction == -1 then
										if cfg.downChime then
											spawn(cfg.downChime)
										end
									end
								end
								spawn(function()
									for i,v in pairs(car.LeftDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Gold")
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.LeftDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Lime green")
										end
									end
								end)
								reopen = true
								DoorDirBin(4)
								openDoors()
							end

						end
					end)
				end
			end
		end
		if car:FindFirstChild("RightDoor") then
			for i,v in pairs(car.RightDoor:GetChildren()) do
				if cfg.ScalerDoor then
					for x,x in pairs(v:GetDescendants()) do
						if x:IsA("Part") and x:IsA("WedgePart") or x:IsA("CornerWedgePart") or x:IsA("UnionOperation") or x:IsA("MeshPart") then 
							x.Touched:connect(function(obj)
								if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
									-- Reopening Front Foors
									if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen then
											if direction == 1 or direction == 0 and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										spawn(function()
											for i,v in pairs(car.RightDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Gold")
														end
													end
												end
											end
											task.wait(0.5)
											for i,v in pairs(car.RightDoor:GetChildren()) do
												if v:FindFirstChild("LED") then
													for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
														if b:isA("BasePart") then
															b.BrickColor = BrickColor.new("Lime green")
														end
													end
												end
											end
										end)
										reopen = true
										DoorDirBin(8)
										openDoors()
									end

								end
							end)	
						end
					end						
				else
					v.Door.Touched:connect(function(obj)
						if not cfg.disableBumper and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState == "Closing" and nudgeCounter <= cfg.reopenLimit and mode == "auto" then
							-- Reopening Front Foors
							if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
								if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen then
									if direction == 1 or direction == 0 and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if cfg.upChime then
											spawn(cfg.upChime)
										end
									elseif direction == -1 then
										if cfg.downChime then
											spawn(cfg.downChime)
										end
									end
								end
								spawn(function()
									for i,v in pairs(car.RightDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Gold")
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.RightDoor:GetChildren()) do
										if v.Name == "LED" then
											v.Door.BrickColor = BrickColor.new("Lime green")
										end
									end
								end)
								reopen = true
								DoorDirBin(8)
								openDoors()
							end

						end
					end)
				end
			end
		end
		if car:FindFirstChild("FrontDoor") then
			for i,v in pairs(car.FrontDoor:GetChildren()) do
				if cfg.ScalerDoor then
					if car:FindFirstChild("DoorSensorFront") then
						car.DoorSensorFront.Touched:connect(function(obj)
							if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

								spawn(function()
									for i,v in pairs(car.FrontDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Gold")
												end
											end
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.FrontDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Lime green")
												end
											end
										end
									end
								end)

								if car.Platform:FindFirstChild("Sensor") then
									if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
								end
								-- Reopening Front Foors
								if doorState == "Closing" then
									if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										reopen = true
										DoorDirBin(1)
										openDoors()
									end
								end

							end
						end)
					end
				else
					v.Closed.Touched:connect(function(obj)
						if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

							spawn(function()
								for i,v in pairs(car.FrontDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Gold")
									end
								end
								task.wait(0.5)
								for i,v in pairs(car.FrontDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Lime green")
									end
								end
							end)

							if car.Platform:FindFirstChild("Sensor") then
								if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
							end
							-- Reopening Front Foors
							if doorState == "Closing" then
								if shaft[tostring(floor)]:FindFirstChild("FrontDoor") and car:FindFirstChild("FrontDoor") then
									if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if direction == 1 or direction == 0 then
											if cfg.upChime then
												spawn(cfg.upChime)
											end
										elseif direction == -1 then
											if cfg.downChime then
												spawn(cfg.downChime)
											end
										end
									end
									reopen = true
									DoorDirBin(1)
									openDoors()
								end
							end

						end
					end)
				end
			end
		end
		if car:FindFirstChild("RearDoor") then
			for i,v in pairs(car.RearDoor:GetChildren()) do
				if cfg.ScalerDoor then
					if car:FindFirstChild("DoorSensorRear") then
						car.DoorSensorRear.Touched:connect(function(obj)
							if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

								spawn(function()
									for i,v in pairs(car.RearDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Gold")
												end
											end
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.RearDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Lime green")
												end
											end
										end
									end
								end)

								if car.Platform:FindFirstChild("Sensor") then
									if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
								end
								-- Reopening Rear Foors
								if doorState == "Closing" then
									if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										reopen = true
										DoorDirBin(2)
										openDoors()
									end
								end

							end
						end)
					end
				else
					v.Closed.Touched:connect(function(obj)
						if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

							spawn(function()
								for i,v in pairs(car.RearDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Gold")
									end
								end
								task.wait(0.5)
								for i,v in pairs(car.RearDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Lime green")
									end
								end
							end)

							if car.Platform:FindFirstChild("Sensor") then
								if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
							end
							-- Reopening Front Foors
							if doorState == "Closing" then
								if shaft[tostring(floor)]:FindFirstChild("RearDoor") and car:FindFirstChild("RearDoor") then
									if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if direction == 1 or direction == 0 then
											if cfg.upChime then
												spawn(cfg.upChime)
											end
										elseif direction == -1 then
											if cfg.downChime then
												spawn(cfg.downChime)
											end
										end
									end
									reopen = true
									DoorDirBin(2)
									openDoors()
								end
							end

						end
					end)
				end
			end
		end
		if car:FindFirstChild("LeftDoor") then
			for i,v in pairs(car.LeftDoor:GetChildren()) do
				if cfg.ScalerDoor then
					if car:FindFirstChild("DoorSensorLeft") then
						car.DoorSensorLeft.Touched:connect(function(obj)
							if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

								spawn(function()
									for i,v in pairs(car.LeftDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Gold")
												end
											end
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.LeftDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Lime green")
												end
											end
										end
									end
								end)

								if car.Platform:FindFirstChild("Sensor") then
									if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
								end

								-- Reopening Front Foors
								if doorState == "Closing" then
									if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
											if direction == 1 or direction == 0 and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										reopen = true
										DoorDirBin(4)
										openDoors()
									end
								end
							end
						end)
					end
				else
					v.Closed.Touched:connect(function(obj)
						if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

							spawn(function()
								for i,v in pairs(car.LeftDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Gold")
									end
								end
								task.wait(0.5)
								for i,v in pairs(car.LeftDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Lime green")
									end
								end
							end)

							if car.Platform:FindFirstChild("Sensor") then
								if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
							end

							-- Reopening Front Foors
							if doorState == "Closing" then
								if shaft[tostring(floor)]:FindFirstChild("LeftDoor") and car:FindFirstChild("LeftDoor") then
									if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if direction == 1 or direction == 0 then
											if cfg.upChime then
												spawn(cfg.upChime)
											end
										elseif direction == -1 then
											if cfg.downChime then
												spawn(cfg.downChime)
											end
										end
									end
									reopen = true
									DoorDirBin(4)
									openDoors()
								end
							end
						end
					end)
				end
			end
		end
		if car:FindFirstChild("RightDoor") then
			for i,v in pairs(car.RightDoor:GetChildren()) do
				if cfg.ScalerDoor then
					if car:FindFirstChild("DoorSensorRight") then
						car.DoorSensorRight.Touched:connect(function(obj)
							if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

								spawn(function()
									for i,v in pairs(car.RightDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Gold")
												end
											end
										end
									end
									task.wait(0.5)
									for i,v in pairs(car.RightDoor:GetChildren()) do
										if v:FindFirstChild("LED") then
											for _,b in pairs(v:FindFirstChild("LED"):GetDescendants()) do
												if b:isA("BasePart") then
													b.BrickColor = BrickColor.new("Lime green")
												end
											end
										end
									end
								end)

								if car.Platform:FindFirstChild("Sensor") then
									if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
								end
								-- Reopening Front Foors
								if doorState == "Closing" then
									if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										reopen = true
										DoorDirBin(8)
										openDoors()
									end
								end

							end
						end)
					end
				else
					v.Closed.Touched:connect(function(obj)
						if cfg.doorSensors and obj.Parent:FindFirstChild("Humanoid") and not safety and doorState and nudgeCounter <= cfg.reopenLimit and mode == "auto" then

							spawn(function()
								for i,v in pairs(car.RightDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Gold")
									end
								end
								task.wait(0.5)
								for i,v in pairs(car.RightDoor:GetChildren()) do
									if v.Name == "LED" then
										v.Door.BrickColor = BrickColor.new("Lime green")
									end
								end
							end)

							if car.Platform:FindFirstChild("Sensor") then
								if car.Platform.Sensor.Playing == false then car.Platform.Sensor:Play() end
							end
							-- Reopening Front Foors
							if doorState == "Closing" then
								if shaft[tostring(floor)]:FindFirstChild("RightDoor") and car:FindFirstChild("RightDoor") then
									if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if direction == 1 or direction == 0 then
											if cfg.upChime then
												spawn(cfg.upChime)
											end
										elseif direction == -1 then
											if cfg.downChime then
												spawn(cfg.downChime)
											end
										end
									end
									reopen = true
									DoorDirBin(8)
									openDoors()
								end
							end

						end
					end)
				end
			end
		end

		for _,k in pairs(shaft:GetChildren()) do
			for i,v in pairs(k:GetChildren()) do 
				if v.Name == "Call" or v.Name == "UpCall" or v.Name == "DownCall" then
					local initMat = Instance.new("StringValue",v)
					initMat.Name = "InitMaterial"
					initMat.Value = string.gsub(tostring(v.Light.Material),"Enum.Material.","")
					ButtonLightOff(v)
					if cfg.ClickDetector then
						if v.Button:FindFirstChild("Button") then
							v.Button.Button:Destroy()
						end
						if v.Button:FindFirstChild("ClickDetector") then
							v.Button.ClickDetector:Destroy()
						end
						local ClickDetector = Instance.new("ClickDetector",v.Button)
						v.Button.ClickDetector.MouseClick:connect(function()
							if v.Button:FindFirstChild("Sound") then
								v.Button.Sound:Play()
							elseif car.Platform:FindFirstChild("Button") then
								car.Platform.Button:Play()
							end
							ButtonLightOn(v)
							if v.Name == "UpCall" and not floorDirs[tonumber(k.Name)] then
								floorDirs[tonumber(k.Name)] = 1
							elseif v.Name == "DownCall" and not floorDirs[tonumber(k.Name)] then
								floorDirs[tonumber(k.Name)] = -1
							end
							if direction == 0 and floor == tonumber(k.Name) then
								if v.Name == "UpCall" then
									direction = 1
								elseif v.Name == "DownCall" then
									direction = -1
								end
							end
							if tonumber(k.Name) ~= floor then
								if v:FindFirstChild("DoorDirection") then
									doorDir[tonumber(k.Name)] = v.DoorDirection.Value
									calls[tonumber(k.Name)] = true
									floorcalls[tonumber(k.Name)] = true
								else
									calls[tonumber(k.Name)] = true
									floorcalls[tonumber(k.Name)] = true
								end
							elseif not doors and motor == 0 and mode == "auto" then
								task.wait(0.1)
								callbuttontrigger = true
								ButtonLightOff(v)
								if cfg.ChimeBeforeDoor or cfg.NoChimeReopen and not cfg.ChimeCallBt then	
									if floorDirs[floor] then
										direction = floorDirs[floor]
									elseif floor == bottomFloor then
										direction = 1
									elseif floor == topFloor then
										direction = -1
									end
									if direction == 1 or direction == 0 then
										if cfg.upChime then
											spawn(cfg.upChime)
										end
									elseif direction == -1 then
										if cfg.downChime then
											spawn(cfg.downChime)
										end
									end
								end
								LanternHandler(floor)
								if v:FindFirstChild("DoorDirection") then
									DoorDirBin(v.DoorDirection.Value)
									openDoors()
								else
									DoorDirBin(15)
									openDoors()
								end
								callbuttontrigger = false
							else
								if cfg.ChimeCallBt then
									if floorDirs[floor] then
										direction = floorDirs[floor]
									elseif floor == bottomFloor then
										direction = 1
									elseif floor == topFloor then
										direction = -1
									end
									if direction == 1 or direction == 0 then
										if cfg.upChime then
											spawn(cfg.upChime)
										end
									elseif direction == -1 then
										if cfg.downChime then
											spawn(cfg.downChime)
										end
									end
								end
								task.wait(0.1)
								ButtonLightOff(v)
							end
						end)
					else
						if v.Button:FindFirstChild("Button") then
							v.Button.Button:Destroy()
						end
						if v.Button:FindFirstChild("ClickDetector") then
							v.Button.ClickDetector:Destroy()
						end
						for Face=1,6 do
							local a = Instance.new("SurfaceGui", v.Button)
							if Face == 1 then a.Face = "Front" elseif Face == 2 then a.Face = "Back" elseif Face == 3 then a.Face = "Right" elseif Face == 4 then a.Face = "Left" elseif Face == 5 then a.Face = "Top" elseif Face == 6 then a.Face = "Bottom" end
							a.Name = "Button"
							local a = Instance.new("TextButton", a)
							a.Name = "Button"
							a.Size = UDim2.new(1, 0, 1, 0)
							a.BackgroundTransparency = 1
							a.TextTransparency = 1
						end
						for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Click:connect(function()
									if v.Button:FindFirstChild("Sound") then
										v.Button.Sound:Play()
									elseif car.Platform:FindFirstChild("Button") then
										car.Platform.Button:Play()
									end
									ButtonLightOn(v)
									if v.Name == "UpCall" and not floorDirs[tonumber(k.Name)] then
										floorDirs[tonumber(k.Name)] = 1
									elseif v.Name == "DownCall" and not floorDirs[tonumber(k.Name)] then
										floorDirs[tonumber(k.Name)] = -1
									end
									if direction == 0 and floor == tonumber(k.Name) then
										if v.Name == "UpCall" then
											direction = 1
										elseif v.Name == "DownCall" then
											direction = -1
										end
									end
									if tonumber(k.Name) ~= floor then
										if v:FindFirstChild("DoorDirection") then
											doorDir[tonumber(k.Name)] = v.DoorDirection.Value
											calls[tonumber(k.Name)] = true
											floorcalls[tonumber(k.Name)] = true
										else
											calls[tonumber(k.Name)] = true
											floorcalls[tonumber(k.Name)] = true
										end
									elseif not doors and motor == 0 and mode == "auto" then
										task.wait(0.1)
										callbuttontrigger = true
										ButtonLightOff(v)
										if cfg.ChimeBeforeDoor or cfg.NoChimeReopen and not cfg.ChimeCallBt then
											if floorDirs[floor] then
												direction = floorDirs[floor]
											elseif floor == bottomFloor then
												direction = 1
											elseif floor == topFloor then
												direction = -1
											end
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										LanternHandler(floor)
										if v:FindFirstChild("DoorDirection") then
											DoorDirBin(v.DoorDirection.Value)
											openDoors()
										else
											DoorDirBin(15)
											openDoors()
										end
										callbuttontrigger = false
									else
										if cfg.ChimeCallBt then
											if floorDirs[floor] then
												direction = floorDirs[floor]
											elseif floor == bottomFloor then
												direction = 1
											elseif floor == topFloor then
												direction = -1
											end
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										task.wait(0.1)
										ButtonLightOff(v)
									end
								end)
							end
						end
					end
				end
			end
		end
		for _,p in pairs(car:GetChildren()) do
			if p.Name == "Panel" then
				for i,v in pairs(p:GetChildren()) do
					if shaft:FindFirstChild(v.Name) then
						local initMat = Instance.new("StringValue",v)
						initMat.Name = "InitMaterial"
						initMat.Value = string.gsub(tostring(v.Light.Material),"Enum.Material.","")
						ButtonLightOff(v)
						if cfg.ClickDetector then
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							local ClickDetector = Instance.new("ClickDetector",v.Button)
							v.Button.ClickDetector.MouseClick:connect(function()
								if v.Button:FindFirstChild("Sound") then
									v.Button.Sound:Play()
								elseif car.Platform:FindFirstChild("Button") then
									car.Platform.Button:Play()
								end
								if mode == "priority" or sftybypass then
									if safety and motor == 0 and tonumber(v.Name) ~= floor then
										for _,k in pairs(car:GetChildren()) do
											if k.Name == "Panel" then
												for _,z in pairs(k:GetChildren()) do
													if z.Name == v.Name then
														ButtonLightOn(z)
													end
												end
											end
										end
										toFloor(tonumber(v.Name))
									end
									return
								end
								for _,z in pairs(car:GetChildren()) do
									if z.Name == "Panel" then
										for _,k in pairs(z:GetChildren()) do
											if k.Name == v.Name then
												ButtonLightOn(k)
											end
										end
									end
								end
								if floor ~= tonumber(v.Name) and calls[tonumber(v.Name)] and callcancel[tonumber(v.Name)] == 1 and motorMode == "idle" and mode == "auto" and cfg.CallCancel then
									if callcanceltimer[tonumber(v.Name)] == 0 and not cfg.SinglePressCancel then
										callcanceltimer[tonumber(v.Name)] = (cfg.CallCancelTime ~= nil and cfg.CallCancelTime or 2)
										coroutine.wrap(function() 
											while callcanceltimer[tonumber(v.Name)] > 0 do 
												callcanceltimer[tonumber(v.Name)] -= 1
												task.wait(1)
											end
										end)()
									else
										callcancel[tonumber(v.Name)] = 0
										if not floorcalls[tonumber(v.Name)] then
											calls[tonumber(v.Name)] = false
										end
										for _,z in pairs(car:GetChildren()) do
											if z.Name == "Panel" then
												for _,k in pairs(z:GetChildren()) do
													if k.Name == v.Name then
														ButtonLightOff(k)
													end
												end
											end
										end
									end
								elseif  floor ~= tonumber(v.Name) then
									callcancel[tonumber(v.Name)] = 1
									if cfg.FloorBTClose then
										doorTimer = 0
									end
									if v:FindFirstChild("DoorDirection") then
										doorDir[tonumber(v.Name)] = v.DoorDirection.Value
										calls[tonumber(v.Name)] = true
									else
										calls[tonumber(v.Name)] = true
									end
								elseif not doors and not calls[floor] and motor == 0 and mode == "auto" then
									task.wait(0.1)
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOff(k)
												end
											end
										end
									end
									if mode == "auto" and motor == 0 then
										if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
											if direction == 1 or direction == 0 then
												if cfg.upChime then
													spawn(cfg.upChime)
												end
											elseif direction == -1 then
												if cfg.downChime then
													spawn(cfg.downChime)
												end
											end
										end
										if v:FindFirstChild("DoorDirection") then
											reopen = true
											DoorDirBin(v.DoorDirection.Value)
											openDoors()
										else
											reopen = true
											DoorDirBin(15)
											openDoors()
										end
									end
								else
									task.wait(0.1)
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOff(v)
												end
											end
										end
									end
								end
							end)
						else
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							for Face=1,6 do
								local a = Instance.new("SurfaceGui", v.Button)
								if Face == 1 then a.Face = "Front" elseif Face == 2 then a.Face = "Back" elseif Face == 3 then a.Face = "Right" elseif Face == 4 then a.Face = "Left" elseif Face == 5 then a.Face = "Top" elseif Face == 6 then a.Face = "Bottom" end
								a.Name = "Button"
								local a = Instance.new("TextButton", a)
								a.Name = "Button"
								a.Size = UDim2.new(1, 0, 1, 0)
								a.BackgroundTransparency = 1
								a.TextTransparency = 1
							end
							for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Click:connect(function()
										if v.Button:FindFirstChild("Sound") then
											v.Button.Sound:Play()
										elseif car.Platform:FindFirstChild("Button") then
											car.Platform.Button:Play()
										end
										if mode == "priority" or sftybypass then
											if safety and motor == 0 and tonumber(v.Name) ~= floor then
												for _,k in pairs(car:GetChildren()) do
													if k.Name == "Panel" then
														for _,z in pairs(k:GetChildren()) do
															if z.Name == v.Name then
																ButtonLightOn(z)
															end
														end
													end
												end
												toFloor(tonumber(v.Name))
											end
											return
										end
										for _,z in pairs(car:GetChildren()) do
											if z.Name == "Panel" then
												for _,k in pairs(z:GetChildren()) do
													if k.Name == v.Name then
														ButtonLightOn(k)
													end
												end
											end
										end
										if floor ~= tonumber(v.Name) and calls[tonumber(v.Name)] and callcancel[tonumber(v.Name)] == 1 and motorMode == "idle" and mode == "auto" and cfg.CallCancel then
											if callcanceltimer[tonumber(v.Name)] == 0 and not cfg.SinglePressCancel then
												callcanceltimer[tonumber(v.Name)] = (cfg.CallCancelTime ~= nil and cfg.CallCancelTime or 2)
												coroutine.wrap(function() 
													while callcanceltimer[tonumber(v.Name)] > 0 do 
														callcanceltimer[tonumber(v.Name)] -= 1
														task.wait(1)
													end
												end)()
											else
												callcancel[tonumber(v.Name)] = 0
												if not floorcalls[tonumber(v.Name)] then
													calls[tonumber(v.Name)] = false
												end
												for _,z in pairs(car:GetChildren()) do
													if z.Name == "Panel" then
														for _,k in pairs(z:GetChildren()) do
															if k.Name == v.Name then
																ButtonLightOff(k)
															end
														end
													end
												end
											end
										elseif  floor ~= tonumber(v.Name) then
											callcancel[tonumber(v.Name)] = 1
											if cfg.FloorBTClose then
												doorTimer = 0
											end
											if v:FindFirstChild("DoorDirection") then
												doorDir[tonumber(v.Name)] = v.DoorDirection.Value
												calls[tonumber(v.Name)] = true
											else
												calls[tonumber(v.Name)] = true
											end
										elseif not doors and not calls[floor] and motor == 0 and mode == "auto" then
											task.wait(0.1)
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOff(k)
														end
													end
												end
											end
											if mode == "auto" and motor == 0 then
												if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
													if direction == 1 or direction == 0 then
														if cfg.upChime then
															spawn(cfg.upChime)
														end
													elseif direction == -1 then
														if cfg.downChime then
															spawn(cfg.downChime)
														end
													end
												end
												if v:FindFirstChild("DoorDirection") then
													reopen = true
													DoorDirBin(v.DoorDirection.Value)
													openDoors()
												else
													reopen = true
													DoorDirBin(15)
													openDoors()
												end
											end
										else
											task.wait(0.1)
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOff(k)
														end
													end
												end
											end
										end
									end)
								end
							end
						end
					elseif v.Name == "Open" then
						local initMat = Instance.new("StringValue",v)
						initMat.Name = "InitMaterial"
						initMat.Value = string.gsub(tostring(v.Light.Material),"Enum.Material.","")
						ButtonLightOff(v)
						if cfg.ClickDetector then
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							local ClickDetector = Instance.new("ClickDetector",v.Button)
							v.Button.ClickDetector.MouseClick:connect(function()
								if mode == "priority" and motor == 0 then
									doorHold = true
								end
								if #inputs < 24 then
									inputs = inputs .. "O"
								end
								if v.Button:FindFirstChild("Sound") then
									v.Button.Sound:Play()
								elseif car.Platform:FindFirstChild("Button") then
									car.Platform.Button:Play()
								end
								for _,z in pairs(car:GetChildren()) do
									if z.Name == "Panel" then
										for _,k in pairs(z:GetChildren()) do
											if k.Name == v.Name then
												ButtonLightOn(k)
											end
										end
									end
								end
								if not doors and motor == 0 and mode == "auto" then
									task.wait(0.1)
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOff(k)
												end
											end
										end
									end
									if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if direction == 1 or direction == 0 then
											if cfg.upChime then
												spawn(cfg.upChime)
											end
										elseif direction == -1 then
											if cfg.downChime then
												spawn(cfg.downChime)
											end
										end
									end
									if v:FindFirstChild("DoorDirection") then
										reopen = true
										DoorDirBin(v.DoorDirection.Value)
										openDoors()
									else
										reopen = true
										DoorDirBin(15)
										openDoors()
									end
								else 
									task.wait(0.1)
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOff(k)
												end
											end
										end
									end
								end
								if mode == "priority" or sftybypass and motor == 0 then
									if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
										if direction == 1 or direction == 0 then
											if cfg.upChime then
												spawn(cfg.upChime)
											end
										elseif direction == -1 then
											if cfg.downChime then
												spawn(cfg.downChime)
											end
										end
									end
									if v:FindFirstChild("DoorDirection") then
										reopen = true
										DoorDirBin(v.DoorDirection.Value)
										openDoors(true)
									else
										reopen = true
										DoorDirBin(15)
										openDoors(true)
									end
								end
							end)
						else
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							for Face=1,6 do
								local a = Instance.new("SurfaceGui", v.Button)
								if Face == 1 then a.Face = "Front" elseif Face == 2 then a.Face = "Back" elseif Face == 3 then a.Face = "Right" elseif Face == 4 then a.Face = "Left" elseif Face == 5 then a.Face = "Top" elseif Face == 6 then a.Face = "Bottom" end
								a.Name = "Button"
								local a = Instance.new("TextButton", a)
								a.Name = "Button"
								a.Size = UDim2.new(1, 0, 1, 0)
								a.BackgroundTransparency = 1
								a.TextTransparency = 1
							end
							for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Click:connect(function()
										if mode == "priority" and motor == 0 then
											doorHold = true
										end
										if #inputs < 24 then
											inputs = inputs .. "O"
										end
										if v.Button:FindFirstChild("Sound") then
											v.Button.Sound:Play()
										elseif car.Platform:FindFirstChild("Button") then
											car.Platform.Button:Play()
										end
										for _,z in pairs(car:GetChildren()) do
											if z.Name == "Panel" then
												for _,k in pairs(z:GetChildren()) do
													if k.Name == v.Name then
														ButtonLightOn(k)
													end
												end
											end
										end
										if not doors and motor == 0 and mode == "auto" then
											task.wait(0.1)
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOff(k)
														end
													end
												end
											end
											if cfg.ChimeBeforeDoor and not cfg.NoChimeReopen and not (cfg.CallOnlyChime and floorcalls[floor] == false) then
												if direction == 1 or direction == 0 then
													if cfg.upChime then
														spawn(cfg.upChime)
													end
												elseif direction == -1 then
													if cfg.downChime then
														spawn(cfg.downChime)
													end
												end
											end	
											if v:FindFirstChild("DoorDirection") then
												reopen = true
												DoorDirBin(v.DoorDirection.Value)
												openDoors()
											else
												reopen = true
												DoorDirBin(15)
												openDoors()
											end
										else
											task.wait(0.1)
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOff(k)
														end
													end
												end
											end
										end
										if mode == "priority" and motor == 0 then
											if v:FindFirstChild("DoorDirection") then
												DoorDirBin(v.DoorDirection.Value)
												openDoors(true)
											else
												DoorDirBin(15)
												openDoors(true)
											end
										end
									end)
								end
							end
						end
					elseif v.Name == "Close" then
						local initMat = Instance.new("StringValue",v)
						initMat.Name = "InitMaterial"
						initMat.Value = string.gsub(tostring(v.Light.Material),"Enum.Material.","")
						ButtonLightOff(v)
						if cfg.ClickDetector then
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							local ClickDetector = Instance.new("ClickDetector",v.Button)
							v.Button.ClickDetector.MouseClick:connect(function()
								if mode == "priority" then
									doorHold = false
								end
								if #inputs < 24 then
									inputs = inputs .. "X"
								end
								if v.Button:FindFirstChild("Sound") then
									v.Button.Sound:Play()
								elseif car.Platform:FindFirstChild("Button") then
									car.Platform.Button:Play()
								end
								for _,z in pairs(car:GetChildren()) do
									if z.Name == "Panel" then
										for _,k in pairs(z:GetChildren()) do
											if k.Name == v.Name then
												ButtonLightOn(k)
											end
										end
									end
								end
								task.wait(0.1)
								for _,z in pairs(car:GetChildren()) do
									if z.Name == "Panel" then
										for _,k in pairs(z:GetChildren()) do
											if k.Name == v.Name then
												ButtonLightOff(k)
											end
										end
									end
								end
								doorTimer = 0
							end)
						else
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							for Face=1,6 do
								local a = Instance.new("SurfaceGui", v.Button)
								if Face == 1 then a.Face = "Front" elseif Face == 2 then a.Face = "Back" elseif Face == 3 then a.Face = "Right" elseif Face == 4 then a.Face = "Left" elseif Face == 5 then a.Face = "Top" elseif Face == 6 then a.Face = "Bottom" end
								a.Name = "Button"
								local a = Instance.new("TextButton", a)
								a.Name = "Button"
								a.Size = UDim2.new(1, 0, 1, 0)
								a.BackgroundTransparency = 1
								a.TextTransparency = 1
							end
							for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Click:connect(function()
										if mode == "priority" then
											doorHold = false
										end
										if #inputs < 24 then
											inputs = inputs .. "X"
										end
										if v.Button:FindFirstChild("Sound") then
											v.Button.Sound:Play()
										elseif car.Platform:FindFirstChild("Button") then
											car.Platform.Button:Play()
										end
										for _,z in pairs(car:GetChildren()) do
											if z.Name == "Panel" then
												for _,k in pairs(z:GetChildren()) do
													if k.Name == v.Name then
														ButtonLightOn(k)
													end
												end
											end
										end
										doorTimer = 0
										task.wait(0.1)
										for _,z in pairs(car:GetChildren()) do
											if z.Name == "Panel" then
												for _,k in pairs(z:GetChildren()) do
													if k.Name == v.Name then
														ButtonLightOff(k)
													end
												end
											end
										end
									end)
								end
							end
						end
					elseif v.Name == "DoorHold" then
						local initMat = Instance.new("StringValue",v)
						initMat.Name = "InitMaterial"
						initMat.Value = string.gsub(tostring(v.Light.Material),"Enum.Material.","")
						ButtonLightOff(v)
						if cfg.ClickDetector then
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							local ClickDetector = Instance.new("ClickDetector",v.Button)
							v.Button.ClickDetector.MouseClick:connect(function()
								if v.Button:FindFirstChild("Sound") then
									v.Button.Sound:Play()
								elseif car.Platform:FindFirstChild("Button") then
									car.Platform.Button:Play()
								end
								if doorHold == false then
									doorHold = true
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOn(k)
												end
											end
										end
									end
								else
									doorHold = false
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOff(k)
												end
											end
										end
									end
								end
							end)
						else
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							for Face=1,6 do
								local a = Instance.new("SurfaceGui", v.Button)
								if Face == 1 then a.Face = "Front" elseif Face == 2 then a.Face = "Back" elseif Face == 3 then a.Face = "Right" elseif Face == 4 then a.Face = "Left" elseif Face == 5 then a.Face = "Top" elseif Face == 6 then a.Face = "Bottom" end
								a.Name = "Button"
								local a = Instance.new("TextButton", a)
								a.Name = "Button"
								a.Size = UDim2.new(1, 0, 1, 0)
								a.BackgroundTransparency = 1
								a.TextTransparency = 1
							end
							for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Click:connect(function()
										if v.Button:FindFirstChild("Sound") then
											v.Button.Sound:Play()
										elseif car.Platform:FindFirstChild("Button") then
											car.Platform.Button:Play()
										end
										if doorHold == false then
											doorHold = true
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOn(k)
														end
													end
												end
											end
										else
											doorHold = false
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOff(k)
														end
													end
												end
											end
										end
									end)
								end
							end
						end
					elseif v.Name == "TimedDoorHold" then
						local initMat = Instance.new("StringValue",v)
						initMat.Name = "InitMaterial"
						initMat.Value = string.gsub(tostring(v.Light.Material),"Enum.Material.","")
						ButtonLightOff(v)
						if cfg.ClickDetector then
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							local ClickDetector = Instance.new("ClickDetector",v.Button)
							v.Button.ClickDetector.MouseClick:connect(function()
								if v.Button:FindFirstChild("Sound") then
									v.Button.Sound:Play()
								elseif car.Platform:FindFirstChild("Button") then
									car.Platform.Button:Play()
								end
								if doorHold == false then
									dholdTimer = cfg.TimedDoorHold ~= nil and cfg.TimedDoorHold or 10
									doorHold = true
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOn(k)
												end
											end
										end
									end
									while dholdTimer > 0 do
										task.wait(1)
										dholdTimer = dholdTimer - 1
										print(dholdTimer)
									end
									doorHold = false
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													ButtonLightOff(k)
												end
											end
										end
									end
								else
									dholdTimer = 0
								end
							end)
						else
							if v.Button:FindFirstChild("Button") then
								v.Button.Button:Destroy()
							end
							if v.Button:FindFirstChild("ClickDetector") then
								v.Button.ClickDetector:Destroy()
							end
							for Face=1,6 do
								local a = Instance.new("SurfaceGui", v.Button)
								if Face == 1 then a.Face = "Front" elseif Face == 2 then a.Face = "Back" elseif Face == 3 then a.Face = "Right" elseif Face == 4 then a.Face = "Left" elseif Face == 5 then a.Face = "Top" elseif Face == 6 then a.Face = "Bottom" end
								a.Name = "Button"
								local a = Instance.new("TextButton", a)
								a.Name = "Button"
								a.Size = UDim2.new(1, 0, 1, 0)
								a.BackgroundTransparency = 1
								a.TextTransparency = 1
							end
							for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Click:connect(function()
										if v.Button:FindFirstChild("Sound") then
											v.Button.Sound:Play()
										elseif car.Platform:FindFirstChild("Button") then
											car.Platform.Button:Play()
										end
										if doorHold == false then
											dholdTimer = cfg.TimedDoorHold ~= nil and cfg.TimedDoorHold or 10
											doorHold = true
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOn(k)
														end
													end
												end
											end
											while dholdTimer > 0 do
												task.wait(1)
												dholdTimer = dholdTimer - 1
												print(dholdTimer)
											end
											doorHold = false
											for _,z in pairs(car:GetChildren()) do
												if z.Name == "Panel" then
													for _,k in pairs(z:GetChildren()) do
														if k.Name == v.Name then
															ButtonLightOff(k)
														end
													end
												end
											end
										else
											dholdTimer = 0
										end
									end)
								end
							end
						end
					elseif v.Name == "Screen" then
						screens[#screens+1] = v
					elseif v.Name == "Alarm" then
						local initMat = Instance.new("StringValue",v)
						initMat.Name = "InitMaterial"
						initMat.Value = string.gsub(tostring(v.Light.Material),"Enum.Material.","")
						for i,l in pairs(v:GetDescendants()) do
							if l.Name == "Light" then	
								if v:FindFirstChild("InactiveColor") then
									if v.InactiveColor.ClassName == "Color3Value" then
										l.Color = v.InactiveColor.Value
									else
										l.BrickColor = v.InactiveColor.Value
									end				
								elseif cfg.AlarmUnLit and not v:FindFirstChild("InactiveColor") then
									if typeof(cfg.AlarmUnLit) == "string" then
										l.BrickColor = BrickColor.new(cfg.AlarmUnLit)
									else
										l.Color = cfg.AlarmUnLit
									end
								elseif cfg.ButtonUnLit and not cfg.AlarmUnLit and not v:FindFirstChild("InactiveColor") then
									if typeof(cfg.ButtonUnLit) == "string" then
										l.BrickColor = BrickColor.new(cfg.ButtonUnLit)
									else
										l.Color = cfg.ButtonUnLit
									end
								else
									l.BrickColor = BrickColor.new("White")
								end
								l.Material = v.InitMaterial.Value
							end
						end
						if not car.Platform:FindFirstChild("Alarm") then 
							local Sound = Instance.new("Sound",car.Platform)
							Sound.Name = "Alarm"
							if cfg.AlarmID then
								Sound.SoundId = cfg.AlarmID
							else
								Sound.SoundId = "rbxassetid://133587934"
							end
							Sound.PlaybackSpeed = 1
							Sound.Volume = 1
							Sound.Looped = true
						end
						if v.Button:FindFirstChild("Button") then
							v.Button.Button:Destroy()
						end
						if v.Button:FindFirstChild("ClickDetector") then
							v.Button.ClickDetector:Destroy()
						end
						for Face=1,6 do
							local a = Instance.new("SurfaceGui", v.Button)
							if Face == 1 then a.Face = "Front" elseif Face == 2 then a.Face = "Back" elseif Face == 3 then a.Face = "Right" elseif Face == 4 then a.Face = "Left" elseif Face == 5 then a.Face = "Top" elseif Face == 6 then a.Face = "Bottom" end
							a.Name = "Button"
							local a = Instance.new("TextButton", a)
							a.Name = "Button"
							a.Size = UDim2.new(1, 0, 1, 0)
							a.BackgroundTransparency = 1
							a.TextTransparency = 1
						end
						for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Down:connect(function()
									if sequences[inputs] then
										sequences[inputs]()
									end
									inputs = ""
									if v.Button:FindFirstChild("Sound") then
										v.Button.Sound:Play()
									elseif car.Platform:FindFirstChild("Button") then
										car.Platform.Button:Play()
									end
									-- Sound Alarm
									if car.Platform:FindFirstChild("Alarm") then
										car.Platform.Alarm:Play()	
									end

									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													for i,l in pairs(k:GetDescendants()) do
														if l.Name == "Light" then					
															if k:FindFirstChild("ActiveColor") then
																if k.ActiveColor.ClassName == "Color3Value" then
																	l.Color = k.ActiveColor.Value
																else
																	l.BrickColor = k.ActiveColor.Value
																end
															elseif cfg.AlarmLit and not k:FindFirstChild("ActiveColor") then
																if typeof(cfg.AlarmLit) == "string" then
																	l.BrickColor = BrickColor.new(cfg.AlarmLit)
																else
																	l.Color = cfg.AlarmLit
																end
															elseif cfg.ButtonLit and not cfg.AlarmLit and not k:FindFirstChild("ActiveColor") then
																if typeof(cfg.ButtonLit) == "string" then
																	l.BrickColor = BrickColor.new(cfg.ButtonLit)
																else
																	l.Color = cfg.ButtonLit
																end
															else
																l.BrickColor = BrickColor.new("Cyan")
															end
															l.Material = "Neon"
														end
													end
												end
											end
										end
									end
								end)
							end
						end
						for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseLeave:connect(function()
									-- Sound Alarm
									if car.Platform:FindFirstChild("Alarm") then
										car.Platform.Alarm:Stop()	
									end
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													for i,l in pairs(k:GetDescendants()) do
														if l.Name == "Light" then	
															if k:FindFirstChild("InactiveColor") then
																if k.InactiveColor.ClassName == "Color3Value" then
																	l.Color = k.InactiveColor.Value
																else
																	l.BrickColor = k.InactiveColor.Value
																end				
															elseif cfg.AlarmUnLit and not k:FindFirstChild("InactiveColor") then
																if typeof(cfg.AlarmUnLit) == "string" then
																	l.BrickColor = BrickColor.new(cfg.AlarmUnLit)
																else
																	l.Color = cfg.AlarmUnLit
																end
															elseif cfg.ButtonUnLit and not cfg.AlarmUnLit and not k:FindFirstChild("InactiveColor") then
																if typeof(cfg.ButtonUnLit) == "string" then
																	l.BrickColor = BrickColor.new(cfg.ButtonUnLit)
																else
																	l.Color = cfg.ButtonUnLit
																end
															else
																l.BrickColor = BrickColor.new("White")
															end
															l.Material = k.InitMaterial.Value
														end
													end
												end
											end
										end
									end
								end)
							end
						end
						for x,x in pairs(v.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Button.MouseButton1Up:connect(function()
									-- Sound Alarm
									if car.Platform:FindFirstChild("Alarm") then
										car.Platform.Alarm:Stop()	
									end
									for _,z in pairs(car:GetChildren()) do
										if z.Name == "Panel" then
											for _,k in pairs(z:GetChildren()) do
												if k.Name == v.Name then
													for i,l in pairs(k:GetDescendants()) do
														if l.Name == "Light" then	
															if k:FindFirstChild("InactiveColor") then
																if k.InactiveColor.ClassName == "Color3Value" then
																	l.Color = k.InactiveColor.Value
																else
																	l.BrickColor = k.InactiveColor.Value
																end				
															elseif cfg.AlarmUnLit and not k:FindFirstChild("InactiveColor") then
																if typeof(cfg.AlarmUnLit) == "string" then
																	l.BrickColor = BrickColor.new(cfg.AlarmUnLit)
																else
																	l.Color = cfg.AlarmUnLit
																end
															elseif cfg.ButtonUnLit and not cfg.AlarmUnLit and not k:FindFirstChild("InactiveColor") then
																if typeof(cfg.ButtonUnLit) == "string" then
																	l.BrickColor = BrickColor.new(cfg.ButtonUnLit)
																else
																	l.Color = cfg.ButtonUnLit
																end
															else
																l.BrickColor = BrickColor.new("White")
															end
															l.Material = k.InitMaterial.Value
														end
													end
												end
											end
										end
									end
								end)
							end
						end
					end
				end
			end
		end

		if car:FindFirstChild("Controls") then
			car.Controls.Switch.ClickDetector.MouseClick:connect(function(player)
				if ref.Parent.SurfLocked.Value == true then return end
				if mode ~= "manual" then
					if velocity > 0 then
						ref.Parent.eStop.Value = true
					end
					car.Controls.Switch.Transparency = 1
					car.Controls.SwitchTurned.Transparency = 0
					if car:FindFirstChild("CabinetControls") then
						car.CabinetControls.Switch.Transparency = 1
						car.CabinetControls.SwitchTurned.Transparency = 0
					end
					if ref.Parent:FindFirstChild("Cabinet") then
						ref.Parent.Cabinet.Surfing.Switch.Transparency = 1
						ref.Parent.Cabinet.Surfing.SwitchTurned.Transparency = 0
					end
					inService = false
					mode = "manual"
					if cfg.narrator and not cfg.DisableOOSVoice then
						voice.TimePosition = 19.55
						voice:Play()
					end
					ref.Parent.eStop.Value = false
				elseif mode == "manual" then
					ref.Parent.eStop.Value = false
					car.Controls.Switch.Transparency = 0
					car.Controls.SwitchTurned.Transparency = 1
					if car:FindFirstChild("CabinetControls") then
						car.CabinetControls.Switch.Transparency = 0
						car.CabinetControls.SwitchTurned.Transparency = 1
					end
					if ref.Parent:FindFirstChild("Cabinet") then
						ref.Parent.Cabinet.Surfing.Switch.Transparency = 0
						ref.Parent.Cabinet.Surfing.SwitchTurned.Transparency = 1
					end
					inService = true
					mode = "auto"
					toFloor(floor,true)
				end
				motor = 0
			end)
			car.Controls.Up.SurfaceGui.Button.MouseButton1Down:connect(function()
				if ref.Parent.SurfLocked.Value == true then return end
				if mode == "manual" then
					motor = cfg.insSpeed
				end
			end)
			car.Controls.Up.SurfaceGui.Button.MouseButton1Up:connect(function()
				if ref.Parent.SurfLocked.Value == true then return end
				if mode == "manual" then
					motor = 0
				end
			end)
			car.Controls.Down.SurfaceGui.Button.MouseButton1Down:connect(function()
				if ref.Parent.SurfLocked.Value == true then return end
				if mode == "manual" then
					motor = 0-cfg.insSpeed
				end
			end)
			car.Controls.Down.SurfaceGui.Button.MouseButton1Up:connect(function()
				if ref.Parent.SurfLocked.Value == true then return end
				if mode == "manual" then
					motor = 0
				end
			end)
			car.Controls.Stop.ClickDetector.MouseClick:connect(function(player)
				if ref.Parent.SurfLocked.Value == true then return end
				emergencyStop = not emergencyStop
				if not emergencyStop then
					ref.Parent.eStop.Value = false
					car.Controls.Stop.Transparency = 0
					if car.Controls.Stop:FindFirstChild("SurfaceGui") then
						car.Controls.Stop.SurfaceGui.Enabled = true
					end
					car.Controls.StopPressed.Transparency = 1
					if car.Controls.StopPressed:FindFirstChild("SurfaceGui") then
						car.Controls.StopPressed.SurfaceGui.Enabled = false
					end
					if car:FindFirstChild("CabinetControls") then	
						car.CabinetControls.Stop.Transparency = 0
						if car.CabinetControls.Stop:FindFirstChild("SurfaceGui") then
							car.CabinetControls.Stop.SurfaceGui.Enabled = true
						end
						car.CabinetControls.StopPressed.Transparency = 1
						if car.CabinetControls.StopPressed:FindFirstChild("SurfaceGui") then
							car.CabinetControls.StopPressed.SurfaceGui.Enabled = false
						end
					end
					if ref.Parent:FindFirstChild("Cabinet") then
						ref.Parent.Cabinet.Surfing.Stop.CFrame = ref.Parent.Cabinet.Surfing.Stop.CFrame * CFrame.new(-0.02,0,0)
					end
				else
					if velocity ~= 0 then
						ref.Parent.eStop.Value = true
					end
					car.Controls.Stop.Transparency = 1
					if car.Controls.Stop:FindFirstChild("SurfaceGui") then
						car.Controls.Stop.SurfaceGui.Enabled = false
					end
					car.Controls.StopPressed.Transparency = 0
					if car.Controls.StopPressed:FindFirstChild("SurfaceGui") then
						car.Controls.StopPressed.SurfaceGui.Enabled = true
					end
					if car:FindFirstChild("CabinetControls") then	
						car.CabinetControls.Stop.Transparency = 1
						if car.CabinetControls.Stop:FindFirstChild("SurfaceGui") then
							car.CabinetControls.Stop.SurfaceGui.Enabled = false
						end
						car.CabinetControls.StopPressed.Transparency = 0
						if car.CabinetControls.StopPressed:FindFirstChild("SurfaceGui") then
							car.CabinetControls.StopPressed.SurfaceGui.Enabled = true
						end
					end
					if ref.Parent:FindFirstChild("Cabinet") then
						ref.Parent.Cabinet.Surfing.Stop.CFrame = ref.Parent.Cabinet.Surfing.Stop.CFrame * CFrame.new(0.02,0,0)
					end
					ref.Parent.eStop.Value = false
				end
			end)
			if car:FindFirstChild("CabinetControls") then
				car.CabinetControls.Switch.ClickDetector.MouseClick:connect(function()
					if mode ~= "manual" then
						if velocity ~= 0 then
							ref.Parent.eStop.Value = true
						end
						car.Controls.Switch.Transparency = 1
						car.Controls.SwitchTurned.Transparency = 0
						if car:FindFirstChild("CabinetControls") then
							car.CabinetControls.Switch.Transparency = 1
							car.CabinetControls.SwitchTurned.Transparency = 0
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Switch.Transparency = 1
							ref.Parent.Cabinet.Surfing.SwitchTurned.Transparency = 0
						end
						inService = false
						mode = "manual"
						if cfg.narrator and not cfg.DisableOOSVoice then
							voice.TimePosition = 19.55
							voice:Play()
						end
						ref.Parent.eStop.Value = false
					elseif mode == "manual" then
						ref.Parent.eStop.Value = false
						car.Controls.Switch.Transparency = 0
						car.Controls.SwitchTurned.Transparency = 1
						if car:FindFirstChild("CabinetControls") then
							car.CabinetControls.Switch.Transparency = 0
							car.CabinetControls.SwitchTurned.Transparency = 1
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Switch.Transparency = 0
							ref.Parent.Cabinet.Surfing.SwitchTurned.Transparency = 1
						end
						inService = true
						mode = "auto"
						toFloor(floor,true)
					end
					motor = 0
				end)
				car.CabinetControls.Up.SurfaceGui.Button.MouseButton1Down:connect(function()
					if mode == "manual" then
						motor = cfg.insSpeed
					end
				end)
				car.CabinetControls.Up.SurfaceGui.Button.MouseButton1Up:connect(function()
					if mode == "manual" then
						motor = 0
					end
				end)
				car.CabinetControls.Down.SurfaceGui.Button.MouseButton1Down:connect(function()
					if mode == "manual" then
						motor = 0-cfg.insSpeed
					end
				end)
				car.CabinetControls.Down.SurfaceGui.Button.MouseButton1Up:connect(function()
					if mode == "manual" then
						motor = 0
					end
				end)
				car.CabinetControls.Stop.ClickDetector.MouseClick:connect(function()
					emergencyStop = not emergencyStop
					if not emergencyStop then
						ref.Parent.eStop.Value = false
						car.Controls.Stop.Transparency = 0
						if car.Controls.Stop:FindFirstChild("SurfaceGui") then
							car.Controls.Stop.SurfaceGui.Enabled = true
						end
						car.Controls.StopPressed.Transparency = 1
						if car.Controls.StopPressed:FindFirstChild("SurfaceGui") then
							car.Controls.StopPressed.SurfaceGui.Enabled = false
						end
						if car:FindFirstChild("CabinetControls") then	
							car.CabinetControls.Stop.Transparency = 0
							if car.CabinetControls.Stop:FindFirstChild("SurfaceGui") then
								car.CabinetControls.Stop.SurfaceGui.Enabled = true
							end
							car.CabinetControls.StopPressed.Transparency = 1
							if car.CabinetControls.StopPressed:FindFirstChild("SurfaceGui") then
								car.CabinetControls.StopPressed.SurfaceGui.Enabled = false
							end
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Stop.CFrame = ref.Parent.Cabinet.Surfing.Stop.CFrame * CFrame.new(-0.02,0,0)
						end
					else
						if velocity ~= 0 then
							ref.Parent.eStop.Value = true
						end
						car.Controls.Stop.Transparency = 1
						if car.Controls.Stop:FindFirstChild("SurfaceGui") then
							car.Controls.Stop.SurfaceGui.Enabled = false
						end
						car.Controls.StopPressed.Transparency = 0
						if car.Controls.StopPressed:FindFirstChild("SurfaceGui") then
							car.Controls.StopPressed.SurfaceGui.Enabled = true
						end
						if car:FindFirstChild("CabinetControls") then	
							car.CabinetControls.Stop.Transparency = 1
							if car.CabinetControls.Stop:FindFirstChild("SurfaceGui") then
								car.CabinetControls.Stop.SurfaceGui.Enabled = false
							end
							car.CabinetControls.StopPressed.Transparency = 0
							if car.CabinetControls.StopPressed:FindFirstChild("SurfaceGui") then
								car.CabinetControls.StopPressed.SurfaceGui.Enabled = true
							end
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Stop.CFrame = ref.Parent.Cabinet.Surfing.Stop.CFrame * CFrame.new(0.02,0,0)
						end
						ref.Parent.eStop.Value = false
					end
				end)
			end
			if ref.Parent:FindFirstChild("Cabinet") then
				ref.Parent.Cabinet.Surfing.Switch.ClickDetector.MouseClick:connect(function()
					if mode ~= "manual" then
						if velocity ~= 0 then
							ref.Parent.eStop.Value = true
						end
						car.Controls.Switch.Transparency = 1
						car.Controls.SwitchTurned.Transparency = 0
						if car:FindFirstChild("CabinetControls") then
							car.CabinetControls.Switch.Transparency = 1
							car.CabinetControls.SwitchTurned.Transparency = 0
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Switch.Transparency = 1
							ref.Parent.Cabinet.Surfing.SwitchTurned.Transparency = 0
						end
						inService = false
						mode = "manual"
						if cfg.narrator and not cfg.DisableOOSVoice then
							voice.TimePosition = 19.55
							voice:Play()
						end
						ref.Parent.eStop.Value = false
					elseif mode == "manual" then
						ref.Parent.eStop.Value = false
						car.Controls.Switch.Transparency = 0
						car.Controls.SwitchTurned.Transparency = 1
						if car:FindFirstChild("CabinetControls") then
							car.CabinetControls.Switch.Transparency = 0
							car.CabinetControls.SwitchTurned.Transparency = 1
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Switch.Transparency = 0
							ref.Parent.Cabinet.Surfing.SwitchTurned.Transparency = 1
						end
						inService = true
						mode = "auto"
						toFloor(floor,true)
					end
					motor = 0
				end)
				ref.Parent.Cabinet.Surfing.Up.SurfaceGui.Button.MouseButton1Down:connect(function()
					if mode == "manual" then
						motor = cfg.insSpeed
					end
				end)
				ref.Parent.Cabinet.Surfing.Up.SurfaceGui.Button.MouseButton1Up:connect(function()
					if mode == "manual" then
						motor = 0
					end
				end)
				ref.Parent.Cabinet.Surfing.Down.SurfaceGui.Button.MouseButton1Down:connect(function()
					if mode == "manual" then
						motor = 0-cfg.insSpeed
					end
				end)
				ref.Parent.Cabinet.Surfing.Down.SurfaceGui.Button.MouseButton1Up:connect(function()
					if mode == "manual" then
						motor = 0
					end
				end)
				ref.Parent.Cabinet.Surfing.Stop.ClickDetector.MouseClick:connect(function()
					emergencyStop = not emergencyStop
					if not emergencyStop then
						car.Controls.Stop.Transparency = 0
						if car.Controls.Stop:FindFirstChild("SurfaceGui") then
							car.Controls.Stop.SurfaceGui.Enabled = true
						end
						car.Controls.StopPressed.Transparency = 1
						if car.Controls.StopPressed:FindFirstChild("SurfaceGui") then
							car.Controls.StopPressed.SurfaceGui.Enabled = false
						end
						if car:FindFirstChild("CabinetControls") then	
							car.CabinetControls.Stop.Transparency = 0
							if car.CabinetControls.Stop:FindFirstChild("SurfaceGui") then
								car.CabinetControls.Stop.SurfaceGui.Enabled = true
							end
							car.CabinetControls.StopPressed.Transparency = 1
							if car.CabinetControls.StopPressed:FindFirstChild("SurfaceGui") then
								car.CabinetControls.StopPressed.SurfaceGui.Enabled = false
							end
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Stop.CFrame = ref.Parent.Cabinet.Surfing.Stop.CFrame * CFrame.new(-0.02,0,0)
						end
					else
						car.Controls.Stop.Transparency = 1
						if car.Controls.Stop:FindFirstChild("SurfaceGui") then
							car.Controls.Stop.SurfaceGui.Enabled = false
						end
						car.Controls.StopPressed.Transparency = 0
						if car.Controls.StopPressed:FindFirstChild("SurfaceGui") then
							car.Controls.StopPressed.SurfaceGui.Enabled = true
						end
						if car:FindFirstChild("CabinetControls") then	
							car.CabinetControls.Stop.Transparency = 1
							if car.CabinetControls.Stop:FindFirstChild("SurfaceGui") then
								car.CabinetControls.Stop.SurfaceGui.Enabled = false
							end
							car.CabinetControls.StopPressed.Transparency = 0
							if car.CabinetControls.StopPressed:FindFirstChild("SurfaceGui") then
								car.CabinetControls.StopPressed.SurfaceGui.Enabled = true
							end
						end
						if ref.Parent:FindFirstChild("Cabinet") then
							ref.Parent.Cabinet.Surfing.Stop.CFrame = ref.Parent.Cabinet.Surfing.Stop.CFrame * CFrame.new(0.02,0,0)
						end
					end
				end)
			end
		end

		function ref.Parent.API.OnInvoke(call,param,param2)
			if call == "fireRecall" then
				if param == true and mode == "fire" then
					return false
				elseif param == false and mode ~= "fire" then
					return false
				end
				if mode ~= "manual" then
					if param then
						if floor == (cfg.recallFloor or bottomFloor) and motor == 0 then
							inService = false
							mode = "fire"
							doorHold = true
							DoorDirBin(15)
							openDoors()								
						else
							inService = false
							doorHold = false
							mode = "manual"
							task.wait(0.1)
							mode = "fire"
							repeat
								task.wait(0.1)
							until doorState == "Closed"
							task.wait(0.1)
							nudgeCounter = 0
							repeat
								task.wait(0.1)
							until toFloor(cfg.recallFloor or bottomFloor,true)
							doorHold = true
							repeat
								spawn(forceOpenDoors)
								task.wait(0.1)
							until doors
						end
					else
						inService = true
						doorHold = false
						mode = "auto"
					end
					return true
				else
					return false
				end
			elseif call == "doorHold" then
				doorHold = param
				return true
			elseif call == "independent" then
				if mode == "priority" and param == false then
					mode = "auto"
					inService = true
					doorHold = false
					return true
				elseif mode ~= "manual" and param == true then
					mode = "priority"
					inService = false
					return true
				else
					return false
				end
			elseif call == "doorOpen" then
				--if motor == 0 then
				spawn(forceOpenDoors)
				--end
			elseif call == "doorOpenNorm" then
				--if motor == 0 then
				if not doors and motor == 0 and mode == "auto" then
					openDoors()
				end
				--end
			elseif call == "doorClose" then
				quickClose = true
				doorHold = false
				nudgeCounter = cfg.reopenLimit + 1
				doorTimer = 0
			elseif call == "doorCloseNorm" then
				doorTimer = 0
			elseif call == "floorCall" then
				if param2 == "U" and not floorDirs[tonumber(param)] then
					floorDirs[tonumber(param)] = 1
				elseif param2 == "D" and not floorDirs[tonumber(param)] then
					floorDirs[tonumber(param)] = -1
				end
				if direction == 0 and floor == tonumber(param) then
					if param2 == "U" then
						direction = 1
					elseif param2 == "D" then
						direction = -1
					end
				end
				if tonumber(param) ~= floor then
					calls[tonumber(param)] = true
					floorcalls[tonumber(param)] = true
				elseif not doors and motor == 0 and mode == "auto" then
					if cfg.ChimeBeforeDoor or cfg.NoChimeReopen then
						if floorDirs[floor] then
							direction = floorDirs[floor]
						elseif floor == bottomFloor then
							direction = 1
						elseif floor == topFloor then
							direction = -1
						end
						if direction == 1 or direction == 0 then
							if cfg.upChime then
								spawn(cfg.upChime)
							end
						elseif direction == -1 then
							if cfg.downChime then
								spawn(cfg.downChime)
							end
						end
					end
					LanternHandler(floor)
					callbuttontrigger = true
					DoorDirBin(15)
					openDoors()
					callbuttontrigger = false
				else return end
			elseif call == "initialSafety" then
				initialSafety = param
			elseif call == "getDoorTarget" then
				return doors
			elseif call == "setDirection" then
				direction = param
			elseif call == "playSound" then
				playSound(unpack(param))
			elseif call == "callCancel" then
				inService = false
				local lastMode = mode
				mode = "manual"
				task.wait(0.1)
				mode = lastMode
				inService = true
			elseif call == "safetyBypass" then
				if param == true then
					carDoorsOpen("FrontDoor",6)
					sftybypass = true
				elseif param == false then
					sftybypass = false
				end
			elseif call == "liftPower" then
				if param == false then
					repeat
						wait(0.1)
					until param == true
				end
			end
		end

		-- Floor Pass Chime
		ref.Parent.Floor.Changed:Connect(function()
			if cfg.FloorPassChime then
				--Floor Pass Chime
				if cfg.FloorPassChimeDelay then
					task.wait(cfg.FloorPassChimeDelay)
				end
				if car.Platform:FindFirstChild("FloorPassChime") then
					car.Platform.FloorPassChime:Play()
				else	
					car.Platform.Beep.PlaybackSpeed = 1
					car.Platform.Beep:Play()
				end
			end
		end)

		spawn(function()
			while true do
				--/ Check Safety /--
				safety = (doorState == "Closed") and (not emergencyStop) and initialSafety or pdsftybypass or sftybypass
				for i,v in pairs(shaft:GetChildren()) do
					if not cfg.ScalerDoor then
						if v:FindFirstChild("FrontDoor") then
							for i,v in pairs(v.FrontDoor:GetChildren()) do
								if v.Door.CFrame ~= v.Closed.CFrame then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
						if v:FindFirstChild("RearDoor") then
							for i,v in pairs(v.RearDoor:GetChildren()) do
								if v.Door.CFrame ~= v.Closed.CFrame then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
						if v:FindFirstChild("LeftDoor") then
							for i,v in pairs(v.LeftDoor:GetChildren()) do
								if v.Door.CFrame ~= v.Closed.CFrame then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
						if v:FindFirstChild("RightDoor") then
							for i,v in pairs(v.RightDoor:GetChildren()) do
								if v.Door.CFrame ~= v.Closed.CFrame then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
					else
						if v:FindFirstChild("FrontDoor") then
							for i,v in pairs(v.FrontDoor:GetChildren()) do
								if v.EngineWeld.C1 ~= CFrame.new(0,0,0) then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
						if v:FindFirstChild("RearDoor") then
							for i,v in pairs(v.RearDoor:GetChildren()) do
								if v.EngineWeld.C1 ~= CFrame.new(0,0,0) then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
						if v:FindFirstChild("LeftDoor") then
							for i,v in pairs(v.LeftDoor:GetChildren()) do
								if v.EngineWeld.C1 ~= CFrame.new(0,0,0) then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
						if v:FindFirstChild("RightDoor") then
							for i,v in pairs(v.RightDoor:GetChildren()) do
								if v.EngineWeld.C1 ~= CFrame.new(0,0,0) then
									if pdsftybypass or sftybypass then
										safety = true
									else
										safety = false
									end
								end
							end
						end
					end
				end
				--[[if car:FindFirstChild("FrontDoor") then
					for i,v in pairs(car.FrontDoor:GetChildren()) do
						if v.Weld.C1 ~= v.Closed.CFrame:inverse() * v.Closed.CFrame then
							safety = false
						end
					end
				end
				if car:FindFirstChild("RearDoor") then
					for i,v in pairs(car.RearDoor:GetChildren()) do
						if v.Weld.C1 ~= v.Closed.CFrame:inverse() * v.Closed.CFrame then
							safety = false
						end
					end
				end]]
				--/ Motor Speed Controller /--
				if car.Platform.Position.Y > shaft[tostring(topFloor)].Level.Position.Y and (velocity > 0 or motor > 0) then
					motor = 0
					velocity = 0
				elseif car.Platform.Position.Y < shaft[tostring(bottomFloor)].Level.Position.Y and (velocity < 0 or motor < 0) then
					motor = 0	
					velocity = 0			
				end
				if not safety then
					motor = 0
					velocity = 0
				else
					if motor > 0 then
						if velocity > motor then
							velocity = velocity - cfg.braking
							if math.abs(motor-velocity) <= cfg.braking then
								velocity = motor
							end
						elseif velocity < motor then
							velocity = velocity + cfg.acceleration
							if math.abs(motor-velocity) <= cfg.acceleration then
								velocity = motor
							end
						end
					elseif motor == 0 then
						if velocity > motor then
							velocity = velocity - cfg.braking
							if math.abs(motor-velocity) <= cfg.braking then
								velocity = motor
							end
						elseif velocity < motor then
							velocity = velocity + cfg.braking
							if math.abs(motor-velocity) <= cfg.braking then
								velocity = motor
							end
						end
					elseif motor < 0 then
						if velocity > motor then
							velocity = velocity - cfg.acceleration
							if math.abs(motor-velocity) <= cfg.acceleration then
								velocity = motor
							end
						elseif velocity < motor then
							velocity = velocity + cfg.braking
							if math.abs(motor-velocity) <= cfg.braking then
								velocity = motor
							end
						end
					end
				end
				if not cfg.cframe then
					if velocity == 0 then
						if not car.Platform.Anchored then
							car.Platform.Anchored = true
							for i,v in pairs(car:GetChildren()) do
								if v.ClassName == "Part" or v.ClassName == "WedgePart" or v.ClassName == "CornerWedgePart" or v.ClassName == "UnionOperation" or v.ClassName == "TrussPart" or v.ClassName == "Seat" then
									v.Velocity = Vector3.new(0,0,0)
									v.RotVelocity = Vector3.new(0,0,0)
								end
							end
						end
					else
						if car.Platform.Anchored then
							car.Platform.Anchored = false
						end
					end
					if cfg.constraintEngine == true then
						ref.Cable_Attachment.PrismaticConstraint.Velocity = velocity
					else
						bodyvelocity.Velocity = Vector3.new(0,velocity,0)
					end
				end
				ref.Parent.Velocity.Value = velocity
				--/ Motor Noise Generator /--
				if not cfg.NewMotorPlay then
					if math.abs(velocity) > (cfg.motorCutoff or 0) and (motorMode == "idle" or motorMode == "stop") then
						motorMode = "start"
						ref.Parent.MotorMode.Value = "start"
						if not cfg.PitchMotor then
							car.Platform.Start:Play()
						end
					elseif motorMode == "start" and (not cfg.PitchMotor and car.Platform.Start.IsPlaying == false) then
						motorMode = "run"
						ref.Parent.MotorMode.Value = "run"
						if not cfg.PitchMotor then
							car.Platform.Run:Play()
						end
					elseif math.abs(velocity) <= (cfg.motorCutoff or 0) and (motorMode == "run" or motorMode == "start") then
						motorMode = "stop"
						ref.Parent.MotorMode.Value = "stop"
						if not cfg.PitchMotor then
							car.Platform.Start:Stop()
							car.Platform.Run:Stop()
							car.Platform.Stop:Play()
						end
					end
				end
				if math.abs(velocity) <= 0 and motorMode == "stop" then
					motorMode = "idle"
					ref.Parent.MotorMode.Value = "idle"
				end
				--/ Locate Car /--
				local nearDist = 32768
				local nearFloor = 0
				for i,v in pairs(shaft:GetChildren()) do
					if math.abs(v.Level.Position.Y-car.Platform.Position.Y) <= nearDist then
						nearDist = math.abs(v.Level.Position.Y-car.Platform.Position.Y)
						nearFloor = tonumber(v.Name)
					end
				end

				if cfg.NewMotorPlay then
					if cfg.LevelSoundBDoor and cfg.motorCutoff == nil and nearFloor ~= floor and nearFloor == nextstop then
						motorMode = "stop"
						ref.Parent.MotorMode.Value = "stop"
						if not cfg.PitchMotor then
							car.Platform.Start:Stop()
							car.Platform.Run:Stop()
							car.Platform.Stop:Play()
						end
					end
				end

				floor = nearFloor
				if cfg.FastInd and mode == "auto" and direction ~= 0 and motorMode ~= "idle" then
					if floor ~= nextstop then
						if direction == 1 then
							for i, v in pairs(allFloors) do
								if v == floor then
									ref.Parent.Floor.Value = allFloors[i+1]
								end
							end
						elseif direction == -1 then
							for i, v in pairs(allFloors) do
								if v == floor then
									ref.Parent.Floor.Value = allFloors[i-1]
								end
							end
						end
					end
				else
					ref.Parent.Floor.Value = floor
				end

				for i,v in pairs(screens) do
					if motor == 0 then
						v.SurfaceGui.Floor.Position = UDim2.new(0.125,0,0,0)
					else
						v.SurfaceGui.Floor.Position = UDim2.new(0.25,0,0,0)
					end
					if motor > 0 then
						v.SurfaceGui.Direction.Text = cfg.upIndicator or "-->"
					elseif motor < 0 then
						v.SurfaceGui.Direction.Text = cfg.downIndicator or "<--"
					else
						v.SurfaceGui.Direction.Text = ""
					end
					v.SurfaceGui.Floor.Text = tostring(floor)
				end
				for i,v in pairs(shaft:GetChildren()) do
					if v:FindFirstChild("FloorIND") then
						v.FloorIND.SurfaceGui.Floor.Text = floor
					end
				end
				for _,v in pairs(car:GetChildren()) do
					if v.Name == "DestPanel" then
						for _,l in pairs(v.SurfaceGui:GetChildren()) do
							if tonumber(l.Name) then
								if calls[tonumber(l.Name)] then
									l.Visible = true
								else
									l.Visible = false
								end
							end
						end
					end
				end
				for _,l in pairs(ref.Parent.Calls:GetChildren()) do
					if calls[tonumber(l.Name)] then
						l.Value = true
					else
						l.Value = false
					end
				end
				--/ Call Management /--
				if (doorState == "Closed" or cfg.idleHold) and motor == 0 and mode == "auto" and allowhandlecall == true then
					coroutine.wrap(handleCalls)()
					--[[if floor == bottomFloor then
						direction = 1
					elseif floor == topFloor then
						direction = -1
					end]]
				end
				if not inService then
					if mode ~= "priority" or sftybypass then
						for _,p in pairs(car:GetChildren()) do
							if p.Name == "Panel" then
								for i,v in pairs(p:GetChildren()) do
									if shaft:FindFirstChild(v.Name) then
										ButtonLightOff(v)
									end
								end
							end
						end
					end
					for _,f in pairs(shaft:GetChildren()) do
						for i,v in pairs(f:GetChildren()) do
							if v.Name == "Call" or v.Name == "UpCall" or v.Name == "DownCall" then
								ButtonLightOff(v)
							end
						end
					end
					for i,v in pairs(calls) do
						calls[i] = false
						floorcalls[i] = false
					end
				end
				ref.Parent.Direction.Value = direction
				--/ Inspection Controls /--
				ref.Parent.Mode.Value = mode
				if car:FindFirstChild("Controls") then
					car.Controls.Display.SurfaceGui.Label.Text = string.upper(mode)
				end
				if motorMode == "idle" then
					task.wait(0.25)
				else
					task.wait(0.05)
					idleTimer = 0
				end
				if cfg.parkingFloor then
					if idleTimer > (cfg.parkingTimer or 20) and floor ~= cfg.parkingFloor then
						calls[cfg.parkingFloor] = true
					end
				end
			end
		end)

		--/ Routines /--
		if cfg.idleHold then
			doorHold = true
			spawn(openDoors)
		end

		if mode ~= "auto" then allowhandlecall = true end

		runService.Heartbeat:connect(function(cycle)
			if cfg.cframe then
				ref.Cable_Attachment.Cable_Main.Part1.CFrame = ref.Cable_Attachment.Cable_Main.Part1.CFrame * CFrame.new(0, cycle*velocity, 0)
				--car.Platform.CFrame = car.Platform.CFrame * CFrame.new(0, cycle*velocity, 0)
			end
			if cfg.PitchMotor then
				if velocity > 0 or velocity < 0 then
					if car.Platform.Motor.IsPlaying == false then car.Platform.Motor:Play() end
					if velocity > 0 or velocity < 0 then
						car.Platform.Motor.PlaybackSpeed = math.abs(velocity)/10
					end
				else
					car.Platform.Motor.PlaybackSpeed = 0
					car.Platform.Motor:Stop()
				end
			end
			if ref.Parent:FindFirstChild("Weight") then
				if cfg.cframe and cfg.newWeightWeld then
					ref.Parent.Weight.Platform.CFrame = ref.Parent.Weight.Platform.CFrame * CFrame.new(0,0-cycle*velocity,0)
				elseif cfg.cframe and not cfg.newWeightWeld then
					ref.Parent.Weight:SetPrimaryPartCFrame(ref.Parent.Weight.Platform.CFrame * CFrame.new(0,0-cycle*velocity,0))
				else
					if ref.Parent.Motor:FindFirstChild("Pulley") then
						for i,v in pairs(ref.Parent.Motor.Pulley:GetChildren()) do
							if v.Name == "Rope" then
								v.Length = (car.Platform.Position.Y - shaft[tostring(bottomFloor)].Level.Position.Y) + cfg.cwOffset
							end
						end			
						if car:FindFirstChild("Hoist") then
							for i,v in pairs(car.Hoist:GetChildren()) do
								if v.Name == "Cable" then
									local dist = ref.Parent.Motor.Motor.Anchor.Position.Y - v.Position.Y
									v.Mesh.Scale = Vector3.new(dist*4,1,1)
									v.Mesh.Offset = Vector3.new(dist/2,0,0)
								end
							end
						end	
					end
				end
			end
			--[[if cfg.weldPlayers and cfg.cframe then
				for i,v in pairs(car.Sensor:GetTouchingParts()) do
					if v.Name == "Torso" and v:FindFirstChild("ManualWeld") then
						v.CFrame = v.CFrame * CFrame.new(0,cycle*velocity,0)
					end
				end
			end]]
		end)
		if not cfg.cframe or cfg.constraintEngine then
			--car.Platform.Anchored = false
			pcall(function()
				car.Platform:SetNetworkOwner()
			end)
		end

		--Card Reader
		ref.Parent.CardReader.Changed:connect(function()
			for _,z in pairs(car:GetChildren()) do
				if z.Name == "Panel" then
					for _,k in pairs(z:GetChildren()) do
						if cfg.LockedFloors ~= nil then
							for i = 1, #cfg.LockedFloors do
								if tonumber(k.Name) == cfg.LockedFloors[i] then
									if ref.Parent.CardReader.Value == true then
										if cfg.ClickDetector then
											k.Button.ClickDetector.MaxActivationDistance = 32
										else
											for x,x in pairs(k.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Enabled = true end end
										end
									else
										if cfg.ClickDetector then
											k.Button.ClickDetector.MaxActivationDistance = 0
										else
											for x,x in pairs(k.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Enabled = false end end
										end
									end
								end
							end
						end
					end
				end
			end
		end)

		for _,z in pairs(shaft:GetChildren()) do
			if cfg.CallLock ~= nil then
				for i = 1, #cfg.CallLock do
					if tonumber(z.Name) == cfg.CallLock[i] then
						z.CardReader.Changed:connect(function()
							for _,k in pairs(z:GetChildren()) do 
								if k.Name == "UpCall" or k.Name == "DownCall" or k.Name == "Call" then
									if z.CardReader.Value == true then
										if cfg.ClickDetector then
											k.Button.ClickDetector.MaxActivationDistance = 32
										else
											for x,x in pairs(k.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Enabled = true end end
										end
									else
										if cfg.ClickDetector then
											k.Button.ClickDetector.MaxActivationDistance = 0
										else
											for x,x in pairs(k.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Enabled = false end end
										end
									end
								end 
							end
						end)
					end
				end
			end
		end

		-- Initializing Locked Floors 
		for _,z in pairs(car:GetChildren()) do
			if z.Name == "Panel" then
				for _,k in pairs(z:GetChildren()) do
					if cfg.LockedFloors ~= nil then
						for i = 1, #cfg.LockedFloors do
							if tonumber(k.Name) == cfg.LockedFloors[i] then
								if cfg.ClickDetector then
									k.Button.ClickDetector.MaxActivationDistance = 0
								else
									for x,x in pairs(k.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Enabled = false end end
								end
							end
						end
					end
				end
			end
		end

		for _,z in pairs(shaft:GetChildren()) do
			if cfg.CallLock ~= nil then
				for i = 1, #cfg.CallLock do
					if tonumber(z.Name) == cfg.CallLock[i] then
						for _,k in pairs(z:GetChildren()) do 
							if k.Name == "UpCall" or k.Name == "DownCall" or k.Name == "Call" then
								if cfg.ClickDetector then
									k.Button.ClickDetector.MaxActivationDistance = 0
								else
									for x,x in pairs(k.Button:GetChildren()) do if x:IsA("SurfaceGui") and x.Name == ("Button") then x.Enabled = false end end
								end
							end 
						end
					end
				end
			end
		end
	end
}

return module
