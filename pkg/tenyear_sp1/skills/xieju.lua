local xieju = fk.CreateSkill {
  name = "ty__xieju"
}

Fk:loadTranslationTable{
  ['ty__xieju'] = '偕举',
  ['#ty__xieju'] = '偕举：令任意名本回合成为过牌的目标的角色视为使用【杀】（有距离限制）',
  [':ty__xieju'] = '出牌阶段限一次，你可以选择任意名本回合成为过牌的目标的角色，这些角色依次可以视为使用一张【杀】（有距离限制）。',
  ['$ty__xieju1'] = '你我本为袍泽，戎行何分先后。',
  ['$ty__xieju2'] = '义不吝众，举义旗者皆老夫兄弟。',
}

xieju:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#ty__xieju",
  can_use = function(self, player)
    return player:usedSkillTimes(xieju.name, Player.HistoryPhase) == 0 and player:getMark("ty__xieju-turn") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return table.contains(player:getTableMark("ty__xieju-turn"), to_select)
  end,
  on_use = function(self, room, effect)
    room:sortPlayersByAction(effect.tos)
    for _, id in ipairs(effect.tos) do
      local target = room:getPlayerById(id)
      if not target.dead then
        U.askToUseVirtualCard(room, target, {
          pattern = "slash",
          skill_name = xieju.name,
          cancelable = true,
          bypass_times = false,
          bypass_distances = false,
          skip_use = true,
        })
      end
    end
  end,
})

xieju:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xieju, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getTableMark("ty__xieju-turn")
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      table.insertIfNeed(mark, id)
    end
    player.room:setPlayerMark(player, "ty__xieju-turn", mark)
  end,
})

return xieju
