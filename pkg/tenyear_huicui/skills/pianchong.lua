local pianchong = fk.CreateSkill {
  name = "pianchong",
}

Fk:loadTranslationTable{
  ["pianchong"] = "偏宠",
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红色牌和黑色牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌后"..
  "摸一张黑色牌；2.你每失去一张黑色牌后摸一张红色牌。",

  ["#pianchong-choice"] = "偏宠：选择一种颜色，失去此颜色的牌时摸另一种颜色的牌",
  ["@pianchong"] = "偏宠",

  ["$pianchong1"] = "得陛下怜爱，恩宠不衰。",
  ["$pianchong2"] = "谬蒙圣恩，光授殊宠。",
}

pianchong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pianchong.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local cards = {}
    local color = Card.NoColor
    for _, id in ipairs(room.draw_pile) do
      local _color = Fk:getCardById(id).color
      if _color ~= color and _color ~= Card.NoColor then
        color = _color
        table.insert(cards, id)
        if #cards == 2 then break end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, pianchong.name, nil, false, player)
      if player.dead then return end
    end
    local choice = room:askToChoice(player, {
      choices = {"red", "black"},
      skill_name = pianchong.name,
      prompt = "#pianchong-choice",
    })
    room:addTableMarkIfNeed(player, "@pianchong", choice)
  end,
})

pianchong:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@pianchong") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@pianchong", 0)
  end,
})

pianchong:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@pianchong") ~= 0 and not player.dead then
      local colors = player:getTableMark("@pianchong")
      local x, y = 0, 0
      local color
      for _, move in ipairs(event.data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              color = Fk:getCardById(info.cardId).color
              if color == Card.Red then
                x = x + 1
              elseif color == Card.Black then
                y = y + 1
              end
            end
          end
        end
      end
      if not table.contains(colors, "red") then
        x = 0
      end
      if not table.contains(colors, "black") then
        y = 0
      end
      if x > 0 or y > 0 then
        event:setCostData(self, {extra_data = {x, y}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self).extra_data
    local x, y = table.unpack(dat)
    local color
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      color = Fk:getCardById(id).color
      if color == Card.Black then
        if x > 0 then
          x = x - 1
          table.insert(cards, id)
        end
      elseif color == Card.Red then
        if y > 0 then
          y = y - 1
          table.insert(cards, id)
        end
      end
      if x == 0 and y == 0 then break end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonDraw, pianchong.name, nil, false, player)
    end
  end,
})

return pianchong
