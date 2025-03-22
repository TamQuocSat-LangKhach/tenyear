local zengdao = fk.CreateSkill {
  name = "zengdao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zengdao"] = "赠刀",
  [":zengdao"] = "限定技，出牌阶段，你可以将装备区内任意数量的牌置于一名其他角色的武将牌旁，该角色造成伤害时，移去一张“赠刀”牌，然后此伤害+1。",

  ["#zengdao"] = "赠刀：将任意装备置为一名角色的“赠刀”牌，其造成伤害时移去一张“赠刀”牌使伤害+1",
  ["#zengdao-invoke"] = "赠刀：移去一张“赠刀”牌使你造成的伤害+1（点“取消”随机移去一张）",

  ["$zengdao1"] = "有功赏之，有过罚之。",
  ["$zengdao2"] = "治军之道，功过分明。",
}

zengdao:addEffect("active", {
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player:getCardIds("e") > 0 and player:usedSkillTimes(zengdao.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("e"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    effect.tos[1]:addToPile(zengdao.name, effect.cards, true, zengdao.name)
  end,
})

zengdao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile(zengdao.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      skill_name = zengdao.name,
      include_equip = false,
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|zengdao",
      prompt = "#zengdao-invoke",
      expand_pile = zengdao.name,
    })
    if #cards == 0 then
      cards = table.random(player:getPile(zengdao.name), 1)
    end
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zengdao.name, nil, true, player)
    data:changeDamage(1)
  end,
})

return zengdao
