local zhanwan = fk.CreateSkill {
  name = "zhanwan"
}

Fk:loadTranslationTable{
  ['zhanwan'] = '斩腕',
  ['@liushi'] = '流矢',
  [':zhanwan'] = '锁定技，受到〖流矢〗效果影响的角色弃牌阶段结束时，若其于此阶段内弃置过牌，你摸等量的牌，然后移除其〖流矢〗的效果。',
  ['$zhanwan1'] = '郝萌，尔敢造反不成？',
  ['$zhanwan2'] = '健儿护主，奸逆断腕！',
}

zhanwan:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if player:hasSkill(zhanwan.name) and target.phase == Player.Discard and target:getMark("@liushi") > 0 then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == target.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
        return false
      end, Player.HistoryPhase)
      if n > 0 then
        event:setCostData(skill, n)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local n = event:getCostData(skill)
    player:drawCards(n, zhanwan.name)
    player.room:setPlayerMark(target, "@liushi", 0)
  end,
})

return zhanwan
