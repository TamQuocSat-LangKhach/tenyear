local tanbei = fk.CreateSkill {
  name = "tanbei",
}

Fk:loadTranslationTable{
  ["tanbei"] = "贪狈",
  [":tanbei"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.你随机获得其区域内的一张牌，本回合不能再对其使用牌；"..
  "2.你本回合对其使用牌无距离和次数限制。",

  ["#tanbei"] = "贪狈：令一名角色选择：你获得其牌，或你对其使用牌无次数距离限制",
  ["tanbei1"] = "%src随机获得你区域内一张牌，本回合不能对你使用牌",
  ["tanbei2"] = "%src本回合对你使用牌无距离次数限制",
  ["@@tanbei-turn"] = "贪狈",

  ["$tanbei1"] = "此机，我怎么会错失！",
  ["$tanbei2"] = "你的东西，现在是我的了！",
}

tanbei:addEffect("active", {
  anim_type = "offensive",
  prompt = "#tanbei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(tanbei.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = { "tanbei2:"..player.id }
    if not target:isAllNude() then
      table.insert(choices, 1, "tanbei1:"..player.id)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = tanbei.name,
    })
    if choice:startsWith("tanbei1") then
      room:addTableMark(player, "tanbei1-turn", target.id)
      room:obtainCard(player, table.random(target:getCardIds("hej")), false, fk.ReasonPrey, player, tanbei.name)
    else
      room:addTableMark(player, "tanbei2-turn", target.id)
      room:setPlayerMark(target, "@@tanbei-turn", 1)
    end
  end,
})

tanbei:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and
      table.find(data.tos, function (p)
        return table.contains(player:getTableMark("tanbei1-turn"), p.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

tanbei:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return table.contains(from:getTableMark("tanbei1-turn"), to.id)
  end,
})

tanbei:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("tanbei2-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("tanbei2-turn"), to.id)
  end,
})

return tanbei
