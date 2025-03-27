local shiyuan = fk.CreateSkill {
  name = "shiyuan"
}

Fk:loadTranslationTable{
  ['shiyuan'] = '诗怨',
  ['yuwei'] = '余威',
  [':shiyuan'] = '每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；3.若其体力值比你少，你摸一张牌。',
  ['$shiyuan1'] = '感怀诗于前，绝怨赋于后。',
  ['$shiyuan2'] = '汉宫楚歌起，四面无援矣。',
}

shiyuan:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shiyuan) and data.from ~= player.id then
      local from = player.room:getPlayerById(data.from)
      local n = 1
      if player:hasSkill("yuwei") and player.room.current.kingdom == "qun" then
        n = 2
      end
      return (from.hp > player.hp and player:getMark("shiyuan1-turn") < n) or
        (from.hp == player.hp and player:getMark("shiyuan2-turn") < n) or
        (from.hp < player.hp and player:getMark("shiyuan3-turn") < n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if from.hp > player.hp then
      player:drawCards(3, shiyuan.name)
      room:addPlayerMark(player, "shiyuan1-turn", 1)
    elseif from.hp == player.hp then
      player:drawCards(2, shiyuan.name)
      room:addPlayerMark(player, "shiyuan2-turn", 1)
    elseif from.hp < player.hp then
      player:drawCards(1, shiyuan.name)
      room:addPlayerMark(player, "shiyuan3-turn", 1)
    end
  end,
})

return shiyuan
