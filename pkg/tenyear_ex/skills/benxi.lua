local benxi = fk.CreateSkill {
  name = "ty_ex__benxi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__benxi"] = "奔袭",
  [":ty_ex__benxi"] = "锁定技，当你于回合内使用牌时，本回合你计算与其他角色距离-1；你的回合内，若你与所有其他角色的距离均为1，"..
  "你使用仅指定一个目标的【杀】或普通锦囊牌时，依次选择至多两项：1.为此牌额外指定一个目标；2.此牌无视防具；3.此牌不能被抵消；"..
  "4.此牌造成伤害时，你摸一张牌。",

  ["@ty_ex__benxi-turn"] = "奔袭",
  ["ty_ex__benxi_choice1"] = "额外指定一个目标",
  ["ty_ex__benxi_choice2"] = "无视防具",
  ["ty_ex__benxi_choice3"] = "不能被抵消",
  ["ty_ex__benxi_choice4"] = "造成伤害时，你摸一张牌",
  ["#ty_ex__benxi-choose"] = "奔袭：请为此%arg额外指定一个目标",

  ["$ty_ex__benxi1"] = "北伐曹魏，以弱制强！",
  ["$ty_ex__benxi2"] = "引军汉中，以御敌袭！",
}

benxi:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benxi.name) and player.room.current == player
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex__benxi-turn", 1)
  end,
})

benxi:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benxi.name) and player.room.current == player and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and data:isOnlyTarget(data.tos[1]) and
      table.every(player.room:getOtherPlayers(player, false), function (p)
        return player:distanceTo(p) == 1
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {
      "ty_ex__benxi_choice1",
      "ty_ex__benxi_choice2",
      "ty_ex__benxi_choice3",
      "ty_ex__benxi_choice4",
      "Cancel",
    }
    local choices = {}
    local choice = room:askToChoice(player, {
      choices = all_choices,
      skill_name = benxi.name,
    })
    if choice == "Cancel" then return end
    table.insert(choices, choice)
    table.removeOne(all_choices, choice)
    choice = room:askToChoice(player, {
      choices = all_choices,
      skill_name = benxi.name,
    })
    table.insert(choices, choice)
    if table.contains(choices, "ty_ex__benxi_choice1") then
      local targets = data:getExtraTargets()
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#ty_ex__benxi-choose:::"..data.card:toLogString(),
          skill_name = benxi.name,
          cancelable = true,
        })
        if #to > 0 then
          data:addTarget(to[1])
        end
      end
    end

    if table.contains(choices, "ty_ex__benxi_choice2") then
      for _, p in ipairs(room.alive_players) do
        room:addTableMark(p, MarkEnum.MarkArmorInvalidFrom, player.id)
      end
      room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true):addCleaner(function()
        for _, p in ipairs(room.alive_players) do
          room:removeTableMark(p, MarkEnum.MarkArmorInvalidFrom, player.id)
        end
      end)
    end

    if table.contains(choices, "ty_ex__benxi_choice3") then
      data.unoffsetableList = table.simpleClone(room.players)
    end

    if table.contains(choices, "ty_ex__benxi_choice4") then
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__benxi = player
    end
  end,
})

benxi:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event then
        local use = use_event.data
        return use.extra_data and use.extra_data.ty_ex__benxi == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, benxi.name)
  end,
})

benxi:addEffect("distance", {
  correct_func = function(self, from, to)
    return -from:getMark("@ty_ex__benxi-turn")
  end,
})

return benxi
