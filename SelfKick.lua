local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart", 2)
Character.Archivable = true

local BV = Instance.new("BodyVelocity")
BV.Velocity = Vector3.new(0, 15, 0)
BV.Parent = HRP

HRP.CFrame = CFrame.new(15, 70, 0)

local Character2 = Character:Clone()
local HRP2 = Character2.HumanoidRootPart
Character2.Parent = Character
LocalPlayer.Character = Character2
Camera.CameraSubject = Character2.Humanoid
Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = CFrame.lookAt(Vector3.new(15, 50, 25), HRP.Position)

Character2.Humanoid:Destroy()
HRP2.Anchored = true
HRP2.CFrame = Camera.CFrame

while true do task.wait()
	if HRP.Position.Y < 10 then
		HRP.CFrame = CFrame.new(15, 70, 0)
	end
end
