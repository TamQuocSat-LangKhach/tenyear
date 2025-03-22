local liandui = fk.CreateSkill {
  name = "liandui",
}

Fk:loadTranslationTable{
  ["liandui"] = "联对",
  [":liandui"] = "当你使用一张牌时，若上一张牌的使用者不为你，你可以令其摸两张牌；其他角色使用一张牌时，若上一张牌的使用者为你，其可以令你摸两张牌。",

  ["#liandui-invoke"] = "联对：你可以发动“联对”，令 %dest 摸两张牌",

  ["$liandui1"] = "以句相联，抒离散之苦。",
  ["$liandui2"] = "以诗相对，颂哀怨之情。",
}

liandui:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(liandui.name) and not target.dead then
      local to
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.data ~= data then
          to = e.data.from
          return true
        end
      end, 0)
      if to then
        event:setCostData(self, {extra_data = to})
        return (target == player and to ~= player and not to.dead) or
          (target ~= player and to == player)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).extra_data
    if player.room:askToSkillInvoke(target, {
      skill_name = liandui.name,
      prompt = "#liandui-invoke::"..to.id,
    }) then
      if target ~= player then
        room:doIndicate(target, {player})
        event:setCostData(self, {tos = {player}})
      else
        event:setCostData(self, {tos = {to}, extra_data = to})
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(2, liandui.name)
  end,
})

return liandui
