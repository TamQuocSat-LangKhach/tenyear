local youdi = fk.CreateSkill {
  name = "sp__youdi",
}

Fk:loadTranslationTable{
  ["sp__youdi"] = "诱敌",
  [":sp__youdi"] = "结束阶段，你可以令一名其他角色弃置你一张手牌，若弃置的牌不是【杀】，则你获得其一张牌；若弃置的牌不是黑色，则你摸一张牌。",

  ["#sp__youdi-choose"] = "诱敌：令一名角色弃置你一张手牌，若不为【杀】，你获得其一张牌；若不为黑色，你摸一张牌",

  ["$sp__youdi1"] = "东吴已容不下我，愿降以保周全。",
  ["$sp__youdi2"] = "笺书七条，足以表我归降之心。",
}

youdi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(youdi.name) and player.phase == Player.Finish and
      not player:isKongcheng() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = youdi.name,
      min_num = 1,
      max_num = 1,
      targets = player.room:getOtherPlayers(player, false),
      prompt = "#sp__youdi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(to, {
      target = player,
      flag = "h",
      skill_name = youdi.name,
    })
    card = Fk:getCardById(card)
    room:throwCard(card, youdi.name, player, to)
    if player.dead or to.dead then return end
    if card.trueName ~= "slash" and not to:isNude() then
      local card2 = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = youdi.name,
      })
      room:obtainCard(player, card2, false, fk.ReasonPrey, player, youdi.name)
    end
    if not player.dead and card.color ~= Card.Black then
      player:drawCards(1, youdi.name)
    end
  end,
})

return youdi
