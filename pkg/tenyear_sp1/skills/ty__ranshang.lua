local ty__ranshang = fk.CreateSkill {
  name = "ty__ranshang"
}

Fk:loadTranslationTable{
  ['ty__ranshang'] = '燃殇',
  [':ty__ranshang'] = '锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；结束阶段，你失去X点体力（X为“燃”标记数），然后若“燃”标记的数量超过2个，则你减2点体力上限并摸两张牌。',
  ['$ty__ranshang1'] = '你会后悔的！啊！！',
  ['$ty__ranshang2'] = '这是要赶尽杀绝吗？',
}

ty__ranshang:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__ranshang.name) then
      return data.damageType == fk.FireDamage
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@wutugu_ran", data.damage)
  end,
})

ty__ranshang:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__ranshang.name) then
      return player.phase == Player.Finish and player:getMark("@wutugu_ran") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, player:getMark("@wutugu_ran"), ty__ranshang.name)
    if not player.dead and player:getMark("@wutugu_ran") > 2 then
      room:changeMaxHp(player, -2)
      if not player.dead then
        player:drawCards(2, ty__ranshang.name)
      end
    end
  end,
})

return ty__ranshang
