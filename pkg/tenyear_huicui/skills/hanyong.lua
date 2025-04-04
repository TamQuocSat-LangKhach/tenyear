local hanyong = fk.CreateSkill {
  name = "ty__hanyong",
}

Fk:loadTranslationTable{
  ["ty__hanyong"] = "悍勇",
  [":ty__hanyong"] = "当你使用【南蛮入侵】、【万箭齐发】或♠普通【杀】时，若你已受伤，你可以令此牌造成的伤害+1，然后若你的体力值大于"..
  "游戏轮数，你获得一个“燃”标记。",

  ["#ty__hanyong-invoke"] = "悍勇：你可以令此%arg伤害+1",

  ["$ty__hanyong1"] = "找死！",
  ["$ty__hanyong2"] = "这就让你们见识见识，哈哈哈哈哈哈哈。",
}

hanyong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hanyong.name) and
      player:isWounded() and
      (table.contains({"savage_assault", "archery_attack"}, data.card.trueName) or
      (data.card.name == "slash" and data.card.suit == Card.Spade))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = hanyong.name,
      prompt = "#ty__hanyong-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.additionalDamage = (data.additionalDamage or 0) + 1
    if player.hp > room:getBanner("RoundCount") and player:hasSkill("ty__ranshang") then
      room:addPlayerMark(player, "@wutugu_ran", 1)
    end
  end,
})

return hanyong
