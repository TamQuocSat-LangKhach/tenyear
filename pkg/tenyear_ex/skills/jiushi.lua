local jiushi = fk.CreateSkill {
  name = "ty_ex__jiushi",
}

Fk:loadTranslationTable{
  ["ty_ex__jiushi"] = "酒诗",
  [":ty_ex__jiushi"] = "当你需使用【酒】时，若你的武将牌正面朝上，你可以翻面视为使用一张【酒】；当你的武将牌背面朝上，你受到伤害时，"..
  "你可以在伤害结算后翻面；当你使用【酒】后，你出牌阶段使用【杀】次数上限+1，直到你回合结束。",

  ["#ty_ex__jiushi"] = "酒诗：你可以翻面，视为使用一张【酒】",
  ["@ty_ex_jiushi"] = "酒诗",

  ["$ty_ex__jiushi1"] = "花开易见落难寻。",
  ["$ty_ex__jiushi2"] = "金樽盛清酒，烟景入诗篇。",
}

jiushi:addEffect("viewas", {
  anim_type = "support",
  pattern = "analeptic",
  prompt = "#ty_ex__jiushi",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = jiushi.name
    return c
  end,
  before_use = function(self, player)
    player:turnOver()
  end,
  enabled_at_play = function (self, player)
    return player.faceup
  end,
  enabled_at_response = function (self, player, response)
    return not response and player.faceup
  end,
})

jiushi:addEffect(fk.Damaged, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiushi.name) and
      (data.extra_data or {}).jiushi_check and not player.faceup
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jiushi.name,
    })
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,
})

jiushi:addEffect(fk.DamageInflicted, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiushi_check = true
  end,
})

jiushi:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiushi.name) and data.card.name == "analeptic"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex_jiushi", 1)
  end,
})

jiushi:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex_jiushi", 0)
  end,
})

jiushi:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:getMark("@ty_ex_jiushi") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@ty_ex_jiushi")
    end
  end,
})

return jiushi
