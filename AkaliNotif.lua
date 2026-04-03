-- original -> https://raw.githubusercontent.com/Kinlei/Dynissimo/main/Scripts/AkaliNotif.lua
-- grok made some changes

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Player = game:GetService("Players").LocalPlayer

local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "AkaliNotif"
NotifGui.Parent = RunService:IsStudio() and Player.PlayerGui or game:GetService("CoreGui")

-- ==================== НАСТРОЙКА ПОЗИЦИЙ ====================
local PositionsConfig = {
	TopLeft     = {Anchor = Vector2.new(0, 0),   Pos = UDim2.new(0, 20, 0, 20),   Reverse = false, SlideX = -1},
	TopRight    = {Anchor = Vector2.new(1, 0),   Pos = UDim2.new(1, -20, 0, 20),  Reverse = false, SlideX = 1},
	DownLeft    = {Anchor = Vector2.new(0, 1),   Pos = UDim2.new(0, 20, 1, -20),  Reverse = true,  SlideX = -1},
	DownRight   = {Anchor = Vector2.new(1, 1),   Pos = UDim2.new(1, -20, 1, -20), Reverse = true,  SlideX = 1},
	CenterLeft  = {Anchor = Vector2.new(0, 0.5), Pos = UDim2.new(0, 20, 0.5, 0),  Reverse = false, SlideX = -1},
	CenterRight = {Anchor = Vector2.new(1, 0.5), Pos = UDim2.new(1, -20, 0.5, 0), Reverse = false, SlideX = 1},
	CenterTop   = {Anchor = Vector2.new(0.5, 0), Pos = UDim2.new(0.5, 0, 0, 20),  Reverse = false, SlideX = 1},
	CenterDown  = {Anchor = Vector2.new(0.5, 1), Pos = UDim2.new(0.5, 0, 1, -20), Reverse = true,  SlideX = 1},
}

local Containers = {}

for posName, cfg in pairs(PositionsConfig) do
	local Container = Instance.new("Frame")
	Container.Name = "Container_" .. posName
	Container.BackgroundTransparency = 1
	Container.AnchorPoint = cfg.Anchor
	Container.Position = cfg.Pos
	Container.Size = UDim2.new(0, 300, 1, -80)   -- ширина 300, почти на всю высоту
	Container.Parent = NotifGui

	Containers[posName] = {
		Frame = Container,
		InstructionObjects = {},
		CachedObjects = {},
		LastTick = tick(),
		Reverse = cfg.Reverse,
		SlideX = cfg.SlideX,
	}
end

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
local function Image(ID, Button)
	local NewImage = Instance.new(string.format("Image%s", Button and "Button" or "Label"))
	NewImage.Image = ID
	NewImage.BackgroundTransparency = 1
	return NewImage
end

local function Round2px()
	local NewImage = Image("http://www.roblox.com/asset/?id=5761488251")
	NewImage.ScaleType = Enum.ScaleType.Slice
	NewImage.SliceCenter = Rect.new(2, 2, 298, 298)
	NewImage.ImageColor3 = Color3.fromRGB(30, 30, 30)
	return NewImage
end

local function Shadow2px()
	local NewImage = Image("http://www.roblox.com/asset/?id=5761498316")
	NewImage.ScaleType = Enum.ScaleType.Slice
	NewImage.SliceCenter = Rect.new(17, 17, 283, 283)
	NewImage.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30)
	NewImage.Position = -UDim2.fromOffset(15, 15)
	NewImage.ImageColor3 = Color3.fromRGB(30, 30, 30)
	return NewImage
end

local Padding = 10
local DescriptionPadding = 10
local TweenTime = 1
local TweenStyle = Enum.EasingStyle.Sine
local TweenDirection = Enum.EasingDirection.Out

local function CalculateBounds(TableOfObjects)
	local X, Y = 0, 0
	for _, Object in next, TableOfObjects or {} do
		X += Object.AbsoluteSize.X
		Y += Object.AbsoluteSize.Y
	end
	return {X = X, Y = Y}
end

local TitleSettings = {Font = Enum.Font.GothamSemibold, Size = 14}
local DescriptionSettings = {Font = Enum.Font.Gotham, Size = 14}
local MaxWidth = 300 - Padding - DescriptionPadding

local function Label(Text, Font, Size, Button)
	local Label = Instance.new(string.format("Text%s", Button and "Button" or "Label"))
	Label.Text = Text
	Label.Font = Font
	Label.TextSize = Size
	Label.BackgroundTransparency = 1
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.RichText = true
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	return Label
end

local function TitleLabel(Text) return Label(Text, TitleSettings.Font, TitleSettings.Size) end
local function DescriptionLabel(Text) return Label(Text, DescriptionSettings.Font, DescriptionSettings.Size) end

local PropertyTweenOut = {Text = "TextTransparency", Fram = "BackgroundTransparency", Imag = "ImageTransparency"}

local function FadeProperty(Object)
	local Prop = PropertyTweenOut[string.sub(Object.ClassName, 1, 4)]
	TweenService:Create(Object, TweenInfo.new(0.25, TweenStyle, TweenDirection), {[Prop] = 1}):Play()
end

