local guangyong = fk.CreateSkill {
  name = "guangyong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guangyong"] = "犷勇",
  [":guangyong"] = "锁定技，当你使用牌指定自己为目标后，你加1点体力上限；当你使用牌指定其他角色为目标后，你减1点体力上限"..
  "（至多减至1），获得其中一名目标角色一张牌。",

  ["#guangyong-choose"] = "犷勇：选择一名目标角色，获得其一张牌",

  ["$guangyong1"] = "孤烟直上，黄沙漫卷祁连天！",
  ["$guangyong2"] = "掷酒湟水，我来宴无定河边骨。"
}

guangyong:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(guangyong.name) and data.firstTarget then
      if table.contains(data.use.tos, player) then
        return true
      end
      if table.find(data.use.tos, function (p)
        return p ~= player and not p.dead
      end) then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.contains(data.use.tos, player) and player.maxHp < 8 then
      room:changeMaxHp(player, 1)
      if player.dead then return end
    end
    if table.find(data.use.tos, function (p)
      return p ~= player and not p.dead
    end) then
      if player.maxHp > 1 then
        room:changeMaxHp(player, -1)
        if player.dead then return end
      end
      local targets = table.filter(data.use.tos, function (p)
        return p ~= player and not p.dead and not p:isNude()
      end)
      if #targets == 0 then return end
      if #targets > 1 then
        targets = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = guangyong.name,
          prompt = "#guangyong-choose",
          cancelable = false,
        })
      end
      local to = targets[1]
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = guangyong.name,
      })
      room:obtainCard(player, card, false, fk.ReasonPrey, player, guangyong.name)
    end
  end,
})

return guangyong
