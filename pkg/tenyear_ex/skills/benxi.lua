local benxi = fk.CreateSkill {
  name = "ty_ex__benxi"
}

Fk:loadTranslationTable{
  ['ty_ex__benxi'] = '奔袭',
  ['@ty_ex__benxi-turn'] = '奔袭',
  ['#ty_ex__benxi_choice'] = '奔袭',
  ['ty_ex__benxi_choice1'] = '此牌额外指定一个目标',
  ['ty_ex__benxi_choice2'] = '此牌无视防具',
  ['ty_ex__benxi_choice3'] = '此牌不能被抵消',
  ['ty_ex__benxi_choice4'] = '此牌造成伤害时，你摸一张牌',
  ['#ty_ex__benxi-choose'] = '奔袭：请为此【%arg】额外指定一个目标',
  ['#ty_ex__benxi_effect'] = '奔袭',
  [':ty_ex__benxi'] = '锁定技，当你于回合内使用牌时，本回合你至其他角色距离-1；你的回合内，若你与所有其他角色的距离均为1，你使用仅指定一个目标的【杀】或普通锦囊牌时依次选择至多两项：1.为此牌额外指定一个目标；2.此牌无视防具；3.此牌不能被抵消；4.此牌造成伤害时，你摸一张牌。',
  ['$ty_ex__benxi1'] = '北伐曹魏，以弱制强！',
  ['$ty_ex__benxi2'] = '引军汉中，以御敌袭！',
}

-- CardUsing effect
benxi:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benxi) and player.phase ~= Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex__benxi-turn", 1)
  end,
})

-- AfterCardTargetDeclared effect
benxi:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(benxi) and player.phase ~= Player.NotActive then
      for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
        if player:distanceTo(p) > 1 then return end
      end
      return (data.card.trueName == "slash" or data.card:getSubtypeString() == "normal_trick") and #TargetGroup:getRealTargets(data.tos) == 1
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local choices = {
      "ty_ex__benxi_choice1",
      "ty_ex__benxi_choice2",
      "ty_ex__benxi_choice3",
      "ty_ex__benxi_choice4",
      "Cancel"
    }
    local choice = room:askToChoice(player, {choices = choices, skill_name = benxi.name})
    if choice == "Cancel" then return end
    table.removeOne(choices, choice)
    local choice2 = room:askToChoice(player, {choices = choices, skill_name = benxi.name})

    if choice == "ty_ex__benxi_choice1" or choice2 == "ty_ex__benxi_choice1" then
      if (data.card.name == "collateral") then return end

      local targets = room:getUseExtraTargets(data)
      if #targets > 0 then
        local tos = room:askToChoosePlayers(player, {targets = targets, min_num = 1, max_num = 1,
          prompt = "#ty_ex__benxi-choose:::"..data.card:toLogString(), skill_name = benxi.name, cancelable = true})

        if #tos > 0 then
          table.forEach(tos, function (id)
            table.insert(data.tos, {id})
          end)
        end
      end
    end

    if choice == "ty_ex__benxi_choice3" or choice2 == "ty_ex__benxi_choice3" then
      data.unoffsetableList = table.map(room.alive_players, Util.IdMapper)
    end

    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return end

    if choice == "ty_ex__benxi_choice2" or choice2 == "ty_ex__benxi_choice2" then
      for _, p in ipairs(room.alive_players) do
        room:addTableMark(p, fk.MarkArmorInvalidFrom, player.id)
      end
      card_event:addCleaner(function()
        for _, p in ipairs(room.alive_players) do
          room:removeTableMark(p, fk.MarkArmorInvalidFrom, player.id)
        end
      end)
    end

    if choice == "ty_ex__benxi_choice4" or choice2 == "ty_ex__benxi_choice4" then
      card_event.tybenxi_draw = player
    end
  end,
})

-- DamageCaused effect
benxi:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    return card_event and card_event.tybenxi_draw == player and data.card == card_event.data[1].card
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, benxi.name)
  end,
})

-- Distance effect
benxi:addEffect('distance', {
  correct_func = function(self, from, to)
    return -from:getMark("@ty_ex__benxi-turn")
  end,
})

return benxi
