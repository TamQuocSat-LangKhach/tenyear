local zhuhai = fk.CreateSkill {
  name = "ty_ex__zhuhai",
}

Fk:loadTranslationTable{
  ["ty_ex__zhuhai"] = "诛害",
  [":ty_ex__zhuhai"] = "其他角色的结束阶段，若其本回合造成过伤害，你可以将一张手牌当【杀】或【过河拆桥】对其使用（无距离限制）。",

  ["#ty_ex__zhuhai-invoke"] = "诛害：你可以将一张手牌当【杀】或【过河拆桥】对 %dest 使用",

  ["$ty_ex__zhuhai1"] = "霜刃出鞘，诛恶方还。",
  ["$ty_ex__zhuhai2"] = "心有不平，拔剑相向。",
}

zhuhai:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhuhai.name) and player ~= target and target.phase == Player.Finish and
      #player:getHandlyIds() > 0 and not target.dead and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target
      end) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = {"slash", "dismantlement"},
      skill_name = zhuhai.name,
      prompt = "#ty_ex__zhuhai-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = {target.id},
      },
      card_filter = {
        n = 1,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return zhuhai
