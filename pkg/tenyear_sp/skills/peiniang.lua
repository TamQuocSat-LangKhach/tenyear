local peiniang = fk.CreateSkill {
  name = "peiniang",
}

Fk:loadTranslationTable{
  ["peiniang"] = "醅酿",
  [":peiniang"] = "你可以将“异瞳”花色的牌当【酒】使用（不计次数）。当一名角色进入濒死状态时，你可以对其使用一张【酒】。",

  ["#peiniang"] = "醅酿：你可以将一张%arg牌当【酒】使用（不计次数）",
  ["#peiniang-use"] = "醅酿：你可以对 %dest 使用【酒】，或将“异瞳”花色的牌当【酒】对其使用",

  ["$peiniang1"] = "今日以酒会友，不醉不归。",
  ["$peiniang2"] = "来半斤牛肉，再酿一壶好酒。",
}

peiniang:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "analeptic",
  prompt = function (skill, player)
    return "#peiniang:::"..player:getMark("@yitong")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getSuitString(true) == player:getMark("@yitong")
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("analeptic")
    card.skillName = peiniang.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function (self, player)
    return player:getMark("@yitong") ~= 0
  end,
  enabled_at_response = function (self, player, response)
    return not response and player:getMark("@yitong") ~= 0
  end,
})

peiniang:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, peiniang.name)
  end,
})

peiniang:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(peiniang.name) and not player:prohibitUse(Fk:cloneCard("analeptic")) and
      not player:isProhibited(target, Fk:cloneCard("analeptic")) and
      #player:getHandlyIds() + #player:getCardIds("e") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local analeptic
    local room = player.room
    local ids = table.filter(table.connect(player:getHandlyIds(), player:getCardIds("e")), function (id)
      analeptic = Fk:getCardById(id)
      if analeptic.name == "analeptic" then
        if not player:prohibitUse(analeptic) and not player:isProhibited(target, analeptic) then
          return true
        end
      elseif analeptic:getSuitString(true) == player:getMark("@yitong") then
        analeptic = Fk:cloneCard("analeptic")
        analeptic.skillName = peiniang.name
        analeptic:addSubcard(id)
        if not player:prohibitUse(analeptic) and not player:isProhibited(target, analeptic) then
          return true
        end
      end
    end)
    local card = room:askToCards(player, {
      skill_name = peiniang.name,
      include_equip = true,
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#peiniang-use::"..target.id,
      cancelable = true,
      expand_pile = player:getHandlyIds(false),
    })
    if #card > 0 then
      event:setCostData(self, { cards = card, tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    local card
    if Fk:getCardById(id).name == "analeptic" then
      card = Fk:getCardById(id)
    else
      card = Fk:cloneCard("analeptic")
      card.skillName = peiniang.name
      card:addSubcard(event:getCostData(self).cards[1])
    end
    room:useCard{
      from = player,
      tos = { target },
      extra_data = {
        analepticRecover = true,
      },
      card = card,
    }
  end,
})

return peiniang
