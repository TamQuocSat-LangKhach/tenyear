local cangchu = fk.CreateSkill {
  name = "cangchu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cangchu"] = "仓储",
  [":cangchu"] = "锁定技，游戏开始时，你获得3枚“粮”标记；每拥有1枚“粮”手牌上限+1；当你于回合外获得牌时，获得1枚“粮”"..
  "（每回合限一枚，且“粮”的总数不能大于存活角色数）。",

  ["@cangchu"] = "粮",

  ["$cangchu1"] = "广积粮草，有备无患。",
  ["$cangchu2"] = "吾奉命于此、建仓储粮。",
}

cangchu:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cangchu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@cangchu", math.min(#room.alive_players, player:getMark("@cangchu") + 3))
  end,
})

cangchu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(cangchu.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      player:getMark("@cangchu") < #player.room.alive_players and player.room.current ~= player then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@cangchu")
  end,
})

cangchu:addEffect(fk.Death, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(cangchu.name, true) and player:getMark("@cangchu") > #player.room.alive_players
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@cangchu", #room.alive_players)
  end,
})

cangchu:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("@cangchu")
  end,
})

cangchu:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@cangchu", 0)
end)

return cangchu
