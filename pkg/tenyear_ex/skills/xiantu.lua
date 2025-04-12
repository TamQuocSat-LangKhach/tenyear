local xiantu = fk.CreateSkill {
  name = "ty_ex__xiantu",
}

Fk:loadTranslationTable{
  ["ty_ex__xiantu"] = "献图",
  [":ty_ex__xiantu"] = "其他角色出牌阶段开始时，你可以摸两张牌，然后将两张牌交给该角色。若如此做，此阶段结束时，若其于此阶段内"..
  "没有造成过伤害，你失去1点体力。",

  ["#ty_ex__xiantu-invoke"] = "献图：你可以摸两张牌并交给 %dest 两张牌",
  ["#ty_ex__xiantu-give"] = "献图：交给 %dest 的两张牌",

  ["$ty_ex__xiantu1"] = "此图载益州山水，请君纳之。",
  ["$ty_ex__xiantu2"] = "我献梧木一株，为引凤而来。",
}

xiantu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiantu.name) and target.phase == Player.Play and
      not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xiantu.name,
      prompt = "#ty_ex__xiantu-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, xiantu.name)
    if player:isNude() then return end
    local cards = room:askToCards(player, {
      skill_name = xiantu.name,
      include_equip = true,
      min_num = 2,
      max_num = 2,
      prompt = "#ty_ex__xiantu-give::"..target.id,
      cancelable = false,
    })
    room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, xiantu.name, nil, false, player)
  end,
})

xiantu:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.phase == Player.Play and
      player:usedSkillTimes(xiantu.name, Player.HistoryPhase) > 0 and
      not player.dead and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target
      end, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, xiantu.name)
  end,
})

return xiantu
