local tunchu = fk.CreateSkill {
  name = "ty__tunchu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__tunchu"] = "囤储",
  [":ty__tunchu"] = "锁定技，游戏开始时，你将手牌摸至等同于游戏人数四倍；你不能弃置或被弃置手牌；准备阶段，若你的手牌数大于体力值，"..
  "则你本回合只能使用三张牌。",

  ["@ty__tunchu-turn"] = "囤储",
  ["@@ty__tunchu_prohibit-turn"] = "囤储 不能出牌",

  ["$ty__tunchu1"] = "秋收冬藏，此四时之理，亘古不变。",
  ["$ty__tunchu2"] = "囤粮之家，必无饥馑之虞。",
}

tunchu:addEffect(fk.GameStart,{
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tunchu.name) and
      player:getHandcardNum() < #player.room.players * 4
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(#player.room.players * 4 - player:getHandcardNum(), tunchu.name)
  end,
})

tunchu:addEffect(fk.EventPhaseStart,{
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tunchu.name) and player.phase == Player.Start and
    player:getHandcardNum() > player.hp
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__tunchu-turn", 3)
  end,
})

tunchu:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(tunchu.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    room:cancelMove(data, ids)
  end,
})

tunchu:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__tunchu-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@ty__tunchu-turn", 1)
    if player:getMark("@ty__tunchu-turn") == 0 then
      room:setPlayerMark(player, "@@ty__tunchu_prohibit-turn", 1)
    end
  end,
})

tunchu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:getMark("@@ty__tunchu_prohibit-turn") > 0
  end,
  prohibit_discard = function(self, player, card)
    return player:hasSkill(tunchu.name) and table.contains(player:getCardIds("h"), card.id)
  end,
})

tunchu:addEffect(fk.AfterCardsMove, {
  priority = 100,
  can_trigger = function(self, event, target, player, data)
    return data[1].skillName == tunchu.name and data[1].moveReason == fk.ReasonDraw
  end,
  on_trigger = Util.TrueFunc,
})

return tunchu
