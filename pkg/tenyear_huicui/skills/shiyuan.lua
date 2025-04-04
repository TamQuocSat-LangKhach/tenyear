local shiyuan = fk.CreateSkill {
  name = "shiyuan",
}

Fk:loadTranslationTable{
  ["shiyuan"] = "诗怨",
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；"..
  "3.若其体力值比你少，你摸一张牌。",

  ["$shiyuan1"] = "感怀诗于前，绝怨赋于后。",
  ["$shiyuan2"] = "汉宫楚歌起，四面无援矣。",
}

shiyuan:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shiyuan.name) and data.from ~= player then
      local n = 1
      if player:hasSkill("yuwei") and data.from.kingdom == "qun" then
        n = 2
      end
      return (data.from.hp > player.hp and player:getMark("shiyuan1-turn") < n) or
        (data.from.hp == player.hp and player:getMark("shiyuan2-turn") < n) or
        (data.from.hp < player.hp and player:getMark("shiyuan3-turn") < n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from.hp > player.hp then
      room:addPlayerMark(player, "shiyuan1-turn", 1)
      player:drawCards(3, shiyuan.name)
    elseif data.from.hp == player.hp then
      room:addPlayerMark(player, "shiyuan2-turn", 1)
      player:drawCards(2, shiyuan.name)
    elseif data.from.hp < player.hp then
      room:addPlayerMark(player, "shiyuan3-turn", 1)
      player:drawCards(1, shiyuan.name)
    end
  end,
})

shiyuan:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "shiyuan1-turn", 0)
  room:setPlayerMark(player, "shiyuan2-turn", 0)
  room:setPlayerMark(player, "shiyuan3-turn", 0)
end)

return shiyuan
