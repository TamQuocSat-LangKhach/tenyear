local sushou = fk.CreateSkill {
  name = "sushou",
}

Fk:loadTranslationTable{
  ["sushou"] = "夙守",
  [":sushou"] = "一名角色的出牌阶段开始时，若其手牌数是全场唯一最多的，你可以失去1点体力并摸X张牌。若此时不是你的回合内，你观看"..
  "当前回合角色一半数量的手牌（向下取整），你可以用至多X张手牌替换其中等量的牌。（X为你已损失的体力值）",

  ["#sushou-invoke"] = "夙守：你可以失去1点体力并摸牌，与 %dest 交换手牌",
  ["#sushou-exchange"] = "夙守：与 %dest 交换至多%arg张手牌",

  ["$sushou1"] = "敌众我寡，怎可少谋？",
  ["$sushou2"] = "临城据守，当出奇计。",
}

sushou:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sushou.name) and target.phase == Player.Play and
      player.hp > 0 and not target.dead and
      table.every(player.room.alive_players, function (p)
        return p == target or p:getHandcardNum() < target:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = sushou.name,
      prompt = "#sushou-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, sushou.name)
    if player.dead then return end
    local x = player:getLostHp()
    if x > 0 then
      player:drawCards(x, sushou.name)
    end
    if target == player or target.dead or target:getHandcardNum() < 2 then return end
    local cards = table.random(target:getCardIds("h"), target:getHandcardNum() // 2)
    local results = room:askToArrangeCards(player, {
      skill_name = sushou.name,
      card_map = {
        target.general, cards,
        player.general, player:getCardIds("h"),
      },
      prompt = "#sushou-exchange::"..target.id..":"..(target:getHandcardNum() // 2),
      cancelable = true,
    })
    local cards1 = table.filter(results[1], function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    local cards2 = table.filter(results[2], function (id)
      return table.contains(cards, id)
    end)
    room:swapCards(player, {
      {player, cards1},
      {target, cards2},
    }, sushou.name)
  end,
})

return sushou
