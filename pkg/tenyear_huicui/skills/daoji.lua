local daoji = fk.CreateSkill {
  name = "ty__daoji",
}

Fk:loadTranslationTable{
  ["ty__daoji"] = "盗戟",
  [":ty__daoji"] = "当其他角色本局游戏第一次使用武器牌时，你可以选择一项：1.获得此武器牌；2.其本回合不能使用或打出【杀】。",

  ["ty__daoji_prohibit"] = "%dest本回合不能出杀",
  ["ty__daoji_prey"] = "获得%dest使用的%arg",
  ["@@ty__daoji_prohibit-turn"] = "盗戟 不能出杀",

  ["$ty__daoji1"] = "典韦勇猛，盗戟可除。",
  ["$ty__daoji2"] = "你的，就是我的。",
}

daoji:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(daoji.name) and
      data.extra_data and data.extra_data.ty__daoji_triggerable and
      (not target.dead or player.room:getCardArea(data.card) == Card.Processing)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if not target.dead then
      table.insert(choices, 1, "ty__daoji_prohibit::"..target.id)
    end
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, 1, "ty__daoji_prey::"..target.id..":"..data.card:toLogString())
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = daoji.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice:startsWith("ty__daoji_prey") then
      room:obtainCard(player, data.card, true, fk.ReasonPrey, player, daoji.name)
    else
      room:setPlayerMark(target, "@@ty__daoji_prohibit-turn", 1)
    end
  end,
})

daoji:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("ty__daoji_used_weapon") == 0 and data.card.sub_type == Card.SubtypeWeapon
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ty__daoji_used_weapon", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__daoji_triggerable = true
  end,
})

daoji:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty__daoji_prohibit-turn") > 0 and card and card.trueName == "slash"
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@ty__daoji_prohibit-turn") > 0 and card and card.trueName == "slash"
  end,
})

daoji:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
    local use = e.data
    if use.card.sub_type == Card.SubtypeWeapon then
      room:setPlayerMark(use.from, "ty__daoji_used_weapon", 1)
    end
  end, Player.HistoryGame)
end)

return daoji
