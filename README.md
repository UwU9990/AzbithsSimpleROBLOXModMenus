# Use case:
```LUA
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/UwU9990/AzbithsSimpleROBLOXModMenus/refs/heads/main/SimpleGuiLibrary.lua"))()

local window = Library:CreateWindow({
	Title = "BBN TRACKER V25",
	Width = 200,
	Height = 340,
}, function(window)
	window:AddToggle("PERM MODE", false, function(enabled)
		print("Perm mode:", enabled)
	end)
	
	window:AddButton("KILLERS", Color3.fromRGB(80, 20, 20), function()
		print("Scanning killers...")
	end)
	
	local emotes = window:AddSubMenu("EMOTES", Color3.fromRGB(0, 80, 80))
	emotes:AddButton("DANCE 1", function()
		print("Playing dance 1")
	end)
	
	window:AddTextBox("Emote ID...", "PLAY", function(id)
		print("Playing ID:", id)
	end)

	window:Connect(RunService.Heartbeat, function()
		if not active then return end
		-- per-frame logic
	end)

	while window.Running do
		if active then
			-- periodic logic
		end
		task.wait(0.1)
	end
end)
```

It's very easy to use, hope you use it, just so you know, NO credit is needed, as this is free-use, you are fine to fork and edit this, and if you encounter errors please use the "Issues" tab.
