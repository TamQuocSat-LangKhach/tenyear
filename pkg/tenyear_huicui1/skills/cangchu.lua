local cangchu = fk.CreateSkill {
  name = "cangchu"
}

Fk:loadTranslationTable{
  ['cangchu'] = '仓储',
  ['@cangchu'] = '粮',
  [':cangchu'] = '锁定技，游戏开始时，你获得3枚“粮”标记；每拥有1枚“粮”手牌上限+1；当你于回合外获得牌时，获得1枚“粮”（每回合限一枚，且“粮”的总数不能大于存活角色数）。',
  ['$cangchu1'] = '广积粮草，有备无患。',
  ['$cangchu2'] = '吾奉命于此、建仓储粮。',
}

cangchu:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@cangchu", math.min(#room.alive_players, player:getMark("@cangchu") + 3))
    room:broadcastProperty(player, "MaxCards")
  end,
})

cangchu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes(cangchu.name, Player.HistoryTurn) < 1 and player:getMark("@cangchu") < #player.room.alive_players then
      if player:hasSkill(skill.name) and player.phase == Player.NotActive then
        for _, move in ipairs(data) do
          if move.toArea == Card.PlayerHand and move.to == player.id then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@cangchu")
    room:broadcastProperty(player, "MaxCards")
  end,
})

cangchu:addEffect(fk.Death, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(skill.name,true) and player:getMark("@cangchu") > #player.room.alive_players
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@cangchu", #room.alive_players)
    room:broadcastProperty(player, "MaxCards")
  end,
})

local cangchu_maxcards = fk.CreateSkill {
  name = "#cangchu_maxcards"
}
cangchu_maxcards:addEffect('maxcards', {
  correct_func = function(self, player)
    return player:getMark("@cangchu")
  end,
})

return cangchu
