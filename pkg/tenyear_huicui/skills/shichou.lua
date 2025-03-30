local shichou = fk.CreateSkill {
  name = "ty__shichou",
}

Fk:loadTranslationTable{
  ["ty__shichou"] = "誓仇",
  [":ty__shichou"] = "出牌阶段，你可以将一张牌当不计次数的【杀】使用：若为红色，目标需弃置一张装备牌；若为黑色，目标需弃置一张黑色手牌。"..
  "否则此【杀】不能被其响应。每种颜色每回合各限一次，且必须指定同一个目标。",

  ["#ty__shichou"] = "誓仇：将一张牌当不计次数的【杀】使用",
  ["#ty__shichou1-discard"] = "誓仇：请弃置一张装备牌，否则不能响应此【杀】",
  ["#ty__shichou2-discard"] = "誓仇：请弃置一张黑色手牌，否则不能响应此【杀】",

  ["$ty__shichou1"] = "去地下忏悔你们的罪行吧！",
  ["$ty__shichou2"] = "以尔等之血，祭我族人。",
}

shichou:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__shichou",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player:getTableMark("ty__shichou-turn") < 2
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local color = Fk:getCardById(to_select).color
      if color == Card.NoColor or table.contains(player:getTableMark("ty__shichou-turn"), color) then return end
      local card = Fk:cloneCard("slash")
      card.skillName = shichou.name
      card:addSubcard(to_select)
      return not player:prohibitUse(card)
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected > 0 or to_select == player then return end
    local card = Fk:cloneCard("slash")
    card.skillName = shichou.name
    card:addSubcards(selected_cards)
    if player:canUseTo(card, to_select, {bypass_times = true}) then
      if player:getMark("ty__shichou_to-turn") == 0 then
        return true
      else
        return to_select.id == player:getMark("ty__shichou_to-turn")
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "ty__shichou-turn", Fk:getCardById(effect.cards[1]).color)
    room:setPlayerMark(player, "ty__shichou_to-turn", effect.tos[1].id)
    local card = Fk:cloneCard("slash")
    card:addSubcards(effect.cards)
    card.skillName = shichou.name
    local use = {
      from = player,
      tos = effect.tos,
      card = card,
      extraUse = true,
    }
    room:useCard(use)
  end,
})

shichou:addEffect(fk.TargetSpecified, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "ty__shichou") and
      data.card.color ~= Card.NoColor and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern, prompt = ".|.|.|.|.|equip", "#ty__shichou1-discard"
    if data.card.color == Card.Black then
      pattern, prompt = ".|.|spade,club|hand", "#ty__shichou2-discard"
    end
    if #room:askToDiscard(data.to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = "ty__shichou",
      cancelable = true,
      pattern = pattern,
      prompt = prompt
    }) == 0 then
      data.disresponsive = true
    end
  end,
})

return shichou
