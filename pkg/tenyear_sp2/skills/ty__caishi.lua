local ty__caishi = fk.CreateSkill {
  name = "ty__caishi"
}

Fk:loadTranslationTable{
  ['ty__caishi'] = '才识',
  ['#ty__caishi-invoke'] = '你可以回复1点体力，然后本回合你不能对自己使用牌',
  ['@@ty__caishi_self-turn'] = '才识',
  [':ty__caishi'] = '摸牌阶段结束时，若你本阶段摸的牌：花色相同，本回合〖忠鉴〗改为“出牌阶段限两次”；花色不同，你可以回复1点体力，然后本回合你不能对自己使用牌。',
  ['$ty__caishi1'] = '柔指弄弦商羽，缀符成乐，似落珠玉盘。',
  ['$ty__caishi2'] = '素手点墨二三，绘文成卷，集缤纷万千。',
}

ty__caishi:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if player:hasSkill(ty__caishi.name) and player == target and player.phase == Player.Draw then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local move = e.data[1]
        if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.DrawPile then
              return true
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player)
    local ids = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      local move = e.data[1]
      if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryPhase)
    if #ids == 0 then return false end
    local different = table.find(ids, function(id) return Fk:getCardById(id).suit ~= Fk:getCardById(ids[1]).suit end)
    event:setCostData(self, different)
    if different then
      return player:isWounded() and player.room:askToSkillInvoke(player, {
        skill_name = ty__caishi.name,
        prompt = "#ty__caishi-invoke"
      })
    else
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local different = event:getCostData(self)
    if different then
      room:recover({ who = player, num = 1, skillName = ty__caishi.name })
      room:addPlayerMark(player, "@@ty__caishi_self-turn")
    else
      room:setPlayerMark(player, "ty__caishi_twice-turn", 1)
    end
  end,
})

ty__caishi:addEffect("prohibit", {
  name = "#ty__caishi_prohibit",
  is_prohibited = function(self, from, to)
    return from:getMark("@@ty__caishi_self-turn") > 0 and from == to
  end,
})

return ty__caishi
