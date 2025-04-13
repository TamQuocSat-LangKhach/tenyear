local weiming = fk.CreateSkill{
  name = "weimingw",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["weimingw"] = "威名",
  [":weimingw"] = "锁定技，体力值小于你或本轮受到过你造成伤害的其他角色对你使用牌时，随机弃置一张手牌，若皆满足，你摸一张牌。",

  ["$weiming1"] = "",
  ["$weiming2"] = "",
}

weiming:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(weiming.name) and
      table.contains(data.tos, player) and not target.dead then
      local choices = {}
      if target.hp < player.hp then
        table.insert(choices, 1)
      end
      if #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        return damage.from == player and damage.to == target
      end, Player.HistoryRound) > 0 then
        table.insert(choices, 2)
      end
      event:setCostData(self, {choice = choices})
      if #choices == 2 then
        return true
      elseif choices[1] == 1 then
        return not target:isKongcheng()
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(target:getCardIds("h"), function (id)
      return not target:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(table.random(cards), weiming.name, target, target)
    end
    if #event:getCostData(self).choice == 2 and not player.dead then
      player:drawCards(1, weiming.name)
    end
  end,
})

return weiming
