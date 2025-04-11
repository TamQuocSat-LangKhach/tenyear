local ty_ex__yanyu = fk.CreateSkill{
  name = "ty_ex__yanyu"
}

Fk:loadTranslationTable{
  ['ty_ex__yanyu'] = '燕语',
  ['#ty_ex__yanyu_record'] = '燕语',
  ['#ty_ex__yanyu-draw'] = '燕语：你可以选择一名男性角色，令其摸%arg张牌',
  [':ty_ex__yanyu'] = '①出牌阶段，你可以重铸【杀】；②出牌阶段结束时，若你于此阶段内发动过【燕语①】，则你可以令一名男性角色摸X张牌（X为你本阶段发动过【燕语①】的次数且至多为3）。',
  ['$ty_ex__yanyu1'] = '边功未成，还请郎君努力。',
  ['$ty_ex__yanyu2'] = '郎君有意倾心诉，妾身心中相思埋。',
}

-- 主技能
ty_ex__yanyu:addEffect('active', {
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, room:getPlayerById(effect.from), ty_ex__yanyu.name)
  end,
})

-- 触发技能
ty_ex__yanyu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == player.Play and 
      player:usedSkillTimes(ty_ex__yanyu.name, Player.HistoryPhase) > 0 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.gender ~= General.Male end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room:getAlivePlayers(), 
        function(p) return p:isMale() end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__yanyu-draw:::"..math.min(3, player:usedSkillTimes(ty_ex__yanyu.name, Player.HistoryPhase)),
      skill_name = ty_ex__yanyu.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, room:getPlayerById(to[1].id))
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local num = math.min(3, player:usedSkillTimes(ty_ex__yanyu.name, Player.HistoryPhase))
    event:getCostData(self):drawCards(num, ty_ex__yanyu.name)
  end,
})

return ty_ex__yanyu
