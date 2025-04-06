local huiling = fk.CreateSkill {
  name = "huiling",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huiling"] = "汇灵",
  [":huiling"] = "锁定技，你使用牌时，若弃牌堆中的红色牌数量多于黑色牌，你回复1点体力；黑色牌数量多于红色牌，你可以弃置一名其他角色"..
  "区域内的一张牌；牌数较少的颜色与你使用牌的颜色相同，你获得一个“灵”标记。",

  ["@ty__sunhanhua_ling"] = "灵",
  ["#huiling-choose"] = "汇灵：你可以弃置一名其他角色区域内的一张牌",

  ["$huiling1"] = "天地有灵，汇于我眸间。",
  ["$huiling2"] = "撷四时钟灵，拈芳兰毓秀。",
}

huiling:addEffect(fk.CardUsing, {
  anim_type = "control",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local red, black = 0, 0
    local color
    for _, id in ipairs(room.discard_pile) do
      color = Fk:getCardById(id).color
      if color == Card.Red then
        red = red + 1
      elseif color == Card.Black then
        black = black + 1
      end
    end
    if red > black then
      if data.card.color == Card.Black then
        room:addPlayerMark(player, "ty__sunhanhua_ling", 1)
        room:setPlayerMark(player, "@ty__sunhanhua_ling", "<font color='red'>"..player:getMark("ty__sunhanhua_ling").."</font>")
      end
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = huiling.name,
        }
      end
    elseif black > red then
      if data.card.color == Card.Red then
        room:addPlayerMark(player, "ty__sunhanhua_ling", 1)
        room:setPlayerMark(player, "@ty__sunhanhua_ling", player:getMark("ty__sunhanhua_ling"))
      end
      local targets = table.filter(room:getOtherPlayers(player), function(p)
        return not p:isAllNude()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#huiling-choose",
          skill_name = huiling.name,
        })
        if #to > 0 then
          local id = room:askToChooseCard(player, {
            target = to[1],
            flag = "hej",
            skill_name = huiling.name,
          })
          room:throwCard(id, huiling.name, to[1], player)
        end
      end
    end
  end,
})

local spec = {
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local red, black = 0, 0
    local color
    for _, id in ipairs(room.discard_pile) do
      color = Fk:getCardById(id).color
      if color == Card.Red then
        red = red + 1
      elseif color == Card.Black then
        black = black + 1
      end
    end
    local x = tostring(player:getMark("ty__sunhanhua_ling"))
    local huiling_info = ""
    if red > black then
      huiling_info = "<font color='red'>" .. x .. "</font>"
    elseif red < black then
      huiling_info = x
    else
      huiling_info = "<font color='grey'>" .. x .. "</font>"
    end
    room:setPlayerMark(player, "@ty__sunhanhua_ling", huiling_info)
  end,
}

huiling:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(huiling.name, true) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DiscardPile then
            return true
          end
        end
      end
    end
  end,
  on_refresh = spec.on_refresh,
})

huiling:addEffect(fk.AfterDrawPileShuffle, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(huiling.name, true)
  end,
  on_refresh = spec.on_refresh,
})

huiling:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "ty__sunhanhua_ling", 0)
  room:setPlayerMark(player, "@ty__sunhanhua_ling", 0)
end)

return huiling
