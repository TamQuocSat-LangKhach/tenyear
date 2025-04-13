local douwei = fk.CreateSkill{
  name = "douwei",
}

Fk:loadTranslationTable{
  ["douwei"] = "斗围",
  [":douwei"] = "出牌阶段，你可以弃置一张伤害牌，视为对任意名攻击范围内包含你的其他角色使用之，若其因此进入濒死状态，你回复1点体力，"..
  "此技能本回合失效。",

  ["#douwei"] = "斗围：弃置一张伤害牌，视为对任意名攻击范围内包含你的角色使用之",

  ["$douwei1"] = "",
  ["$douwei2"] = "",
}

douwei:addEffect("active", {
  anim_type = "offensive",
  prompt = "#douwei",
  card_num = 1,
  min_target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).is_damage_card and
      not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and to_select:inMyAttackRange(player)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local name = Fk:getCardById(effect.cards[1]).name
    room:throwCard(effect.cards, douwei.name, player, player)
    local targets = table.simpleClone(effect.tos)
    targets = table.filter(targets, function(p)
      return not p.dead
    end)
    if #targets == 0 then return end
    room:sortByAction(targets)
    room:useVirtualCard(name, nil, player, targets, douwei.name, true)
  end,
})

douwei:addEffect(fk.EnterDying, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(douwei.name) and
      data.damage and data.damage.card and player.room.logic:damageByCardEffect() and
      table.contains(data.damage.card.skillNames, douwei.name) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        return use.card == data.damage.card and use.from == player and not player.dead
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:invalidateSkill(player, douwei.name, "-turn")
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = douwei.name,
      }
    end
  end,
})

return douwei
