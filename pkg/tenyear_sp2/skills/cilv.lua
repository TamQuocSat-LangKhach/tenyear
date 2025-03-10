local cilv = fk.CreateSkill {
  name = "cilv"
}

Fk:loadTranslationTable{
  ['cilv'] = '辞虑',
  ['cilv1'] = '此牌对你无效',
  ['cilv2'] = '防止此牌造成伤害',
  ['cilv3'] = '此牌结算后你获得之',
  ['#cilv-choose'] = '辞虑：选择一项对%arg执行，然后移除此项',
  ['#cilv_delay'] = '辞虑',
  [':cilv'] = '当你成为普通锦囊牌的目标后，你可以摸X张牌（X为此技能的剩余选项数），若你的手牌数大于你的体力上限，你选择并移除一项：1.此牌对你无效；2.此牌造成伤害时防止之；3.此牌结算结束后你获得之。',
  ['$cilv1'] = '妾一介女流，安知社稷之虑。',
  ['$cilv2'] = '若家国无损、宗庙得续，我无异议。',
}

cilv:addEffect(fk.TargetConfirmed, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card:isCommonTrick() and not table.every({1,2,3}, function (i)
      return player:getMark("cilv" .. tostring(i)) > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = table.filter({1,2,3}, function (i)
      return player:getMark("cilv" .. tostring(i)) == 0
    end)
    player:drawCards(#nums, skill.name)
    if player.dead or player:getHandcardNum() <= player.maxHp then return false end
    local all_choices = {"cilv1", "cilv2", "cilv3"}
    local choices = table.filter(all_choices, function (choice)
      return player:getMark(choice) == 0
    end)
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skill.name,
      prompt = "#cilv-choose:::" .. data.card:toLogString(),
      all_choices = all_choices
    })
    room:setPlayerMark(player, choice, 1)
    if choice == "cilv1" then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    elseif choice == "cilv2" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_defensive = data.extra_data.cilv_defensive or {}
      table.insert(data.extra_data.cilv_defensive, player.id)
    elseif choice == "cilv3" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_recycle = data.extra_data.cilv_recycle or {}
      table.insert(data.extra_data.cilv_recycle, player.id)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and data == skill.name
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "cilv1", 0)
    room:setPlayerMark(player, "cilv2", 0)
    room:setPlayerMark(player, "cilv3", 0)
  end,
})

cilv:addEffect(fk.CardUseFinished, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    return data.extra_data and data.extra_data.cilv_recycle and table.contains(data.extra_data.cilv_recycle, player.id) and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove, player.id, "cilv")
    else
      return true
    end
  end,
})

cilv:addEffect(fk.DamageCaused, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if data.card then
      local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      local use = card_event.data[1]
      return use.extra_data and use.extra_data.cilv_defensive and table.contains(use.extra_data.cilv_defensive, player.id)
    end
  end,
  on_cost = Util.TrueFunc,
})

return cilv
