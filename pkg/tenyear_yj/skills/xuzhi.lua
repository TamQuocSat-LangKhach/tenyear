local xuzhi = fk.CreateSkill {
  name = "xuzhi"
}

Fk:loadTranslationTable{
  ['xuzhi'] = '蓄志',
  ['#xuzhi-active'] = '蓄志：选择两名角色，令他们同时选择至少一张手牌并交换',
  ['#xuzhi-card'] = '蓄志：选择至少一张手牌进行交换',
  ['#xuzhi-use'] = '蓄志：你可以视为使用一张无距离限制的【杀】',
  [':xuzhi'] = '出牌阶段限一次，你可以令两名角色同时选择至少一张手牌并交换这些牌，获得牌数较少的角色视为使用一张无距离限制的【杀】；若获得牌数相等，你摸两张牌，且可以对本阶段未以此法选择过的角色再发动〖蓄志〗。',
  ['$xuzhi1'] = '鹿复现于野，孰不可射乎？',
  ['$xuzhi2'] = '天下之士合纵，欲复攻于秦。',
}

xuzhi:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 2,
  prompt = "#xuzhi-active",
  can_use = function(self, player)
    return player:usedSkillTimes(xuzhi.name, Player.HistoryPhase) < 1 + player:getMark("xuzhi_times-phase")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng() and
      Fk:currentRoom():getPlayerById(to_select):getMark("xuzhi-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    room:setPlayerMark(targets[1], "xuzhi-phase", 1)
    room:setPlayerMark(targets[2], "xuzhi-phase", 1)
    local result = room:askToCards({
      player = targets,
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = xuzhi.name,
      cancelable = false,
      prompt = "#xuzhi-card",
    })
    U.swapCards(room, player, targets[1], targets[2], result[effect.tos[1]], result[effect.tos[2]], xuzhi.name)
    local n1, n2 = #result[effect.tos[1]], #result[effect.tos[2]]
    if n1 == n2 then
      if player.dead then return end
      room:addPlayerMark(player, "xuzhi_times-phase")
      player:drawCards(2, xuzhi.name)
    else
      local to = n2 > n1 and targets[2] or targets[1]
      if to.dead then return end
      U.askForUseVirtualCard(room, to, "slash", {}, xuzhi.name, "#xuzhi-use", true, true, true, true)
    end
  end,
})

return xuzhi
