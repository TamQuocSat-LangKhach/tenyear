local ty_ex__jiefan = fk.CreateSkill {
  name = "ty_ex__jiefan"
}

Fk:loadTranslationTable{
  ['ty_ex__jief__fan'] = '解烦',
  ['#ty_ex__jiefan-discard'] = '解烦：弃置一张武器牌，否则 %dest 摸一张牌',
  [':ty_ex__jiefan'] = '限定技，出牌阶段，你可以选择一名角色，然后令攻击范围内有该角色的所有角色各选择一项：1.弃置一张武器牌；2.令其摸一张牌。若此时为第一轮，此回合结束时本技能视为未发动过。',
  ['$ty_ex__jiefan1'] = '烦忧千万，且看我一刀解之。',
  ['$ty_ex__jiefan2'] = '莫道雄兵属北地，解烦威名天下扬。',
}

ty_ex__jiefan:addEffect('active', {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__jiefan.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect, player)
    local target = room:getPlayerById(effect.tos[1])
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target.dead then break end
      if p:inMyAttackRange(target) then
        local discards = room:askToDiscard(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = ty_ex__jiefan.name,
          cancelable = true,
          pattern = ".|.|.|.|.|weapon",
          prompt = "#ty_ex__jiefan-discard::" .. target.id
        })
        if #discards == 0 then
          target:drawCards(1, ty_ex__jiefan.name)
        end
      end
    end
  end,
})

ty_ex__jiefan:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(ty_ex__jiefan.name, Player.HistoryTurn) > 0 and player.room:getBanner("RoundCount") == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:setSkillUseHistory(ty_ex__jiefan.name, 0, Player.HistoryGame)
  end,
})

return ty_ex__jiefan
