local huagui = fk.CreateSkill {
  name = "huagui"
}

Fk:loadTranslationTable{
  ['huagui'] = '化归',
  ['#huagui-choose'] = '化归：你可以秘密选择至多%arg名角色，各选择交给你一张牌或展示一张牌',
  ['#huagui-card'] = '化归：选择一张牌，交给 %src 或展示之',
  ['huagui1'] = '交出',
  ['huagui2'] = '展示',
  ['#huagui-choice'] = '化归：选择将%arg交给 %src 或展示之',
  [':huagui'] = '出牌阶段开始时，你可秘密选择至多X名其他角色（X为最大阵营存活人数），这些角色同时选择：若1.将一张牌交给你；2.展示一张牌。均选择展示牌，你获得这些牌。',
  ['$huagui1'] = '烈不才，难为君之朱紫。',
  ['$huagui2'] = '一身风雨，难坐高堂。',
}

huagui:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huagui.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude()
    end), Util.IdMapper)

    if #targets == 0 then return end

    local nums = {0, 0, 0}
    for _, p in ipairs(room.alive_players) do
      if p.role == "lord" or p.role == "loyalist" then
        nums[1] = nums[1] + 1
      elseif p.role == "rebel" then
        nums[2] = nums[2] + 1
      else
        nums[3] = nums[3] + 1
      end
    end

    local n = math.max(table.unpack(nums))
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#huagui-choose:::"..tostring(n),
      skill_name = huagui.name,
      cancelable = true,
      no_indicate = true
    })

    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(event:getCostData(self), function(id) return room:getPlayerById(id) end)
    local other_players = room:getOtherPlayers(player, false)

    local extraData = {
      num = 1,
      min_num = 1,
      include_equip = true,
      pattern = ".",
      reason = huagui.name,
    }

    for _, p in ipairs(tos) do
      p.request_data = json.encode({ "choose_cards_skill", "#huagui-card:"..player.id, false, extraData })
    end

    room:notifyMoveFocus(other_players, huagui.name)
    room:doBroadcastRequest("AskForUseActiveSkill", tos)

    for _, p in ipairs(tos) do
      local id
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        id = replyCard.subcards[1]
      else
        id = table.random(p:getCardIds{Player.Hand, Player.Equip})
      end

      room:setPlayerMark(p, "huagui-phase", id)
    end

    for _, p in ipairs(tos) do
      local id = p:getMark("huagui-phase")
      local choices = {"huagui1"}

      if room:getCardArea(id) == Player.Hand then
        table.insert(choices, "huagui2")
      end

      local card = Fk:getCardById(id)
      p.request_data = json.encode({ choices, choices, huagui.name, "#huagui-choice:"..player.id.."::"..card:toLogString() })
    end

    room:notifyMoveFocus(other_players, huagui.name)
    room:doBroadcastRequest("AskForChoice", tos)

    local get = true
    for _, p in ipairs(tos) do
      local choice

      if p.reply_ready then
        choice = p.client_reply
      else
        choice = "huagui1"
      end

      local card = Fk:getCardById(p:getMark("huagui-phase"))

      if choice == "huagui1" then
        get = false
        room:obtainCard(player, card, false, fk.ReasonGive, p.id)
      else
        p:showCards({card})
      end
    end

    if get then
      room:delay(2000)
    end

    for _, p in ipairs(tos) do
      if get then
        local card = Fk:getCardById(p:getMark("huagui-phase"))
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end

      room:setPlayerMark(p, "huagui-phase", 0)
    end
  end,
})

return huagui
