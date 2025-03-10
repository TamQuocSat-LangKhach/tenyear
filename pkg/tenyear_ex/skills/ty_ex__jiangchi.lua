local ty_ex__jiangchi = fk.CreateSkill {
  name = "ty_ex__jiangchi"
}

Fk:loadTranslationTable{
  ['ty_ex__jiang__chi'] = '将驰',
  ['ty_ex__jiangchi_active'] = '将驰',
  ['#ty_ex__jiangchi-invoke'] = '将驰：你可以选一项执行',
  ['@@ty_ex__jiangchi_targetmod-phase'] = '将驰 多出杀',
  ['@@ty_ex__jiangchi_prohibit-phase'] = '将驰 不出杀',
  [':ty_ex__jiangchi'] = '出牌阶段开始时，你可以选择一项：1.摸两张牌，此阶段不能使用或打出【杀】；2.摸一张牌；3.弃置一张牌，此阶段使用【杀】无距离限制且可以多使用一张【杀】。',
  ['$ty_ex__jiangchi1'] = '率师而行，所向皆破！',
  ['$ty_ex__jiangchi2'] = '数从征伐，志意慷慨，不避险阻！',
}

ty_ex__jiangchi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target)
    return target == player and player:hasSkill(ty_ex__jiangchi) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player)
    local _, ret = player.room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__jiangchi_active",
      prompt = "#ty_ex__jiangchi-invoke",
      cancelable = true,
    })
    if ret then
      event:setCostData(skill, ret.cards)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(ty_ex__jiangchi.name)
    if player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0 then
      room:notifySkillInvoked(player, ty_ex__jiangchi.name, "offensive")
      room:throwCard(event:getCostData(skill), ty_ex__jiangchi.name, player)
    else
      room:notifySkillInvoked(player, ty_ex__jiangchi.name, "drawcard")
      local num = (player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0) and 2 or 1
      player:drawCards(num, ty_ex__jiangchi.name)
    end
  end,
})

ty_ex__jiangchi:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0
      and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances = function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0
  end,
})

ty_ex__jiangchi:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0 and card.trueName == "slash"
  end,
  prohibit_response = function (skill, player, card)
    return player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0 and card.trueName == "slash"
  end
})

return ty_ex__jiangchi
