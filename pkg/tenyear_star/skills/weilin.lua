local weilin = fk.CreateSkill {
  name = "weilin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["weilin"] = "威临",
  [":weilin"] = "锁定技，你于回合内对一名角色造成伤害时，若其本回合没有受到过伤害且你本回合已使用牌数不小于其体力值，则此伤害+1。",

  ["$weilin1"] = "今吾入京城，欲寻人而食。",
  ["$weilin2"] = "天下事在我，我今为之，谁敢不从？",
}

weilin:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(weilin.name) and player.room.current == player then
      local room = player.room
      if #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == data.to
      end) == 0 then
        local n = 0
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          if e.data.from == player then
            n = n + 1
          end
          if n >= data.to.hp then
            return true
          end
        end, Player.HistoryTurn)
        return n >= data.to.hp
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return weilin
