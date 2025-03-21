local porong = fk.CreateSkill {
  name = "porong",
}

Fk:loadTranslationTable{
  ["porong"] = "破戎",
  [":porong"] = "连招技（伤害牌+【杀】），你可以获得此【杀】目标和其相邻角色各一张手牌，并令此【杀】额外结算一次。",

  ["#porong-invoke"] = "破戎：是否令此【杀】额外结算一次，并获得目标及其相邻角色各一张手牌？",
  ["#porong-prey"] = "破戎：获得 %dest 一张手牌",

  ["$porong1"] = "胡未灭，家何为？",
  ["$porong2"] = "诸君且听，这雁门虎啸！"
}

porong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(porong.name) and data.card.trueName == "slash" and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[porong.name]
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = porong.name,
      prompt = "#porong-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, porong.name, 0)
    data.additionalEffect = (data.additionalEffect or 0) + 1
    local targets = {}
    for _, p in ipairs(data.tos) do
      if p:getLastAlive() ~= player then
        table.insert(targets, p:getLastAlive())
      end
      if p ~= player then
        table.insert(targets, p)
      end
      if p:getNextAlive() ~= player then
        table.insert(targets, p:getNextAlive())
      end
    end
    if #targets == 0 then return end
    room:doIndicate(player, targets)
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p:isKongcheng() and not p.dead then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = porong.name,
          prompt = "#porong-prey::"..p.id,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, porong.name, nil, false, player)
      end
    end
  end,
})

porong:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(porong.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.is_damage_card then
      if player:getMark(porong.name) > 0 and data.card.trueName == "slash" then
        data.extra_data = data.extra_data or {}
        data.extra_data.combo_skill = data.extra_data.combo_skill or {}
        data.extra_data.combo_skill[porong.name] = true
      else
        room:setPlayerMark(player, porong.name, 1)
      end
    else
      room:setPlayerMark(player, porong.name, 0)
    end
  end,
})

return porong
