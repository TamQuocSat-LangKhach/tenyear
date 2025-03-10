local ty__xushen = fk.CreateSkill {
  name = "ty__xushen"
}

Fk:loadTranslationTable{
  ['ty__xushen'] = '许身',
  ['ty__zhennan'] = '镇南',
  ['#ty__xushen_delay'] = '许身',
  ['#ty__xushen-choose'] = '许身：你可以令一名其他角色选择是否变身为十周年关索并摸三张牌！',
  ['#ty__xushen-invoke'] = '许身：你可以变身为十周年关索并摸三张牌！',
  ['ty__guansuo'] = '关索',
  [':ty__xushen'] = '限定技，当你进入濒死状态后，你可以回复1点体力并获得技能〖镇南〗，然后如果你脱离濒死状态且关索不在场，你可令一名其他角色选择是否用关索代替其武将并令其摸三张牌',
  ['$ty__xushen1'] = '倾郎心，许君身。',
  ['$ty__xushen2'] = '世间只与郎君好。',
}

ty__xushen:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__xushen.name) and player.dying and player:usedSkillTimes(ty__xushen.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = ty__xushen.name
    })
    room:handleAddLoseSkills(player, "ty__zhennan", nil, true, false)
    if not player.dead then
      local data = { extra_data = {} }
      data.extra_data.ty__xushen_data = player.id
    end
  end,
})

ty__xushen:addEffect(fk.AfterDying, {
  name = "#ty__xushen_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty__xushen_data == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then 
      return 
    end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__xushen-choose",
      skill_name = ty__xushen.name
    })
    if #to > 0 then
      to = room:getPlayerById(to[1])
      if room:askToSkillInvoke(to, {
        skill_name = ty__xushen.name,
        prompt = "#ty__xushen-invoke"
      }) then
        U.changeHero(to, "ty__guansuo")
        if not to.dead then
          to:drawCards(3, ty__xushen.name)
        end
      end
    end
  end,
})

return ty__xushen
