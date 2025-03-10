local zijin = fk.CreateSkill {
  name = "zijin"
}

Fk:loadTranslationTable{
  ['zijin'] = '自矜',
  ['#zijin-discard'] = '自矜：你需要弃置一张牌，否则你失去1点体力',
  [':zijin'] = '锁定技，当牌使用结算结束后，若使用者为你且此牌未造成过伤害，你选择：1.弃置一张牌；2.失去1点体力。',
}

zijin:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(zijin.name) and not data.damageDealt
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
