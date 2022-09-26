local Postie = require(game.ReplicatedStorage:WaitForChild("Postie"))
local Zone = require(game.ReplicatedStorage:WaitForChild('Zone'))
local Teams = game:GetService("Teams")

local Sdk = {
    data = {},
    zones = {}
}

local function destroyTeamFrames(object)
	for _, child in pairs(object:GetChildren()) do
		if child:IsA("UiGridLayout") or child:IsA("UiCorner") then
			continue
		else
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end
end

local function initButton(button, handler, args)
    button.MouseButton1Up:Connect(function()
        handler(args, button)
    end)
end

local function onTeamPickBtnClick(props)
	local args = props.args
	local team = props.team
    local player = args.player
    local main = args.main
    local teamsBtn = args.btn

    player.Team = Teams[team.Name]
    main.Visible = false
	teamsBtn.Visible = true

    if team.Name ~= "Animal" then
        main.Parent.PoopButton.Visible = false
    else
        main.Parent.PoopButton.Visible = true
    end

	destroyTeamFrames(args.gridFrame)

    Postie.SignalClient("TeamPick", player, team.Name)
    print("sent team name")
end

local function onPoopClick(player)
    local playerData = Sdk.data[player]

    if playerData.hasActed == true then
        return
    end

    playerData.hasActed = true
    Postie.SignalClient("RunCountdown", player, false)

    -- xp
    local XP = 125
    local multiplier = playerData.multiplier
    local xpAmount = XP*multiplier
    
    -- poop clone
    local poopClone = game.ReplicatedStorage.PoopModel:Clone()
    poopClone.Name = "Poop"
    poopClone.Poop.Position = player.Character.HumanoidRootPart.Position
    poopClone.Parent = workspace.PoopZones

    -- poop zone handler
    local zone = Zone.new(poopClone.PoopZonePart)

    local function onPoopEnter(player, data)
        Postie.SignalClient("EnteredPoopZone", player, data)
    end
    
    local function onPoopExit(player, data)
        Postie.SignalClient("EnteredPoopZone", player, data)
    end

    zone.playerEntered:Connect(function(plr)
        if plr.Team.Name == "Civilian" or plr.Team.Name == "Animal" or Sdk.data[player].hasActed == true then
            return
        else
            Sdk.zones[plr] = zone
            onPoopEnter(plr, { state = true, object = poopClone.Poop })
            print("MESSAGE/Info:  ", plr, " entered poop zone.")
        end
    end)

    zone.playerExited:Connect(function(plr)
        if plr.Team.Name == "Civilian" or plr.Team.Name == "Animal" or Sdk.data[player].hasActed == true  then
            return
        else
            table.clear(Sdk.zones, Sdk.zones[plr])
            onPoopExit(plr, { state = false, object = nil })
            print("MESSAGE/Info:  ", plr, " exited poop zone.")
        end
    end)
end

local function createTeamsPickOptions(args)
	for _, team in pairs(Teams:GetChildren()) do
        if args.player.Team ==  team then
            continue
        else
	        local teamPickFrame = args.teamPickFrame:Clone()

	        local button = teamPickFrame.TextButton
	        button.Text = team.Name
	        button.Name = team.Name

            if team.Name == "Animal" then
				button.BackgroundColor3 = Color3.new(1, 0.666667, 0)
			else
                if team.Name == "Worker" then
				    button.BackgroundColor3 = Color3.new(0, 0, 1)
                else
                    if team.Name == "Civilian" then
                        button.BackgroundColor3 = Color3.new(0, 1, 0)
                    end
                end
			end

	        initButton(button, onTeamPickBtnClick, { args = args, team = team })

			teamPickFrame.Parent = args.gridFrame
		end
    end
end

local function onMainBtnClick(args)
    if args.main.Visible == true then
        if args.btn.Name == "TeamsButton" then
            destroyTeamFrames(args.gridFrame)
        end

        args.main.Visible = false
        args.btn.Visible = true
    else
        if args.btn.Name == "TeamsButton" then
            createTeamsPickOptions(args)
        end

        args.main.Visible = true
        args.btn.Visible = false
    end
end

