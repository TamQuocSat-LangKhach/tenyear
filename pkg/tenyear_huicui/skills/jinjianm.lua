local jinjianm = fk.CreateSkill {
  name = "jinjianm",
}

Fk:loadTranslationTable{
  ["jinjianm"] = "劲坚",
  [":jinjianm"] = "当你造成或受到伤害后，你获得一个“劲”标记，然后你可以与伤害来源拼点：若你赢，你回复1点体力。每有一个“劲”你的攻击范围+1。",

  ["@mushun_jin"] = "劲",
  ["#jinjianm-invoke"] = "劲坚：你可以与 %dest 拼点，若赢，你回复1点体力",

  ["$jinjianm1"] = "卑微之人，脊中亦有七寸硬骨！",
  ["$jinjianm2"] = "目不识丁，胸中却含三分浩气！",
}

jinjianm:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@mushun_jin", 0)
end)

jinjianm:addEffect(fk.Damaged, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jinjianm.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@mushun_jin", 1)
    if data.from and not data.from.dead and player:canPindian(data.from) and
      room:askToSkillInvoke(player, {
        skill_name = jinjianm.name,
        prompt = "#jinjianm-invoke::"..data.from.id,
      }) then
      room:doIndicate(player, {data.from})
      local pindian = player:pindian({data.from}, jinjianm.name)
      if pindian.results[data.from].winner == player and player:isWounded() and not player.dead then
        player.room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = jinjianm.name,
        }
      end
    end
  end
})

jinjianm:addEffect(fk.Damage, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jinjianm.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@mushun_jin", 1)
  end
})

jinjianm:addEffect("atkrange", {
  correct_func = function (skill, from, to)
    return from:getMark("@mushun_jin")
  end,
})

return jinjianm
