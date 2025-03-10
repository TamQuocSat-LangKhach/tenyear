local jiedao = fk.CreateSkill {
  name = "jiedao"
}

Fk:loadTranslationTable{
  ['jiedao'] = '截刀',
  ['#jiedao-invoke'] = '截刀：你可以令你对 %dest 造成的伤害+%arg',
  ['#jiedao-discard'] = '截刀：你需弃置等同于此伤害加值的牌（%arg张）',
  [':jiedao'] = '当你每回合第一次造成伤害时，你可令此伤害至多+X（X为你损失的体力值）。然后若受到此伤害的角色没有死亡，你弃置等同于此伤害加值的牌。',
  ['$jiedao1'] = '截头大刀的威力，你来尝尝？',
  ['$jiedao2'] = '我这大刀，可是不看情面的。',
}

jiedao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(jiedao.name) then
      if player:getMark("jiedao-turn") == 0 then
        player.room:addPlayerMark(player, "jiedao-turn", 1)
        return player:isWounded()
      end
    end
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = jiedao.name,
      prompt = "#jiedao-invoke::" .. target.id .. ":" .. player:getLostHp()
    })
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getLostHp()
    data.damage = data.damage + n
    data.extra_data = data.extra_data or {}
    data.extra_data.jiedao = n
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and not data.to.dead and data.extra_data and data.extra_data.jiedao and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = data.extra_data.jiedao
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = jiedao.name,
        cancelable = false,
        pattern = ".",
        prompt = "#jiedao-discard:::" .. n
      })
    end
  end,
})

return jiedao
