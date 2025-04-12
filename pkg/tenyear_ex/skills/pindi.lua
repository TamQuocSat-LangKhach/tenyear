local pindi = fk.CreateSkill {
  name = "ty_ex__pindi",
}

Fk:loadTranslationTable{
  ["ty_ex__pindi"] = "品第",
  [":ty_ex__pindi"] = "出牌阶段每名角色限一次，你可以弃置一张本阶段未以此法弃置类型的牌并选择一名角色，令其摸X张牌或弃置X张牌"..
  "（X为本回合此技能发动次数）。若其已受伤，横置或重置你的武将牌。",

  ["#ty_ex__pindi"] = "品第：弃置一张未弃置过类别的牌，令一名角色摸牌或弃牌（%arg张）",

  ["$ty_ex__pindi1"] = "以九品论才，正是栋梁之谋。",
  ["$ty_ex__pindi2"] = "置州郡中正，可为百年之政。",
}

pindi:addEffect("active", {
  anim_type = "control",
  prompt = function(self, player)
    return "#ty_ex__pindi:::"..(player:usedSkillTimes(pindi.name, Player.HistoryTurn) + 1)
  end,
  card_num = 1,
  target_num = 1,
  interaction = UI.ComboBox { choices = {"draw_card", "discard_skill"} },
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select) and
      not table.contains(player:getTableMark("ty_ex__pindi-phase"), Fk:getCardById(to_select):getTypeString())
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and not table.contains(player:getTableMark("ty_ex__pindi_target-phase"), to_select.id) then
      return self.interaction.data == "ty_ex__pindi_draw" or not to_select:isNude()
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "ty_ex__pindi-phase", Fk:getCardById(effect.cards[1]):getTypeString())
    room:addTableMark(player, "ty_ex__pindi_target-phase", target.id)
    room:throwCard(effect.cards, pindi.name, player)
    if not target.dead then
      local n = player:usedSkillTimes(pindi.name, Player.HistoryTurn)
      if self.interaction.data == "draw_card" then
        target:drawCards(n, pindi.name)
      else
        room:askToDiscard(target, {
          skill_name = pindi.name,
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

return pindi
