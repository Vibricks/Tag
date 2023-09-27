local AllowedPlayer = {
    "SamuraiRyumaa",
    "GloomyOni",
    "PilloriedDev",
    "alexwazhere242",
    "K0iist",
    "GloomyOni",
}

function IsAllowedPlayer(player)
    if table.find(AllowedPlayer, player.Name) or player:IsInGroup(33122111) then
		return true
	end
end
game.Players.PlayerAdded:Connect(function(player)
    if not IsAllowedPlayer(player) then
        player:Kick("Game is still under development, testers only!")
    end
end)