local ty_ex__qiuyuan = fk.CreateSkill {
  name = "ty_ex__qiuyuan"
}

Fk:loadTranslationTable{
  ['ty_ex__qiuy__an'] = '求援',
  ['#ty_ex__qiuyuan-choose'] = '求援：令另一名其他角色交给你一张不为【杀】的基本牌，否则其成为此【杀】额外目标',
  ['#ty_ex__qiuyuan-give'] = '求援：交给 %dest 一张不为【杀】的基本牌，否则成为此【杀】额外目标且不能响应此【杀】',
  [':ty_ex__qiuyuan'] = '当你成为【杀】的目标时，你可以令另一名其他角色交给你一张除【杀】以外的基本牌，否则也成为此【杀】的目标且不能响应此【杀】。',
  ['$ty_ex__qiuyuan1'] = '陛下，我不想离开。',
  ['$ty_ex__qiuyuan2'] = '将军此事，可有希望。',
}

ty_ex__qiuyuan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty_ex__qiuyuan.name) and data.card.trueName == "slash" then
      local tos = AimGroup:getAllTargets(data.tos)
      return table.find(player.room:getOtherPlayers(player), function(p)
        return p.id ~= data.from and not table.contains(tos, p.id) and not target:isProhibited(player, data.card)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p.id ~= data.from and not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not target:isProhibited(player, data.card)
    end)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty_ex__qiuyuan-choose",
        skill_name = ty_ex__qiuyuan.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, to[1].id)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toId = event:getCostData(self)
    local to = room:getPlayerById(toId)
    -- FIXME: fix exppattern
    local cards = table.filter(to:getCardIds("he"), function(id) return Fk:getCardById(id).type == Card.TypeBasic and Fk:getCardById(id).trueName ~= "slash" end)
    if #cards > 0 then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|.|.|." .. table.concat(cards, ","),
        prompt = "#ty_ex__qiuyuan-give::" .. player.id,
        skill_name = ty_ex__qiuyuan.name,
        cancelable = true
      })
      if #card > 0 then
        room:obtainCard(player, Fk:getCardById(card[1]), true, fk.ReasonGive, toId)
        return
      end
    end
    AimGroup:addTargets(room, data, toId)
    AimGroup:setTargetDone(data.tos, toId)
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local _data = e.data[1]
      _data.disresponsiveList = _data.disresponsiveList or {}
      table.insertIfNeed(_data.disresponsiveList, toId)
    end
  end,
})

return ty_ex__qiuyuan
