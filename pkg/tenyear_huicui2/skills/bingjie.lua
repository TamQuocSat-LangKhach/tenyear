local bingjie = fk.CreateSkill {
  name = "bingjie"
}

Fk:loadTranslationTable{
  ['bingjie'] = '秉节',
  ['@@bingjie-turn'] = '秉节',
  ['#bingjie-discard'] = '秉节：请弃置一张牌，若你弃置了%arg牌，无法响应%arg2',
  [':bingjie'] = '出牌阶段开始时，你可以减1点体力上限，然后当你本回合使用【杀】或普通锦囊牌指定目标后，除你以外的目标角色各弃置一张牌，若弃置的牌与你使用的牌颜色相同，其无法响应此牌。',
  ['$bingjie1'] = '秉节传旌，心存丹衷。',
  ['$bingjie2'] = '秉节刚劲，奸佞务尽。',
}

bingjie:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(bingjie.name) and target == player and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {skill_name = bingjie.name})
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(player, "@@bingjie-turn")
    room:changeMaxHp(player, -1)
  end,
})

bingjie:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@bingjie-turn") > 0 and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data.firstTarget and data.tos and table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(AimGroup:getAllTargets(data.tos)) do
      local to = room:getPlayerById(pid)
      if not to.dead and not to:isNude() and to ~= player then
        local throw = room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = bingjie.name,
          cancelable = false,
          pattern = ".",
          prompt = "#bingjie-discard:::"..data.card:getColorString()..":"..data.card:toLogString()
        })
        if #throw > 0 and Fk:getCardById(throw[1]).color == data.card.color then
          data.disresponsiveList = data.disresponsiveList or {}
          table.insertIfNeed(data.disresponsiveList, to.id)
        end
      end
    end
  end,
})

return bingjie
