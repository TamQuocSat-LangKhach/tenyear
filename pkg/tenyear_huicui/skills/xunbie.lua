local xunbie = fk.CreateSkill {
  name = "xunbie",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xunbie"] = "殉别",
  [":xunbie"] = "限定技，当你进入濒死状态时，你可以将武将牌改为甘夫人或糜夫人，然后回复体力至1并防止你受到的伤害直到回合结束。",

  ["@@xunbie-turn"] = "殉别",

  ["$xunbie1"] = "既为君之妇，何惧为君之鬼。",
  ["$xunbie2"] = "今临难将罹，唯求不负皇叔。",
}

xunbie:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunbie.name) and player.dying and
      player:usedSkillTimes(xunbie.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local generals = {}
    for _, general in ipairs({"ty__ganfuren", "ty__mifuren"}) do
      if not table.find(room.alive_players, function(p)
        return p.general == general or p.deputyGeneral == general
      end) then
        table.insert(generals, general)
      end
    end
    if #generals > 0 then
      local general = room:askToChooseGeneral(player, {
        generals = generals,
        n = 1,
        no_convert = true,
      })
      local isDeputy = false
      if player.deputyGeneral ~= "" and table.contains(Fk.generals[player.deputyGeneral]:getSkillNameList(), xunbie.name) then
        isDeputy = true
      end
      if table.contains(Fk.generals[player.general]:getSkillNameList(), xunbie.name) then
        isDeputy = false
      end
      room:changeHero(player, general, false, isDeputy, true)
      if player.dead then return end
    end
    room:setPlayerMark(player, "@@xunbie-turn", 1)
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = xunbie.name,
      }
    end
  end,
})

xunbie:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@xunbie-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

return xunbie
