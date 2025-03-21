local guanchao = fk.CreateSkill {
  name = "guanchao",
}

Fk:loadTranslationTable{
  ["guanchao"] = "观潮",
  [":guanchao"] = "出牌阶段开始时，你可以选择“递增”或“递减”，本阶段当你使用牌时，若你此阶段使用过的所有牌点数均为严格递增或严格递减，你摸一张牌。",

  ["guanchao_ascending"] = "递增",
  ["guanchao_decending"] = "递减",
  ["@guanchao-phase"] = "观潮",

  ["$guanchao1"] = "朝夕之间，可知所进退。",
  ["$guanchao2"] = "月盈，潮起晨暮也；月亏，潮起日半也。",
}

guanchao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guanchao.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"guanchao_ascending", "guanchao_decending", "Cancel"},
      skill_name = guanchao.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@guanchao-phase", {event:getCostData(self).choice})
  end,
})

guanchao:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and data.extra_data and data.extra_data.guanchao
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, guanchao.name)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@guanchao-phase") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card.mark == 0 then
      room:setPlayerMark(player, "@guanchao-phase", 0)
      return
    end
    local mark = player:getTableMark("@guanchao-phase")
    if #mark == 1 then
      table.insert(mark, data.card.number)
    else
      if (mark[1] == "guanchao_ascending" and data.card.number > mark[2]) or
        (mark[1] == "guanchao_decending" and data.card.number < mark[2]) then
        data.extra_data = data.extra_data or {}
        data.extra_data.guanchao = true
        mark[2] = data.card.number
      else
        room:setPlayerMark(player, "@guanchao-phase", 0)
        return
      end
    end
    room:setPlayerMark(player, "@guanchao-phase", mark)
  end,
})

return guanchao
