local chenghao = fk.CreateSkill {
  name = "chenghao",
}

Fk:loadTranslationTable{
  ["chenghao"] = "称好",
  [":chenghao"] = "当一名角色受到属性伤害后，若其受到此伤害前处于“连环状态”且是此伤害传导的起点，你可以观看牌堆顶的X张牌并"..
  "将这些牌分配给任意角色（X为横置角色数+1）。",

  ["$chenghao1"] = "好，很好，非常好。",
  ["$chenghao2"] = "您的话也很好。",
}

chenghao:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenghao.name) and data.damageType ~= fk.NormalDamage and data.beginnerOfTheDamage and
      not data.chain and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1 + #table.filter(room.alive_players, function(p)
      return p.chained
    end)
    local cards = room:getNCards(n)
    room:askToYiji(player, {
      cards = cards,
      targets = room.alive_players,
      skill_name = chenghao.name,
      min_num = #cards,
      max_num = #cards,
      expand_pile = cards,
    })
  end,
})

return chenghao
