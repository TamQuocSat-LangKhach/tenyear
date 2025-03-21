local juyi = fk.CreateSkill {
  name = "ty_ex__juyi",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty_ex__juyi"] = "举义",
  [":ty_ex__juyi"] = "觉醒技，准备阶段，若你已受伤且体力上限大于存活角色数，你将手牌摸至体力上限，然后获得技能〖崩坏〗和〖威重〗。",

  ["$ty_ex__juyi1"] = "举义旗，兴王师，伐不臣！",
  ["$ty_ex__juyi2"] = "逆贼篡国，天下义士当共讨之！",
}

juyi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juyi.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(juyi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:isWounded() and player.maxHp > #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, juyi.name)
    end
    if player.dead then return end
    player.room:handleAddLoseSkills(player, "benghuai|ty_ex__weizhong")
  end,
})

return juyi