local function createPlayerUi(player)
    local UiElements = game.ReplicatedStorage:WaitForChild("UiElements")

    local mainGui = player.PlayerGui:WaitForChild("MainGui")

    -- shop gui
    -- local shopMain = UiElements.ShopMain:Clone()
    -- shopMain.Parent = mainGui
    local shopBtn = UiElements.ShopButton:Clone()
    shopBtn.Parent = mainGui.ButtonsHolder

    -- initButton(teamBtn, onMainBtnClick, { main = shopMain })

    -- team gui
    local teamMain = UiElements.TeamMain:Clone()
    teamMain.Parent = mainGui
    local teamsBtn = UiElements.TeamsButton:Clone()
    teamsBtn.Visible = false
    teamsBtn.Parent = mainGui.ButtonsHolder
    local teamCloseBtn = teamMain.Back.CloseButton

    local teamsArgs = {
        player = player,
        main = teamMain, 
		btn = teamsBtn, 
		gridFrame = teamMain.Back.GridFrame, 
		teamPickFrame = UiElements.TeamPickFrame 
    }

    initButton(teamCloseBtn, onMainBtnClick, teamsArgs)
    initButton(teamsBtn, onMainBtnClick, teamsArgs)
    createTeamsPickOptions(teamsArgs, onPoopClick, player)

    -- poop gui
    local poopBtn = UiElements.PoopButton:Clone()
    poopBtn.Parent = mainGui

    initButton(poopBtn, onPoopClick, player)
end

local function createPlayerData(player)
    local data = Sdk.data
    
    data[player] = {}
    data[player].multiplier = 0
    data[player].Level = { level = 0, xp = 0 }
    data[player].Duties = { pooped = 0, cleaned = 0 }
    data[player].hasActed = false

end

-- will need to tweak.  may not use attachment
local function addPoopAttachment(character)
    local att = Instance.new("Attachment")
    att.Name = "PoopAttachment"
    att.Orientation = Vector3.new(-0.002, -135, 0.001)
    att.Position = Vector3.new(0.427, 0.5, 1.634)
    att.Axis = Vector3.new(-0.707, 0, 0.707)
    att.SecondaryAxis = Vector3.new(0, 1, 0)
    att.WorldAxis = Vector3.new(-0.707, 0, 0.707)
    att.WorldOrientation = Vector3.new(-0.002, -135, 0.001)
    att.WorldPosition = Vector3.new(0.427, -9.5, 1.634)
    att.WorldSecondaryAxis = Vector3.new(0, 1, 0)
    att.Parent = character.LeftFoot
    print("added attachment")
end

local function onCharacterAdded(character)

    print("made it here")
    local characterPosition = character.HumanoidRootPart.Position

    addPoopAttachment(character)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	
    -- Todo check if player data already exists
    -- if data then grab data and update data
	-- note:  might swap out sdk data for datastore data
	
    createPlayerData(player)
	createPlayerUi(player)

    -- while task.wait() do

    -- end

end

local function onPlayerRemoving(player)

end

local function onCountdownFinishedSignal(player, bool)
    local playerData = Sdk.data[player]
        
    playerData.hasActed = bool
end

local function onCleanEvent(player, args)
    local playerData = Sdk.data[player]

    if playerData.hasActed == true then
        return
    end
        
    playerData.hasActed = args.cleaned

    -- xp
    local XP = 125
    local multiplier = playerData.multiplier
    local xpAmount = XP*multiplier

    if args.cleaned then
        playerData["Duties"].cleaned+=1
        playerData["Level"].xp+=xpAmount
        args.poop:Destroy()

        local playerZone = Sdk.zones[player]
        playerZone:Destroy()
        print("MESSAGE/Info:  ", player, " destroyed ", playerZone, ".")
    else
        playerData["Level"].xp+=xpAmount/3
        args.poop.Size = Vector3.new(args.poop.Size/3)
    end
end

function Sdk.Init()

    -- placing scripts
    local playerHandler = script.Parent.PlayerHandler
    playerHandler.Parent = game.StarterPlayer.StarterCharacterScripts
    local platformChecker = script.Parent.PlatformChecker
    platformChecker.Parent = game.ReplicatedStorage
    local timer = script.Parent.Timer
	timer.Parent = game.ReplicatedStorage

    -- remote functions
    local remoteFunctions = Instance.new("Folder", game.ReplicatedStorage)
    remoteFunctions.Name = "RemoteFunctions"

    -- bindings
    game.Players.PlayerAdded:Connect(onPlayerAdded)
    game.Players.PlayerRemoving:Connect(onPlayerRemoving)
    Postie.ListenSignal("CountdownFinished", onCountdownFinishedSignal)
    Postie.ListenSignal("CleanEvent", onCleanEvent)
end

return Sdk