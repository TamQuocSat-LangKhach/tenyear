local qiuyuan = fk.CreateSkill {
  name = "ty_ex__qiuyuan",
}

Fk:loadTranslationTable{
  ["ty_ex__qiuyuan"] = "求援",
  [":ty_ex__qiuyuan"] = "当你成为【杀】的目标时，你可以令另一名其他角色交给你一张除【杀】以外的基本牌，否则其也成为此【杀】的目标"..
  "且不能响应此【杀】。",

  ["#ty_ex__qiuyuan-choose"] = "求援：令另一名角色交给你一张非【杀】基本牌，否则其成为此【杀】额外目标",
  ["#ty_ex__qiuyuan-give"] = "求援：交给 %dest 一张非【杀】基本牌，否则你成为此【杀】额外目标且不能响应",

  ["$ty_ex__qiuyuan1"] = "陛下，我不想离开。",
  ["$ty_ex__qiuyuan2"] = "将军此事，可有希望。",
}

qiuyuan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiuyuan.name) and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p ~= data.from and not table.contains(data.use.tos, p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p ~= data.from and not table.contains(data.use.tos, p)
    end)
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__qiuyuan-choose",
      skill_name = qiuyuan.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = table.filter(to:getCardIds("h"), function(id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeBasic and card.trueName ~= "slash"
    end)
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qiuyuan.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#ty_ex__qiuyuan-give::"..player.id,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, qiuyuan.name, nil, true, to)
    else
      table.insert(data.tos[AimData.Done], to)
      table.insert(data.use.tos, to)
      data.use.disresponsiveList = data.use.disresponsiveList or {}
      table.insertIfNeed(data.use.disresponsiveList, to)
    end
  end,
})

return qiuyuan
