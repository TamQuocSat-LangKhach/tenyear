local xunbie = fk.CreateSkill {
  name = "xunbie"
}

Fk:loadTranslationTable{
  ['xunbie'] = '殉别',
  ['ty__ganfuren'] = '甘夫人',
  ['ty__mifuren'] = '糜夫人',
  ['@@xunbie-turn'] = '殉别',
  ['#xunbie_trigger'] = '殉别',
  [':xunbie'] = '限定技，当你进入濒死状态时，你可以将武将牌改为甘夫人或糜夫人，然后回复体力至1并防止你受到的伤害直到回合结束。',
  ['$xunbie1'] = '既为君之妇，何惧为君之鬼。',
  ['$xunbie2'] = '今临难将罹，唯求不负皇叔。',
}

xunbie:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(xunbie.name) and player.dying and player:usedSkillTimes(xunbie.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local generals = {}
    if not table.find(room.alive_players, function(p) return p.general == "ty__ganfuren" or p.deputyGeneral == "ty__ganfuren" end) then
      table.insert(generals, "ty__ganfuren")
    end
    if not table.find(room.alive_players, function(p) return p.general == "ty__mifuren" or p.deputyGeneral == "ty__mifuren" end) then
      table.insert(generals, "ty__mifuren")
    end
    if #generals > 0 then
      local general = room:askToChooseGeneral(player, { generals = generals, n = 1, no_convert = true })
      U.changeHero(player, general, false)
      if player.dead then return end
    end
    room:setPlayerMark(player, "@@xunbie-turn", 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = xunbie.name
      })
    end
  end,
})

xunbie:addEffect(fk.DamageInflicted, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("@@xunbie-turn") > 0
  end,
  on_use = function(self, event, target, player)
    player:broadcastSkillInvoke(xunbie.name)
    return true
  end,
})

return xunbie
