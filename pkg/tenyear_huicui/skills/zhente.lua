local zhente = fk.CreateSkill {
  name = "zhente",
}

Fk:loadTranslationTable{
  ["zhente"] = "贞特",
  [":zhente"] = "每回合限一次，当你成为其他角色使用基本牌或普通锦囊牌的目标后，你可以令其选择一项：1.本回合不能再使用此颜色的牌；"..
  "2.此牌对你无效。",

  ["#zhente-invoke"] = "贞特：是否令 %dest 选择此牌对你无效或不能再使用同色牌？",
  ["zhente1"] = "%arg对%src无效",
  ["zhente2"] = "本回合不能再使用%arg牌",
  ["@zhente-turn"] = "贞特",

  ["$zhente1"] = "抗声昭节，义形于色。",
  ["$zhente2"] = "少履贞特之行，三从四德。",
}

zhente:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhente.name) and
      (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and data.from ~= player and not data.from.dead and
      player:usedSkillTimes(zhente.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhente.name,
      prompt = "#zhente-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(data.from, {
      choices = {
        "zhente1:"..player.id.."::"..data.card:toLogString(),
        "zhente2:::"..data.card:getColorString(),
      },
      skill_name = zhente.name,
    })
    if choice:startsWith("zhente1") then
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    else
      room:addTableMark(data.from, "@zhente-turn", data.card:getColorString())
    end
  end,
})

zhente:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("@zhente-turn"), card:getColorString())
  end,
})

return zhente
