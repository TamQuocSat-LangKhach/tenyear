local zijin = fk.CreateSkill {
  name = "zijin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zijin"] = "自矜",
  [":zijin"] = "锁定技，当你使用牌后，若此牌未造成伤害，你需弃置一张牌或失去1点体力。",

  ["#zijin-discard"] = "自矜：弃置一张牌，否则失去1点体力",
}

zijin:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zijin.name) and not data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zijin.name,
      cancelable = true,
      prompt = "#zijin-discard",
    }) == 0 then
      room:loseHp(player, 1, zijin.name)
    end
  end,
})

return zijin
