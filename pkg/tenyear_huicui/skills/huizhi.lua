local huizhi = fk.CreateSkill {
  name = "huizhi",
}

Fk:loadTranslationTable{
  ["huizhi"] = "蕙质",
  [":huizhi"] = "准备阶段，你可以弃置任意张手牌（可以不弃），然后将手牌摸至与全场手牌最多的角色相同（至少摸一张，至多摸五张）。",

  ["#huizhi-invoke"] = "蕙质：弃置任意张手牌（可以不弃），然后将手牌摸至全场最多（至少摸一张，至多摸五张）",

  ["$huizhi1"] = "妾有一席幽梦，予君三千暗香。",
  ["$huizhi2"] = "我有玲珑之心，其情唯衷陛下。",
}

huizhi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huizhi.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "discard_skill",
      prompt = "#huizhi-invoke",
      cancelable = true,
      extra_data = {
        num = 999,
        min_num = 0,
        include_equip = false,
        pattern = ".",
        skillName = huizhi.name,
      }
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if #cards > 0 then
      room:throwCard(cards, huizhi.name, player, player)
      if player.dead then return end
    end
    local n = 0
    for _, p in ipairs(room.alive_players) do
      n = math.max(n, p:getHandcardNum())
    end
    room:drawCards(player, math.max(math.min(n - player:getHandcardNum(), 5), 1), huizhi.name)
  end,
})

return huizhi
