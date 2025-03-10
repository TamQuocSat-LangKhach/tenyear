local tongli = fk.CreateSkill {
  name = "tongli"
}

Fk:loadTranslationTable{
  ['tongli'] = '同礼',
  ['@tongli-phase'] = '同礼',
  ['#tongli_delay'] = '同礼',
  [':tongli'] = '当你于出牌阶段内使用基本牌或普通锦囊牌指定目标后，若你于此阶段内拥有此技能时使用过牌的次数为X，你可以令你于此牌结算后视为对包含此牌的所有原本目标在内的角色使用X次牌名相同的牌。（X为你手牌中的花色数，包含无色）',
  ['$tongli1'] = '胞妹殊礼，妾幸同之。',
  ['$tongli2'] = '夫妻之礼，举案齐眉。',
}

tongli:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tongli.name) and player.phase == Player.Play and data.firstTarget and
      data.extra_data and data.extra_data.tongli_target and
      not table.contains(data.card.skillNames, tongli.name) and player:getMark("@tongli-phase") > 0 and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not (table.contains({"peach", "analeptic"}, data.card.trueName) and
      table.find(player.room.alive_players, function(p) return p.dying end)) then
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      return #suits == player:getMark("@tongli-phase")
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.tongli = {
      from = player.id,
      tos = data.extra_data.tongli_target,
      times = player:getMark("@tongli-phase")
    }
  end
})

tongli:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(tongli.name, true) and player.phase == Player.Play and
      not table.contains(data.card.skillNames, tongli.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@tongli-phase", 1)
    if type(data.tos) == "table" then
      data.extra_data = data.extra_data or {}
      data.extra_data.tongli_target = table.simpleClone(data.tos)
    end
  end,
})

tongli:on_lose(function(skill, player)
  player.room:setPlayerMark(player, "@tongli-phase", 0)
end)

local tongli_delay = fk.CreateTriggerSkill{
  name = "#tongli_delay",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.tongli and not player.dead then
      local dat = table.simpleClone(data.extra_data.tongli)
      if dat.from == player.id then
        local use = parseTongliUseStruct(player, data.card.name, dat.tos)
        if use then
          event:setCostData(skill, use)
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local dat = table.simpleClone(data.extra_data.tongli)
    local use = table.simpleClone(event:getCostData(skill))
    local room = player.room
    player:broadcastSkillInvoke("tongli")
    for _ = 1, dat.times, 1 do
      room:useCard(use)
      if player.dead then break end
      use = parseTongliUseStruct(player, data.card.name, dat.tos)
      if use == nil then break end
    end
  end,
}

tongli:addRelatedSkill(tongli_delay)

return tongli
