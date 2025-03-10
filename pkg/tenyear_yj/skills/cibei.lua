local cibei = fk.CreateSkill {
  name = "cibei"
}

Fk:loadTranslationTable{
  ['cibei'] = '刺北',
  ['hanlong_ci'] = '刺',
  ['#cibei-invoke'] = '刺北：是否将此【杀】和一张“刺”交换？',
  ['#cibei-choose'] = '刺北：选择一名角色，弃置其区域内一张牌',
  ['@@cibei-inhand'] = '刺北',
  ['#cibei_delay'] = '刺北',
  [':cibei'] = '当【杀】使用结算结束后，若此【杀】造成过伤害，你可以将此【杀】与一张不为【杀】的“刺”交换，然后弃置一名角色区域内的一张牌。一名角色的回合结束时，若所有“刺”均为【杀】，你获得所有“刺”，这些【杀】不能被弃置、不计入手牌上限、使用时无距离和次数限制。',
  ['$cibei1'] = '匹夫一怒，流血二人，天下缟素。',
  ['$cibei2'] = '我欲效专诸、聂政之旧事，逐天狼于西北。',
}

-- 主技能效果
cibei:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if #player:getPile("hanlong_ci") > 0 then
      return table.find(player:getPile("hanlong_ci"), function(id) return Fk:getCardById(id).trueName ~= "slash" end) and
        data.card.trueName == "slash" and (not data.card:isVirtual() or #data.card.subcards == 1) and data.damageDealt and
        Fk:getCardById(data.card:getEffectiveId(), true).trueName == "slash" and player.room:getCardArea(data.card) == Card.Processing
    end
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = skill.name, prompt = "#cibei-invoke" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local c = data.card:getEffectiveId()
    local ids = table.filter(player:getPile("hanlong_ci"), function(id) return Fk:getCardById(id).trueName ~= "slash" end)
    local piles = room:askToArrangeCards(player, { skill_name = skill.name, card_map = {{c}, ids, "slash", "hanlong_ci"}, prompt = "#cibei-cibei" })
    local c2 = 0
    if piles[1][1] == c then
      c2 = table.random(ids)
    else
      c2 = piles[1][1]
    end
    local moves = {{
      ids = {c},
      to = player.id,
      toArea = Card.PlayerSpecial,
      moveReason = fk.ReasonExchange,
      skillName = skill.name,
      specialName = "hanlong_ci",
    }, {
        ids = {c2},
        from = player.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonExchange,
        skillName = skill.name,
        fromSpecialName = "hanlong_ci",
      }}
    room:moveCards(table.unpack(moves))
    if not player.dead then
      local targets = table.filter(room.alive_players, function(p) return not p:isAllNude() end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, { targets = table.map(targets, Util.IdMapper), min_num = 1, max_num = 1, prompt = "#cibei-choose", skill_name = skill.name, cancelable = false })
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askToChooseCard(player, { target = to, flag = "hej", skill_name = skill.name })
          room:throwCard({id}, skill.name, to, player)
        end
      end
    end
  end,
})

cibei:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    return table.every(player:getPile("hanlong_ci"), function(id) return Fk:getCardById(id).trueName == "slash" end)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:moveCardTo(player:getPile("hanlong_ci"), Card.PlayerHand, player, fk.ReasonPrey, skill.name, "", true, player.id, "@@cibei-inhand")
  end,
})

-- 刷新效果
cibei:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and
      data.card.trueName == "slash" and not data.card:isVirtual() and data.card:getMark("@@cibei-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

-- 子技能效果
local cibei_prohibit = fk.CreateSkill {
  name = "#cibei_prohibit"
}
cibei_prohibit:addEffect('prohibit', {
  prohibit_discard = function(self, player, card)
    return card:getMark("@@cibei-inhand") > 0
  end,
})
cibei:addRelatedSkill(cibei_prohibit)

local cibei_maxcards = fk.CreateSkill {
  name = "#cibei_maxcards"
}
cibei_maxcards:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card:getMark("@@cibei-inhand") > 0
  end,
})
cibei:addRelatedSkill(cibei_maxcards)

local cibei_targetmod = fk.CreateSkill {
  name = "#cibei_targetmod"
}
cibei_targetmod:addEffect('targetmod', {
  bypass_times = function(self, player, skill, card)
    return card and card:getMark("@@cibei-inhand") > 0
  end,
  bypass_distances = function(self, player, skill, card)
    return card and card:getMark("@@cibei-inhand") > 0
  end,
})
cibei:addRelatedSkill(cibei_targetmod)

local cibei_delay = fk.CreateSkill {
  name = "#cibei_delay",
  mute = true
}
cibei_delay:addEffect(fk.BeforeCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@cibei-inhand") > 0 then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
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
    if #ids > 0 then
      player.room:sendLog{
        type = "#cancelDismantle",
        card = ids,
        arg = "cibei",
      }
    end
  end,
})
cibei:addRelatedSkill(cibei_delay)

return cibei
