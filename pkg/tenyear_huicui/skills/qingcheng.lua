local qingcheng = fk.CreateSkill {
  name = "ty__qingcheng",
}

Fk:loadTranslationTable{
  ["ty__qingcheng"] = "倾城",
  [":ty__qingcheng"] = "出牌阶段限一次，你可以与一名手牌数不大于你的男性角色交换手牌。",

  ["#ty__qingcheng"] = "倾城：与一名手牌数不大于你的男性角色交换手牌",

  ["$ty__qingcheng1"] = "我和你们真是投缘呐。",
  ["$ty__qingcheng2"] = "哼，眼睛都都直了呀。",
}

qingcheng:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__qingcheng",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(qingcheng.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:isMale() and player:getHandcardNum() >= to_select:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:swapAllCards(player, {player, target}, qingcheng.name)
  end,
})

return qingcheng
