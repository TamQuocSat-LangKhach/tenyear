local baojia = fk.CreateSkill{
  name = "baojia",
}

Fk:loadTranslationTable{
  ["baojia"] = "保驾",
  [":baojia"] = "游戏开始时，你选择一名其他角色，你与其每回合首次受到牌造成的伤害时，你可以废除一个装备栏防止此伤害，此牌结算结束后你获得之。",

  ["@baojia"] = "保驾",
  ["#baojia-choose"] = "保驾：请选择要保驾的角色",
  ["#baojia-invoke"] = "保驾：是否废除一个装备栏，防止 %dest 受到的伤害？",

  ["$baojia1"] = "",
  ["$baojia2"] = "",
}

baojia:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(baojia.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = baojia.name,
      prompt = "#baojia-choose",
      cancelable = false,
    })[1]
    room:setPlayerMark(player, baojia.name, to.id)
    room:setPlayerMark(player, "@baojia", to.general)
  end,
})

baojia:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(baojia.name) and
      (target == player or player:getMark(baojia.name) == target.id) and data.card and
      #player:getAvailableEquipSlots() > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function (e)
        local damage = e.data
        return damage.to == target and damage.card ~= nil
      end, Player.HistoryTurn) == 0 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = player:getAvailableEquipSlots()
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = baojia.name,
      prompt = "#baojia-invoke::"..target.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:abortPlayerArea(player, event:getCostData(self).choice)
    if not player.dead then
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        if use.card == data.card then
          use.extra_data = use.extra_data or {}
          use.extra_data.baojia = use.extra_data.baojia or {}
          table.insertIfNeed(use.extra_data.baojia, player)
        end
      end
    end
  end,
})

baojia:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.baojia and table.contains(data.extra_data.baojia, player) and
      not player.dead and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, baojia.name, nil, true, player)
  end,
})

return baojia
