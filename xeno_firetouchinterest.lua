local touchCache, ptp = {}, function(p1: Part, p2: Part, cf: CFrame, lv: boolean)
	if cf then
		return game:GetService("RunService").PreRender:Connect(function()
			if lv then p1.CFrame = p2.CFrame lv = false else p1.CFrame = cf lv = true end
		end)
	end
	return game:GetService("RunService").PreRender:Connect(function()
		p1.CFrame = p2.CFrame
	end)
end
return function firetouchinterest(toucher: Part, to_touch: Part, state: number)
	if to_touch.Parent and to_touch.Parent:FindFirstChildOfClass("Humanoid") then
		toucher, to_touch = to_touch, toucher
	end

	local tinfo = touchCache[to_touch] -- [t[1]: Toucher, t[2]: State, t[3]: Thread]
	if tinfo then
		if tinfo[1] == toucher and tinfo[2] == state then return end -- function was called previously
		repeat task.wait() until coroutine.status(tinfo[3]) == "dead"
	end

	touchCache[to_touch] = {toucher, state, task.spawn(function()
		local cf, cc, tf = to_touch.CFrame, to_touch.CanCollide, to_touch.Transparency
		local et, tv = if state == 0 then "Touched" else "TouchEnded", false
		local connection = to_touch[et]:Connect(function() tv = true end)

		to_touch.CanCollide = false
		to_touch.Transparency = 1

		if state == 0 then
			local connection2 = ptp(to_touch, toucher)
			task.wait(.001)
			connection2:Disconnect() -- var 'tv' should be true
		end

		if not tv then
			local connection2, t = if state == 0 then ptp(to_touch, toucher, cf, false) else ptp(to_touch, toucher, cf, true), tick()
			repeat task.wait() until tv or tick() - t > 0.3
			connection2:Disconnect()
		end

		if state == 0 then
			to_touch.CFrame = cf
		end

		to_touch.CanCollide = cc
		to_touch.Transparency = tf

		connection:Disconnect()
		touchCache[to_touch] = nil
	end)}
end
