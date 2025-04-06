local skill = fk.CreateSkill {
  name = "#siege_engine_skill",
  attached_equip = "siege_engine",
}

Fk:loadTranslationTable{
  ["#siege_engine_skill"] = "大攻车",
  ["#siege_engine-slash"] = "大攻车：你可以视为使用【杀】",
  ["#siege_engine-choose"] = "大攻车：你可以为此【杀】额外指定至多%arg个目标",
}

skill:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = skill.name,
      prompt = "#siege_engine-slash",
      cancelable = true,
      extra_data = {
        bypass_distances = table.find(player:getCardIds("e"), function (id)
          return Fk:getCardById(id).name == "siege_engine" and Fk:getCardById(id):getMark("xianzhu1") > 0
        end) ~= nil,
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

skill:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and
      data.card.trueName == "slash" and table.contains(data.card.skillNames, skill.name) then
      local siege_engine = table.filter(player:getCardIds("e"), function (id)
        return Fk:getCardById(id).name == "siege_engine"
      end)
      if #siege_engine > 0 then
        local bypass_distances = table.find(siege_engine, function (id)
          return Fk:getCardById(id):getMark("xianzhu1") > 0
        end) ~= nil
        return table.find(siege_engine, function (id)
          return Fk:getCardById(id):getMark("xianzhu2") > 0
        end) and #data:getExtraTargets({bypass_distances = bypass_distances}) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    local bypass_distances = false
    for _, id in ipairs(player:getCardIds("e")) do
      local card = Fk:getCardById(id)
      if card.name == "siege_engine" then
        n = n + card:getMark("xianzhu2")
        if card:getMark("xianzhu1") > 0 then
          bypass_distances = true
        end
      end
    end
    local tos = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets({bypass_distances = bypass_distances}),
      min_num = 1,
      max_num = n,
      prompt = "#siege_engine-choose:::"..n,
      skill_name = skill.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

skill:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return target == player and
      table.contains(data.card.skillNames, skill.name) and
      table.find(player:getCardIds("e"), function (id)
        return Fk:getCardById(id).name == "siege_engine" and Fk:getCardById(id):getMark("xianzhu1") > 0
      end) and
      not data.to.dead
  end,
  on_refresh = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and table.contains(data.card.skillNames, skill.name) and
      player.room.logic:damageByCardEffect() and not data.to.dead and not data.to:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1
    for _, id in ipairs(player:getCardIds("e")) do
      if Fk:getCardById(id).name == "siege_engine" then
        n = n + Fk:getCardById(id):getMark("xianzhu3")
      end
    end
    local cards = room:askToChooseCards(player, {
      target = data.to,
      min = 1,
      max = n,
      flag = "he",
      skill_name = skill.name,
    })
    room:throwCard(cards, skill.name, data.to, player)
  end,
})

skill:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return table.find(player:getCardIds("e"), function (id)
      return Fk:getCardById(id).name == "siege_engine"
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player and move.toArea ~= Card.Void then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card.name == "siege_engine" and info.fromArea == Card.PlayerEquip then
            if not player.dead and move.moveReason == fk.ReasonDiscard and
              (card:getMark("xianzhu1") + card:getMark("xianzhu2") + card:getMark("xianzhu3")) == 0 then
              player.room:cancelMove(data, {info.cardId})
            end
          end
        end
      end
    end
  end,
})

return skill
