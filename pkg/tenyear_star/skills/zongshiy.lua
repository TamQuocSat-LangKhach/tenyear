local zongshiy = fk.CreateSkill {
  name = "zongshiy"
}

Fk:loadTranslationTable{
  ['zongshiy'] = '纵势',
  ['#zongshiy-active'] = '发动 纵势，选择展示一张基本牌或普通锦囊牌',
  ['#zongshiy-use'] = '发动 纵势，将手牌中其他所有同花色的牌当【%arg】使用，并可指定至多%arg2个目标',
  ['#zongshiy-target'] = '纵势：为即将使用的%arg指定至多%arg2个目标（无距离限制）',
  [':zongshiy'] = '出牌阶段，你可以展示一张基本牌或普通锦囊牌，然后将此花色的所有其他手牌当这张牌使用（此牌可指定的目标数改为以此法使用的牌数）。',
  ['$zongshiy1'] = '四世三公之家，当为天下之望。',
  ['$zongshiy2'] = '大势在我，可怀问鼎之心。',
}

zongshiy:addEffect('active', {
  anim_type = "special",
  card_num = 1,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeBasic or card:isCommonTrick() then
        --FIXME：未测试，暂且排除【借刀杀人】类卡。
        if card.skill:getMinTargetNum() > 1 then return false end

        local suit = card.suit
        if suit == Card.NoSuit then return false end

        local cards = table.filter(player:getCardIds(Player.Hand), function (id)
          return id ~= to_select and Fk:getCardById(id).suit == suit
        end)
        if #cards == 0 then return false end

        local to_use = Fk:cloneCard(card.name)
        to_use.skillName = zongshiy.name
        to_use:addSubcards(cards)
        return #getZongshiTargets(Fk:currentRoom(), player, to_use) > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:getCardById(effect.cards[1])
    local suit = card.suit
    player:showCards(effect.cards)
    if player.dead then return end
    local cards = table.filter(player:getCardIds(Player.Hand), function (id)
      return id ~= effect.cards[1] and Fk:getCardById(id).suit == suit
    end)
    if #cards == 0 then return end
    local to_use = Fk:cloneCard(card.name)
    to_use.skillName = zongshiy.name
    to_use:addSubcards(cards)
    if player:prohibitUse(to_use) then return end
    local targets = getZongshiTargets(room, player, to_use)
    if #targets == 0 then return end
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #cards,
      prompt = "#zongshiy-target:::" .. to_use:toLogString() .. ":" .. tostring(#cards),
      skill_name = zongshiy.name,
    })

    room:useCard{
      from = player.id,
      tos = table.map(targets, function(p) return {p} end),
      card = to_use,
      extraUse = (player.phase == Player.NotActive),
    }
  end,
  prompt = function(self, player, selected_cards, selected_targets)
    if #selected_cards == 0 then
      return "#zongshiy-active"
    else
      local card = Fk:getCardById(selected_cards[1])
      local i = #table.filter(player:getCardIds(Player.Hand), function (id)
        return id ~= selected_cards[1] and Fk:getCardById(id).suit == card.suit
      end)
      return "#zongshiy-use:::" .. card.trueName .. ":" .. tostring(i)
    end
  end,
})

return zongshiy
