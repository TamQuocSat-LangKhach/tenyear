local xianniang = fk.CreateSkill {
  name = "xianniang",
}

Fk:loadTranslationTable {
  ["xianniang"] = "献酿",
  [":xianniang"] = "每轮各限一次，当你的牌被其他角色弃置后，或当你受到伤害后，你可以获得一名手牌数不小于你的角色至多两张牌，"..
  "然后可以将至多等量的牌交给另一名角色；以此法获得和交出的基本牌视为【酒】。若你本轮以此法获得的牌数大于2，你失去1点体力。",

  ["#xianniang-choose"] = "献酿：你可以选择一名手牌数不小于你的角色，获得其至多两张牌",
  ["#xianniang-give"] = "献酿：你可以将至多%arg张牌交给一名角色（其中的基本牌将被视为【酒】）",
  ["@@xianniang-inhand"] = "献酿",

  ["$xianniang1"] = "将军！嘿嘿~酒来了~",
  ["$xianniang2"] = "酒里没毒，真是的，自己吓自己！",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getHandcardNum() >= player:getHandcardNum() and not p:isNude()
    end)
    if #player:getCardIds("e") > 0 then
      table.insert(targets, player)
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = xianniang.name,
      prompt = "#xianniang-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = 2,
      flag = to == player and "e" or "he",
      skill_name = xianniang.name,
    })
    room:addPlayerMark(player, "xianniang_num-round", #ids)

    local xianniangMove = function(cards, pA, pB, reason)
      local ids1, ids2 = {}, {}
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).type == Card.TypeBasic then
          table.insert(ids1, id)
        else
          table.insert(ids2, id)
        end
      end
      local moveInfos = {}
      if #ids1 > 0 then
        table.insert(moveInfos, {
          ids = ids1,
          from = pA,
          to = pB,
          toArea = Card.PlayerHand,
          moveReason = reason,
          proposer = player,
          skillName = xianniang.name,
          moveVisible = false,
          moveMark = "@@xianniang-inhand",
        })
      end
      if #ids2 > 0 then
        table.insert(moveInfos, {
          ids = ids2,
          from = pA,
          to = pB,
          toArea = Card.PlayerHand,
          moveReason = reason,
          proposer = player,
          skillName = xianniang.name,
          moveVisible = false,
        })
      end
      room:moveCards(table.unpack(moveInfos))
    end
    xianniangMove(ids, to, player, fk.ReasonPrey)
    if player.dead then return end

    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p ~= to
    end)
    if #targets == 0 then return end
    to, ids = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = #ids,
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = xianniang.name,
      prompt = "#xianniang-give:::"..#ids,
      cancelable = true,
    })
    if #to > 0 and #ids > 0 then
      xianniangMove(ids, player, to[1], fk.ReasonGive)
      if player.dead then return end
    end

    if player:getMark("xianniang_num-round") > 2 then
      room:loseHp(player, 1, xianniang.name)
    end
  end,
}

xianniang:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(xianniang.name) and player:usedEffectTimes(self.name, Player.HistoryRound) == 0 then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard and move.proposer and move.proposer ~= player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return #player:getCardIds("e") > 0 or
                table.find(player.room:getOtherPlayers(player, false), function (p)
                  return p:getHandcardNum() >= player:getHandcardNum() and not p:isNude()
                end)
            end
          end
        end
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

xianniang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xianniang.name) and
      player:usedEffectTimes(self.name, Player.HistoryRound) == 0 and
      (#player:getCardIds("e") > 0 or
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getHandcardNum() >= player:getHandcardNum() and not p:isNude()
      end))
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

xianniang:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@xianniang-inhand") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("analeptic", card.suit, card.number)
  end,
})

return xianniang
