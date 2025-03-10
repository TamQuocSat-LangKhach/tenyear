local qingshid = fk.CreateSkill {
  name = "qingshid"
}

Fk:loadTranslationTable{
  ['qingshid'] = '倾势',
  ['#qingshid-choose'] = '倾势：你可以对其中一名目标角色造成1点伤害',
  ['@qingshid-turn'] = '倾势',
  [':qingshid'] = '当你于回合内使用【杀】或锦囊牌指定其他角色为目标后，若此牌是你本回合使用的第X张牌（X为你的手牌数），你可以对其中一名目标角色造成1点伤害。',
  ['$qingshid1'] = '潮起万丈之仞，可阻江南春风。',
  ['$qingshid2'] = '缮甲兵，耀威武，伐吴指日可待。',
}

qingshid:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase ~= Player.NotActive
      and player:getHandcardNum() == player:getMark("qingshid-turn")
      and data.tos and data.firstTarget
      and table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = AimGroup:getAllTargets(data.tos),
      min_num = 1,
      max_num = 1,
      prompt = "#qingshid-choose",
      skill_name = skill.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(event:getCostData(skill)),
      damage = 1,
      skillName = skill.name,
    }
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "qingshid-turn", 1)
    if player:hasSkill(skill.name, true) then
      room:setPlayerMark(player, "@qingshid-turn", player:getMark("qingshid-turn"))
    end
  end,
})

return qingshid
