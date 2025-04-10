local gouzhu = fk.CreateSkill {
  name = "gouzhu",
}

Fk:loadTranslationTable{
  ["gouzhu"] = "苟渚",
  [":gouzhu"] = "当你失去技能后，若此技能为：<br>"..
  "锁定技，你回复1点体力；<br>"..
  "觉醒技，你获得一张基本牌；<br>"..
  "限定技，你对随机一名其他角色造成1点伤害；<br>"..
  "转换技，你的手牌上限+1；<br>"..
  "主公技，你加1点体力上限。",
}

gouzhu:addEffect(fk.EventLoseSkill, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gouzhu.name) and
      not data.name:startsWith("#") and data:isPlayerSkill() and
      table.find({Skill.Compulsory, Skill.Wake, Skill.Limited, Skill.Switch, Skill.Lord}, function (tag)
        return data:hasTag(tag, false)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data:hasTag(Skill.Compulsory, false) then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = gouzhu.name,
        }
        if player.dead then return end
      end
    end
    if data:hasTag(Skill.Wake) then
      local card = room:getCardsFromPileByRule(".|.|.|.|.|basic")
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, gouzhu.name, nil, false, player.id)
      end
      if player.dead then return end
    end
    if data:hasTag(Skill.Limited) then
      if #room:getOtherPlayers(player, false) > 0 then
        local to = table.random(room:getOtherPlayers(player, false))
        room:doIndicate(player, {to})
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = gouzhu.name,
        }
        if player.dead then return end
      end
    end
    if data:hasTag(Skill.Switch) then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    end
    if data:hasTag(Skill.Lord) then
      room:changeMaxHp(player, 1)
    end
  end,
})

return gouzhu
