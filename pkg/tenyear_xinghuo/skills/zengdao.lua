local zengdao = fk.CreateSkill {
  name = "zengdao"
}

Fk:loadTranslationTable{
  ['zengdao'] = '赠刀',
  ['#zengdao-invoke'] = '赠刀：移去一张“赠刀”牌使你造成的伤害+1（点“取消”则随机移去一张）',
  [':zengdao'] = '限定技，出牌阶段，你可以将装备区内任意数量的牌置于一名其他角色的武将牌旁，该角色造成伤害时，移去一张“赠刀”牌，然后此伤害+1。',
  ['$zengdao1'] = '有功赏之，有过罚之。',
  ['$zengdao2'] = '治军之道，功过分明。',
}

-- ActiveSkill部分
zengdao:addEffect('active', {
  anim_type = "support",
  frequency = Skill.Limited,
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player:getCardIds("e") > 0 and player:usedSkillTimes(zengdao.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Equip
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local cards = effect.cards
    target:addToPile(zengdao.name, cards, true, zengdao.name)
  end,
})

-- TriggerSkill部分
zengdao:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("zengdao") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      pattern = ".|.|.|zengdao|.|.|.",
      prompt = "#zengdao-invoke",
      skill_name = zengdao.name
    })

    if #cards == 0 then 
      cards = {player:getPile("zengdao")[math.random(1, #player:getPile("zengdao"))]} 
    end

    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zengdao.name, nil, true, player.id)

    data.damage = data.damage + 1
  end,
})

return zengdao
