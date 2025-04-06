local skill = fk.CreateSkill {
  name = "#thunder_blade_skill",
  attached_equip = "thunder_blade",
}

Fk:loadTranslationTable{
  ["#thunder_blade_skill"] = "天雷刃",
  ["#thunder_blade-invoke"] = "天雷刃：你可以令 %dest 判定<br>♠，其受到3点雷电伤害；♣，其受到1点雷电伤害，你回复1点体力并摸一张牌",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and
      not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#thunder_blade-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    local judge = {
      who = to,
      reason = skill.name,
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
          skillName = skill.name,
        }
      end
    elseif judge.card.suit == Card.Club then
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = skill.name,
        }
      end
      if not player.dead and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = skill.name,
        }
      end
      if not player.dead then
        player:drawCards(1, skill.name)
      end
    end
  end,
})

return skill
