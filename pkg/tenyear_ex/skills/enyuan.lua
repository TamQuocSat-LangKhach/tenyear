local enyuan = fk.CreateSkill {
  name = "ty_ex__enyuan",
}

Fk:loadTranslationTable{
  ["ty_ex__enyuan"] = "恩怨",
  [":ty_ex__enyuan"] = "当你得到一名其他角色至少两张牌后，你可以令其摸一张牌；当你受到1点伤害后，伤害来源选择一项：2.交给你一张手牌，"..
  "若不为<font color='red'>♥</font>，你摸一张牌；2.失去1点体力。",

  ["#ty_ex__enyuan-draw"] = "恩怨：你可以令 %dest 摸一张牌",
  ["#ty_ex__enyuan-give"] = "恩怨：交给 %src 一张手牌，否则失去1点体力",

  ["$ty_ex__enyuan1"] = "善因得善果，恶因得恶报！",
  ["$ty_ex__enyuan2"] = "私我者赠之琼瑶，厌我者报之斧钺！",
}

enyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(enyuan.name) then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player and move.to == player and move.toArea == Card.PlayerHand and
         #move.moveInfo > 1 and not move.from.dead then
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = {}
    for _, move in ipairs(data) do
      if move.from and move.from ~= player and move.to == player and move.toArea == Card.PlayerHand and
        #move.moveInfo > 1 and not move.from.dead then
        table.insertIfNeed(targets, move.from)
      end
    end
    player.room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(enyuan.name) then break end
      if not p.dead then
        event:setCostData(self, {tos = {p}})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    return player.room:askToSkillInvoke(player, {
      skill_name = enyuan.name,
      prompt = "#ty_ex__enyuan-draw::"..to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    to:drawCards(1, enyuan.name)
  end,
})

enyuan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(enyuan.name) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, {tos = {data.from}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player == data.from then
      room:loseHp(player, 1, enyuan.name)
    else
      local card = room:askToCards(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = enyuan.name,
        cancelable = true,
        pattern = ".|.|.|hand",
        prompt = "#ty_ex__enyuan-give:" .. player.id,
      })
      if #card > 0 then
        local suit = Fk:getCardById(card[1]).suit
        room:obtainCard(player, card, false, fk.ReasonGive, data.from, enyuan.name)
        if not player.dead and suit ~= Card.Heart then
          player:drawCards(1, enyuan.name)
        end
      else
        room:loseHp(data.from, 1, enyuan.name)
      end
    end
  end,
})

return enyuan
