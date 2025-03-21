local sanwen = fk.CreateSkill {
  name = "sanwen",
}

Fk:loadTranslationTable{
  ["sanwen"] = "散文",
  [":sanwen"] = "每回合限一次，当你获得牌时，若你手中有与这些牌牌名相同的牌，你可以展示之并弃置获得的同名牌，然后摸弃牌数两倍数量的牌。",

  ["#sanwen-invoke"] = "散文：你可以弃置获得的同名牌（%arg张），然后摸两倍的牌",

  ["$sanwen1"] = "文若春华，思若泉涌。",
  ["$sanwen2"] = "独步汉南，散文天下。",
}

sanwen:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(sanwen.name) and player:usedSkillTimes(sanwen.name, Player.HistoryTurn) == 0 then
      local get = {}
      local handcards = player:getCardIds("h")
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand and move.to == player then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(handcards, info.cardId) then
              table.insertIfNeed(get, info.cardId)
            end
          end
        end
      end
      if #get == 0 then return end
      local throw, show = {}, {}
      for _, id in ipairs(get) do
        for _, _id in ipairs(handcards) do
          if not table.contains(get, _id) then
            local name = Fk:getCardById(_id).trueName
            if Fk:getCardById(id).trueName == name then
              table.insertIfNeed(throw, id)
              table.insertIfNeed(show, _id)
            end
          end
        end
      end
      if #throw > 0 then
        event:setCostData(self, {extra_data = {throw, show}})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).extra_data[1]
    return room:askToSkillInvoke(player, {
      skill_name = sanwen.name,
      prompt = "#sanwen-invoke:::"..#cards,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local throw = event:getCostData(self).extra_data[1]
    local show = event:getCostData(self).extra_data[2]
    table.insertTable(show, throw)
    player:showCards(show)
    throw = table.filter(throw, function (id)
      return table.contains(player:getCardIds("h"), id) and not player:prohibitDiscard(Fk:getCardById(id))
    end)
    if #throw > 0 and not player.dead then
      room:throwCard(throw, sanwen.name, player, player)
      if not player.dead then
        player:drawCards(2 * #throw, sanwen.name)
      end
    end
  end,
})

return sanwen
