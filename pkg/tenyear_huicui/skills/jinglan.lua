local jinglan = fk.CreateSkill {
  name = "jinglan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jinglan"] = "惊澜",
  [":jinglan"] = "锁定技，当你造成伤害后，若你的手牌数：大于体力值，你弃四张手牌；等于体力值，你弃一张牌并回复1点体力；小于体力值，"..
  "你受到1点火焰伤害并摸五张牌。",

  ["$jinglan1"] = "潮生潮落，风浪不息。",
  ["$jinglan2"] = "狂风舟起，巨浪滔天。",
}

jinglan:addEffect(fk.Damage, {
  mute = true,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jinglan.name)
    if player:getHandcardNum() > player.hp then
      room:notifySkillInvoked(player, jinglan.name, "negative")
      room:askToDiscard(player, {
        min_num = 4,
        max_num = 4,
        include_equip = false,
        skill_name = jinglan.name,
      })
    elseif player:getHandcardNum() == player.hp then
      room:notifySkillInvoked(player, jinglan.name, "support")
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = jinglan.name,
      })
      if player:isWounded() and not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = jinglan.name,
        }
      end
    elseif player:getHandcardNum() < player.hp then
      room:notifySkillInvoked(player, jinglan.name, "drawcard")
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = jinglan.name,
      }
      if not player.dead then
        player:drawCards(5, jinglan.name)
      end
    end
  end,
})

return jinglan
