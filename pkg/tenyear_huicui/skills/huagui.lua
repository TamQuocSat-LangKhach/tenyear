local huagui = fk.CreateSkill {
  name = "huagui",
}

Fk:loadTranslationTable{
  ["huagui"] = "化归",
  [":huagui"] = "出牌阶段开始时，你可以秘密选择至多X名其他角色（X为最大阵营存活人数），这些角色同时选择：1.交给你一张牌；"..
  "2.展示一张牌。若均选择展示牌，你获得这些牌。",

  ["#huagui-choose"] = "化归：你可以秘密选择至多%arg名角色，各选择交给你一张牌或展示一张牌",
  ["#huagui-ask"] = "化归：选择一张牌，交给 %src 或展示之",

  ["$huagui1"] = "烈不才，难为君之朱紫。",
  ["$huagui2"] = "一身风雨，难坐高堂。",
}

huagui:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huagui.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)

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
      prompt = "#huagui-choose:::"..n,
      skill_name = huagui.name,
      cancelable = true,
      no_indicate = true,
    })

    if #tos > 0 then
      event:setCostData(self, {extra_data = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).extra_data

    local req = Request:new(tos, "AskForUseActiveSkill")
    req.focus_text = huagui.name
    req.focus_players = room:getOtherPlayers(player, false)
    local extraData = {
      "huagui_active",
      "#huagui-ask:"..player.id,
      false,
      {},
    }
    for _, p in ipairs(tos) do
      req:setData(p, extraData)
    end
    req:ask()

    local dat = {}
    for _, p in ipairs(tos) do
      local result = req:getResult(p)
      if result ~= "" then
        dat[p] = {
          cards = result.card.subcards,
          choice = result.interaction_data,
        }
      else
        dat[p] = {
          cards = table.random(p:getCardIds("he"), 1),
          choice = "give",
        }
      end
    end

    local moves = {}
    room:sortByAction(tos)
    for _, p in ipairs(tos) do
      if dat[p].choice == "give" then
        table.insert(moves, {
          ids = dat[p].cards,
          from = p,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          skillName = huagui.name,
          moveVisible = false,
          proposer = p,
        })
      else
        p:showCards(dat[p].cards)
      end
    end
    if #moves > 0 then
      room:moveCards(table.unpack(moves))
    else
      for _, p in ipairs(tos) do
        table.insert(moves, {
          ids = dat[p].cards,
          from = p,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          skillName = huagui.name,
          moveVisible = true,
          proposer = player,
        })
      end
      room:moveCards(table.unpack(moves))
    end
  end,
})

return huagui
