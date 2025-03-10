local dangzai = fk.CreateSkill {
  name = "dangzai"
}

Fk:loadTranslationTable{
  ['dangzai'] = '挡灾',
  ['#dangzai-choose'] = '挡灾：你可以将一名角色判定区里的任意张牌移至你的判定区',
  ['#dangzai-ask'] = '挡灾：选择任意张牌从%dest判定区移给你',
  [':dangzai'] = '出牌阶段开始时，你可以选择一名判定区内有牌的其他角色，将其判定区里的任意张牌移至你的判定区。',
  ['$dangzai1'] = '此处有我，休得放肆！',
  ['$dangzai2'] = '退后，让我来！'
}

dangzai:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(dangzai) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p) return p:canMoveCardsInBoardTo(player, "j") end)
  end,
  on_cost = function(self, event, target, player)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
      return p:canMoveCardsInBoardTo(player, "j")
    end), Util.IdMapper)
    local to = player.room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#dangzai-choose",
      skill_name = dangzai.name
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local src = room:getPlayerById(event:getCostData(self))
    local cards = table.filter(src:getCardIds("j"), function(id)
      return src:canMoveCardInBoardTo(player, id)
    end)
    local chosen_cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = #cards,
      targets = {src},
      min_target_num = 0,
      max_target_num = 0,
      pattern = nil,
      prompt = "#dangzai-ask::" .. src.id,
      skill_name = dangzai.name
    })
    local chosen_cards_ids = table.unpack(chosen_cards[2])
    cards = table.map(chosen_cards_ids, function(id)
      return room:getCardOwner(id):getVirualEquip(id) or Fk:getCardById(id)
    end)
    room:moveCardTo(cards, Player.Judge, player, fk.ReasonJustMove, dangzai.name, nil, true, player.id)
  end,
})

return dangzai
