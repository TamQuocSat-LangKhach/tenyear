local yunjiu = fk.CreateSkill {
  name = "yunjiu",
}

Fk:loadTranslationTable{
  ["yunjiu"] = "运柩",
  [":yunjiu"] = "当一名角色死亡时，你可以将其区域内一张牌交给一名其他角色。若如此做，你加1点体力上限并回复1点体力。",

  ["#yunjiu-give"] = "运柩：将 %dest 的一张牌交给一名其他角色",

  ["$yunjiu1"] = "此吾主之柩，请诸君勿扰。",
  ["$yunjiu2"] = "故者为大，尔等欲欺大者乎？"
}

yunjiu:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yunjiu.name) and not target:isAllNude() and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToYiji(player, {
      cards = target:getCardIds("hej"),
      targets = room:getOtherPlayers(player, false),
      skill_name = yunjiu.name,
      min_num = 1,
      max_num = 1,
      prompt = "#yunjiu-give::" .. target.id,
      expand_pile = target:getCardIds("hej"),
    })
    if player.dead then return end
    room:changeMaxHp(player, 1)
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = yunjiu.name,
      }
    end
  end,
})

return yunjiu
