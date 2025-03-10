local ty_ex__juyi = fk.CreateSkill {
  name = "ty_ex__juyi"
}

Fk:loadTranslationTable{
  ['ty_ex__juyi'] = '举义',
  [':ty_ex__juyi'] = '觉醒技，准备阶段开始时，若你已受伤且体力上限大于存活角色数，你将手牌摸至体力上限，然后获得技能〖崩坏〗和〖威重〗。',
  ['$ty_ex__juyi1'] = '待补充',
  ['$ty_ex__juyi2'] = '待补充',
}

ty_ex__juyi:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(ty_ex__juyi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    return player:isWounded() and player.maxHp > #player.room.alive_players
  end,
  on_use = function(self, event, target, player)
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, ty_ex__juyi.name)
    end
    player.room:handleAddLoseSkills(player, "benghuai|ty_ex__weizhong", nil)
  end,
})

return ty_ex__juyi
