local lihuo = fk.CreateSkill {
  name = "ty_ex__lihuo",
}

Fk:loadTranslationTable{
  ["ty_ex__lihuo"] = "疬火",
  [":ty_ex__lihuo"] = "当你使用普通【杀】时，你可以将此【杀】改为火【杀】，然后此【杀】结算结束后，若此【杀】造成过伤害，你失去1点体力；"..
  "你使用火【杀】可以多选择一个目标。你每回合使用的第一张牌结算后，若此牌为【杀】，你可以将之置为“醇”。",

  ["#ty_ex__lihuo1-invoke"] = "疬火：是否将%arg改为火【杀】，若造成伤害，结算后你失去1点体力",
  ["#ty_ex__lihuo-choose"] = "疬火：你可以为此%arg增加一个目标",
  ["#ty_ex__lihuo2-invoke"] = "疬火：你可以将%arg置为“醇”",

  ["$ty_ex__lihuo1"] = "叛军者，非烈火灼身难泄吾恨。",
  ["$ty_ex__lihuo2"] = "投敌于火，烧炙其身，皮焦肉烂！",
}

lihuo:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lihuo.name) and data.card.name == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lihuo.name,
      prompt = "#ty_ex__lihuo1-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
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
    data.extra_data.ty_ex__lihuo = player
  end,
})

lihuo:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lihuo.name) and data.card.name == "fire__slash" and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__lihuo-choose:::"..data.card:toLogString(),
      skill_name = lihuo.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = {to.id},
      arg = lihuo.name,
      arg2 = data.card:toLogString()
    }
    data:addTarget(to)
  end,
})

lihuo:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.damageDealt and data.extra_data and data.extra_data.ty_ex__lihuo == player then
      return true
    end
    if target == player and player:hasSkill(lihuo.name) and player:hasSkill("ty_ex__chunlao", true) and
      data.card.trueName == "slash" and player.room:getCardArea(data.card) == Card.Processing then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn)
      if #use_events == 1 and use_events[1].data == data then
        event:setCostData(self, {cards = data.card})
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event:getCostData(self) then
      if player.room:askToSkillInvoke(player, {
        skill_name = lihuo.name,
        prompt = "#ty_ex__lihuo2-invoke:::"..data.card:toLogString(),
      }) then
        return true
      end
    end
    event:setCostData(self, nil)
    if data.damageDealt and data.extra_data and data.extra_data.ty_ex__lihuo == player then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self) then
      player:addToPile("ty_ex__chengpu_chun", data.card, true, lihuo.name)
    end
    if not player.dead and data.damageDealt and data.extra_data and data.extra_data.ty_ex__lihuo == player then
      player.room:loseHp(player, 1, lihuo.name)
    end
  end,
})

return lihuo
