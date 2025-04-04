local huangkong = fk.CreateSkill {
  name = "huangkong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huangkong"] = "惶恐",
  [":huangkong"] = "锁定技，你的回合外，当你成为【杀】或普通锦囊牌的目标后，若你没有手牌，你摸两张牌。",

  ["$huangkong1"] = "满腹忠心，如履薄冰！",
  ["$huangkong2"] = "咱家乃皇帝之母，能有什么坏心思？",
}

huangkong:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huangkong.name) and
      player:isKongcheng() and player.room.current ~= player and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, huangkong.name)
  end,
})

return huangkong
