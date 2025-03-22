local yicong = fk.CreateSkill {
  name = "ty_ex__yicong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__yicong"] = "义从",
  [":ty_ex__yicong"] = "锁定技，你计算与其他角色的距离-1；若你已损失的体力值不小于2，其他角色计算与你的距离+1。",

  ["$ty_ex__yicong1"] = "恩义聚骠骑，百战从公孙！",
  ["$ty_ex__yicong2"] = "义从呼啸至，白马抖精神！",
}

yicong:addEffect("distance", {
  correct_func = function(self, from, to)
    local n = 0
    if from:hasSkill(yicong.name) then
      n = -1
    end
    if to:hasSkill(yicong.name) and to:getLostHp() >= 2 then
      n = n + 1
    end
    return n
  end,
})

yicong:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(yicong.name) and
      player:getLostHp() >= 2 and data.num < 0 and player:getLostHp() + data.num < 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, yicong.name, "defensive")
    player:broadcastSkillInvoke(yicong.name)
  end,
})

return yicong
