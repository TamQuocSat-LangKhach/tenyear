local siegeEngineSkill = fk.CreateSkill {
  name = "#siege_engine_skill"
}

Fk:loadTranslationTable{
  ['#siege_engine_skill'] = '大攻车',
  ['siege_engine'] = '大攻车',
  ['siege_engine_slash'] = '大攻车',
  ['#siege_engine-invoke'] = '大攻车：你可以视为使用【杀】',
}

siegeEngineSkill:addEffect(fk.EventPhaseStart, {
  attached_equip = "siege_engine",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(siegeEngineSkill.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "siege_engine_slash",
      prompt = "#siege_engine-invoke",
      cancelable = true,
    })
    if success then
      event:setCostData(skill, dat)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("slash")
    card.skillName = siegeEngineSkill.name
    room:useCard{
      from = player.id,
      tos = table.map(event:getCostData(skill).targets, function(id) return {id} end),
      card = card,
      extraUse = true,
    }
  end,
})

siegeEngineSkill:addEffect(fk.Damage, {
  attached_equip = "siege_engine",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(siegeEngineSkill.name) and data.card and table.contains(data.card.skillNames, siegeEngineSkill.name) and
      player.room.logic:damageByCardEffect() and not data.to.dead and not data.to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      min_num = 1,
      max_num = 1 + player:getMark("xianzhu3"),
      pattern = "he",
      skill_name = siegeEngineSkill.name,
    })
    room:throwCard(cards, siegeEngineSkill.name, data.to, player)
  end,
})

siegeEngineSkill:addEffect(fk.TargetSpecified, {
  attached_equip = "siege_engine",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(siegeEngineSkill.name) and data.card and table.contains(data.card.skillNames, siegeEngineSkill.name)
      and player:getMark("xianzhu1") > 0
  end,
  on_use = function(self, event, target, player, data)
    room:getPlayerById(data.to):addQinggangTag(data)
  end,
})

siegeEngineSkill:addEffect(fk.BeforeCardsMove, {
  attached_equip = "siege_engine",
  can_trigger = function(self, event, target, player, data)
    return table.find(player:getCardIds("e"), function (id)
      return Fk:getCardById(id).name == "siege_engine"
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mirror_moves = {}
    local to_void, cancel_move = {},{}
    local no_updata = (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) == 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea ~= Card.Void then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id).name == "siege_engine" and info.fromArea == Card.PlayerEquip then
            if not player.dead and no_updata and move.moveReason == fk.ReasonDiscard then
              table.insert(cancel_move, id)
            else
              table.insert(mirror_info, info)
              table.insert(to_void, id)
            end
          else
            table.insert(move_info, info)
          end
        end
        move.moveInfo = move_info
        if #mirror_info > 0 then
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #cancel_move > 0 then
      player.room:sendLog{ type = "#cancelDismantle", card = cancel_move, arg = "#siege_engine_skill" }
    end
    if #to_void > 0 then
      table.insertTable(data, mirror_moves)
      player.room:sendLog{ type = "#destructDerivedCards", card = to_void }
    end
  end,
})

local siegeEngineTargetmod = fk.CreateSkill {
  name = "#siege_engine_targetmod"
}

siegeEngineTargetmod:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card)
    return skill.trueName == "slash_skill" and card and table.contains(card.skillNames, "#siege_engine_skill")
      and player:getMark("xianzhu1") > 0
  end,
  extra_target_func = function(self, player, skill, card)
    if skill.trueName == "slash_skill" and card and table.contains(card.skillNames, "#siege_engine_skill") then
      return player:getMark("xianzhu2")
    end
  end,
})

return siegeEngineSkill, siegeEngineTargetmod
