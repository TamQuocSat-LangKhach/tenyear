local jinjianm = fk.CreateSkill {
  name = "jinjianm"
}

Fk:loadTranslationTable{
  ['jinjianm'] = '劲坚',
  ['@mushun_jin'] = '劲',
  ['#jinjianm-invoke'] = '劲坚：你可以与 %dest 点，若赢，你回复1点体力',
  [':jinjianm'] = '当你造成或受到伤害后，你获得一个“劲”标记，然后你可以与伤害来源拼点：若你赢，你回复1点体力。每有一个“劲”你的攻击范围+1。',
  ['$jinjianm1'] = '卑微之人，脊中亦有七寸硬骨！',
  ['$jinjianm2'] = '目不识丁，胸中却含三分浩气！',
}

jinjianm:addEffect(fk.Damage, {
  can_trigger = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@mushun_jin", 1)
  end
})

jinjianm:addEffect(fk.Damaged, {
  can_trigger = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local to = data.from
    if to and not to.dead and to ~= player and not player:isKongcheng() and not to:isKongcheng() and
      player.room:askToSkillInvoke(player, {skill_name = jinjianm.name, prompt = "#jinjianm-invoke::"..to.id}) then
      local pindian = player:pindian({to}, jinjianm.name)
      if pindian.results[to.id].winner == player and player:isWounded() then
        player.room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = jinjianm.name
        })
      end
    end
  end
})

jinjianm:addEffect('atkrange', {
  name = "#jinjianm_attackrange",
  correct_func = function (skill, from, to)
    return from:getMark("@mushun_jin")
  end,
})

return jinjianm
