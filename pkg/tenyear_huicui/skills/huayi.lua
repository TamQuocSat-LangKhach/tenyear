local huayi = fk.CreateSkill {
  name = "huayi",
}

Fk:loadTranslationTable{
  ["huayi"] = "华衣",
  [":huayi"] = "结束阶段，你可以判定，然后直到你的下回合开始时根据结果获得以下效果：红色，每个回合结束时摸一张牌；黑色，受到伤害后摸两张牌。",

  ["@huayi"] = "华衣",

  ["$huayi1"] = "皓腕凝霜雪，罗襦绣鹧鸪。",
  ["$huayi2"] = "绝色戴珠玉，佳人配华衣。",
}

huayi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huayi.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = huayi.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if judge.card.color ~= Card.NoColor then
      room:setPlayerMark(player, "@huayi", judge.card:getColorString())
    end
  end,
})

huayi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@huayi", 0)
  end,
})

huayi:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@huayi") == "red"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, huayi.name)
  end,
})

huayi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@huayi") == "black"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, huayi.name)
  end,
})

return huayi
