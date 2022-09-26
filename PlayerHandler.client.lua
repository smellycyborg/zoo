local Postie = require(game.ReplicatedStorage:WaitForChild("Postie"))
local platformChecker = require(game.ReplicatedStorage:WaitForChild("PlatformChecker"))
local Timer = require(game.ReplicatedStorage:WaitForChild("Timer"))

local player = game.Players.LocalPlayer
local PlayerGui = player.PlayerGui
local InteractBillboard = PlayerGui:WaitForChild("InteractBillboard")

local UIS = game:GetService("UserInputService")
local KEYBIND = "E"

local platform = platformChecker()

local team

local inZone = false
local hasActed = false
local connection

local zone = nil
local poop = nil

local Countdown = nil
local COUNTDOWN_TIME = 10
local count = 3

local function onCountdownTick()
    local subtitleText = Countdown:getTimeLeft() and math.ceil(Countdown:getTimeLeft()) or ""
    local act = team == "Animal" and "poop" or "clean"
    PlayerGui.MainGui.Countdown.Text = subtitleText .. " seconds until next " .. act .. ".."
end

local function onCountdownFinished()
    Postie.SignalServer("CountdownFinished", false)
    hasActed = false
    Countdown = nil
    PlayerGui.MainGui.Countdown.Visible = false
end

local function runCountdown()
    if Countdown == nil then
        Countdown = Timer.new()
        Countdown:start(COUNTDOWN_TIME)

        -- countdown ui handle
        local act = team == "Animal" and "poop" or "clean"
        PlayerGui.MainGui.Countdown.Visible = true
        PlayerGui.MainGui.Countdown.Text = "10 seconds until next " .. act .. ".."

        Countdown.tick:Connect(onCountdownTick)
        Countdown.finished:Connect(onCountdownFinished)
    end
end

local function cleanPoop()
    if hasActed and connection then
        connection:Disconnect()
		return
	else
		if poop == nil then
			return
		else
			if hasActed == false then
                hasActed = true
                
       			local cleaned = count == 3 and true or false
		        connection:Disconnect()
		        Postie.SignalServer("CleanEvent", { poop = poop.Parent, cleaned = cleaned })
		        poop = nil

                runCountdown()
			end
		end
    end
end

-- function for when player presses key or touches whatever
local function onKeyPress(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode[KEYBIND] then
        if hasActed ~= true then
            cleanPoop()
        end
    end
end

local function onEnteredPoopSignal(data)
    if not team or team == "Animal" or team == "Civilian" then
        return
    end

    poop = data.object
    InteractBillboard.Enabled = data.state
    InteractBillboard.Adornee = data.state and poop or nil

    inZone = data.state
    if not inZone and connection then
        connection:Disconnect()
        return
    end

    if hasActed then
        repeat
            wait()
        until hasActed == false

        if not inZone then
            return
        end
    end

    if platform == "mobile" then

    else
        if platform == "computer" or "studio" then
          connection = UIS.InputBegan:Connect(onKeyPress)
        else -- platform is console
            
        end
    end
end

local function onTeamPickSignal(teamName)
    team = teamName
end

-- bindings
Postie.ListenSignal("RunCountdown", runCountdown)
Postie.ListenSignal("EnteredPoopZone", onEnteredPoopSignal)
Postie.ListenSignal("TeamPick", onTeamPickSignal)