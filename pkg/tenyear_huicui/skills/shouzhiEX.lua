local shouzhi = fk.CreateSkill {
  name = "shouzhiEX",
}

Fk:loadTranslationTable{
  ["shouzhiEX"] = "守执",
  [":shouzhiEX"] = "一名角色的回合结束时，若你的手牌数比回合开始时多，你可以弃置一张手牌；比回合开始时少，你可以摸两张牌。",

  ["#shouzhi-draw"] = "守执：你可以摸两张牌",
  ["#shouzhi-discard"] = "守执：你可以弃置一张牌",
}

shouzhi:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shouzhi.name) and
      player:getHandcardNum() ~= tonumber(player:getMark("@shouzhi-turn"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = tonumber(player:getMark("@shouzhi-turn"))
    n = n - player:getHandcardNum()
    if n > 0 then
      if room:askToSkillInvoke(player, {
        skill_name = shouzhi.name,
        prompt = "#shouzhi-draw",
      }) then
        event:setCostData(self, nil)
        return true
      end
    else
      local cards = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = shouzhi.name,
        cancelable = true,
        prompt = "#shouzhi-discard",
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shouzhi")
    if event:getCostData(self) ~= nil then
      room:notifySkillInvoked(player, "shouzhi", "negative")
      room:throwCard(event:getCostData(self).cards, "shouzhi", player, player)
    else
      room:notifySkillInvoked(player, "shouzhi", "drawcard")
      player:drawCards(2, "shouzhi")
    end
  end,
})

return shouzhi
