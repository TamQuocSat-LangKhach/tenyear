local huizhi = fk.CreateSkill {
  name = "huizhi"
}

Fk:loadTranslationTable{
  ['huizhi'] = '蕙质',
  ['#huizhi-invoke'] = '蕙质：你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同（最多摸五张）',
  [':huizhi'] = '准备阶段，你可以弃置任意张手牌（可不弃），然后将手牌摸至与全场手牌最多的角色相同（至少摸一张，最多摸五张）。',
  ['$huizhi1'] = '妾有一席幽梦，予君三千暗香。',
  ['$huizhi2'] = '我有玲珑之心，其情唯衷陛下。',
}

huizhi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(huizhi.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local success, ret = player.room:askToDiscard(player, {
      min_num = 0,
      include_equip = false,
      skill_name = huizhi.name,
      pattern = ".",
      prompt = "#huizhi-invoke",
      cancelable = true
    })
    if success then
      event:setCostData(self, ret)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cost_data = event:getCostData(self)
    if #cost_data > 0 then
      room:throwCard(cost_data, huizhi.name, player, player)
    end
    if player.dead then return end
    local n = 0
    for _, p in ipairs(room.alive_players) do
      n = math.max(n, p:getHandcardNum())
    end
    room:drawCards(player, math.max(math.min(n - player:getHandcardNum(), 5), 1), huizhi.name)
  end,
})

return huizhi
