local hengwu = fk.CreateSkill {
  name = "hengwu",
}

Fk:loadTranslationTable{
  ["hengwu"] = "横骛",
  [":hengwu"] = "当你使用或打出牌时，若你没有该花色的手牌，你可以摸X张牌（X为场上与此牌花色相同的装备数量）。",

  ["$hengwu1"] = "横枪立马，独啸秋风！",
  ["$hengwu2"] = "世皆彳亍，唯我纵横！",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hengwu.name) and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):compareSuitWith(data.card)
        end) and
      table.find(player.room.alive_players, function (p)
        return table.find(p:getCardIds("e"), function (id)
          return Fk:getCardById(id):compareSuitWith(data.card)
        end) ~= nil
      end)
  end,
  on_use = function(self, event, target, player, data)
    local x = 0
    for _, p in ipairs(player.room.alive_players) do
      for _, id in ipairs(p:getCardIds("e")) do
        if Fk:getCardById(id):compareSuitWith(data.card) then
          x = x + 1
        end
      end
    end
    player:drawCards(x, hengwu.name)
  end,
}

hengwu:addEffect(fk.CardUsing, spec)
hengwu:addEffect(fk.CardResponding, spec)

return hengwu
