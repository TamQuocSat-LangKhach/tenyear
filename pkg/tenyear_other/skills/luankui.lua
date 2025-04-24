local luankui = fk.CreateSkill {
  name = "luankui",
}

Fk:loadTranslationTable{
  ["luankui"] = "乱魁",
  [":luankui"] = "你每回合第二次造成伤害后，可以弃置一张“袁绍”牌令你本回合下次造成的伤害翻倍；你每回合第二次获得牌后，可以弃置一张“袁术”牌"..
  "令你本回合下次摸牌翻倍。",

  ["#luankui1-invoke"] = "乱魁：你可以弃置一张“袁绍”牌，本回合你下次造成伤害翻倍",
  ["#luankui2-invoke"] = "乱魁：你可以弃置一张“袁术”牌，本回合你下次摸牌翻倍",
  ["@@luankui1-turn"] = "伤害翻倍",
  ["@@luankui2-turn"] = "摸牌翻倍",
}

luankui:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(luankui.name) and
      #player.room.logic:getActualDamageEvents(3, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) == 2 and
      not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@lieti-inhand") == Fk:translate("yuanshao")
    end)
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = luankui.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#luankui1-invoke",
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@luankui1-turn", 1)
    room:throwCard(event:getCostData(self).cards, luankui.name, player, player)
  end,
})

luankui:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@luankui1-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@luankui1-turn", 0)
    data:changeDamage(2 * data.damage - 1)
  end,
})

luankui:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(luankui.name) and player:getMark("luankui2-turn") < 2 then
      player.room:setPlayerMark(player, "luankui2-turn", 1)
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          player.room.logic:getEventsByRule(GameEvent.MoveCards, 3, function (e)
            for _, m in ipairs(e.data) do
              if m.to == player and m.toArea == Player.Hand then
                player.room:addPlayerMark(player, "luankui2-turn", 1)
                return true
              end
            end
          end, nil, Player.HistoryTurn)
          return player:getMark("luankui2-turn") == 2 and not player:isKongcheng()
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@lieti-inhand") == Fk:translate("yuanshu")
    end)
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = luankui.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#luankui2-invoke",
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@luankui2-turn", 1)
    room:throwCard(event:getCostData(self).cards, luankui.name, player, player)
  end,
})

luankui:addEffect(fk.BeforeDrawCard, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@luankui2-turn") > 0 and data.num > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@luankui2-turn", 0)
    data.num = 2 * data.num
  end,
})

return luankui
