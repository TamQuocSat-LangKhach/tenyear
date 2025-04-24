local zhidui = fk.CreateSkill {
  name = "zhidui",
}

Fk:loadTranslationTable{
  ["zhidui"] = "智对",
  [":zhidui"] = "当你使用牌时，若与上一张被使用的牌：牌名字数和类别均相同，你可以选择一项：1.摸两张牌；2.此牌不计入次数限制；均不同，"..
  "此技能本回合失效。",

  ["zhidui_times"] = "此牌不计入次数",

  ["$zhidui1"] = "",
  ["$zhidui2"] = "",
}

zhidui:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhidui.name) then
      local use_events = player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
        return e.id < player.room.logic:getCurrentEvent().id
      end, 0)
      if #use_events > 0 then
        local use = use_events[1].data
        local yes1 = use.card.type == data.card.type
        local yes2 = Fk:translate(use.card.trueName, "zh_CN"):len() == Fk:translate(data.card.trueName, "zh_CN"):len()
        if yes1 and yes2 then
          event:setCostData(self, {choice = 1})
          return true
        elseif not yes1 and not yes2 then
          event:setCostData(self, {choice = "negative"})
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "negative" then
      return true
    else
      choice = room:askToChoice(player, {
        choices = {"draw2", "zhidui_times", "Cancel"},
        skill_name = zhidui.name,
      })
      if choice ~= "Cancel" then
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhidui.name)
    local choice = event:getCostData(self).choice
    if choice == "negative" then
      room:notifySkillInvoked(player, zhidui.name, "negative")
      room:invalidateSkill(player, zhidui.name, "-turn")
    elseif choice == "draw2" then
      room:notifySkillInvoked(player, zhidui.name, "drawcard")
      player:drawCards(2, zhidui.name)
    elseif choice == "zhidui_times" then
      room:notifySkillInvoked(player, zhidui.name, "offensive")
      if not data.extraUse then
        player:addCardUseHistory(data.card.trueName, -1)
        data.extraUse = true
      end
    end
  end,
})

return zhidui
