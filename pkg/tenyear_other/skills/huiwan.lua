local huiwan = fk.CreateSkill {
  name = "huiwan",
}

Fk:loadTranslationTable{
  ["huiwan"] = "会玩",
  [":huiwan"] = "每回合每种牌名限一次，当你摸牌时，你可以选择至多等量牌堆中有的基本牌或普通锦囊牌牌名，改为从牌堆中获得你选择的牌。",

  ["#huiwan-choice"] = "会玩：你可以选择至多 %arg 个牌名，本次改为摸所选牌名的牌",

  ["$huiwan1"] = "金珠弹黄鹂，玉带做秋千，如此游戏人间。",
  ["$huiwan2"] = "小爷横行江东，今日走马、明日弄鹰。",
}

local U = require "packages/utility/utility"

huiwan:addEffect(fk.BeforeDrawCard, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huiwan.name) and data.num > 0 and
      table.find(player.room.draw_pile, function (id)
        local card = Fk:getCardById(id)
        return (card.type == Card.TypeBasic or card:isCommonTrick()) and
          not table.contains(player:getTableMark("huiwan_card_names-turn"), card.trueName)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for _, name in ipairs(room:getBanner("huiwan_all_names")) do
      if table.find(room.draw_pile, function (id)
          return Fk:getCardById(id).trueName == name
        end) and
        not table.contains(player:getTableMark("huiwan_card_names-turn"), name) then
        table.insertIfNeed(choices, name)
      end
    end
    local result = U.askForChooseCardNames(room, player,
      choices, 1, data.num, huiwan.name, "#huiwan-choice:::" .. data.num, nil, true)
    if #result > 0 then
      event:setCostData(self, {choice = result})
      return true
    end
  end,

  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = table.simpleClone(event:getCostData(self).choice)
    local record = player:getTableMark("huiwan_card_names-turn")
    table.insertTable(record, names)
    room:setPlayerMark(player, "huiwan_card_names-turn", record)
    local toDraw = {}
    for i = #room.draw_pile, 1, -1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if table.contains(names, card.trueName) then
        table.removeOne(names, card.trueName)
        table.insert(toDraw, card.id)
      end
    end
    if #toDraw > 0 then
      room:obtainCard(player, toDraw, false, fk.ReasonJustMove, player, huiwan.name)
    end
    data.num = data.num - #toDraw
  end,
})

huiwan:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  local allCardNames = {}
  for _, id in ipairs(Fk:getAllCardIds()) do
    local card = Fk:getCardById(id)
    if (card.type == Card.TypeBasic or card:isCommonTrick()) then
      table.insertIfNeed(allCardNames, card.trueName)
    end
  end
  room:setBanner("huiwan_all_names", allCardNames)
end)

return huiwan