local function FindIndexByDependency(Table, Dependency)
	for Index, Object in next, Table do
		if typeof(Object) == "table" then
			for _, v in next, Object do
				if v == Dependency then return Index end
			end
		elseif Object == Dependency then
			return Index
		end
	end
end

local function ResetObjects(objs)
	for _, Object in next, objs do
		Object[2] = 0
		Object[3] = false
	end
end

local function FadeOutAfter(Object, Seconds, InstructionObjects)
	wait(Seconds)
	FadeProperty(Object)
	for _, SubObj in next, Object:GetDescendants() do
		FadeProperty(SubObj)
	end
	wait(0.25)
	table.remove(InstructionObjects, FindIndexByDependency(InstructionObjects, Object))
	ResetObjects(InstructionObjects)
end

-- ==================== ОБНОВЛЕНИЕ ПОЗИЦИЙ (один RenderStep) ====================
local function UpdateContainer(data)
	local DeltaTime = tick() - data.LastTick
	data.LastTick = tick()

	local objs = data.InstructionObjects
	local Reverse = data.Reverse
	local PreviousObjects = {}

	for i, Object in ipairs(objs) do
		local Label, Delta, Done = Object[1], Object[2], Object[3]

		if not Done then
			if Delta < TweenTime then
				Object[2] = math.clamp(Delta + DeltaTime, 0, 1)
				Delta = Object[2]
			else
				Object[3] = true
			end
		end

		local NewValue = TweenService:GetValue(Delta, TweenStyle, TweenDirection)
		local CurrentPos = Label.Position

		local TargetPos
		if not Reverse then
			-- Стэк сверху вниз
			local offset = CalculateBounds(PreviousObjects).Y + (Padding * #PreviousObjects)
			TargetPos = UDim2.new(0, 0, 0, offset)
		else
			-- Стэк снизу вверх (новые внизу, старые поднимаются вверх)
			local totalHeight = 0
			for j = #objs, 1, -1 do
				local lbl = objs[j][1]
				totalHeight += lbl.AbsoluteSize.Y + Padding
				if objs[j] == Object then
					TargetPos = UDim2.new(0, 0, 1, -totalHeight + Padding)
					break
				end
			end
		end

		Label.Position = CurrentPos:Lerp(TargetPos, NewValue)
		table.insert(PreviousObjects, Label)
	end

	data.CachedObjects = PreviousObjects
end

RunService:BindToRenderStep("UpdateNotifications", 0, function()
	for _, data in pairs(Containers) do
		UpdateContainer(data)
	end
end)

-- ==================== ОСНОВНАЯ ФУНКЦИЯ УВЕДОМЛЕНИЙ ====================
return {
	Notify = function(Properties)
		local Properties = typeof(Properties) == "table" and Properties or {}
		local Title = Properties.Title
		local Description = Properties.Description
		local Duration = Properties.Duration or 5
		local Position = Properties.Position or "TopRight"   -- ← вот сюда можно указать любую позицию

		local containerData = Containers[Position]
		if not containerData then
			warn("[AkaliNotif] Неизвестная позиция: " .. tostring(Position) .. ". Используется TopRight.")
			containerData = Containers.TopRight
		end

		if Title or Description then
			local Y = Title and 26 or 0
			if Description then
				local TextSize = TextService:GetTextSize(Description, DescriptionSettings.Size, DescriptionSettings.Font, Vector2.new(0, 0))
				Y += math.ceil(TextSize.X / MaxWidth) * TextSize.Y + 8
			end

			local NewLabel = Round2px()
			NewLabel.Size = UDim2.new(1, 0, 0, Y)

			-- Начальная позиция (выезд с нужной стороны)
			local slideX = containerData.SlideX
			local initialX = slideX
			local initialOffsetX = slideX == -1 and -20 or 20

			if containerData.Reverse then
				-- Для нижних позиций выезжаем снизу
				NewLabel.Position = UDim2.new(initialX, initialOffsetX, 1, 20)
			else
				-- Для верхних/центральных — выезжаем сбоку
				local offsetY = CalculateBounds(containerData.CachedObjects).Y + (Padding * #containerData.InstructionObjects)
				NewLabel.Position = UDim2.new(initialX, initialOffsetX, 0, offsetY)
			end

			if Title then
				local NewTitle = TitleLabel(Title)
				NewTitle.Size = UDim2.new(1, -10, 0, 26)
				NewTitle.Position = UDim2.fromOffset(10, 0)
				NewTitle.Parent = NewLabel
			end

			if Description then
				local NewDescription = DescriptionLabel(Description)
				NewDescription.TextWrapped = true
				NewDescription.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(-DescriptionPadding, Title and -26 or 0)
				NewDescription.Position = UDim2.fromOffset(10, Title and 26 or 0)
				NewDescription.TextYAlignment = Enum.TextYAlignment[Title and "Top" or "Center"]
				NewDescription.Parent = NewLabel
			end

			Shadow2px().Parent = NewLabel
			NewLabel.Parent = containerData.Frame

			table.insert(containerData.InstructionObjects, {NewLabel, 0, false})
			coroutine.wrap(FadeOutAfter)(NewLabel, Duration, containerData.InstructionObjects)
		end
	end,
}
