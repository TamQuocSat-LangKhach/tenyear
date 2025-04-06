local caishi = fk.CreateSkill {
  name = "ty__caishi",
}

Fk:loadTranslationTable{
  ["ty__caishi"] = "才识",
  [":ty__caishi"] = "摸牌阶段结束时，若你本阶段摸的牌：花色相同，本回合〖忠鉴〗改为“出牌阶段限两次”；花色不同，你可以回复1点体力，"..
  "然后本回合你不能对自己使用牌。",

  ["#ty__caishi-invoke"] = "才识：你可以回复1点体力，然后本回合不能对自己使用牌",
  ["@@ty__caishi-turn"] = "才识",

  ["$ty__caishi1"] = "柔指弄弦商羽，缀符成乐，似落珠玉盘。",
  ["$ty__caishi2"] = "素手点墨二三，绘文成卷，集缤纷万千。",
}

caishi:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(caishi.name) and player.phase == Player.Draw then
      local suit, yes
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.moveReason == fk.ReasonDraw then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.DrawPile then
                local suit2 = Fk:getCardById(info.cardId).suit
                if suit == nil then
                  yes = true
                  suit = suit2
                elseif suit ~= Fk:getCardById(info.cardId).suit then
                  yes = false
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if not player:isWounded() and yes == false then
        yes = nil
      end
      if yes ~= nil then
        event:setCostData(self, {choice = yes})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choice = event:getCostData(self).choice
    if choice == false then
      return player.room:askToSkillInvoke(player, {
        skill_name = caishi.name,
        prompt = "#ty__caishi-invoke",
      })
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == false then
      room:recover{
        who = player,
        num = 1,
        skillName = caishi.name,
      }
      room:addPlayerMark(player, "@@ty__caishi-turn")
    else
      room:setPlayerMark(player, "ty__caishi_twice-turn", 1)
    end
  end,
})

caishi:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and from:getMark("@@ty__caishi-turn") > 0 and from == to
  end,
})

return caishi
