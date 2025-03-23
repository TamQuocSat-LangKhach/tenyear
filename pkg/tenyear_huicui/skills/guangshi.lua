local guangshi = fk.CreateSkill {
  name = "guangshi"
}

Fk:loadTranslationTable{
  ['guangshi'] = '光噬',
  ['@@xinzhong'] = '信众',
  [':guangshi'] = '锁定技，准备阶段，若所有其他角色均是“信众”，你摸X张牌（X为这些角色数），失去1点体力。',
  ['$guangshi1'] = '舍身饲火，光耀人间。',
  ['$guangshi2'] = '愿为奉光之薪柴，照太平于人间。',
}

guangshi:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guangshi.name) and player.phase == Player.Start and #player.room.alive_players > 1 and
      table.every(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark("@@xinzhong") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(#room.alive_players - 1, guangshi.name)
    if player:isAlive() then
      player.room:loseHp(player, 1, guangshi.name)
    end
  end,
})

return guangshi
