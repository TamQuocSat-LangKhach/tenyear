local shizhao = fk.CreateSkill {
  name = "shizhao"
}

Fk:loadTranslationTable{
  ['shizhao'] = '失诏',
  ['@mushun_jin'] = '劲',
  ['@shizhao-turn'] = '失诏',
  [':shizhao'] = '锁定技，你的回合外，当你每回合第一次失去最后一张手牌时：若你有“劲”，你移去一个“劲”并摸两张牌；没有“劲”，你本回合下一次受到的伤害值+1。',
  ['$shizhao1'] = '并无夹带，阁下多心了。',
  ['$shizhao2'] = '将军多虑，顺安有忤逆之心？',
}

shizhao:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shizhao) and player:isKongcheng() and player.phase == Player.NotActive and
      player:usedSkillTimes(shizhao.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
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
    if player:getMark("@mushun_jin") > 0 then
      player:broadcastSkillInvoke(shizhao.name, 1)
      room:notifySkillInvoked(player, shizhao.name, "drawcard")
      room:removePlayerMark(player, "@mushun_jin", 1)
      player:drawCards(2, shizhao.name)
    else
      player:broadcastSkillInvoke(shizhao.name, 2)
      room:notifySkillInvoked(player, shizhao.name, "negative")
      room:addPlayerMark(player, "@shizhao-turn", 1)
    end
  end,
})

shizhao:addEffect(fk.DamageInflicted, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@shizhao-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@shizhao-turn")
    player.room:setPlayerMark(player, "@shizhao-turn", 0)
  end,
})

return shizhao
