local cilv = fk.CreateSkill {
  name = "cilv",
  dynamic_desc = function (self, player)
    if #player:getTableMark(self.name) == 3 then
      return "dummyskill"
    elseif player:getMark(self.name) ~= 0 then
      local str = {}
      for i = 1, 3, 1 do
        if table.contains(player:getMark(self.name), i) then
          table.insert(str, "<s>"..Fk:translate("cilv"..i).."</s>")
        else
          table.insert(str, Fk:translate("cilv"..i))
        end
      end
      return "cilv_inner:"..table.concat(str, "；")
    end
  end,
}

Fk:loadTranslationTable{
  ["cilv"] = "辞虑",
  [":cilv"] = "当你成为普通锦囊牌的目标后，你可以摸X张牌（X为此技能的剩余选项数），若你的手牌数大于你的体力上限，你选择并移除一项："..
  "1.此牌对你无效；2.此牌造成伤害时防止之；3.此牌结算结束后你获得之。",

  [":cilv_inner"] = "当你成为普通锦囊牌的目标后，你可以摸X张牌（X为此技能的剩余选项数），若你的手牌数大于你的体力上限，你选择并移除一项：{1}。",

  ["#cilv-choose"] = "辞虑：选择一项对%arg执行",
  ["cilv1"] = "此牌对你无效",
  ["cilv2"] = "防止此牌造成伤害",
  ["cilv3"] = "此牌结算后你获得之",

  ["$cilv1"] = "妾一介女流，安知社稷之虑。",
  ["$cilv2"] = "若家国无损、宗庙得续，我无异议。",
}

cilv:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cilv.name) and
      data.card:isCommonTrick() and #player:getTableMark(cilv.name) < 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3 - #player:getTableMark(cilv.name), cilv.name)
    if player.dead or player:getHandcardNum() <= player.maxHp then return end

    local all_choices = {"cilv1", "cilv2", "cilv3"}
    local choices = table.filter({1, 2, 3}, function (i)
      return not table.contains(player:getTableMark(cilv.name), i)
    end)
    if #choices == 0 then return end
    choices = table.map(choices, function (i)
      return "cilv"..i
    end)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = cilv.name,
      prompt = "#cilv-choose:::" .. data.card:toLogString(),
      all_choices = all_choices,
    })
    if player:hasSkill(cilv.name, true) then
      room:addTableMark(player, cilv.name, table.indexOf(all_choices, choice))
    end
    if choice == "cilv1" then
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    elseif choice == "cilv2" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_defensive = player.id
    elseif choice == "cilv3" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_prey = data.extra_data.cilv_prey or {}
      table.insert(data.extra_data.cilv_prey, player.id)
    end
  end,
})

cilv:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, cilv.name, 0)
end)

cilv:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and
      data.extra_data and data.extra_data.cilv_prey and table.contains(data.extra_data.cilv_prey, player.id) and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, cilv.name)
  end,
})

cilv:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return false end
      local use = use_event.data
      return use.extra_data and use.extra_data.cilv_defensive == player.id
    end
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

return cilv
