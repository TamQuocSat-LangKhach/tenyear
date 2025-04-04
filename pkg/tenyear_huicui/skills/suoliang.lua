local suoliang = fk.CreateSkill {
  name = "suoliang",
}

Fk:loadTranslationTable{
  ["suoliang"] = "索粮",
  [":suoliang"] = "每回合限一次，你对一名其他角色造成伤害后，你可以展示该角色的至多X张牌（X为其体力上限且最多为5），"..
  "获得其中的<font color='red'>♥</font>和♣牌。若你未获得牌，则弃置你选择的牌。",

  ["#suoliang-invoke"] = "索粮：你可以选择 %dest 最多%arg张牌，获得其中的<font color='red'>♥</font>和♣牌，若没有则弃置这些牌",

  ["$suoliang1"] = "奉上万石粮草，吾便退兵！",
  ["$suoliang2"] = "听闻北海富庶，特来借粮。",
}

suoliang:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(suoliang.name) and
      player:usedSkillTimes(suoliang.name, Player.HistoryTurn) == 0 and
      data.to ~= player and not data.to.dead and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = suoliang.name,
      prompt = "#suoliang-invoke::"..data.to.id..":"..math.min(data.to.maxHp, 5),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      target = data.to,
      min = 1,
      max = math.min(data.to.maxHp, 5),
      flag = "he",
      skill_name = suoliang.name,
    })
    data.to:showCards(cards)
    if player.dead or data.to.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(data.to:getCardIds("he"), id)
    end)
    if #cards == 0 then return end
    local get = table.filter(cards, function (id)
      return table.contains({Card.Heart, Card.Club}, Fk:getCardById(id).suit)
    end)
    if #get > 0 then
      room:obtainCard(player, get, true, fk.ReasonPrey, player, suoliang.name)
    else
      room:throwCard(cards, suoliang.name, data.to, player)
    end
  end,
})

return suoliang
