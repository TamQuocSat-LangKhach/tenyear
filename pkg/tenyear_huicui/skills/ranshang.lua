local ranshang = fk.CreateSkill {
  name = "ty__ranshang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__ranshang"] = "燃殇",
  [":ty__ranshang"] = "锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；结束阶段，你失去X点体力（X为“燃”标记数），然后若“燃”标记的数量"..
  "超过2个，则你减2点体力上限并摸两张牌。",

  ["$ty__ranshang1"] = "你会后悔的！啊！！",
  ["$ty__ranshang2"] = "这是要赶尽杀绝吗？",
}

ranshang:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@wutugu_ran", 0)
end)

ranshang:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ranshang.name) and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@wutugu_ran", data.damage)
  end,
})

ranshang:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ranshang.name) and player.phase == Player.Finish and
      player:getMark("@wutugu_ran") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, player:getMark("@wutugu_ran"), ranshang.name)
    if not player.dead and player:getMark("@wutugu_ran") > 2 then
      room:changeMaxHp(player, -2)
      if not player.dead then
        player:drawCards(2, ranshang.name)
      end
    end
  end,
})

return ranshang
