local kengqiang = fk.CreateSkill {
  name = "kengqiang",
}

Fk:loadTranslationTable{
  ["kengqiang"] = "铿锵",
  [":kengqiang"] = "每回合限一次，当你使用伤害牌时，你可以选择一项：1.摸X张牌（X为你的体力上限）；2.此牌伤害+1，造成伤害后你获得之。",

  ["kengqiang1"] = "摸体力上限张牌",
  ["kengqiang2"] = "此牌伤害+1，造成伤害后你获得之",

  ["$kengqiang1"] = "女子着征袍，战意越关山。",
  ["$kengqiang2"] = "兴武效妇好，挥钺断苍穹！",
}

kengqiang:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kengqiang.name) and data.card.is_damage_card then
      if player:usedSkillTimes("shangjue", Player.HistoryGame) == 0 then
        return player:usedEffectTimes(kengqiang.name, Player.HistoryTurn) == 0 and
          player:getMark("kengqiang1-turn") == 0 and player:getMark("kengqiang2-turn") == 0
      else
        return player:getMark("kengqiang1-turn") == 0 or player:getMark("kengqiang2-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"kengqiang1", "kengqiang2", "Cancel"}
    local choices = table.simpleClone(all_choices)
    for i = 2, 1, -1 do
      if player:getMark("kengqiang"..i.."-turn") > 0 then
        table.remove(choices, i)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = kengqiang.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "kengqiang1" then
      player:drawCards(player.maxHp, kengqiang.name)
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
      data.extra_data = data.extra_data or {}
      data.extra_data.kengqiang = player
    end
  end,
})

kengqiang:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and data.card and
      player.room:getCardArea(data.card) == Card.Processing then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return false end
      local use = use_event.data
      return use.extra_data and use.extra_data.kengqiang == player
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, kengqiang.name, nil, true, player)
  end
})

return kengqiang
