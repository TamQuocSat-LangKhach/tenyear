local jiaoying = fk.CreateSkill {
  name = "jiaoying"
}

Fk:loadTranslationTable{
  ['jiaoying'] = '醮影',
  ['@jiaoying-turn'] = '醮影',
  ['jiaoying_usedcard'] = '使用过牌',
  ['#jiaoying_delay'] = '醮影',
  ['#jiaoying-choose'] = '醮影：可选择至多%arg名角色将手牌补至5张',
  [':jiaoying'] = '锁定技，其他角色获得你的手牌后，该角色本回合不能使用或打出与此牌颜色相同的牌。然后此回合结束阶段，若其本回合没有再使用牌，你令一名角色将手牌摸至五张。',
  ['$jiaoying1'] = '独酌清醮，霓裳自舞。',
  ['$jiaoying2'] = '醮影倩丽，何人爱怜。',
}

jiaoying:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiaoying.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
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
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local to = room:getPlayerById(move.to)
        local jiaoying_colors = type(to:getMark("jiaoying_colors-turn")) == "table" and to:getMark("jiaoying_colors-turn") or {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local color = Fk:getCardById(info.cardId).color
            if color ~= Card.NoColor then
              table.insertIfNeed(jiaoying_colors, color)
              table.insertIfNeed(jiaoying_targets, to.id)
              if to:getMark("@jiaoying-turn") == 0 then
                room:setPlayerMark(to, "@jiaoying-turn", {})
              end
            end
          end
        end
        room:setPlayerMark(to, "jiaoying_colors-turn", jiaoying_colors)
      end
    end
    room:setPlayerMark(player, "jiaoying_targets-turn", jiaoying_targets)
  end,
  can_refresh = function(self, event, target, player, data)
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    return table.contains(jiaoying_targets, target.id) and not table.contains(jiaoying_ignores, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    table.insert(jiaoying_ignores, target.id)
    player.room:setPlayerMark(player, "jiaoying_ignores-turn", jiaoying_ignores)
    player.room:setPlayerMark(target, "@jiaoying-turn", {"jiaoying_usedcard"})
  end,
})

jiaoying:addEffect(fk.EventPhaseStart, {
  name = "#jiaoying_delay",
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish then
      local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
      local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
      event:setCostData(skill, #jiaoying_targets - #jiaoying_ignores)
      if event:getCostData(skill) > 0 then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(skill)
    local targets = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room.alive_players, function (p) return p:getHandcardNum() < 5 end), Util.IdMapper),
      min_num = 1,
      max_num = x,
      prompt = "#jiaoying-choose:::" .. x,
      skill_name = jiaoying.name,
      cancelable = true
    })
    if #targets > 0 then
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        if not to.dead and to:getHandcardNum() < 5 then
          to:drawCards(5 - to:getHandcardNum(), jiaoying.name)
        end
      end
    end
  end,
})

jiaoying:addEffect('prohibit', {
  name = "#jiaoying_prohibit",
  prohibit_use = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
  prohibit_response = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
})

return jiaoying
