local xushen = fk.CreateSkill {
  name = "ty__xushen",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty__xushen"] = "许身",
  [":ty__xushen"] = "限定技，当你进入濒死状态后，你可以回复1点体力并获得技能〖镇南〗，然后如果你脱离濒死状态且关索不在场，你可以令一名"..
  "其他角色选择是否用关索代替其武将并令其摸三张牌",

  ["#ty__xushen-choose"] = "许身：你可以令一名角色选择是否变身为十周年关索并摸三张牌！",
  ["#ty__xushen-invoke"] = "许身：你可以变身为十周年关索并摸三张牌！",

  ["$ty__xushen1"] = "倾郎心，许君身。",
  ["$ty__xushen2"] = "世间只与郎君好。",
}

xushen:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xushen.name) and
      player.dying and player:usedSkillTimes(xushen.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = xushen.name,
    }
    if player.dead then return end
    room:handleAddLoseSkills(player, "ty__zhennan", nil, true, false)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__xushen_data = player
  end,
})

xushen:addEffect(fk.AfterDying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty__xushen_data == player and
      #player.room:getOtherPlayers(player, false) > 0 and
      not table.find(player.room.alive_players, function(p)
        return string.find(p.general, "guansuo") ~= nil or string.find(p.deputyGeneral, "guansuo") ~= nil
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__xushen-choose",
      skill_name = xushen.name,
    })
    if #to > 0 then
      to = to[1]
      if room:askToSkillInvoke(to, {
        skill_name = xushen.name,
        prompt = "#ty__xushen-invoke",
      }) then
        room:changeHero(to, "ty__guansuo", false, false, true, true, true)
        if not to.dead then
          to:drawCards(3, xushen.name)
        end
      end
    end
  end,
})

return xushen
