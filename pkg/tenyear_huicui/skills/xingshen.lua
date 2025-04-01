local xingshen = fk.CreateSkill {
  name = "xingshen",
}

Fk:loadTranslationTable{
  ["xingshen"] = "省身",
  [":xingshen"] = "当你受到伤害后，你可以摸一张牌并令下一次发动〖严教〗亮出的牌数+1。若你的手牌数为全场最少，则改为摸两张牌；"..
  "若你的体力值为全场最少，则下一次发动〖严教〗亮出的牌数改为+2（加值总数至多为6）。",

  ["@yanjiao"] = "严教",

  ["$xingshen1"] = "居上不骄，制节谨度。",
  ["$xingshen2"] = "君子之行，皆积小以致高大。",
}

xingshen:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function(p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end) then
      player:drawCards(2, xingshen.name)
    else
      player:drawCards(1, xingshen.name)
    end
    if player.dead or player:getMark("@yanjiao") > 5 or not player:hasSkill("yanjiao", true) then return end
    if table.every(room.alive_players, function(p)
      return p.hp >= player.hp
    end) then
      room:addPlayerMark(player, "@yanjiao", math.min(6 - player:getMark("@yanjiao"), 2))
    else
      room:addPlayerMark(player, "@yanjiao", 1)
    end
  end,
})

return xingshen
