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

local function makeDraggable(dragHandle, targetFrame, trackConnection)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	trackConnection(dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position
		end
	end))

	trackConnection(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	trackConnection(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local function attachControls(target, container, anchorFrame, rootWindow)
	target.SubMenus = {}

	local function hideSubMenus()
		for _, sub in ipairs(target.SubMenus) do
			sub:SetVisible(false)
		end
	end

	function target:AddLabel(text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.9, 0, 0, 22)
		label.Text = text or ""
		label.TextColor3 = DEFAULT_THEME.Text
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.Parent = container
		return label
	end

	function target:AddButton(text, colorOrCallback, maybeCallback)
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
		btn.Parent = container

		if callback then
			btn.MouseButton1Click:Connect(callback)
		end

		return btn
	end

	function target:AddToggle(text, defaultState, callback)
		local state = defaultState == true

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.9, 0, 0, 28)
		btn.BorderSizePixel = 0
		btn.TextColor3 = DEFAULT_THEME.Text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.Parent = container

		local function refresh()
			btn.Text = string.format("%s: %s", text or "Toggle", state and "ON" or "OFF")
			btn.BackgroundColor3 = state and DEFAULT_THEME.ToggleOn or DEFAULT_THEME.ToggleOff
		end

		refresh()

		btn.MouseButton1Click:Connect(function()
			state = not state
			refresh()
			if callback then
				task.spawn(callback, state)
			end
		end)

		local toggleObj = {
			Button = btn,
			GetState = function()
				return state
			end,
			SetState = function(_, newState)
				local nextState = newState == true
				if state == nextState then return end
				state = nextState
				refresh()
				if callback then
					callback(state)
				end
			end,
		}

		table.insert(rootWindow._toggles, toggleObj)
		return toggleObj
	end

	function target:AddTextBox(placeholder, buttonText, callback)
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(0.9, 0, 0, 56)
		holder.BackgroundTransparency = 1
		holder.Parent = container

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

	function target:AddSubMenu(label, color)
		local subFrame = Instance.new("Frame")
		subFrame.Size = UDim2.new(0, 180, 0, 300)
		subFrame.Position = UDim2.new(1, 10, 0, 0)
		subFrame.BackgroundColor3 = DEFAULT_THEME.SubMenu
		subFrame.BorderSizePixel = 0
		subFrame.Visible = false
		subFrame.Parent = anchorFrame

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
		layout.Padding = UDim.new(0, 4)
		layout.Parent = scroll

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
		end)

		local SubMenu = {
			Frame = subFrame,
			Scroll = scroll,
		}

		attachControls(SubMenu, scroll, subFrame, rootWindow)

		function SubMenu:SetVisible(visible)
			subFrame.Visible = visible
			if not visible then
				for _, child in ipairs(SubMenu.SubMenus) do
					child:SetVisible(false)
				end
			end
		end

		local toggleBtn = target:AddButton((label or "MENU") .. " >", color or DEFAULT_THEME.Button, function()
			local nextState = not subFrame.Visible
			hideSubMenus()
			SubMenu:SetVisible(nextState)
		end)

		SubMenu.Button = toggleBtn
		table.insert(target.SubMenus, SubMenu)

		return SubMenu
	end
end

function Library:CreateWindow(options, buildFn)
	if type(options) == "function" then
		buildFn = options
		options = {}
	end
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

	local Window = {
		Running = true,
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		Content = content,
		_connections = {},
		_toggles = {},
		_onCloseCallbacks = {},
	}

	function Window:AddConnection(conn)
		if conn then
			table.insert(Window._connections, conn)
		end
		return conn
	end

	function Window:Connect(signal, fn)
		return Window:AddConnection(signal:Connect(fn))
	end

	function Window:OnClose(fn)
		if type(fn) == "function" then
			table.insert(Window._onCloseCallbacks, fn)
		end
	end

	makeDraggable(topBar, mainFrame, function(conn)
		Window:AddConnection(conn)
	end)

	attachControls(Window, content, mainFrame, Window)

	function Window:SetVisible(visible)
		mainFrame.Visible = visible
		if not visible then
			for _, sub in ipairs(Window.SubMenus) do
				sub:SetVisible(false)
			end
		end
	end

	function Window:Destroy()
		if not Window.Running then return end
		Window.Running = false

		for _, toggle in ipairs(Window._toggles) do
			if toggle.GetState() then
				toggle:SetState(false)
			end
		end

		for _, conn in ipairs(Window._connections) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
		end
		Window._connections = {}
		Window._toggles = {}

		for _, fn in ipairs(Window._onCloseCallbacks) do
			pcall(fn)
		end
		Window._onCloseCallbacks = {}

		screenGui:Destroy()
	end

	closeBtn.MouseButton1Click:Connect(function()
		Window:Destroy()
	end)

	if type(buildFn) == "function" then
		task.spawn(buildFn, Window)
	end

	return Window
end

--[[
Example Usage:

local RunService = game:GetService("RunService")

Library:CreateWindow({
	Title = "BBN TRACKER V25",
	Width = 200,
	Height = 340,
}, function(window)
	local active = false

	window:AddToggle("MY TOGGLE", false, function(enabled)
		active = enabled
		print("Toggled:", enabled)
	end)

	-- Automatically disconnected when X is clicked
	window:Connect(RunService.Heartbeat, function()
		if not active then return end
		-- per-frame logic
	end)

	-- Automatically stops when X is clicked
	while window.Running do
		if active then
			-- periodic logic
		end
		task.wait(0.1)
	end
end)
--]]

return Library
