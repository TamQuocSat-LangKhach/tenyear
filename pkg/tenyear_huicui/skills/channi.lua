local channi = fk.CreateSkill {
  name = "channi",
}

Fk:loadTranslationTable{
  ["channi"] = "谗逆",
  [":channi"] = "出牌阶段限一次，你可以交给一名其他角色任意张手牌，然后该角色可以将X张手牌当一张【决斗】使用（X至多为你以此法交给其的牌数），"..
  "其此使用【决斗】：造成伤害后，其摸X张牌；受到伤害后，你弃置所有手牌。",

  ["#channi"] = "谗逆：将任意张手牌交给一名角色，其可以将手牌当【决斗】使用",
  ["#channi-invoke"] = "谗逆：将至多%arg张手牌当【决斗】使用，若造成伤害你摸等量牌，若受到伤害则 %src 弃置所有手牌",

  ["$channi1"] = "此人心怀叵测，将军当拔剑诛之！",
  ["$channi2"] = "请夫君听妾身之言，勿为小人所误！",
}

channi:addEffect("active", {
  anim_type = "support",
  prompt = "#channi",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(channi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = #effect.cards
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, channi.name, nil, false, player)
    if target.dead or #target:getHandlyIds() == 0 then return end
    local success, dat = room:askToUseActiveSkill(target, {
      skill_name = "channi_viewas",
      prompt = "#channi-invoke:"..player.id.."::"..n,
      cancelable = true,
      extra_data = {
        channi_num = n,
      }
    })
    if success and dat then
      local card = Fk:cloneCard("duel")
      card.skillName = channi.name
      card:addSubcards(dat.cards)
      local use = {
        from = target,
        tos = dat.targets,
        card = card,
        extra_data = {
          channi_data = {
            player.id,
            target.id,
            #dat.cards,
          },
        }
      }
      room:useCard(use)
    end
  end,
})

channi:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and target and not target.dead and data.card and
      table.contains(data.card.skillNames, channi.name) and player.room.logic:damageByCardEffect() then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return false end
      local use = use_event.data
      if use.extra_data then
        local channi_data = use.extra_data.channi_data
        if channi_data and channi_data[1] == player.id and channi_data[2] == target.id then
          event:setCostData(self, {choice = channi_data[3]})
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(event:getCostData(self).choice, channi.name)
  end
})

local spec = {
  can_trigger = function(self, event, target, player, data)
    if not player.dead and target and not target.dead and data.card and
      table.contains(data.card.skillNames, channi.name) then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return false end
      local use = use_event.data
      if use.extra_data then
        local channi_data = use.extra_data.channi_data
        if channi_data and channi_data[1] == player.id and channi_data[2] == target.id then
          event:setCostData(self, {choice = channi_data[3]})
          return true
        end
      end
    end
  end,
}

channi:addEffect(fk.Damaged, {
  mute = true,
  is_delay_effect = true,
  can_trigger = spec.can_trigger,
  on_use = function(self, event, target, player, data)
    player:throwAllCards("h", channi.name)
  end,
})
return channi
