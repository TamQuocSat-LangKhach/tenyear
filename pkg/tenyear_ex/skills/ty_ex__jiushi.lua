local jiushi = fk.CreateSkill {
  name = "ty_ex__jiushi"
}

Fk:loadTranslationTable{
  ['ty_ex__jiushi'] = '酒诗',
  ['#ty_ex__jiushi_record'] = '酒诗',
  ['@ty_ex_jiushi_buff'] = '酒诗',
  [':ty_ex__jiushi'] = '①若你的武将牌正面朝上，你可以翻面视为使用一张【酒】。②当你的武将牌背面朝上，你受到伤害时，你可在伤害结算后翻面。③当你使用【酒】时，你令你使用【杀】次数上限+1，直到你的下个回合结束。',
  ['$ty_ex__jiushi1'] = '花开易见落难寻。',
  ['$ty_ex__jiushi2'] = '金樽盛清酒，烟景入诗篇。',
}

jiushi:addEffect('viewas', {
  anim_type = "support",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self, player, cards)
    if not player.faceup then return end
    local c = Fk:cloneCard("analeptic")
    c.skillName = skill.name
    return c
  end,
})

jiushi:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill) and player.data.ty_ex__jiushi
  end,
  on_trigger = function(self, event, target, player, data)
    player.data.ty_ex__jiushi = false
    skill:doCost(event, target, player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = skill.name})
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill) and not player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    player.data.ty_ex__jiushi = true
  end,
})

jiushi:addEffect(fk.AfterCardUseDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiushi) and data.card.name == "analeptic"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex_jiushi_buff", 1)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_ex_jiushi_buff") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex_jiushi_buff", 0)
  end,
})

jiushi:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(jiushi) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@ty_ex_jiushi_buff")
    end
  end,
})

return jiushi
