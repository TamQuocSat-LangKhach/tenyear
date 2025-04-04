local xianshu = fk.CreateSkill {
  name = "xianshu",
}

Fk:loadTranslationTable{
  ["xianshu"] = "贤淑",
  [":xianshu"] = "出牌阶段，你可以将一张“箜篌”牌交给一名其他角色并摸X张牌（X为你与该角色体力值之差且至多为5），若此牌为：红色，"..
  "且该角色体力值不大于你，该角色回复1点体力；黑色，且该角色体力值不小于你，该角色失去1点体力。",

  ["#xianshu"] = "贤淑：将一张“箜篌”牌交给其他角色并摸牌",

  ["$xianshu1"] = "居宠而不骄，秉贤淑于内庭。",
  ["$xianshu2"] = "心怀玲珑意，宜家国于春秋。",
}

xianshu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#xianshu",
  card_num = 1,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@konghou-inhand") > 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local color = Fk:getCardById(effect.cards[1]).color
    room:obtainCard(target, effect.cards, true, fk.ReasonGive, player, xianshu.name)
    if player.dead or target.dead then return end
    local x = math.abs(player.hp - target.hp)
    if x > 0 then
      player:drawCards(math.min(x, 5), xianshu.name)
    end
    if player.dead or target.dead then return end
    if color == Card.Red and target.hp <= player.hp and target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = xianshu.name,
      }
    elseif color == Card.Black and target.hp >= player.hp then
      room:loseHp(target, 1, xianshu.name)
    end
  end,
})

return xianshu
