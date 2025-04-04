local xizhen = fk.CreateSkill {
  name = "xizhen",
}

Fk:loadTranslationTable{
  ["xizhen"] = "袭阵",
  [":xizhen"] = "出牌阶段开始时，你可以选择一名其他角色，视为对其使用【杀】或【决斗】，然后本阶段你的牌每次被使用或打出牌响应时，"..
  "该角色回复1点体力，你摸一张牌（若其未受伤，改为两张）。",

  ["#xizhen-choose"] = "袭阵：视为对一名角色使用【杀】或【决斗】，本阶段你的牌被响应时其回复体力，你摸牌",
  ["#xizhen-choice"] = "袭阵：选择视为对 %dest 使用的牌",

  ["$xizhen1"] = "今我为刀俎，尔等皆为鱼肉。",
  ["$xizhen2"] = "先发可制人，后发制于人。",
}

xizhen:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xizhen.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true}) or
          player:canUseTo(Fk:cloneCard("duel"), p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true}) or
        player:canUseTo(Fk:cloneCard("duel"), p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xizhen-choose",
      skill_name = xizhen.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(player, "xizhen-phase", to.id)
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if player:canUseTo(Fk:cloneCard(name), to, {bypass_distances = true, bypass_times = true}) then
        table.insert(choices, name)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xizhen.name,
      prompt = "#xizhen-choice::"..to.id,
    })
    room:useVirtualCard(choice, nil, player, to, xizhen.name, true)
  end,
})

local spec = {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("xizhen-phase") ~= 0 and data.responseToEvent and data.responseToEvent.from == player and
      not player.room:getPlayerById(player:getMark("xizhen-phase")).dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {player:getMark("xizhen-phase")}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("xizhen-phase"))
    if to:isWounded() then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = xizhen.name,
      }
      if not player.dead then
        player:drawCards(1, xizhen.name)
      end
    else
      player:drawCards(2, xizhen.name)
    end
  end,
}

xizhen:addEffect(fk.CardUsing, spec)
xizhen:addEffect(fk.CardResponding, spec)

return xizhen
