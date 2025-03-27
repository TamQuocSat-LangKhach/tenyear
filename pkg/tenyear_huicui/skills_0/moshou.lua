local moshou = fk.CreateSkill {
  name = "moshou"
}

Fk:loadTranslationTable{
  ['moshou'] = '墨守',
  [':moshou'] = '当你成为黑色牌的目标后，你可以摸体力上限张牌，然后下次以此法摸牌数-1。若你以此法摸牌数为1，则重置为体力上限。',
  ['$moshou1'] = '好战必亡，此亘古之理。',
  ['$moshou2'] = '天下汹汹之势，恪守方得自保。',
}

moshou:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(moshou.name) and data.card.color == Card.Black
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getMark(moshou.name)
    if n == 0 then
      n = player.maxHp
    end
    local new_num = n > 1 and n - 1 or player.maxHp
    player.room:setPlayerMark(player, moshou.name, new_num)
    player:drawCards(n, moshou.name)
  end,
})

moshou:on_lose(function (self, player)
  player.room:setPlayerMark(player, moshou.name, 0)
end)

return moshou
