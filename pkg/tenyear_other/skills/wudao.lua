local wudao = fk.CreateSkill {
  name = "wudao",
}

Fk:loadTranslationTable{
  ["wudao"] = "悟道",
  [":wudao"] = "当你于一回合连续使用两张同类别牌时，你可以令你本回合使用此类别的牌伤害+1且不能被响应。",

  ["@wudao-turn"] = "悟道",
  ["#wudao-invoke"] = "悟道：你可以你本回合你%arg伤害+1且不可被响应",

  ["$wudao1"] = "众所周知，能力越大，能力也就越大。",
  ["$wudao2"] = "龙争虎斗彼岸花，约翰给你一个家。",
  ["$wudao3"] = "唯一能够打破命运牢笼的，只有我们自己。",
}

wudao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(wudao.name) and data.card.type ~= Card.TypeEquip and
      not table.contains(player:getTableMark("@wudao-turn"), data.card:getTypeString().."_char") then
      local use_events = player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id < player.room.logic:getCurrentEvent().id then
          return e.data.from == player
        end
      end, 0, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data.card.type == data.card.type
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = wudao.name,
      prompt = "#wudao-invoke:::" .. data.card:getTypeString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "@wudao-turn", data.card:getTypeString().."_char")
  end,
})

wudao:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("@wudao-turn"), data.card:getTypeString().."_char") and
      (data.card.is_damage_card or data.card:isCommonTrick())
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return wudao
