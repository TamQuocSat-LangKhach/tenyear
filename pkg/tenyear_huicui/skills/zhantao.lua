local zhantao = fk.CreateSkill {
  name = "zhantao",
}

Fk:loadTranslationTable{
  ["zhantao"] = "斩涛",
  [":zhantao"] = "当你或你攻击范围内的角色受到有点数的牌造成的伤害后，若伤害来源不为你，你可以判定，若点数大于造成伤害的牌的点数，"..
  "你视为对伤害来源使用【杀】。",

  ["#zhantao-invoke"] = "斩涛：你可以判定，若点数大于伤害牌则视为对 %dest 使用【杀】",

  ["$zhantao1"] = "清锋定涛，乱王土虽远必诛！",
  ["$zhantao2"] = "仗剑四顾，看天下汹涌之势。",
}

zhantao:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhantao.name) and
      (target == player or player:inMyAttackRange(target)) and
      data.from and not data.from.dead and data.from ~= player and
      data.card and data.card.number > 0 and data.card.number < 13
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhantao.name,
      prompt = "#zhantao-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = zhantao.name,
      pattern = ".|"..(data.card.number + 1).."~13",
    }
    room:judge(judge)
    if judge:matchPattern() and not data.from.dead then
      room:useVirtualCard("slash", nil, player, data.from, zhantao.name, true)
    end
  end,
})

return zhantao
