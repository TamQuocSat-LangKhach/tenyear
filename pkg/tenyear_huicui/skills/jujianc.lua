local jujianc = fk.CreateSkill {
  name = "jujianc",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["jujianc"] = "拒谏",
  [":jujianc"] = "主公技，出牌阶段限一次，你可以令一名其他魏势力角色摸一张牌，直到本轮结束，其使用的普通锦囊牌对你无效。",

  ["#jujianc"] = "拒谏：令一名魏势力角色摸一张牌，其本轮使用普通锦囊牌对你无效",
  ["@@jujianc-round"] = "拒谏",

  ["$jujianc1"] = "尔等眼中，只见到朕的昏庸吗？",
  ["$jujianc2"] = "我做天子，不得自在邪？",
}

jujianc:addEffect("active", {
  anim_type = "support",
  prompt = "#jujianc",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jujianc.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and to_select.kingdom == "wei"
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:drawCards(target, 1, jujianc.name)
    if player.dead or target.dead then return end
    room:addTableMark(target, "@@jujianc-round", player.id)
  end,
})

jujianc:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.to == player and data.card:isCommonTrick() and target and
      table.contains(target:getTableMark("@@jujianc-round"), player.id)
  end,
  on_use = function(self, event, target, player, data)
    data.nullified = true
  end,
})

return jujianc
