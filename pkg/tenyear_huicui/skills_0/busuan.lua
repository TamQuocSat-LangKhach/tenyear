local busuan = fk.CreateSkill {
  name = "busuan"
}

Fk:loadTranslationTable{
  ["busuan"] = "卜算",
  [":busuan"] = "出牌阶段限一次，你可以选择一名其他角色，然后选择至多两种基本牌或锦囊牌牌名。"..
  "该角色下次摸牌阶段摸牌时，改为从牌堆或弃牌堆中获得你选择的牌。",

  ["#busuan"] = "卜算，选择一名角色，控制其下个摸牌阶段摸牌的牌名",
  ["#busuan-choose"] = "卜算：选择至多两个卡名，作为 %dest 下次摸牌阶段摸到的牌",

  ["$busuan1"] = "今日一卦，便知命数。",
  ["$busuan2"] = "喜仰视星辰，夜不肯寐。",
}

local U = require "packages/utility/utility"

busuan:addEffect("active", {
  anim_type = "control",
  prompt = "#busuan",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(busuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = U.askForChooseCardNames(room, player, Fk:getAllCardNames("btd"), 1, 2, busuan.name,
      "#busuan-choose::" .. target.id, Fk:getAllCardNames("btd"), false)
    local mark = target:getTableMark(busuan.name)
    table.insertTable(mark, room:askToChoices(player, choices))
    room:setPlayerMark(target, busuan.name, mark)
  end,
})

busuan:addEffect(fk.BeforeDrawCard, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.skillName "phase_draw" and
      data.num > 0 and player:getMark(busuan.name) ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local card_names = player:getMark(busuan.name)
    room:setPlayerMark(player, busuan.name, 0)
    for i = 1, #card_names, 1 do
      table.insert(cards, -1)
    end
    for i = 1, #card_names, 1 do
      if cards[i] == -1 then
        local name = card_names[i]
        local x = #table.filter(card_names, function (card_name)
          return card_name == name
        end)
        local tosearch = room:getCardsFromPileByRule(".|.|.|.|" .. name, x, "discardPile")
        if #tosearch < x then
          table.insertTable(tosearch, room:getCardsFromPileByRule(".|.|.|.|" .. name, x - #tosearch))
        end

        for i2 = 1, #card_names, 1 do
          if card_names[i2] == name then
            if #tosearch > 0 then
              cards[i2] = tosearch[1]
              table.remove(tosearch, 1)
            else
              cards[i2] = -2
            end
          end
        end
      end
    end
    local to_get = {}
    for i = 1, #card_names, 1 do
      if #to_get >= data.num then break end
      if cards[i] > -1 then
        table.insert(to_get, cards[i])
      end
    end

    data.num = data.num - #to_get

    if #to_get > 0 then
      room:moveCards({
        ids = to_get,
        to = target,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = busuan.name,
        moveVisible = false,
      })
    end
  end,
})

return busuan
