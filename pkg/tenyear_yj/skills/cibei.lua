local cibei = fk.CreateSkill {
  name = "cibei",
}

Fk:loadTranslationTable{
  ["cibei"] = "刺北",
  [":cibei"] = "当【杀】使用结算结束后，若此【杀】造成过伤害，你可以将此【杀】与一张不为【杀】的“刺”交换，然后弃置一名角色区域内的一张牌。"..
  "一名角色的回合结束时，若所有“刺”均为【杀】，你获得所有“刺”，这些【杀】不能被弃置、不计入手牌上限、使用时无距离和次数限制。",

  ["#cibei-invoke"] = "刺北：是否将此【杀】和一张“刺”交换？",
  ["#cibei"] = "刺北：将此【杀】和一张“刺”交换",
  ["#cibei-choose"] = "刺北：选择一名角色，弃置其区域内一张牌",
  ["@@cibei-inhand"] = "刺北",

  ["$cibei1"] = "匹夫一怒，流血二人，天下缟素。",
  ["$cibei2"] = "我欲效专诸、聂政之旧事，逐天狼于西北。",
}

Fk:addPoxiMethod{
  name = "cibei",
  prompt = function (data, extra_data)
    return "#cibei"
  end,
  card_filter = function (to_select, selected, data, extra_data)
    if data and #selected < 2 then
      for _, id in ipairs(selected) do
        for _, v in ipairs(data) do
          if table.contains(v[2], id) and table.contains(v[2], to_select) then
            return false
          end
        end
      end
      if table.contains(data[1][2], to_select) then
        return Fk:getCardById(to_select).trueName ~= "slash"
      end
      return true
    end
  end,
  feasible = function(selected, data)
    return data and #selected == 2
  end,
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}

cibei:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cibei.name) and #player:getPile("hanlong_ci") > 0 and
      data.card.trueName == "slash" and (not data.card:isVirtual() or #data.card.subcards == 1) and data.damageDealt and
      table.find(player:getPile("hanlong_ci"), function(id)
        return Fk:getCardById(id).trueName ~= "slash"
      end) and
      Fk:getCardById(Card:getIdList(data.card)[1], true).trueName == "slash" and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = cibei.name,
      prompt = "#cibei-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askToPoxi(player, {
      poxi_type = cibei.name,
      data = {
        {"hanlong_ci", player:getPile("hanlong_ci")},
        {"slash", Card:getIdList(data.card)},
      },
      cancelable = false,
    })
    local cards1, cards2 = {result[1]}, {result[2]}
    if table.contains(player:getPile("hanlong_ci"), result[2]) then
      cards1, cards2 = {result[2]}, {result[1]}
    end
    room:moveCards({
      ids = cards1,
      from = player,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = cibei.name,
      proposer = player,
      moveVisible = true,
    },
    {
      ids = cards2,
      to = player,
      toArea = Card.PlayerSpecial,
      specialName = "hanlong_ci",
      moveReason = fk.ReasonJustMove,
      skillName = cibei.name,
      proposer = player,
      moveVisible = true,
    })
    if not player.dead then
      local targets = table.filter(room.alive_players, function(p)
        return not p:isAllNude()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = cibei.name,
          prompt = "#cibei-choose",
          cancelable = false,
        })[1]
        if to == player then
          local cards = table.filter(player:getCardIds("hej"), function (id)
            return not player:prohibitDiscard(id)
          end)
          if #cards > 0 then
            local id = room:askToCards(player, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = cibei.name,
              pattern = tostring(Exppattern{ id = cards }),
              cancelable = false,
              expand_pile = player:getCardIds("j"),
            })
            room:throwCard(id, cibei.name, player, player)
          end
        else
          local id = room:askToChooseCard(player, {
            target = to,
            flag = "hej",
            skill_name = cibei.name,
          })
          room:throwCard(id, cibei.name, to, player)
        end
      end
    end
  end,
})

cibei:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cibei.name) and
      table.every(player:getPile("hanlong_ci"), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("hanlong_ci")
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, cibei.name, nil, true, player, "@@cibei-inhand")
  end,
})

cibei:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      not data.card:isVirtual() and data.card:getMark("@@cibei-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

cibei:addEffect("prohibit", {
  prohibit_discard = function(self, player, card)
    return card:getMark("@@cibei-inhand") > 0
  end,
})

cibei:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@cibei-inhand") > 0
  end,
})

cibei:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and card:getMark("@@cibei-inhand") > 0
  end,
  bypass_distances = function(self, player, skill, card)
    return card and card:getMark("@@cibei-inhand") > 0
  end,
})

cibei:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@cibei-inhand") > 0 then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        local move_info = {}
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@cibei-inhand") > 0 then
            table.insert(ids, info.cardId)
          else
            table.insert(move_info, info)
          end
        end
        if #ids > 0 then
          move.moveInfo = move_info
        end
      end
    end
  end,
})

return cibei
