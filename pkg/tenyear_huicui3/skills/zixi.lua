local zixi = fk.CreateSkill {
  name = "zixi"
}

Fk:loadTranslationTable{
  ['zixi'] = '姊希',
  ['zixi_active'] = '姊希',
  ['#zixi-cost'] = '是否发动 姊希，将一张“琴”放置在一名角色的判定区',
  ['@[zixi]'] = '姊希',
  ['#zixi_delay'] = '姊希',
  ['#zixi_special_rule'] = '姊希',
  [':zixi'] = '出牌阶段开始时和结束时，你可以将一张“琴”放置在一名角色的判定区（牌名当做【兵粮寸断】、【乐不思蜀】或【闪电】使用，且判定阶段不执行效果）。你使用基本牌或普通锦囊牌指定唯一目标后，可根据其判定区里的牌数执行：1张：此牌结算后，你视为对其使用一张牌名相同的牌；2张：你摸2张牌；3张：弃置其判定区里的所有牌，对其造成3点伤害。',
  ['$zixi1'] = '日暮飞伯劳，倦梳头，坐看鸥鹭争舟。',
  ['$zixi2'] = '姊折翠柳寄江北，念君心悠悠。',
}

zixi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if not player or not player:hasSkill(zixi.name) then return false end
    return player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "zixi_active",
      prompt = "#zixi-cost",
      cancelable = true,
    })
    if dat then
      event:setCostData(skill.name, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(skill.name))
    local to = room:getPlayerById(dat.targets[1])
    local card = Fk:cloneCard(dat.interaction)
    card:addSubcard(dat.cards[1])
    card.skillName = zixi.name
    to:addVirtualEquip(card)
    room:moveCardTo(card, Player.Judge, to, fk.ReasonJustMove, zixi.name)
  end,
})

zixi:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if not player or not player:hasSkill(zixi.name) then return false end
    return player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "zixi_active",
      prompt = "#zixi-cost",
      cancelable = true,
    })
    if dat then
      event:setCostData(skill.name, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(skill.name))
    local to = room:getPlayerById(dat.targets[1])
    local card = Fk:cloneCard(dat.interaction)
    card:addSubcard(dat.cards[1])
    card.skillName = zixi.name
    to:addVirtualEquip(card)
    room:moveCardTo(card, Player.Judge, to, fk.ReasonJustMove, zixi.name)
  end,
})

zixi:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if not player or not player:hasSkill(zixi.name) then return false end
    local to = player.room:getPlayerById(data.to)
    local x = #to:getCardIds(Player.Judge)
    if (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not table.contains(data.card.skillNames, zixi.name) then
      return U.isOnlyTarget(to, data, event) and (x > 0 and x < 4)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local x = #to:getCardIds(Player.Judge)
    if room:askToSkillInvoke(player, {
      skill_name = zixi.name,
      prompt = "#zixi-invoke" .. tostring(x) .. "::" .. data.to .. ":" .. data.card:toLogString(),
    }) then
      room:doIndicate(player.id, {data.to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local x = #to:getCardIds(Player.Judge)
    if x == 1 then
      data.extra_data = data.extra_data or {}
      data.extra_data.zixi = {
        from = player.id,
        to = data.to,
        subTargets = data.subTargets
      }
    elseif x == 2 then
      room:drawCards(player, 2, zixi.name)
    elseif x == 3 then
      to:throwAllCards("j")
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 3,
          skillName = zixi.name,
        }
      end
    end
  end,
})

zixi:addEffect(fk.AfterCardsMove, {
  can_trigger = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, id in ipairs(player:getCardIds(Player.Judge)) do
      local zixi_card = player:getVirualEquip(id)
      if zixi_card and table.contains(zixi_card.skillNames, "zixi") then
        table.insert(mark, {id, zixi_card.trueName})
      end
    end
    local old_mark = player:getMark("@[zixi]")
    if #mark == 0 then
      if old_mark ~= 0 then
        room:setPlayerMark(player, "@[zixi]", 0)
      end
      return false
    end
    if type(old_mark) ~= "table" or #mark ~= #old_mark then
      room:setPlayerMark(player, "@[zixi]", mark)
    end
  end,
})

zixi:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.zixi and not player.dead then
      local use = table.simpleClone(data.extra_data.zixi)
      if use.from == player.id then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = zixi.name
        if player:prohibitUse(card) then return false end
        use.card = card
        local room = player.room
        local to = room:getPlayerById(use.to)
        if not to.dead and U.canTransferTarget(to, use, false) then
          local tos = {use.to}
          if use.subTargets then
            table.insertTable(tos, use.subTargets)
          end
          event:setCostData(skill.name, {
            from = player.id,
            tos = table.map(tos, function(pid) return { pid } end),
            card = card,
            extraUse = true
          })
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:useCard(table.simpleClone(event:getCostData(skill.name)))
  end,
})

zixi:addEffect(fk.EventPhaseStart, {
  mute = true,
  priority = 0, -- game rule
  can_trigger = function(self, event, target, player, data)
    return player.phase == Player.Judge
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Judge)
    for i = #cards, 1, -1 do
      if table.contains(player:getCardIds(Player.Judge), cards[i]) then
        local zixi_card = player:getVirualEquip(cards[i])
        if zixi_card == nil or not table.contains(zixi_card.skillNames, "zixi") then
          local card
          card = player:removeVirtualEquip(cards[i])
          if not card then
            card = Fk:getCardById(cards[i])
          end

          room:moveCardTo(card, Card.Processing, nil, fk.ReasonPut, "game_rule")

          ---@type CardEffectEvent
          local effect_data = {
            card = card,
            to = player.id,
            tos = { {player.id} },
          }
          room:doCardEffect(effect_data)
          if effect_data.isCancellOut and card.skill then
            card.skill:onNullified(room, effect_data)
          end
        end
      end
    end
  end,
})

return zixi
