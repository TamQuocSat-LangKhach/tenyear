local sidi = fk.CreateSkill {
  name = "ty_ex__sidi",
}

Fk:loadTranslationTable{
  ["ty_ex__sidi"] = "司敌",
  [":ty_ex__sidi"] = "结束阶段，你可以将一张非基本牌置于武将牌上，称为“司”。其他角色的出牌阶段开始时，你可以移去一张“司”，"..
  "令其此阶段不能使用或打出与此“司”颜色相同的牌，此阶段结束时，若其没有使用过：【杀】，你视为对其使用一张【杀】；锦囊牌，你摸两张牌。",

  ["#ty_ex__sidi-put"] = "司敌：你可以将一张非基本牌置为“司”",
  ["#ty_ex__sidi-invoke"] = "司敌：你可以移去一张“司”，令 %dest 此阶段不能使用打出颜色相同的牌",
  ["@ty_ex__sidi-phase"] = "司敌",

  ["$ty_ex__sidi1"] = "总算困住你了！",
  ["$ty_ex__sidi2"] = "你出得了手吗？"
}

sidi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "ty_ex__sidi",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sidi.name) and player.phase == Player.Finish and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      skill_name = sidi.name,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = ".|.|.|.|.|^basic",
      prompt = "#ty_ex__sidi-put",
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(sidi.name, event:getCostData(self).cards, true, sidi.name)
  end,
})

sidi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sidi.name) and target ~= player and target.phase == Player.Play and
      #player:getPile(sidi.name) > 0 and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|ty_ex__sidi",
      prompt = "#ty_ex__sidi-invoke::"..target.id,
      skill_name = sidi.name,
      expand_pile = sidi.name,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local color = Fk:getCardById(event:getCostData(self).cards[1]):getColorString()
    room:moveCards({
      from = player,
      ids = event:getCostData(self).cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = sidi.name,
    })
    if not target.dead then
      room:addTableMarkIfNeed(target, "@ty_ex__sidi-phase", color)
    end
  end,
})

sidi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ty_ex__sidi-phase"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ty_ex__sidi-phase"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0
    end
  end,
})

sidi:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("#ty_ex__sidi_2_trig", Player.HistoryPhase) > 0 and not player.dead and not target.dead then
      local trick, slash = true, true
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == target then
          if use.card.type == Card.TypeTrick then
            trick = false
          elseif use.card.trueName == "slash" then
            slash = false
          end
        end
      end, Player.HistoryPhase)
      if trick or slash then
        event:setCostData(self, {trick = trick, slash = slash})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).slash and not target.dead then
      room:useVirtualCard("slash", nil, player, target, sidi.name, true)
    end
    if event:getCostData(self).trick and not player.dead then
      player:drawCards(2, sidi.name)
    end
  end,
})

return sidi
