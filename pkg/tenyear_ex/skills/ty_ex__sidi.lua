local ty_ex__sidi = fk.CreateSkill {
  name = "ty_ex__sidi"
}

Fk:loadTranslationTable{
  ['ty_ex__sidi'] = '司敌',
  ['#ty_ex__sidi-put'] = '司敌：可以将一张非基本牌置于武将牌上，称为“司”',
  ['#ty_ex__sidi-invoke'] = '司敌：可以移去一张“司”，令 %dest 此阶段不能使用或打出与此“司”颜色相同的牌',
  ['@ty_ex__sidi-phase'] = '司敌',
  [':ty_ex__sidi'] = '结束阶段，你可以将一张非基本牌置于武将牌上，称为“司”。其他角色的出牌阶段开始时，你可以移去一张“司”，令其于此阶段不能使用或打出与此“司”颜色相同的牌，此阶段结束时，若其没有使用过：【杀】，你视为对其使用一张【杀】；锦囊牌，你摸两张牌。',
  ['$ty_ex__sidi1'] = '总算困住你了！',
  ['$ty_ex__sidi2'] = '你出得了手吗？'
}

ty_ex__sidi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "ty_ex__sidi",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      if target == player then
        return player.phase == Player.Finish and not player:isNude()
      else
        return target.phase == Player.Play and #player:getPile(ty_ex__sidi.name) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|.|.|trick,equip",
        prompt = "#ty_ex__sidi-put"
      })
      if #card > 0 then
        event:setCostData(skill, card)
        return true
      end
    else
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|ty_ex__sidi|.|.",
        prompt = "#ty_ex__sidi-invoke::"..target.id,
        skill_name = ty_ex__sidi.name
      })
      if #card > 0 then
        event:setCostData(skill, card)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      player:addToPile(ty_ex__sidi.name, event:getCostData(skill)[1], true, ty_ex__sidi.name)
    else
      room:doIndicate(player.id, {target.id})
      local color = Fk:getCardById(event:getCostData(skill)[1]):getColorString()
      room:moveCards({
        from = player.id,
        ids = event:getCostData(skill),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = ty_ex__sidi.name,
        specialName = ty_ex__sidi.name,
      })
      room:addTableMark(target, "@ty_ex__sidi-phase", color)
      room:setPlayerMark(player, "ty_ex__sidi_victim-phase", target.id)
    end
  end,
})

ty_ex__sidi:addEffect('prohibit', {
  name = "#ty_ex__sidi_prohibit",
  prohibit_response = function(self, player, card)
    local mark = player:getTableMark("@ty_ex__sidi-phase")
    return table.contains(mark, card:getColorString())
  end,
  prohibit_use = function(self, player, card)
    local mark = player:getTableMark("@ty_ex__sidi-phase")
    return table.contains(mark, card:getColorString())
  end,
})

ty_ex__sidi:addEffect(fk.EventPhaseEnd, {
  name = "#ty_ex__sidi_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and player:getMark("ty_ex__sidi_victim-phase") == target.id and target.phase == Player.Play then
      local trick,slash = true,true
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == target.id then
          if use.card.type == Card.TypeTrick then
            trick = false
          elseif use.card.trueName == "slash" then
            slash = false
          end
        end
        return false
      end, Player.HistoryPhase)
      if trick or slash then
        event:setCostData(skill, {trick = trick, slash = slash})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(skill).slash and not target.dead then
      room:useVirtualCard("slash", nil, player, target, "ty_ex__sidi", true)
    end
    if event:getCostData(skill).trick and not player.dead then
      player:drawCards(2, ty_ex__sidi.name)
    end
  end,
})

return ty_ex__sidi
