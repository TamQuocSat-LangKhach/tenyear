local xunxian = fk.CreateSkill {
  name = "xunxian"
}

Fk:loadTranslationTable{
  ['xunxian'] = '逊贤',
  ['#xunxian-choose'] = '逊贤：你可以将%arg交给一名手牌数大于你的角色',
  [':xunxian'] = '每回合限一次，你使用或打出的牌置入弃牌堆时，你可以将之交给一名手牌数或体力值大于你的角色。',
  ['$xunxian1'] = '督军之才，子明强于我甚多。',
  ['$xunxian2'] = '此间重任，公卿可担之。',
}

xunxian:addEffect(fk.CardUseFinished, {
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunxian.name) and player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(xunxian.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (#p.player_cards[Player.Hand] > #player.player_cards[Player.Hand] or p.hp > player.hp) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xunxian-choose:::"..data.card:toLogString(),
      skill_name = xunxian.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(event:getCostData(self), data.card, true, fk.ReasonGive, player.id)
  end,
})

return xunxian
