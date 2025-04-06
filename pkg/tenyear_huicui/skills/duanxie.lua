local duanxie = fk.CreateSkill{
  name = "ty__duanxie",
}

Fk:loadTranslationTable{
  ["ty__duanxie"] = "断绁",
  [":ty__duanxie"] = "出牌阶段限一次，你可以令一名其他角色横置，然后你横置。",

  ["#ty__duanxie"] = "断绁：令一名其他角色横置，然后你横置",

  ["$ty__duanxie1"] = "区区绳索，就想挡住吾等去路？！",
  ["$ty__duanxie2"] = "以身索敌，何惧同伤！",
}

duanxie:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__duanxie",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(duanxie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player and not to_select.chained
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:setChainState(true)
    if not player.chained and not player.dead then
      player:setChainState(true)
    end
  end,
})

return duanxie
