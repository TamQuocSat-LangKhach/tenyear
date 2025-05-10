local tongli = fk.CreateSkill {
  name = "tongli",
}

Fk:loadTranslationTable{
  ["tongli"] = "同礼",
  [":tongli"] = "当你于出牌阶段内使用基本牌或普通锦囊牌指定目标后，若你此阶段已使用牌数为X，你可以令你于此牌结算后视为对"..
  "包含此牌的所有原本目标在内的角色依次使用X次牌名相同的牌。（X为你手牌中的花色数，包含无色）",

  ["@tongli-phase"] = "同礼",

  ["$tongli1"] = "胞妹殊礼，妾幸同之。",
  ["$tongli2"] = "夫妻之礼，举案齐眉。",
}

tongli:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tongli.name) and player.phase == Player.Play and data.firstTarget and
      data.extra_data and data.extra_data.tongli_tos and
      not table.contains(data.card.skillNames, tongli.name) and player:getMark("@tongli-phase") > 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not (table.contains({"peach", "analeptic"}, data.card.trueName) and
      table.find(player.room.alive_players, function(p)
        return p.dying
      end)) then
      local suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      return #suits == player:getMark("@tongli-phase")
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.tongli = {
      card = data.card,
      from = player,
      tos = data.extra_data.tongli_tos,
      subTos = data.extra_data.tongli_subTos,
      times = player:getMark("@tongli-phase"),
    }
  end
})

tongli:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongli.name) and player.phase == Player.Play and
      not table.contains(data.card.skillNames, tongli.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@tongli-phase", 1)
    if type(data.tos) == "table" then
      data.extra_data = data.extra_data or {}
      data.extra_data.tongli_tos = table.simpleClone(data.tos)
      data.extra_data.tongli_subTos = data.subTos and table.simpleClone(data.subTos) or nil
    end
  end,
})

local parseTongliUseStruct = function (player, data)
  local card = Fk:cloneCard(data.card.name)
  card.skillName = tongli.name
  if player:prohibitUse(card) then return nil end
  local all_tos = {}
  for _, target in ipairs(data.tos) do
    local passed_target = {}
    if target.dead then return nil end
    if #passed_target == 0 and player:isProhibited(target, card) then return nil end
    if data.subTos then
      if table.find(data.subTos, function(p)
        return p.dead
      end) then
        return nil
      else
        local subTo = data:getSubTos(target)
        if not card.skill:modTargetFilter(player, subTo, {target}, card) then return nil end
      end
    else
      if not card.skill:modTargetFilter(player, target, passed_target, card) then return nil end
    end
    table.insert(passed_target, target)
    table.insert(all_tos, target)
  end
  if card.multiple_targets and card.skill:getMinTargetNum(player) == 0 then
    all_tos = card:getAvailableTargets(player, {bypass_distances = true, bypass_times = true})
  end
  return {
    from = player,
    tos = all_tos,
    subTos = data.subTos,
    card = card,
    extraUse = true,
  }
end

tongli:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.tongli and not player.dead then
      local dat = table.simpleClone(data.extra_data.tongli)
      if dat.from == player then
        local use = parseTongliUseStruct(player, dat)
        if use then
          event:setCostData(self, {extra_data = use})
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(data.extra_data.tongli)
    local use = table.simpleClone(event:getCostData(self).extra_data)
    for _ = 1, dat.times, 1 do
      room:useCard(use)
      if player.dead then break end
      use = parseTongliUseStruct(player, dat)
      if use == nil then break end
    end
  end,
})

tongli:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@tongli-phase", 0)
end)

return tongli
