local chaozhen = fk.CreateSkill {
  name = "chaozhen",
}

Fk:loadTranslationTable{
  ["chaozhen"] = "朝镇",
  [":chaozhen"] = "准备阶段或当你进入濒死状态时，你可以从场上或牌堆中随机获得一张点数最小的牌，若此牌点数为A，你回复1点体力，"..
  "此技能本回合失效；若不为A，你减1点体力上限。",

  ["#chaozhen-invoke"] = "朝镇：你可以从场上或牌堆中随机获得一张点数最小的牌",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = {"Field", "Pile", "Cancel"},
      skill_name = chaozhen.name,
      prompt = "#chaozhen-invoke"
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, num = {}, 14
    if event:getCostData(self).choice == "Field" then
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds("ej")) do
          if Fk:getCardById(id).number <= num then
            num = Fk:getCardById(id).number
            table.insert(cards, id)
          end
        end
      end
    else
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number <= num then
          num = Fk:getCardById(id).number
          table.insert(cards, id)
        end
      end
    end
    cards = table.filter(cards, function (id)
      return Fk:getCardById(id).number == num
    end)
    if #cards == 0 then return end
    local card = table.random(cards)
    local yes = Fk:getCardById(card).number == 1
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, chaozhen.name, nil, true, player)
    if player.dead then return end
    if yes then
      room:invalidateSkill(player, chaozhen.name, "-turn")
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = chaozhen.name,
        })
      end
    else
      room:changeMaxHp(player, -1)
    end
  end,
}

chaozhen:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chaozhen.name) and player.phase == Player.Start
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

chaozhen:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chaozhen.name)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return chaozhen
