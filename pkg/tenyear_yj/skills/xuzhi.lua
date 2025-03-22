local xuzhi = fk.CreateSkill {
  name = "xuzhi",
}

Fk:loadTranslationTable{
  ["xuzhi"] = "蓄志",
  [":xuzhi"] = "出牌阶段限一次，你可以令两名角色同时选择至少一张手牌并交换这些牌，获得牌数较少的角色视为使用一张无距离限制的【杀】；"..
  "若获得牌数相等，你摸两张牌，且可以对本阶段未以此法选择过的角色再发动〖蓄志〗。",

  ["#xuzhi"] = "蓄志：选择两名角色，令他们同时选择至少一张手牌并交换",
  ["#xuzhi-ask"] = "蓄志：选择至少一张手牌进行交换",
  ["#xuzhi-slash"] = "蓄志：你可以视为使用一张无距离限制的【杀】",

  ["$xuzhi1"] = "鹿复现于野，孰不可射乎？",
  ["$xuzhi2"] = "天下之士合纵，欲复攻于秦。",
}

xuzhi:addEffect("active", {
  anim_type = "support",
  prompt = "#xuzhi",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(xuzhi.name, Player.HistoryPhase) < 1 + player:getMark("xuzhi_times-phase")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2 and not to_select:isKongcheng() and not table.contains(player:getTableMark("xuzhi-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    room:addTableMark(player, "xuzhi-phase", effect.tos[1].id)
    room:addTableMark(player, "xuzhi-phase", effect.tos[2].id)
    local result = room:askToJointCards(player, {
      players = effect.tos,
      min_num = 1,
      max_num = 999,
      cancelable = false,
      skill_name = xuzhi.name,
      prompt = "#xuzhi-ask",
    })
    room:swapCards(player, {
      {effect.tos[1], result[effect.tos[1]]},
      {effect.tos[2], result[effect.tos[2]]},
    }, xuzhi.name)
    local n1, n2 = #result[effect.tos[1]], #result[effect.tos[2]]
    if n1 == n2 then
      if player.dead then return end
      room:addPlayerMark(player, "xuzhi_times-phase")
      player:drawCards(2, xuzhi.name)
    else
      local to = n2 > n1 and effect.tos[2] or effect.tos[1]
      if to.dead then return end
      room:askToUseVirtualCard(to, {
        name = "slash",
        skill_name = xuzhi.name,
        prompt = "#xuzhi-slash",
        cancelable = true,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
        },
      })
    end
  end,
})

return xuzhi
