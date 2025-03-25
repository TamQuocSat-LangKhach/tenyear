local zhuanwen = fk.CreateSkill {
  name = "zhuanwen",
}

Fk:loadTranslationTable{
  ["zhuanwen"] = "撰文",
  [":zhuanwen"] = "结束阶段，你可以选择一名其他角色，展示牌堆顶X张牌（X为其手牌数，至多为5）并选择一项：1.对其依次使用其中的伤害牌；"..
  "2.令其获得其中的非伤害牌。然后将剩余牌置于牌堆顶。",

  ["#zhuanwen-choose"] = "撰文：选择一名角色，展示牌堆顶其手牌数张牌（至多5张），对其使用其中的伤害牌或令其获得其中的非伤害牌",
  ["zhuanwen1"] = "对其使用伤害牌",
  ["zhuanwen2"] = "其获得非伤害牌",
  ["#zhuanwen-choice"] = "撰文：选择对 %dest 执行的一项",

  ["$zhuanwen1"] = "夺人妻子，掘人祖陵，彼与桀纣何异！",
  ["$zhuanwen2"] = "奸宦之后，权佞之子，安敢居南而大！",
}

zhuanwen:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuanwen.name) and player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zhuanwen-choose",
      skill_name = zhuanwen.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:getNCards(math.min(to:getHandcardNum(), 5))
    room:turnOverCardsFromDrawPile(player, cards, zhuanwen.name)
    local choice = room:askToChoice(player, {
      choices = {"zhuanwen1", "zhuanwen2"},
      skill_name = zhuanwen.name,
      prompt = "#zhuanwen-choice::"..to.id,
    })
    if choice == "zhuanwen1" then
      for _, id in ipairs(cards) do
        if player.dead or to.dead then break end
        local card = Fk:getCardById(id)
        if card.is_damage_card and not player:isProhibited(to, card) then
          room:delay(800)
          room:useCard({
            from = player,
            tos = {to},
            card = card,
            extraUse = true,
          })
        end
      end
    else
      local get = table.filter(cards, function (id)
        return not Fk:getCardById(id).is_damage_card
      end)
      if #get > 0 then
        room:moveCardTo(get, Card.PlayerHand, to, fk.ReasonJustMove, zhuanwen.name, nil, true, to)
      end
    end
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      room:returnCardsToDrawPile(player, cards, zhuanwen.name)
    end
  end,
})

return zhuanwen
