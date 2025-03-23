local xizhen = fk.CreateSkill {
  name = "xizhen"
}

Fk:loadTranslationTable{
  ['xizhen'] = '袭阵',
  ['#xizhen-choose'] = '袭阵：视为对一名角色使用【杀】或【决斗】，本阶段你的牌被响应时其回复1点体力，你摸一张牌（若其未受伤则改为两张）',
  ['#xizhen-choice'] = '袭阵：选择视为对 %dest 使用的牌',
  ['#xizhen_trigger'] = '袭阵',
  [':xizhen'] = '出牌阶段开始时，你可选择一名其他角色，视为对其使用【杀】或【决斗】，然后本阶段你的牌每次被使用或打出牌响应时，该角色回复1点体力，你摸一张牌（若其未受伤，改为两张）。',
  ['$xizhen1'] = '今我为刀俎，尔等皆为鱼肉。',
  ['$xizhen2'] = '先发可制人，后发制于人。',
}

-- 主技能
xizhen:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xizhen.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function (p)
        return not (player:isProhibited(p, Fk:cloneCard("slash")) and player:isProhibited(p, Fk:cloneCard("duel")))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return not (player:isProhibited(p, Fk:cloneCard("slash")) and player:isProhibited(p, Fk:cloneCard("duel")))
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xizhen-choose",
      skill_name = xizhen.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local to = room:getPlayerById(cost_data.tos[1])
    room:setPlayerMark(player, "xizhen-phase", to.id)
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if not player:isProhibited(to, Fk:cloneCard(name)) then
        table.insert(choices, name)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xizhen.name,
      prompt = "#xizhen-choice::"..to.id
    })
    room:useVirtualCard(choice, nil, player, to, xizhen.name, true)
  end,
})

-- 触发技
xizhen:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("xizhen-phase") ~= 0 and player.data.responseToEvent and player.data.responseToEvent.from == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("xizhen-phase"))
    if not to.dead then
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
    end
  end,
})

xizhen:addEffect(fk.CardResponding, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("xizhen-phase") ~= 0 and player.data.responseToEvent and player.data.responseToEvent.from == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("xizhen-phase"))
    if not to.dead then
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
    end
  end,
})

return xizhen
