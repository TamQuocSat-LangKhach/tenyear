local gouzhu = fk.CreateSkill {
  name = "gouzhu"
}

Fk:loadTranslationTable{
  ['gouzhu'] = '苟渚',
  [':gouzhu'] = '当你失去技能后，若此技能为：<br>锁定技，你回复1点体力；<br>觉醒技，你获得一张基本牌；<br>限定技，你对随机一名其他角色造成1点伤害；<br>转换技，你的手牌上限+1；<br>主公技，你加1点体力上限。',
  ['$gouzhu1'] = '',
  ['$gouzhu2'] = '',
}

gouzhu:addEffect(fk.EventLoseSkill, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gouzhu.name) and data.isPlayerSkill and data.visible
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.frequency == Skill.Compulsory then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = gouzhu.name,
        }
      end
    end
    if player.dead then return end
    if data.frequency == Skill.Wake then
      local card = room:getCardsFromPileByRule(".|.|.|.|.|basic")
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, gouzhu.name, nil, false, player.id)
      end
    end
    if player.dead then return end
    if data.frequency == Skill.Limited then
      if #room:getOtherPlayers(player) > 0 then
        local to = table.random(room:getOtherPlayers(player))
        room:doIndicate(player.id, {to.id})
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = gouzhu.name,
        }
      end
    end
    if player.dead then return end
    if data.switchSkillName and data.switchSkillName ~= "" then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    end
    if data.lordSkill then
      room:changeMaxHp(player, 1)
    end
  end,
})

return gouzhu
