if CLIENT then return end
include('lang.lua')
util.AddNetworkString("spawn_protect_say")
util.AddNetworkString("spawn_protect_say_error")

local SP_enabled = CreateConVar("spawn_protect_enabled", 1, FCVAR_ARCHIVE, SP_LANG.SP_enabled)
local SP_radius = CreateConVar("spawn_protect_radius", 120, FCVAR_ARCHIVE, SP_LANG.SP_radius)
local SP_setspawn = CreateConVar("spawn_protect_setspawn", 1, FCVAR_ARCHIVE, SP_LANG.SP_setspawn)
local SP_recoil = CreateConVar("spawn_protect_setsp_recoil", 60, FCVAR_ARCHIVE, SP_LANG.SP_recoil)
local SP_block = CreateConVar("spawn_protect_block", 1, FCVAR_ARCHIVE, SP_LANG.SP_block)

local AllPosition = nil
local AllRadius = 0
local Players_spawns = {}

function TakeDamage( vic, ply )
	if(SP_enabled:GetInt() == 0) then return end
	if ply == vic then
		return true
	end 
	if ply:IsPlayer() then
		if InSpawn(ply) then
			SendToChatError( SP_LANG.AttackPlyInSpawn,ply)
			hook.Call( "SpawnProtectAttackPlyInSpawn", GAMEMODE, ply )
			hook.Call( "SpawnProtectTakingDamage", GAMEMODE, vic )
			return false
		end
	end
	if vic:IsPlayer()  then
		if InSpawn(vic) and ply:IsPlayer() then
			SendToChatError( SP_LANG.AttackPlyInSpawn2,ply)
			hook.Call( "SpawnProtectAttackPlyInSpawn", GAMEMODE, ply )
			hook.Call( "SpawnProtectTakingDamage", GAMEMODE, vic )
			return false
		end
	end
end
hook.Add("PlayerShouldTakeDamage", "Spawn Protect", TakeDamage)

function InSpawn(ply)
	local spawns = ents.FindByClass( "info_player_start" )
	local radius_protect = SP_radius:GetInt()
	for key,val in pairs(spawns) do 
		local distanse = ply:GetPos():Distance(val:GetPos())
		if (distanse <= radius_protect) then 
			return true 
		end
	end
	if AllPosition != nil then
		local distanse = ply:GetPos():Distance(AllPosition)
		if (distanse <= (AllRadius+radius_protect)) then 
			return true 
		end
	end
	return false
end

function SetAllSpawn(ply,radius)
	if(SP_enabled:GetInt() == 0) then return end
	if not ply:IsValid() then return end
	if not (ply:IsAdmin() or ply:IsSuperAdmin()) then
		SendToChatError( SP_LANG.NoPermissions,ply)
		return
	end
	AllRadius = radius
	AllPosition = ply:GetPos()
	AllPosition.z = AllPosition.z+10
	SendToAllChat( SP_LANG.CreatedAllSpawn)
end

function UnSetAllSpawn(ply)
	if(SP_enabled:GetInt() == 0) then return end
	if not ply:IsValid() then return end
	if not (ply:IsAdmin() or ply:IsSuperAdmin()) then
		SendToChatError( SP_LANG.NoPermissions,ply)
		return
	end
	if AllPosition != nil then
		AllPosition = nil
		SendToAllChat( SP_LANG.DeletedAllSpawn)
	else
		SendToChatError( SP_LANG.NotCreatedSpawn,ply)
	end
end

function SetSpawn(ply)
	if(SP_enabled:GetInt() == 0) then return end
	if(SP_setspawn:GetInt() == 0) then return end
	if not ply:IsValid() then return end
	if tonumber(ply:GetPData("SetSpawn", 0 )) < (os.time()-SP_recoil:GetInt()) then
		Players_spawns[ply] = ply:GetPos()
		Players_spawns[ply].z = Players_spawns[ply].z + 10
		ply:SetPData("SetSpawn", os.time() )
		SendToChat( SP_LANG.CreatedSpawn,ply)
	else
		local ost =  tonumber(ply:GetPData("SetSpawn", 0 )) - (os.time()-SP_recoil:GetInt())
		SendToChatError( string.format(SP_LANG.RecoilSpawn2,SP_recoil:GetInt()),ply)
		SendToChatError( string.format(SP_LANG.RecoilSpawn,ost),ply)
	end
