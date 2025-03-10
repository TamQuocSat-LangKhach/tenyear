local sp__youdi = fk.CreateSkill {
  name = "sp__youdi"
}

Fk:loadTranslationTable{
  ['sp__youdi'] = '诱敌',
  ['#sp__youdi-choose'] = '诱敌：令一名角色弃置你一张牌，若不为【杀】，你获得其一张牌；若不为黑色，你摸一张牌',
  [':sp__youdi'] = '结束阶段，你可以令一名其他角色弃置你一张手牌，若弃置的牌不是【杀】，则你获得其一张牌；若弃置的牌不是黑色，则你摸一张张牌。',
  ['$sp__youdi1'] = '东吴已容不下我，愿降以保周全。',
  ['$sp__youdi2'] = '笺书七条，足以表我归降之心。',
}

sp__youdi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(sp__youdi) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#sp__youdi-choose",
      skill_name = sp__youdi.name
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local card = room:askToChooseCard(to, {
      target = player,
      flag = "h",
      skill_name = sp__youdi.name
    })
    room:throwCard({card}, sp__youdi.name, player, to)
    if Fk:getCardById(card).trueName ~= "slash" and not to:isNude() then
      local card2 = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = sp__youdi.name
      })
      room:obtainCard(player, card2, false, fk.ReasonPrey)
    end
    if Fk:getCardById(card).color ~= Card.Black then
      player:drawCards(1, sp__youdi.name)
    end
  end,
})

return sp__youdi
