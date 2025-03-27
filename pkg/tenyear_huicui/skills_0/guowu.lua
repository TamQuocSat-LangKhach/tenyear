local guowu = fk.CreateSkill { name = "guowu" }

Fk:loadTranslationTable {
  ['guowu'] = '帼武',
  ['#guowu_delay'] = '帼武',
  ['#guowu-choose'] = '帼武：你可以为%arg增加至多两个目标',
  [':guowu'] = '出牌阶段开始时，你可以展示所有手牌，若包含的类别数：不小于1，你从弃牌堆中获得一张【杀】；不小于2，你本阶段使用牌无距离限制；不小于3，你本阶段使用【杀】或普通锦囊牌可以多指定两个目标。',
  ['$guowu1'] = '方天映黛眉，赤兔牵红妆。',
  ['$guowu2'] = '武姬青丝利，巾帼女儿红。',
}

guowu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guowu.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    player:showCards(cards)
    if player.dead then return end
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    if #types > 1 then
      room:addPlayerMark(player, "guowu2-phase", 1)
    end
    if #types > 2 then
      room:addPlayerMark(player, "guowu3-phase", 1)
    end
    local card = room:getCardsFromPileByRule("slash", 1, "discardPile")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, guowu.name, nil, true, player.id)
    end
  end,
})

guowu:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("guowu3-phase") > 0 and not player.dead and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and #player.room:getUseExtraTargets(data) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getUseExtraTargets(data)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 2,
      prompt = "#guowu-choose:::"..data.card:toLogString(),
      skill_name = guowu.name,
      cancelable = true
    })
    if #tos > 0 then
      table.forEach(tos, function(id)
        table.insert(data.tos, {id})
      end)
    end
  end,
})

guowu:addEffect('targetmod', {
  bypass_distances = function(self, player)
    return player:getMark("guowu2-phase") > 0
  end,
})

return guowu
