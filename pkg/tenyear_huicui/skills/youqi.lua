local youqi = fk.CreateSkill {
  name = "youqi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["youqi"] = "幽栖",
  [":youqi"] = "锁定技，其他角色因〖引路〗弃置牌时，你有概率获得此牌，该角色距离你越近，概率越高。",

  ["$youqi1"] = "寒烟锁旧山，坐看云起出。",
  ["$youqi2"] = "某隐居山野，不慕富贵功名。",
}

youqi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youqi.name) then
      local ids = {}
      for _, move in ipairs(data) do
        if move.skillName == "yinlu" and move.from and move.from ~= player and not move.from.dead then
          --距离1，0.9概率；距离5以上，0.5概率
          local x = 1 - (math.min(5, player:distanceTo(move.from)) / 10)
          if x > math.random() then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
      end
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, event:getCostData(self).cards, true, fk.ReasonJustMove, player, youqi.name)
  end,
})

return youqi
