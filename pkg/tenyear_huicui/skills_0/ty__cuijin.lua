local ty__cuijin = fk.CreateSkill {
  name = "ty__cuijin"
}

Fk:loadTranslationTable{
  ['ty__cuijin'] = '催进',
  ['#ty__cuijin-ask'] = '是否弃置一张牌，对 %dest 发动 催进',
  ['#ty__cuijin_delay'] = '催进',
  [':ty__cuijin'] = '当你或攻击范围内的角色使用【杀】或【决斗】时，你可弃置一张牌，令此【杀】或【决斗】的伤害值基数+1。当此牌结算结束后，若此牌未造成伤害，你摸两张牌，对使用者造成1点伤害。',
  ['$ty__cuijin1'] = '军令如山，诸君焉敢不前？',
  ['$ty__cuijin2'] = '前攻者赏之，后靡斩之！'
}

ty__cuijin:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ty__cuijin) and (player:inMyAttackRange(target) or target == player)
      and table.contains({"slash", "duel"}, data.card.trueName) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty__cuijin.name,
      cancelable = true,
      prompt = "#ty__cuijin-ask::" .. target.id,
      skip = true
    })
    if #card > 0 then
      room:doIndicate(player.id, {target.id})
      event:setCostData(skill, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(skill), ty__cuijin.name, player, player)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__cuijinUser = data.extra_data.ty__cuijinUser or {}
    table.insert(data.extra_data.ty__cuijinUser, player.id)
  end,
})

ty__cuijin:addEffect(fk.CardUseFinished, {
  name = "#ty__cuijin_delay",
  mute = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return not player.dead and table.contains((data.extra_data or {}).ty__cuijinUser or {}, player.id) and not data.damageDealt
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__cuijin.name, "offensive")
    player:broadcastSkillInvoke(ty__cuijin.name)
    player:drawCards(2, ty__cuijin.name)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = ty__cuijin.name,
      }
    end
  end,
})

return ty__cuijin
