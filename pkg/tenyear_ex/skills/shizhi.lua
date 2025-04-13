local shizhi = fk.CreateSkill {
  name = "ty_ex__shizhi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__shizhi"] = "矢志",
  [":ty_ex__shizhi"] = "锁定技，若你的体力值为1，你的【闪】视为【杀】；当你使用这些【杀】造成伤害后，你回复1点体力。",

  ["$ty_ex__shizhi1"] = "护汉成勋业，矢志报国恩。",
  ["$ty_ex__shizhi2"] = "怀精忠之志，坦赤诚之心。",
}

shizhi:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(shizhi.name) and player.hp == 1 and card.name == "jink" and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard("slash", to_select.suit, to_select.number)
    card.skillName = shizhi.name
    return card
  end,
})

shizhi:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player == target and player:hasSkill(shizhi.name) and
      data.card and table.contains(data.card.skillNames, shizhi.name) and player:isWounded()
  end,
  on_use = function (self, event, target, player, data)
    player.room:recover {
      who = player,
      num = 1,
      recoverBy = player,
      skillName = shizhi.name,
    }
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(shizhi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player:filterHandcards()
  end,
}
shizhi:addEffect(fk.HpChanged, spec)
shizhi:addEffect(fk.MaxHpChanged, spec)
shizhi:addAcquireEffect(function (self, player, is_start)
  player:filterHandcards()
end)
shizhi:addLoseEffect(function (self, player, is_death)
  player:filterHandcards()
end)

return shizhi