end

function UnSetSpawn(ply)
	if(SP_enabled:GetInt() == 0) then return end
	if(SP_setspawn:GetInt() == 0) then return end
	if Players_spawns[ply] != nil then
		Players_spawns[ply] = nil
		SendToChat( SP_LANG.DeletedSpawn,ply)
	else
		SendToChatError( SP_LANG.NotCreatedSpawn,ply)
	end
end

function AllSpawn(ply)
	if(SP_enabled:GetInt() == 0) then return end
	if Players_spawns[ply] != nil then
		ply:SetPos(Players_spawns[ply])
	end
	if AllPosition != nil then
		local x = math.random(0,AllRadius) - (AllRadius/2)
		local y = math.random(0,AllRadius) - (AllRadius/2)
		while (x^2) + (y^2) > (AllRadius^2) do
			x = math.random(0,AllRadius) - (AllRadius/2)
			y = math.random(0,AllRadius) - (AllRadius/2)
		end
		local pos = Vector(AllPosition.x-x,AllPosition.y-y,AllPosition.z)
		ply:SetPos(pos)
	end
end
hook.Add("PlayerSpawn", "All Spawn", AllSpawn)

function PropInPlayer(ply,mv)
	if(SP_enabled:GetInt() == 0) then return end
	if(SP_block:GetInt() == 0) then return end
	local trace = { start = ply:GetPos(), endpos = ply:GetPos(), filter = ply }
	local tr = util.TraceEntity( trace, ply )
	if ( tr.Hit ) then
		if InSpawn(ply) and not tr.Entity:CreatedByMap() then
			SendToChat( string.format(SP_LANG.PropInPlayer,tr.Entity:GetClass()),ply)
			tr.Entity:Remove()
		end
	end
end
hook.Add("PlayerTick", "Prop in player", PropInPlayer)
--В вас был предмет: %s, он был удалён.
function SendToAllChat(text)
	net.Start("spawn_protect_say")
		net.WriteString(text)
	net.Broadcast()
end

function SendToChat(text,ply)
	net.Start("spawn_protect_say")
		net.WriteString(text)
	net.Send(ply)
end

function SendToAllChatError(text)
	net.Start("spawn_protect_say_error")
		net.WriteString(text)
	net.Broadcast()
end

function SendToChatError(text,ply)
	net.Start("spawn_protect_say_error")
		net.WriteString(text)
	net.Send(ply)
end

concommand.Add( "setallspawn", function( ply, cmd, args )
	if args[1] == nil  then
		SendToChatError( SP_LANG.NoRangeAllSpawn,ply)
		SetAllSpawn(ply,500)
	elseif tonumber(args[1])<500 then
		SendToChatError( SP_LANG.SmallRangeAllSpawn,ply)
		SetAllSpawn(ply,500)
	else
		SetAllSpawn(ply,tonumber(args[1]))
	end
end )

concommand.Add( "unsetallspawn", function( ply, cmd, args )
	UnSetAllSpawn(ply)
end )

concommand.Add( "setspawn", function( ply, cmd, args )
	SetSpawn(ply)
end )

concommand.Add( "unsetspawn", function( ply, cmd, args )
	UnSetSpawn(ply)
end )

hook.Add('PlayerSay', 'Spawn Protect Commands', function(ply, text)
	local prefix = text:sub( 1,1 )
	if prefix != "!" and prefix != "/" then return end
	local argsandcmd = string.Split( string.sub(text,2,string.len(text)), " " )
	local command = string.lower(argsandcmd[1])
	if command == "setallspawn" then
		if argsandcmd[2] == nil  then
			SendToChatError( SP_LANG.NoRangeAllSpawn,ply)
			SetAllSpawn(ply,500)
		elseif tonumber(rgsandcmd[2])<500 then
			SendToChatError( SP_LANG.SmallRangeAllSpawn,ply)
			SetAllSpawn(ply,500)
		else
			SetAllSpawn(ply,tonumber(argsandcmd[2]))
		end
		return false
	elseif command == "unsetallspawn" then
		UnSetAllSpawn(ply)
		return false
	elseif command == "setspawn" then
		SetSpawn(ply)
		return false
	elseif command == "unsetspawn" then
		UnSetSpawn(ply)
		return false
	end
end)

