-- SimpleGuiLibrary.lua
-- Refactored from BBN Tracker V25 into a simple, reusable Roblox GUI library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Library = {}
Library.__index = Library

local DEFAULT_THEME = {
	Background = Color3.fromRGB(30, 30, 30),
	TopBar = Color3.fromRGB(15, 15, 15),
	SubMenu = Color3.fromRGB(20, 20, 20),
	Button = Color3.fromRGB(45, 45, 45),
	ToggleOff = Color3.fromRGB(70, 70, 70),
	ToggleOn = Color3.fromRGB(0, 80, 150),
	Input = Color3.fromRGB(40, 40, 40),
	Close = Color3.fromRGB(180, 50, 50),
	Text = Color3.new(1, 1, 1),
}

local function makeDraggable(dragHandle, targetFrame)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

function Library:CreateWindow(options)
	options = options or {}
	local titleText = options.Title or "SIMPLE GUI"
	local width = options.Width or 200
	local height = options.Height or 340
	local position = options.Position or UDim2.new(0.5, -math.floor(width / 2), 0.4, 0)

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = options.Name or titleText:gsub("%s+", "_")
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, width, 0, height)
	mainFrame.Position = position
	mainFrame.BackgroundColor3 = DEFAULT_THEME.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 30)
	topBar.BackgroundColor3 = DEFAULT_THEME.TopBar
	topBar.BorderSizePixel = 0
	topBar.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -35, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.Text = titleText
	titleLabel.TextColor3 = DEFAULT_THEME.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.Parent = topBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -30, 0, 0)
	closeBtn.Text = "X"
	closeBtn.BackgroundColor3 = DEFAULT_THEME.Close
	closeBtn.BorderSizePixel = 0
	closeBtn.TextColor3 = DEFAULT_THEME.Text
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = topBar

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, 0, 1, -40)
	content.Position = UDim2.new(0, 0, 0, 40)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 2
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.Parent = mainFrame

	local mainLayout = Instance.new("UIListLayout")
	mainLayout.Padding = UDim.new(0, 4)
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.Parent = content

	mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 8)
	end)

	makeDraggable(topBar, mainFrame)

	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	local Window = {
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		Content = content,
		SubMenus = {},
	}

	function Window:SetVisible(visible)
		mainFrame.Visible = visible
	end

	function Window:Destroy()
		screenGui:Destroy()
	end

	function Window:AddLabel(text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.9, 0, 0, 22)
		label.Text = text or ""
		label.TextColor3 = DEFAULT_THEME.Text
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.Parent = content
		return label
	end

	function Window:AddButton(text, colorOrCallback, maybeCallback)
		local color = DEFAULT_THEME.Button
		local callback = maybeCallback
		if typeof(colorOrCallback) == "function" then
			callback = colorOrCallback
		elseif typeof(colorOrCallback) == "Color3" then
			color = colorOrCallback
		end

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.9, 0, 0, 26)
		btn.Text = text or "Button"
		btn.BackgroundColor3 = color
		btn.BorderSizePixel = 0
		btn.TextColor3 = DEFAULT_THEME.Text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.Parent = content

		if callback then
			btn.MouseButton1Click:Connect(callback)
		end

		return btn
	end

	function Window:AddToggle(text, defaultState, callback)
		local state = defaultState == true

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.9, 0, 0, 28)
		btn.BorderSizePixel = 0
		btn.TextColor3 = DEFAULT_THEME.Text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.Parent = content

		local function refresh()
			btn.Text = string.format("%s: %s", text or "Toggle", state and "ON" or "OFF")
			btn.BackgroundColor3 = state and DEFAULT_THEME.ToggleOn or DEFAULT_THEME.ToggleOff
		end

		refresh()

		btn.MouseButton1Click:Connect(function()
			state = not state
			refresh()
			if callback then
				callback(state)
			end
		end)

		return {
			Button = btn,
			GetState = function()
				return state
			end,
			SetState = function(_, newState)
				state = newState == true
				refresh()
				if callback then
					callback(state)
				end
			end,
		}
	end

	function Window:AddTextBox(placeholder, buttonText, callback)
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(0.9, 0, 0, 56)
		holder.BackgroundTransparency = 1
		holder.Parent = content

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, 0, 0, 25)
		box.Position = UDim2.new(0, 0, 0, 0)
		box.BackgroundColor3 = DEFAULT_THEME.Input
		box.BorderSizePixel = 0
		box.TextColor3 = DEFAULT_THEME.Text
		box.PlaceholderText = placeholder or "Enter text..."
		box.Text = ""
		box.Font = Enum.Font.Gotham
		box.TextSize = 12
		box.Parent = holder

		local submitBtn = Instance.new("TextButton")
		submitBtn.Size = UDim2.new(1, 0, 0, 25)
		submitBtn.Position = UDim2.new(0, 0, 0, 30)
		submitBtn.Text = buttonText or "SUBMIT"
		submitBtn.BackgroundColor3 = DEFAULT_THEME.ToggleOn
		submitBtn.BorderSizePixel = 0
		submitBtn.TextColor3 = DEFAULT_THEME.Text
		submitBtn.Font = Enum.Font.GothamBold
		submitBtn.TextSize = 12
		submitBtn.Parent = holder

		submitBtn.MouseButton1Click:Connect(function()
			if callback then
				callback(box.Text)
			end
		end)

		return {
			TextBox = box,
			Button = submitBtn,
			GetText = function()
				return box.Text
			end,
		}
	end

	function Window:AddSubMenu(label, color)
		local subFrame = Instance.new("Frame")
		subFrame.Size = UDim2.new(0, 180, 0, 300)
		subFrame.Position = UDim2.new(1, 10, 0, 0)
		subFrame.BackgroundColor3 = DEFAULT_THEME.SubMenu
		subFrame.BorderSizePixel = 0
		subFrame.Visible = false
		subFrame.Parent = mainFrame

		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, 0, 1, -10)
		scroll.Position = UDim2.new(0, 0, 0, 5)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 2
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.Parent = subFrame

		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0, 3)
		layout.Parent = scroll

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
		end)

		table.insert(Window.SubMenus, subFrame)

		local toggleBtn = Window:AddButton((label or "MENU") .. " >", color or DEFAULT_THEME.Button, function()
			local nextState = not subFrame.Visible
			for _, other in ipairs(Window.SubMenus) do
				other.Visible = false
			end
			subFrame.Visible = nextState
		end)

		local SubMenu = {
			Frame = subFrame,
			Scroll = scroll,
			Button = toggleBtn,
		}

		function SubMenu:AddButton(btnText, callback)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0.9, 0, 0, 25)
			b.Text = btnText or "Item"
			b.BackgroundColor3 = DEFAULT_THEME.Button
			b.BorderSizePixel = 0
			b.TextColor3 = DEFAULT_THEME.Text
			b.Font = Enum.Font.Gotham
			b.TextSize = 12
			b.Parent = scroll

			if callback then
				b.MouseButton1Click:Connect(callback)
			end

			return b
		end

		function SubMenu:SetVisible(visible)
			subFrame.Visible = visible
		end

		return SubMenu
	end

	return Window
end

--[[
Example Usage:

local window = Library:CreateWindow({
	Title = "BBN TRACKER V25",
	Width = 200,
	Height = 340,
})

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
--]]

return Library
