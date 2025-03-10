local thunderBladeSkill = fk.CreateSkill {
  name = "#thunder_blade_skill"
}

Fk:loadTranslationTable{
  ['#thunder_blade_skill'] = '天雷刃',
  ['thunder_blade'] = '天雷刃',
  ['#thunder_blade-invoke'] = '天雷刃：你可以令 %dest 判定<br>♠，其受到3点雷电伤害；♣，其受到1点雷电伤害，你回复1点体力并摸一张牌',
}

thunderBladeSkill:addEffect(fk.TargetSpecified, {
  attached_equip = "thunder_blade",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(thunderBladeSkill.name) and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = thunderBladeSkill.name,
      prompt = "#thunder_blade-invoke::"..data.to
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local judge = {
      who = to,
      reason = thunderBladeSkill.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade then
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 3,
          damageType = fk.ThunderDamage,
          skillName = thunderBladeSkill.name,
        }
      end
    elseif judge.card.suit == Card.Club then
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = thunderBladeSkill.name,
        }
      end
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = thunderBladeSkill.name
        })
      end
      if not player.dead then
        player:drawCards(1, thunderBladeSkill.name)
      end
    end
  end,
})

return thunderBladeSkill
