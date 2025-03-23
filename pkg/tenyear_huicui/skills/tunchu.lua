local tunchu = fk.CreateSkill {
  name = "ty__tunchu"
}

Fk:loadTranslationTable{
  ['ty__tunchu'] = '囤储',
  ['@ty__tunchu-turn'] = '囤储',
  ['@@ty__tunchu_prohibit-turn'] = '囤储 不能出牌',
  [':ty__tunchu'] = '锁定技，游戏开始时，你将手牌摸至等同于游戏人数四倍数量张（以此法摸牌不生成牌移动后时机）；你不能弃置你的手牌；当你因其他角色弃置而失去手牌前，防止这些牌移动；准备阶段开始时，若你的手牌数大于体力值，则你于本回合内只能使用三张牌。',
  ['$ty__tunchu1'] = '秋收冬藏，此四时之理，亘古不变。',
  ['$ty__tunchu2'] = '囤粮之家，必无饥馑之虞。',
}

-- GameStart, BeforeCardsMove, EventPhaseStart
tunchu:addEffect({fk.GameStart, fk.BeforeCardsMove, fk.EventPhaseStart}, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tunchu) then
      return false
    end

    if event == fk.GameStart then
      return (#player.room.players * 4 - player:getHandcardNum()) > 0
    elseif event == fk.BeforeCardsMove then
      return table.find(
        target,
        function(info)
          return info.from == player.id and info.moveReason == fk.ReasonDiscard and table.find(info.moveInfo, function(moveInfo) return moveInfo.fromArea == Card.PlayerHand end)
        end
      )
    else
      return target == player and player.phase == Player.Start and player:getHandcardNum() > player.hp
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:drawCards(#room.players * 4 - player:getHandcardNum(), tunchu.name)
    elseif event == fk.BeforeCardsMove then
      local ids = {}
      for _, move in ipairs(target) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          local moveInfos = {}
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(ids, info.cardId)
            else
              table.insert(moveInfos, info)
            end
          end
          if #ids > 0 then
            move.moveInfo = moveInfos
          end
        end
      end
      if #ids > 0 then
        player.room:sendLog{
          type = "#cancelDismantle",
          card = ids,
          arg = tunchu.name,
        }
      end
    else
      room:setPlayerMark(player, "@ty__tunchu-turn", 3)
    end
  end,
})

-- AfterCardUseDeclared
tunchu:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__tunchu-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local tunchuMark = player:getMark("@ty__tunchu-turn")
    tunchuMark = tunchuMark - 1
    if tunchuMark == 0 then
      room:addPlayerMark(player, "@@ty__tunchu_prohibit-turn")
    end

    room:setPlayerMark(player, "@ty__tunchu-turn", tunchuMark)
  end,
})

-- ProhibitSkill
tunchuProhibit = fk.CreateSkill {
  name = "#ty__tunchu_prohibit"
}

tunchu:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty__tunchu_prohibit-turn") > 0
  end,
  prohibit_discard = function(self, player, card)
    return player:hasSkill(tunchu) and Fk:currentRoom():getCardArea(card.id) == Card.PlayerHand
  end,
})

-- Break Skill
local tunchuBreak = fk.CreateTriggerSkill{
  name = "#ty__tunchu_break",
  mute = true,
  priority = 100,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    return data[1].skillName == tunchu.name and data[1].moveReason == fk.ReasonDraw
  end,
  on_trigger = Util.TrueFunc,
}

return tunchu
