local ganlu = fk.CreateSkill {
  name = "ty_ex__ganlu",
}

Fk:loadTranslationTable{
  ["ty_ex__ganlu"] = "甘露",
  [":ty_ex__ganlu"] = "出牌阶段限一次，你可以选择两名角色，交换其装备区内的所有牌，然后若其装备区牌数之差大于你已损失体力值，你弃置两张手牌。",

  ["#ty_ex__ganlu"] = "甘露：交换两名角色的装备，然后若装备数之差大于你已损失体力值需弃置两张手牌",

  ["$ty_ex__ganlu1"] = "纳采问名，而后交换文定。",
  ["$ty_ex__ganlu2"] = "兵戈相向，何如化戈为帛？",
}

ganlu:addEffect("active", {
  anim_type = "control",
  prompt = "#ty_ex__ganlu",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(ganlu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return not #to_select:getCardIds("e") == 0 and #selected[1]:getCardIds("e") == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:swapAllCards(effect.from, effect.tos, ganlu.name, "e")
    if not player.dead and math.abs(#effect.tos[1]:getCardIds("e") - #effect.tos[2]:getCardIds("e")) > player:getLostHp() then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = ganlu.name,
        cancelable = false,
      })
    end
  end,
})

return ganlu
