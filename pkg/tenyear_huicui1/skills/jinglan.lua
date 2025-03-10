local jinglan = fk.CreateSkill {
  name = "jinglan"
}

Fk:loadTranslationTable{
  ['jinglan'] = '惊澜',
  [':jinglan'] = '锁定技，当你造成伤害后，若你的手牌数：大于体力值，你弃四张手牌；等于体力值，你弃一张牌并回复1点体力；小于体力值，你受到1点火焰伤害并摸五张牌。',
  ['$jinglan1'] = '潮生潮落，风浪不息。',
  ['$jinglan2'] = '狂风舟起，巨浪滔天。',
}

jinglan:addEffect(fk.Damage, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > player.hp then
      room:askToDiscard(player, {min_num = 4, max_num = 4, include_equip = false, skill_name = skill.name})
    elseif player:getHandcardNum() == player.hp then
      room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = skill.name})
      if player:isWounded() and not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = skill.name,
        }
      end
    elseif player:getHandcardNum() < player.hp then
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = skill.name,
      }
      if not player.dead then
        player:drawCards(5, skill.name)
      end
    end
  end,
})

return jinglan
