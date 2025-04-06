local murui = fk.CreateSkill {
  name = "murui",
  dynamic_desc = function (self, player)
    if #player:getTableMark(self.name) == 3 then
      return "dummyskill"
    elseif player:getMark(self.name) ~= 0 then
      local str = {}
      for i = 1, 3, 1 do
        if table.contains(player:getMark(self.name), i) then
          table.insert(str, "<s>"..Fk:translate("murui_"..i).."</s>")
        else
          table.insert(str, Fk:translate("murui_"..i))
        end
      end
      return "murui_inner:"..table.concat(str, "；")
    end
  end,
}

Fk:loadTranslationTable{
  ["murui"] = "暮锐",
  [":murui"] = "你可以于以下时机使用一张牌：1.每轮开始时；2.有角色死亡的回合结束时；3.你的回合开始时。若此牌造成了伤害，"..
  "则你摸两张牌并删除对应选项。",

  [":murui_inner"] = "你可以于以下时机使用一张牌：{1}。若此牌造成了伤害，则你摸两张牌并删除对应选项。",
  ["murui_1"] = "每轮开始时",
  ["murui_2"] = "有角色死亡的回合结束时",
  ["murui_3"] = "你的回合开始时",

  ["#murui-use"] = "暮锐：你可以使用一张牌，若造成伤害则摸两张牌并删除此时机",

  ["$murui1"] = "背水一战，将至绝地而何畏死。",
  ["$murui2"] = "破釜沉舟，置之死地而后生。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToPlayCard(player, {
      skill_name = murui.name,
      prompt = "#murui-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      use.extraUse = true
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = table.simpleClone(event:getCostData(self).extra_data)
    room:useCard(use)
    if use and use.damageDealt and not player.dead then
      if event == fk.RoundStart then
        room:addTableMark(player, murui.name, 1)
      elseif event == fk.TurnEnd then
        room:addTableMark(player, murui.name, 2)
      elseif event == fk.TurnStart then
        room:addTableMark(player, murui.name, 3)
      end
      player:drawCards(2, murui.name)
    end
  end,
}

murui:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(murui.name) and
      not table.contains(player:getTableMark(murui.name), 1)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

murui:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(murui.name) and
      not table.contains(player:getTableMark(murui.name), 2) and
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, Util.TrueFunc, Player.HistoryTurn) > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

murui:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(murui.name) and
      not table.contains(player:getTableMark(murui.name), 3)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

murui:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, murui.name, 0)
end)

return murui
