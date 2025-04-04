local jiaoying = fk.CreateSkill {
  name = "jiaoying",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaoying"] = "醮影",
  [":jiaoying"] = "锁定技，其他角色获得你的手牌后，该角色本回合不能使用或打出与此牌颜色相同的牌。此回合结束阶段，若其本回合没有再使用牌，"..
  "你可以令一名角色将手牌摸至五张。",

  ["@@jiaoying-turn"] = "醮影",
  ["#jiaoying-choose"] = "醮影：你可以令至多%arg名角色将手牌补至5张",

  ["$jiaoying1"] = "独酌清醮，霓裳自舞。",
  ["$jiaoying2"] = "醮影倩丽，何人爱怜。",
}

jiaoying:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiaoying.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getTableMark("jiaoying_targets-turn")
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local color = Fk:getCardById(info.cardId).color
            if color ~= Card.NoColor then
              room:addTableMarkIfNeed(move.to, "jiaoying_colors-turn", color)
              table.insertIfNeed(targets, move.to.id)
              room:setPlayerMark(move.to, "@@jiaoying-turn", 1)
            end
          end
        end
      end
    end
    room:setPlayerMark(player, "jiaoying_targets-turn", targets)
  end,
})

jiaoying:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return table.contains(player:getTableMark("jiaoying_targets-turn"), target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "jiaoying_ignores-turn", target.id)
  end,
})

jiaoying:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and
      #player:getTableMark("jiaoying_targets-turn") > #player:getTableMark("jiaoying_ignores-turn") and
      table.find(player.room.alive_players, function (p)
        return p:getHandcardNum() < 5
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < 5
    end)
    local n = #player:getTableMark("jiaoying_targets-turn") - #player:getTableMark("jiaoying_ignores-turn")
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#jiaoying-choose:::"..n,
      skill_name = jiaoying.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tos = event:getCostData(self).tos
    for _, to in ipairs(tos) do
      if not to.dead and to:getHandcardNum() < 5 then
        to:drawCards(5 - to:getHandcardNum(), jiaoying.name)
      end
    end
  end,
})

jiaoying:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("jiaoying_colors-turn"), card.color)
  end,
  prohibit_response = function(self, player, card)
    return card and table.contains(player:getTableMark("jiaoying_colors-turn"), card.color)
  end,
})

return jiaoying
