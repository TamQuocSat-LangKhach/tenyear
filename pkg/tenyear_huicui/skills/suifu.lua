local suifu = fk.CreateSkill {
  name = "suifu",
}

Fk:loadTranslationTable{
  ["suifu"] = "绥抚",
  [":suifu"] = "其他角色的结束阶段，若本回合你和一号位共计至少受到2点伤害，你可将当前回合角色的所有手牌置于牌堆顶，视为使用一张【五谷丰登】。",

  ["#suifu-invoke"] = "绥抚：你可以将 %dest 所有手牌置于牌堆顶，视为使用【五谷丰登】",

  ["$suifu1"] = "以柔克刚，方是良策。",
  ["$suifu2"] = "镇抚边疆，为国家计。",
}

suifu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(suifu.name) and target ~= player and target.phase == Player.Finish and
      not target:isKongcheng() and not target.dead then
      local count = 0
      return #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        if damage.to == player or damage.to.seat == 1 then
          count = count + damage.damage
        end
        return count > 1
      end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = suifu.name,
      prompt = "#suifu-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.reverse(target:getCardIds("h"))
    room:moveCards({
      ids = cards,
      from = target,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skill_name = suifu.name,
    })
    room:useVirtualCard("amazing_grace", nil, player, table.filter(room.alive_players, function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace"))
    end), suifu.name, false)
  end,
})

return suifu
