local kuizhen = fk.CreateSkill {
  name = "kuizhen"
}

Fk:loadTranslationTable{
  ['kuizhen'] = '溃阵',
  ['#kuizhen-active'] = '发动 溃阵，选择一名角色，令其视为对你使用【决斗】',
  ['@@kuizhen-inhand'] = '溃阵',
  [':kuizhen'] = '出牌阶段限一次，你可以选择一名手牌数或体力值不小于你的角色，其视为对你使用【决斗】，若你：受到过此【决斗】造成的伤害，你观看其所有手牌，获得其中所有的【杀】且你使用以此法获得的【杀】无次数限制；未受到过此【决斗】造成的伤害，其失去1点体力。',
  ['$kuizhen1'] = '今一马当先，效霸王破釜！',
  ['$kuizhen2'] = '自古北马皆傲，视南风为鱼俎。',
}

kuizhen:addEffect("active", {
  anim_type = "offensive",
  prompt = "#kuizhen-active",
  can_use = function(self, player)
    return player:usedSkillTimes(kuizhen.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if target.hp >= player.hp or target:getHandcardNum() >= player:getHandcardNum() then
        local duel = Fk:cloneCard("duel")
        duel.skillName = kuizhen.name
        return target:canUseTo(duel, player)
      end
    end
  end,
  target_num = 1,
  on_use = function(self, room, effect, event)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:cloneCard("duel")
    card.skillName = kuizhen.name
    local use = {} ---@type CardUseStruct
    use.from = target.id
    use.tos = { {player.id} }
    use.card = card
    use.extraUse = true
    room:useCard(use)
    if target.dead then return end
    if use.damageDealt and use.damageDealt[player.id] then
      if player.dead then return end
      local cards = target:getCardIds(Player.Hand)
      if #cards == 0 then return end
      U.viewCards(player, cards, kuizhen.name)
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, kuizhen.name, nil, false, player.id, "@@kuizhen-inhand")
    else
      room:loseHp(target, 1, kuizhen.name)
    end
  end,
})

kuizhen:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and
      data.card.trueName == "slash" and not data.card:isVirtual() and data.card:getMark("@@kuizhen-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

local kuizhen_targetmod = fk.CreateSkill {
  name = "kuizhen_targetmod"
}

kuizhen_targetmod:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and not card:isVirtual() and card:getMark("@@kuizhen-inhand") > 0
  end,
})

return kuizhen, kuizhen_targetmod
