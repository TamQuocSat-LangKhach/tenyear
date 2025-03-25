local zhenrao = fk.CreateSkill {
  name = "zhenrao",
}

Fk:loadTranslationTable{
  ["zhenrao"] = "震扰",
  [":zhenrao"] = "每回合每名角色限一次，当你使用牌指定其他角色为目标后，或当其他角色使用牌指定你为目标后，你可以选择手牌数大于你的"..
  "其中一个目标或使用者，对其造成1点伤害。",

  ["#zhenrao-invoke"] = "震扰：是否对 %dest 造成1点伤害？",
  ["#zhenrao-choose"] = "震扰：是否对其中一名角色造成1点伤害？",

  ["$zhenrao1"] = "此病需静养，怎堪兵戈铁马之扰。",
  ["$zhenrao2"] = "孤值有疾，竟为文家小儿所扰。",
}

zhenrao:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhenrao.name) then
      if target == player then
        return data.firstTarget and
          table.find(data.use.tos, function (p)
            return p:getHandcardNum() > player:getHandcardNum() and
              not p.dead and not table.contains(player:getTableMark("zhenrao-turn"), p.id)
          end)
      else
        return data.to == player and target:getHandcardNum() > player:getHandcardNum() and
          not target.dead and not table.contains(player:getTableMark("zhenrao-turn"), target.id)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if target == player then
      targets = table.filter(data.use.tos, function (p)
        return p:getHandcardNum() > player:getHandcardNum() and
          not p.dead and not table.contains(player:getTableMark("zhenrao-turn"), p.id)
      end)
    else
      targets = {target}
    end
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = zhenrao.name,
        prompt = "#zhenrao-invoke::"..targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    else
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zhenrao-choose",
        skill_name = zhenrao.name,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMark(player, "zhenrao-turn", to.id)
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = zhenrao.name,
    }
  end,
})

return zhenrao
