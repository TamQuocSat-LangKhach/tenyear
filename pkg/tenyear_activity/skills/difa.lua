local difa = fk.CreateSkill {
  name = "difa"
}

Fk:loadTranslationTable{
  ['difa'] = '地法',
  ['#difa-invoke'] = '是否发动 地法，弃置一张刚得到的红色牌，然后检索一张锦囊牌',
  [':difa'] = '每回合限一次，当你于回合内得到红色牌后，你可以弃置其中一张牌，然后选择一种锦囊牌的牌名，从牌堆或弃牌堆获得一张此牌名的牌。',
  ['$difa1'] = '地蕴天成，微妙玄通。',
  ['$difa2'] = '观地之法，吉在其中。',
}

difa:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(difa.name) and player:usedSkillTimes(difa.name) == 0 and player.phase ~= Player.NotActive then
      local ids = {}
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) and Fk:getCardById(info.cardId).color == Card.Red then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 then
        event:setCostData(skill, ids)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = difa.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = event:getCostData(skill) }),
      prompt = "#difa-invoke",
      skip = true
    })
    if #card > 0 then
      event:setCostData(skill, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(skill), difa.name, player, player)
    local names = player:getMark("difa_names")
    if type(names) ~= "table" then
      names = U.getAllCardNames("td", true)
      room:setPlayerMark(player, "difa_names", names)
    end
    if #names == 0 then return end
    local name = room:askToChoice(player, {
      choices = names,
      skill_name = difa.name
    })
    local cards = room:getCardsFromPileByRule(name, 1, "discardPile")
    if #cards == 0 then
      cards = room:getCardsFromPileByRule(name, 1)
    end
    if #cards > 0 then
      room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
  end,
})

return difa
