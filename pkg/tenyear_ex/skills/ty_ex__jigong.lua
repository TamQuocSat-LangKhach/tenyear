local ty_ex__jigong = fk.CreateSkill {
  name = "ty_ex__jigong"
}

Fk:loadTranslationTable{
  ['ty_ex__jigong'] = '急攻',
  ['#ty_ex__jigong-choice'] = '急攻:请选择你要摸的牌数量',
  ['@jigong_draw-turn'] = '急攻 摸牌数',
  ['@ty_ex__jigong-turn'] = '急攻 伤害数',
  [':ty_ex__jigong'] = '出牌阶段开始时，你可以摸至多三张牌。若如此做，你本回合的手牌上限基数改为X，且弃牌阶段结束时，若X不小于Y，则你回复1点体力。（X为你本回合内造成的伤害值之和，Y为你本回合内因〖急攻〗摸牌而获得的牌的数量总和）',
  ['$ty_ex__jigong1'] = '此时不战，更待何时！',
  ['$ty_ex__jigong2'] = '箭在弦上，不得不发！',
}

-- 主技能
ty_ex__jigong:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty_ex__jigong.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choices = {}
    for i = 1, 3 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = ty_ex__jigong.name,
      prompt = "#ty_ex__jigong-choice"
    })
    player:drawCards(tonumber(choice), ty_ex__jigong.name)
    room:addPlayerMark(player, "@jigong_draw-turn", tonumber(choice))

    -- 刷新事件处理
    can_refresh = function(self, event, target, player)
      return target == player and player:usedSkillTimes(ty_ex__jigong.name, Player.HistoryPhase) > 0
    end,
      on_refresh = function(self, event, target, player, data)
      player.room:addPlayerMark(player, "@ty_ex__jigong-turn", data.damage)
    end,
    end
})

-- 最大手牌数技能
ty_ex__jigong:addEffect('maxcards', {
  fixed_func = function (skill, player)
    if player:usedSkillTimes("ty_ex__jigong", Player.HistoryTurn) > 0 then
      return player:getMark("@ty_ex__jigong-turn")
    end
  end,
})

-- 回复技能
ty_ex__jigong:addEffect(fk.EventPhaseEnd, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    local num = player:getMark("@ty_ex__jigong-turn")
    local num1 = player:getMark("@jigong_draw-turn")
    if target == player and player:usedSkillTimes("ty_ex__jigong", Player.HistoryTurn) > 0 and player.phase == Player.Discard then
      return num >= num1 and player:isWounded()
    end
  end,
  on_use = function(self, event, target, player)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "ty_ex__jigong"
    })
  end
})

return ty_ex__jigong
