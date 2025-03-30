local dangzai = fk.CreateSkill {
  name = "dangzai",
}

Fk:loadTranslationTable{
  ["dangzai"] = "挡灾",
  [":dangzai"] = "出牌阶段开始时，你可以选择一名判定区内有牌的其他角色，将其判定区里的任意张牌移至你的判定区。",

  ["#dangzai-choose"] = "挡灾：你可以将一名角色判定区里的任意张牌移至你的判定区",
  ["#dangzai-ask"] = "挡灾：选择任意张牌从 %dest 判定区移给你",

  ["$dangzai1"] = "此处有我，休得放肆！",
  ["$dangzai2"] = "退后，让我来！"
}

dangzai:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangzai.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:canMoveCardsInBoardTo(player, "j")
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:canMoveCardsInBoardTo(player, "j")
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#dangzai-choose",
      skill_name = dangzai.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = table.filter(to:getCardIds("j"), function (id)
      return to:canMoveCardInBoardTo(player, id)
    end)
    local cards = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = 999,
      flag = { card_data = {{ to.general, ids }} },
      skill_name = dangzai.name,
      prompt = "#dangzai-ask::" .. to.id,
    })
    cards = table.map(cards, function(id)
      return room:getCardOwner(id):getVirualEquip(id) or Fk:getCardById(id)
    end)
    room:moveCardTo(cards, Player.Judge, player, fk.ReasonJustMove, dangzai.name, nil, true, player)
  end,
})

return dangzai
