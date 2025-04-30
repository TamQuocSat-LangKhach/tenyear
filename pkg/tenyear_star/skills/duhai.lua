local duhai = fk.CreateSkill{
  name = "duhai",
}

Fk:loadTranslationTable{
  ["duhai"] = "蠹害",
  [":duhai"] = "当你成为其他角色使用牌的目标后，你可以选择一种花色，令其获得此花色的“蠹”标记。该角色的回合结束时，若其手牌中有“蠹”标记花色的牌，"..
  "其失去这些花色数的体力，然后移去这些花色的“蠹”标记。",

  ["#duhai-invoke"] = "蠹害：选择一种花色令 %dest 获得“蠹”标记，其回合结束时失去体力",
  ["@duhai"] = "蠹",

  ["$duhai1"] = "朝堂好似大染缸，进来了，休想清白出去！",
  ["$duhai2"] = "后生，你也配打咱家主意？",
}

duhai:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(duhai.name) and
      data.from ~= player and not data.from.dead and #data.from:getTableMark("@duhai") < 4
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {"log_spade", "log_heart", "log_club", "log_diamond"}
    local choices = table.filter(all_choices, function (s)
      return not table.contains(data.from:getTableMark("@duhai"), s)
    end)
    table.insert(all_choices, "Cancel")
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = duhai.name,
      prompt = "#duhai-invoke::"..data.from.id,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.from}, choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:addTableMark(data.from, "@duhai", event:getCostData(self).choice)
  end,
})

duhai:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and table.find(player:getTableMark("@duhai"), function (suit)
      return table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getSuitString(true) == suit
      end) ~= nil
    end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n, new_mark = 0, table.simpleClone(player:getTableMark("@duhai"))
    for _, suit in ipairs(player:getTableMark("@duhai")) do
      if table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getSuitString(true) == suit
      end) then
        n = n + 1
        table.removeOne(new_mark, suit)
      end
    end
    room:loseHp(player, n, duhai.name)
    if not player.dead then
      room:setPlayerMark(player, "@duhai", #new_mark > 0 and new_mark or 0)
    end
  end,
})

return duhai
