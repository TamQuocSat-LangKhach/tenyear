local qingshid = fk.CreateSkill {
  name = "qingshid",
}

Fk:loadTranslationTable{
  ["qingshid"] = "倾势",
  [":qingshid"] = "当你于回合内使用【杀】或锦囊牌指定其他角色为目标后，若此牌是你本回合使用的第X张牌（X为你的手牌数），"..
  "你可以对其中一名目标角色造成1点伤害。",

  ["#qingshid-choose"] = "倾势：你可以对其中一名目标角色造成1点伤害",

  ["$qingshid1"] = "潮起万丈之仞，可阻江南春风。",
  ["$qingshid2"] = "缮甲兵，耀威武，伐吴指日可待。",
}

qingshid:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingshid.name) and data.firstTarget and
      player.room.current == player and
      table.find(data.use.tos, function(p)
        return p ~= player and not p.dead
      end) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) == player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.use.tos, function(p)
      return p ~= player and not p.dead
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#qingshid-choose",
      skill_name = qingshid.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = qingshid.name,
    }
  end,
})

return qingshid
