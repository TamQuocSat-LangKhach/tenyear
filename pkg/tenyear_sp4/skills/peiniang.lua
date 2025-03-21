local peiniang = fk.CreateSkill {
  name = "peiniang"
}

Fk:loadTranslationTable{
  ['peiniang'] = '醅酿',
  ['#peiniang'] = '醅酿：你可以将一张%arg牌当【酒】使用（不计次数）',
  ['@yitong'] = '异瞳',
  ['#peiniang-use'] = '醅酿：你可以对 %dest 使用【酒】',
  [':peiniang'] = '你可以将“异瞳”花色的牌当【酒】使用（不计次数）。当一名角色进入濒死状态时，你可以将一张【酒】或“异瞳”花色的牌当【酒】（使用方法②）对其使用。',
  ['$peiniang1'] = '今日以酒会友，不醉不归。',
  ['$peiniang2'] = '来半斤牛肉，再酿一壶好酒。',
}

-- ViewAsSkill
peiniang:addEffect('viewas', {
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
    card.skillName = skill.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function (skill, player)
    return player:getMark("@yitong") ~= 0
  end,
  enabled_at_response = function (skill, player, response)
    return not response and player:getMark("@yitong") ~= 0
  end,
})

-- TargetModSkill
peiniang:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "peiniang")
  end,
})

-- TriggerSkill
peiniang:addEffect(fk.EnterDying, {
  mute = true,
  main_skill = peiniang,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(peiniang) and
      not player:prohibitUse(Fk:cloneCard("analeptic")) and
      not player:isProhibited(target, Fk:cloneCard("analeptic"))
  end,
  on_cost = function (self, event, target, player, data)
    local analeptic
    local ex_cards = {}
    local room = player.room
    local ids = table.filter(player:getCardIds("he&"), function (id)
      analeptic = Fk:getCardById(id)
      if analeptic.trueName == "analeptic" or analeptic:getSuitString(true) == player:getMark("@yitong") then
        analeptic = Fk:cloneCard("analeptic")
        analeptic.skillName = "peiniang"
        analeptic:addSubcard(id)
        if not player:prohibitUse(analeptic) and not player:isProhibited(target, analeptic) then
          if room:getCardArea(id) == Player.Special then
            table.insert(ex_cards, id)
          end
          return true
        end
      end
    end)
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#peiniang-use::"..target.id,
      skill_name = "peiniang",
      cancelable = true,
    })
    if #card > 0 then
      room:doIndicate(player.id, { target.id })
      event:setCostData(skill, { cards = card, tos = {target.id} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "peiniang", "support")
    player:broadcastSkillInvoke("peiniang")
    local card = Fk:cloneCard("analeptic")
    card.skillName = "peiniang"
    card:addSubcard(event:getCostData(skill).cards[1])
    room:useCard{
      from = player.id,
      tos = { { target.id } },
      extra_data = { analepticRecover = true },
      card = card,
    }
  end,
})

return peiniang
