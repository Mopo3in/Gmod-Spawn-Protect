if SERVER then return end

net.Receive("spawn_protect_say", function()
	local data = net.ReadString()
	chat.AddText(Color(0,0,255), "[Spawn Protect] ",Color(255,255,255),data)
end)

net.Receive("spawn_protect_say_error", function()
	local data = net.ReadString()
	chat.AddText(Color(0,0,255), "[Spawn Protect] ",Color(255,0,0),data)
end)