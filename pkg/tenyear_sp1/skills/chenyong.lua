local chenyong = fk.CreateSkill{
  name = "chenyong"
}

Fk:loadTranslationTable{
  ['chenyong'] = '沉勇',
  ['@chenyong-turn'] = '沉勇',
  [':chenyong'] = '结束阶段，你可以摸X张牌（X为本回合你使用过牌的类型数）。',
  ['$chenyong1'] = '将者，当泰山崩于前而不改色。',
  ['$chenyong2'] = '救将陷之城，焉求益兵之助。',
}

chenyong:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chenyong.name) and player.phase == Player.Finish and player:getMark("chenyong-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#player:getMark("chenyong-turn"), chenyong.name)
  end,
})

chenyong:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase < Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("chenyong-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card:getTypeString())
    room:setPlayerMark(player, "chenyong-turn", mark)
    if player:hasSkill(chenyong.name, true) then
      room:setPlayerMark(player, "@chenyong-turn", #player:getMark("chenyong-turn"))
    end
  end,
})

return chenyong
