local wujie = fk.CreateSkill {
  name = "wujie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["wujie"] = "无节",
  [":wujie"] = "锁定技，你使用的无色牌不计入次数且无距离限制；其他角色杀死你后不执行奖惩。",

  ["$wujie1"] = "腹中有粮则脊自直，非节盈之。",
  ["$wujie2"] = "气节？可当粟米果腹乎！",
}

wujie:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wujie.name) and data.card.color == Card.NoColor
  end,
  on_use = function(self, event, target, player, data)
    if not data.extraUse then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
})

wujie:addEffect(fk.BuryVictim, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wujie.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.skip_reward_punish = true
  end,
})

wujie:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(wujie.name) and card and card.color == Card.NoColor
  end,
})

return wujie
