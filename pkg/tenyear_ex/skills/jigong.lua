local jigong = fk.CreateSkill {
  name = "ty_ex__jigong",
}

Fk:loadTranslationTable{
  ["ty_ex__jigong"] = "急攻",
  [":ty_ex__jigong"] = "出牌阶段开始时，你可以摸至多三张牌，若如此做，你本回合的手牌上限改为你此阶段造成的伤害值；弃牌阶段结束时，"..
  "若伤害值不小于因此摸的牌数，你回复1点体力。",

  ["#ty_ex__jigong-choice"] = "急攻：摸至多三张牌，本回合手牌上限改为造成伤害值",
  ["@ty_ex__jigong-turn"] = "急攻",

  ["$ty_ex__jigong1"] = "此时不战，更待何时！",
  ["$ty_ex__jigong2"] = "箭在弦上，不得不发！",
}


jigong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jigong.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"1", "2", "3", "Cancel"},
      skill_name = jigong.name,
      prompt = "#ty_ex__jigong-choice",
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    room:addPlayerMark(player, "ty_ex__jigong_draw-turn", n)
    room:setPlayerMark(player, "@ty_ex__jigong-turn",
      string.format("%d/%d", player:getMark("ty_ex__jigong_draw-turn"), player:getMark("ty_ex__jigong_damage-turn")))
    player:drawCards(n, jigong.name)
  end,
})

jigong:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and
      player:usedSkillTimes(jigong.name, Player.HistoryTurn) > 0 and
      player:getMark("ty_ex__jigong_damage-turn") >= player:getMark("ty_ex__jigong_draw-turn") and
      player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = jigong.name,
    }
  end,
})

jigong:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(jigong.name, Player.HistoryPhase) > 0 and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "ty_ex__jigong_damage-turn", data.damage)
    room:setPlayerMark(player, "@ty_ex__jigong-turn",
      string.format("%d/%d", player:getMark("ty_ex__jigong_draw-turn"), player:getMark("ty_ex__jigong_damage-turn")))
  end,
})

jigong:addEffect("maxcards", {
  fixed_func = function (skill, player)
    if player:usedSkillTimes(jigong.name, Player.HistoryTurn) > 0 then
      return player:getMark("ty_ex__jigong_damage-turn")
    end
  end,
})

return jigong
