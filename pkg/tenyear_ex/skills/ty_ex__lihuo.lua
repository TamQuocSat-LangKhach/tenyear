local ty_ex__lihuo = fk.CreateSkill {
  name = "ty_ex__lihuo"
}

Fk:loadTranslationTable{
  ['ty_ex__lihuo'] = '疬火',
  ['#ty_ex__lihuo1-invoke'] = '疬火：是否将%arg改为火【杀】？',
  ['#ty_ex__lihuo2-invoke'] = '疬火：你可以将%arg置为“醇”',
  ['ty_ex__chengpu_chun'] = '醇',
  ['#ty_ex__lihuo_record'] = '疬火（失去体力）',
  [':ty_ex__lihuo'] = '你使用普通【杀】可以改为火【杀】，结算后若此法使用的【杀】造成了伤害，你失去1点体力；你使用火【杀】时，可以增加一个目标。你于一个回合内使用的第一张牌结算后，若此牌为【杀】，你可以将之置为“醇”。',
  ['$ty_ex__lihuo1'] = '叛军者，非烈火灼身难泄吾恨。',
  ['$ty_ex__lihuo2'] = '投敌于火，烧炙其身，皮焦肉烂！',
}

ty_ex__lihuo:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(ty_ex__lihuo.name) then
      local data = player.room:getCurrentEvent().data[1]
      return data.card.name == "slash"
    end
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__lihuo.name,
      prompt = "#ty_ex__lihuo1-invoke:::"..player.room:getCurrentEvent().data[1].card:toLogString()
    })
  end,
  on_use = function(self, event, target, player)
    local data = player.room:getCurrentEvent().data[1]
    local card = Fk:cloneCard("fire__slash", data.card.suit, data.card.number)
    for k, v in pairs(data.card) do
      if card[k] == nil then
        card[k] = v
      end
    end
    if data.card:isVirtual() then
      card.subcards = data.card.subcards
    else
      card.id = data.card.id
    end
    card.skillNames = data.card.skillNames
    data.card = card
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__lihuo = data.extra_data.ty_ex__lihuo or {}
    table.insert(data.extra_data.ty_ex__lihuo, player.id)
  end,
})

ty_ex__lihuo:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(ty_ex__lihuo.name) then
      local data = player.room:getCurrentEvent().data[1]
      return data.card.name == "fire__slash" and #player.room:getUseExtraTargets(data) > 0
    end
  end,
  on_cost = function(self, event, target, player)
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room:getUseExtraTargets(event.data[1]),
      min_num = 1,
      max_num = 1,
      prompt = "#lihuo-choose:::"..player.room:getCurrentEvent().data[1].card:toLogString(),
      skill_name = ty_ex__lihuo.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(skill, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local data = player.room:getCurrentEvent().data[1]
    table.insert(data.tos, event:getCostData(skill))
  end,
})

ty_ex__lihuo:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(ty_ex__lihuo.name) then
      local data = player.room:getCurrentEvent().data[1]
      return data.card.trueName ~= "slash" and #player.room:getUseExtraTargets(data) > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
    if #cardlist ~= 1 or Fk:getCardById(cardlist[1], true).trueName ~= "slash" then return end
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark = player:getMark("ty_ex__lihuo_record-turn")
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data[1]
        if last_use.from == player.id then
          mark = e.id
          room:setPlayerMark(player, "ty_ex__lihuo_record-turn", mark)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    if mark == use_event.id then
      player:addToPile("ty_ex__chengpu_chun", data.card, true, ty_ex__lihuo.name)
    end
  end,
})

local ty_ex__lihuo_record = fk.CreateSkill {
  name = "#ty_ex__lihuo_record"
}

ty_ex__lihuo_record:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player)
    return not player.dead and player.room:getCurrentEvent().data[1].damageDealt and
      player.room:getCurrentEvent().data[1].extra_data and
      player.room:getCurrentEvent().data[1].extra_data.ty_ex__lihuo and
      table.contains(player.room:getCurrentEvent().data[1].extra_data.ty_ex__lihuo, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    player.room:loseHp(player, 1, "ty_ex__lihuo")
  end,
})

return ty_ex__lihuo, ty_ex__lihuo_record
