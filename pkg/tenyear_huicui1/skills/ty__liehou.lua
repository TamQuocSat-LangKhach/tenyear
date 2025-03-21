local ty__liehou = fk.CreateSkill {
  name = "ty__liehou"
}

Fk:loadTranslationTable{
  ['ty__liehou'] = '列侯',
  ['@ty__liehou'] = '列侯',
  ['#ty__liehou-discard'] = '列侯：你需弃置%arg张牌，否则失去1点体力',
  [':ty__liehou'] = '锁定技，摸牌阶段，你额外摸一张牌，然后选择一项：1.弃置等量的牌；2.失去1点体力。',
  ['$ty__liehou1'] = '论功行赏，加官进侯。',
  ['$ty__liehou2'] = '增班列侯，赏赐无量！'
}

ty__liehou:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__liehou.name) 
  end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, ty__liehou.name)
    player:broadcastSkillInvoke(ty__liehou.name)
    data.n = data.n + 1 + player:getMark("@ty__liehou")
  end
})

ty__liehou:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__liehou.name) and 
      player:usedSkillTimes(ty__liehou.name, Player.HistoryPhase) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1 + player:getMark("@ty__liehou")
    if #room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = ty__liehou.name,
      cancelable = true,
      pattern = ".",
      prompt = "#ty__liehou-discard:::"..n
    }) < n then
      room:loseHp(player, 1, ty__liehou.name)
    end
  end
})

return ty__liehou
