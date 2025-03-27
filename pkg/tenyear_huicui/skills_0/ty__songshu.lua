local ty__songshu = fk.CreateSkill {
  name = "ty__songshu"
}

Fk:loadTranslationTable{
  ['ty__songshu'] = '颂蜀',
  [':ty__songshu'] = '出牌阶段限一次，你可以与一名其他角色拼点：若你没赢，你和该角色各摸两张牌；若你赢，视为本阶段此技能未发动过。',
  ['$ty__songshu1'] = '称颂蜀汉，以表诚心。',
  ['$ty__songshu2'] = '吴蜀两和，方可安稳。',
}

ty__songshu:addEffect('active', {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(ty__songshu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and player:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, ty__songshu.name)
    if pindian.results[target.id].winner == player then
      player:setSkillUseHistory(ty__songshu.name, 0, Player.HistoryPhase)
    else
      if not player.dead then
        room:askToDrawCards(player, { num = 2, reason = ty__songshu.name })
      end
      if not target.dead then
        room:askToDrawCards(target, { num = 2, reason = ty__songshu.name })
      end
    end
  end,
})

return ty__songshu
