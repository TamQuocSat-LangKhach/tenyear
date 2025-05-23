local zhuilie = fk.CreateSkill {
  name = "zhuilie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhuilie"] = "追猎",
  [":zhuilie"] = "锁定技，你使用【杀】无距离限制；当你使用【杀】指定你攻击范围外的角色为目标后，此【杀】不计入次数且你进行一次判定，"..
  "若结果为武器牌或坐骑牌，此【杀】伤害基数值增加至该角色的体力值，否则你失去1点体力。",

  ["$zhuilie1"] = "哈哈！我喜欢，猎夺沙场的快感！",
  ["$zhuilie2"] = "追敌夺魂，猎尽贼寇。",
}

zhuilie:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuilie.name) and
      data.card.trueName == "slash" and not player:inMyAttackRange(data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not data.extraData then
      player:addCardUseHistory(data.card.trueName, -1)
      data.extraData = true
    end
    local judge = {
      who = player,
      reason = zhuilie.name,
      pattern = ".|.|.|.|.|weapon,offensive_ride,defensive_ride",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.additionalDamage = (data.additionalDamage or 0) + data.to.hp - 1
    elseif not player.dead then
      room:loseHp(player, 1, zhuilie.name)
    end
  end,
})

zhuilie:addEffect("targetmod", {
  bypass_distances = function(self, player, skill)
    return player:hasSkill(zhuilie.name) and skill.trueName == "slash_skill"
  end,
})

return zhuilie
