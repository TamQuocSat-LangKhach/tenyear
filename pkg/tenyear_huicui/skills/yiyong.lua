local yiyong = fk.CreateSkill {
  name = "yiyong",
}

Fk:loadTranslationTable{
  ["yiyong"] = "异勇",
  [":yiyong"] = "当你对其他角色造成伤害时，你可以与该角色同时弃置至少一张牌（该角色无牌则不弃）。若你弃置的牌的点数之和："..
  "不大于其，你摸X张牌（X为该角色弃置的牌数+1）；不小于其，此伤害+1。",

  ["#yiyong-invoke"] = "异勇：与 %dest 同时弃置任意张牌，根据弃牌点数之和执行效果",
  ["#yiyong-discard"] = "异勇：弃置至少一张牌，根据弃牌点数之和执行效果",

  ["$yiyong1"] = "关氏鼠辈，庞令明之子来邪！",
  ["$yiyong2"] = "凭一腔勇力，父仇定可报还。",
}

yiyong:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yiyong.name) and
      data.to ~= player and not player:isNude() and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      if room:askToSkillInvoke(player, {
        skill_name = yiyong.name,
        prompt = "#yiyong-invoke::"..data.to.id,
      }) then
        event:setCostData(self, {tos = {data.to}})
        return true
      end
    else
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = yiyong.name,
        pattern = "false",
        prompt = "#yiyong-invoke::"..data.to.id,
        cancelable = true,
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askToJointCards(player, {
      players = {player, data.to},
      min_num = 1,
      max_num = 999,
      cancelable = false,
      skill_name = yiyong.name,
      prompt = "#yiyong-discard",
      will_throw = true,
    })
    local n1, n2 = 0, 0
    for _, id in ipairs(result[player]) do
      n1 = n1 + Fk:getCardById(id).number
    end
    for _, id in ipairs(result[data.to]) do
      n2 = n2 + Fk:getCardById(id).number
    end
    local moves = {}
    table.insert(moves, {
      from = player,
      ids = result[player],
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      proposer = player,
    })
    if #result[data.to] > 0 then
      table.insert(moves, {
        from = data.to,
        ids = result[data.to],
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = data.to,
      })
    end
    room:moveCards(table.unpack(moves))
    if n1 <= n2 and not player.dead then
      player:drawCards(#result[data.to] + 1, yiyong.name)
    end
    if n1 >= n2 then
      data:changeDamage(1)
    end
  end,
})

return yiyong
