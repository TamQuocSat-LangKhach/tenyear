local difa = fk.CreateSkill {
  name = "difa",
}

Fk:loadTranslationTable{
  ["difa"] = "地法",
  [":difa"] = "每回合限一次，当你于回合内得到红色牌后，你可以弃置其中一张牌，然后选择一种锦囊牌的牌名，从牌堆或弃牌堆获得一张此牌名的牌。",

  ["#difa-invoke"] = "地法：你可以弃置其中一张红色牌，选择一张锦囊牌名获得之",
  ["#difa-choice"] = "地法：选择你要获得的锦囊牌",

  ["$difa1"] = "地蕴天成，微妙玄通。",
  ["$difa2"] = "观地之法，吉在其中。",
}

local U = require "packages/utility/utility"

difa:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(difa.name) and player.room.current ~= player and
      player:usedSkillTimes(difa.name, Player.HistoryTurn) == 0 then
      local ids = {}
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) and Fk:getCardById(info.cardId).color == Card.Red then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = difa.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = event:getCostData(self).cards }),
      prompt = "#difa-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, difa.name, player, player)
    if player.dead then return end
    local name = U.askForChooseCardNames(room, player, Fk:getAllCardNames("td"), 1, 1, difa.name, "#difa-choice")[1]
    local cards = room:getCardsFromPileByRule(name, 1, "discardPile")
    if #cards == 0 then
      cards = room:getCardsFromPileByRule(name, 1)
    end
    if #cards > 0 then
      room:obtainCard(player, cards, true, fk.ReasonJustMove, player, difa.name)
    end
  end,
})

return difa
