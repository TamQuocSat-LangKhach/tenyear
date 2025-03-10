local ty_ex__zili = fk.CreateSkill {
  name = "ty_ex__zili"
}

Fk:loadTranslationTable{
  ['ty_ex__zili'] = '自立',
  ['ty_ex__paiyi'] = '排异',
  [':ty_ex__zili'] = '觉醒技，准备阶段，若“权”的数量达到3或更多，你减1点体力上限，然后回复1点体力并摸两张牌，并获得技能〖排异〗。',
  ['$ty_ex__zili1'] = '烧去剑阁八百里，蜀中自有一片天!',
  ['$ty_ex__zili2'] = '天下风流出我辈，一遇风云便化龙。',
}

ty_ex__zili:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__zili.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(ty_ex__zili.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("zhonghui_quan") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead then
      player:drawCards(2, ty_ex__zili.name)
    end
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ty_ex__zili.name
      })
    end
    room:handleAddLoseSkills(player, "ty_ex__paiyi", nil, true, false)
  end,
})

return ty_ex__zili
