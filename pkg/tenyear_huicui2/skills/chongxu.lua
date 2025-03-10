local chongxu = fk.CreateSkill {
  name = "chongxu"
}

Fk:loadTranslationTable{
  ['chongxu'] = '冲虚',
  ['#chongxu'] = '冲虚：你可以失去〖汇灵〗，加%arg点体力上限，获得〖踏寂〗和〖清荒〗',
  [':chongxu'] = '限定技，出牌阶段，若“灵”的数量不小于4，你可以失去〖汇灵〗，增加等量的体力上限，并获得〖踏寂〗和〖清荒〗。',
  ['$chongxu1'] = '慕圣道冲虚，有求者皆应。',
  ['$chongxu2'] = '养志无为，遗冲虚于物外。',
}

chongxu:addEffect('active', {
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = function(self, player)
    return "#chongxu:::" .. tostring(player:getMark("ty__sunhanhua_ling"))
  end,
  can_use = function(self, player)
    return player:getMark("ty__sunhanhua_ling") > 3 and
      player:usedSkillTimes(chongxu.name, Player.HistoryGame) == 0 and
      player:hasSkill(huiling, true)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local x = player:getMark("ty__sunhanhua_ling")
    room:handleAddLoseSkills(player, "-huiling", nil, true, false)
    room:changeMaxHp(player, x)
    room:handleAddLoseSkills(player, "taji|qinghuang", nil, true, false)
  end
})

return chongxu
