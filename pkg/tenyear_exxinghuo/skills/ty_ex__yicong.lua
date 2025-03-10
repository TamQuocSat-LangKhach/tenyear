local ty_ex__yicong = fk.CreateSkill {
  name = "ty_ex__yicong"
}

Fk:loadTranslationTable{
  ['ty_ex__yicong'] = '义从',
  [':ty_ex__yicong'] = '锁定技，你计算与其他角色的距离-1；若你已损失的体力值不小于2，其他角色计算与你的距离+1。',
  ['$ty_ex__yicong1'] = '恩义聚骠骑，百战从公孙！',
  ['$ty_ex__yicong2'] = '义从呼啸至，白马抖精神！',
}

ty_ex__yicong:addEffect('distance', {
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    local n = 0
    if from:hasSkill(ty_ex__yicong.name) then
      n = -1
    end
    if to:hasSkill(ty_ex__yicong.name) and to:getLostHp() >= 2 then
      n = n + 1
    end
    return n
  end,
})

ty_ex__yicong:addEffect('refresh', {
  events = {fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(ty_ex__yicong) 
      and player:getLostHp() >= 2 and data.num < 0 and player:getLostHp() + data.num < 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, ty_ex__yicong.name, "defensive")
    player:broadcastSkillInvoke(ty_ex__yicong.name)
  end,
})

return ty_ex__yicong
