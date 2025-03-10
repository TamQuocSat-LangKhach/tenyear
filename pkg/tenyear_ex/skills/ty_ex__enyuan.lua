local ty_ex__enyuan = fk.CreateSkill {
  name = "ty_ex__enyuan"
}

Fk:loadTranslationTable{
  ['ty_ex__enyuan'] = '恩怨',
  ['#ty_ex__enyuan-en-invoke'] = '恩怨：你可以令 %dest 摸一张牌',
  ['#ty_ex__enyuan-yuan-invoke'] = '是否对 %dest 发动 恩怨',
  ['#ty_ex__enyuan-give'] = '恩怨：你需交给 %src 一张手牌，否则失去1点体力',
  [':ty_ex__enyuan'] = '当你得到一名其他角色的牌后，若这些牌数大于1，你可以令其摸一张牌；当你受到1点伤害后，你可以令来源选择：1.将一张手交给你，若不为<font color=>♥</font>，你摸一张牌；2.失去1点体力。',
  ['$ty_ex__enyuan1'] = '善因得善果，恶因得恶报！',
  ['$ty_ex__enyuan2'] = '私我者赠之琼瑶，厌我者报之斧钺！',
}

ty_ex__enyuan:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__enyuan) then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
        if not player.dead and not player.room:getPlayerById(move.from).dead then
          self:doCost(event, target, player, {move.from})
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__enyuan.name,
      prompt = "#ty_ex__enyuan-en-invoke::" .. data[1]
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty_ex__enyuan.name)
    room:notifySkillInvoked(player, ty_ex__enyuan.name, "support")
    room:doIndicate(player.id, {data[1]})
    room:getPlayerById(data[1]):drawCards(1, ty_ex__enyuan.name)
  end,
})

ty_ex__enyuan:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__enyuan) then
      return target == player and data.from and not data.from.dead
    end
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if i > 1 and (data.from.dead or not player:hasSkill(ty_ex__enyuan)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__enyuan.name,
      prompt = "#ty_ex__enyuan-yuan-invoke::" .. data.from.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty_ex__enyuan.name)
    room:notifySkillInvoked(player, ty_ex__enyuan.name, "masochism")
    room:doIndicate(player.id, {data.from.id})
    if player == data.from then
      room:loseHp(player, 1, ty_ex__enyuan.name)
    else
      local card = room:askToCards(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = ty_ex__enyuan.name,
        cancelable = true,
        pattern = ".|.|.|hand|.|.",
        prompt = "#ty_ex__enyuan-give:" .. player.id
      })
      if #card > 0 then
        local suit = Fk:getCardById(card[1]).suit
        room:obtainCard(player, card[1], false, fk.ReasonGive, data.from.id)
        if suit ~= Card.Heart then
          player:drawCards(1, ty_ex__enyuan.name)
        end
      else
        room:loseHp(data.from, 1, ty_ex__enyuan.name)
      end
    end
  end,
})

return ty_ex__enyuan
