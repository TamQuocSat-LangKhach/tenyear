local kuangfu = fk.CreateSkill {
  name = "ty__kuangfu",
}

Fk:loadTranslationTable{
  ["ty__kuangfu"] = "狂斧",
  [":ty__kuangfu"] = "出牌阶段限一次，你可以弃置场上的一张装备牌，视为使用一张【杀】（无距离次数限制）。"..
  "若弃置的不是你的牌且此【杀】未造成伤害，你弃置两张手牌；若弃置的是你的牌且此【杀】造成伤害，你摸两张牌。",

  ["#ty__kuangfu"] = "狂斧：弃置一名角色一张的装备，视为使用一张无距离次数限制的【杀】",
  ["#ty__kuangfu-slash"] = "狂斧：视为使用一张【杀】",

  ["$ty__kuangfu1"] = "大斧到处，片甲不留！",
  ["$ty__kuangfu2"] = "你可接得住我一斧？",
}

kuangfu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__kuangfu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kuangfu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #to_select:getCardIds("e") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "e",
      skill_name = kuangfu.name,
    })
    room:throwCard(id, kuangfu.name, target, player)
    if player.dead then return end
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = kuangfu.name,
      prompt = "#ty__kuangfu-slash",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
    })
    if not use or player.dead then return end
    if target == player and use.damageDealt then
      room:drawCards(player, 2, kuangfu.name)
    elseif target ~= player and not use.damageDealt then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = kuangfu.name,
        cancelable = false,
      })
    end
  end,
})

return kuangfu
