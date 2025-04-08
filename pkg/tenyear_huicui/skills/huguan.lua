local huguan = fk.CreateSkill {
  name = "huguan",
}

Fk:loadTranslationTable{
  ["huguan"] = "护关",
  [":huguan"] = "一名角色于其出牌阶段内使用第一张牌时，若为红色，你可以声明一个花色，本回合此花色的牌不计入其手牌上限。",

  ["#huguan-invoke"] = "护关：你可以声明一种花色，令 %dest 本回合此花色牌不计入手牌上限",
  ["#huguan-choice"] = "护关：选择令 %dest 本回合不计入手牌上限的花色",
  ["@huguan-turn"] = "护关",
}

huguan:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(huguan.name) and target.phase == Player.Play and not target.dead then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        return e.data.from == target
      end, Player.HistoryPhase)
      return #use_events > 0 and use_events[1].data == data and data.card.color == Card.Red
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = huguan.name,
      prompt = "#huguan-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"log_spade", "log_heart", "log_club", "log_diamond"},
      skill_name = huguan.name,
      prompt = "#huguan-choice::"..target.id,
    })
    room:addTableMarkIfNeed(target, "@huguan-turn", choice)
  end,
})

huguan:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return table.contains(player:getTableMark("@huguan-turn"), card:getSuitString(true))
  end,
})

return huguan
