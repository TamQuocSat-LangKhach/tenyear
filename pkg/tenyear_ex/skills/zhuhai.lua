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
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__zhuhai_viewas",
      prompt = "#ty_ex__zhuhai-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = {target.id},
      },
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(event:getCostData(self).choice)
    card:addSubcards(event:getCostData(self).cards)
    card.skillName = zhuhai.name
    room:useCard{
      from = player,
      tos =  {target},
      card = card,
      extraUse = true,
    }
  end,
})

return zhuhai
