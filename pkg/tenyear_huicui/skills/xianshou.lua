local xianshou = fk.CreateSkill {
  name = "xianshou",
}

Fk:loadTranslationTable{
  ["xianshou"] = "仙授",
  [":xianshou"] = "出牌阶段限一次，你可以令一名角色摸一张牌。若其未受伤，则多摸一张牌。",

  ["#xianshou"] = "仙授：令一名角色摸一张牌，若其未受伤则多摸一张牌",
}

xianshou:addEffect("active", {
  anim_type = "support",
  prompt = "#xianshou",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xianshou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    target:drawCards(not target:isWounded() and 2 or 1, xianshou.name)
  end
})

return xianshou
