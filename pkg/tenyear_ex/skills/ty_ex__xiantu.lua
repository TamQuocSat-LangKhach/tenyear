local ty_ex__xiantu = fk.CreateSkill {
  name = "ty_ex__xiantu"
}

Fk:loadTranslationTable{
  ['ty_ex__xiantu'] = '献图',
  ['#ty_ex__xiantu-invoke'] = '献图：你可以摸两张牌并交给 %dest 两张牌',
  ['#ty_ex__xiantu-give'] = '献图：选择交给 %dest 的两张牌',
  [':ty_ex__xiantu'] = '其他角色出牌阶段开始时，你可以摸两张牌，然后将两张牌交给该角色。若如此做，此阶段结束时，若其于此阶段内没有造成过伤害，你失去1点体力。',
  ['$ty_ex__xiantu1'] = '此图载益州山水，请君纳之。',
  ['$ty_ex__xiantu2'] = '我献梧木一株，为引凤而来。',
}

ty_ex__xiantu:addEffect(fk.EventPhaseStart, {
  mute = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(ty_ex__xiantu.name) and target.phase == Player.Play and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = ty_ex__xiantu.name, prompt = "#ty_ex__xiantu-invoke::" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty_ex__xiantu.name)
    room:notifySkillInvoked(player, ty_ex__xiantu.name)
    player:drawCards(2, ty_ex__xiantu.name)
    if player:isNude() then return end
    local cards
    if #player:getCardIds("he") <= 2 then
      cards = player:getCardIds("he")
    else
      cards = room:askToCards(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        pattern = ".",
        prompt = "#ty_ex__xiantu-give::" .. target.id,
      })
    end
    room:obtainCard(target.id, cards, false, fk.ReasonGive, player.id)
  end,
})

ty_ex__xiantu:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Play and player:usedSkillTimes(ty_ex__xiantu.name, Player.HistoryPhase) > 0 and not player.dead then
      local events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        return damage and target == damage.from
      end, Player.HistoryPhase)
      return #events == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty_ex__xiantu.name)
    room:notifySkillInvoked(player, ty_ex__xiantu.name, "negative")
    room:loseHp(player, 1, ty_ex__xiantu.name)
  end,
})

return ty_ex__xiantu
