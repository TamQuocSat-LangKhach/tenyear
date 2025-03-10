local liunian = fk.CreateSkill {
  name = "liunian"
}

Fk:loadTranslationTable{
  ['liunian'] = '流年',
  [':liunian'] = '锁定技，牌堆第一次洗牌的回合结束时，你加1点体力上限。牌堆第二次洗牌的回合结束时，你回复1点体力，然后本局游戏手牌上限+10。',
  ['$liunian1'] = '佳期若梦，似水流年。',
  ['$liunian2'] = '逝者如流水，昼夜不将息。',
}

liunian:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(liunian.name) and player:getMark("liunian-turn") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player:getMark(liunian.name) == 1 then
      room:changeMaxHp(player, 1)
    else
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = liunian.name
        })
      end
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 10)
    end
  end,
})

liunian:addEffect(fk.AfterDrawPileShuffle, {
  can_refresh = function(self, event, target, player)
    return player:getMark(liunian.name) < 2
  end,
  on_refresh = function(self, event, target, player)
    player.room:addPlayerMark(player, liunian.name, 1)
    player.room:setPlayerMark(player, "liunian-turn", 1)
  end,
})

return liunian
