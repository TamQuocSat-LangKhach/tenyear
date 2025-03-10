local ty_ex__pindi = fk.CreateSkill {
  name = "ty_ex__pindi"
}

Fk:loadTranslationTable{
  ['ty_ex__pindi'] = '品第',
  ['#ty_ex__pindi'] = '品第：弃置一张未弃置过类别的牌，令一名角色摸牌或弃牌（%arg张）',
  ['ty_ex__pindi_draw'] = '摸牌',
  ['ty_ex__pindi_discard'] = '弃牌',
  [':ty_ex__pindi'] = '出牌阶段每名角色限一次，你可以弃置一张本阶段未以此法弃置类型的牌并选择一名角色，令其摸X张牌或弃置X张牌（X为本回合此技能发动次数）。若其已受伤，横置或重置你的武将牌。',
  ['$ty_ex__pindi1'] = '以九品论才，正是栋梁之谋。',
  ['$ty_ex__pindi2'] = '置州郡中正，可为百年之政。',
}

ty_ex__pindi:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = function(self, player)
    return "#ty_ex__pindi:::"..(player:usedSkillTimes(ty_ex__pindi.name, Player.HistoryTurn) + 1)
  end,
  interaction = function(skill)
    return UI.ComboBox { choices = {"ty_ex__pindi_draw", "ty_ex__pindi_discard"} }
  end,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select)) then
      local mark = player:getTableMark("ty_ex__pindi-phase")
      return not table.contains(mark, Fk:getCardById(to_select):getTypeString())
    end
  end,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 and target:getMark("ty_ex__pindi_target-phase") == 0 then
      return skill.interaction.data == "ty_ex__pindi_draw" or not target:isNude()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "ty_ex__pindi-phase", Fk:getCardById(effect.cards[1]):getTypeString())
    room:setPlayerMark(target, "ty_ex__pindi_target-phase", 1)
    room:throwCard(effect.cards, ty_ex__pindi.name, player)
    if not target.dead then
      local n = player:usedSkillTimes(ty_ex__pindi.name, Player.HistoryTurn)
      if skill.interaction.data == "ty_ex__pindi_draw" then
        target:drawCards(n, ty_ex__pindi.name)
      else
        room:askToDiscard(target, {
          min_num = n,
          max_num = n,
          include_equip = true,
          cancelable = false,
        })
      end
    end
    if target:isWounded() and not player.dead then
      player:setChainState(not player.chained)
    end
  end,
})

return ty_ex__pindi
