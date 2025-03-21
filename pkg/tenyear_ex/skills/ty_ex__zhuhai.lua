local ty_ex__zhuhai = fk.CreateSkill {
  name = "ty_ex__zhuhai"
}

Fk:loadTranslationTable{
  ['ty_ex__zhuhai'] = '诛害',
  ['ty_ex__zhuhai_active'] = '诛害',
  ['#ty_ex__zhuhai-use'] = '诛害：将一张手牌当【杀】或【过河拆桥】对 %src 使用',
  [':ty_ex__zhuhai'] = '其他角色的结束阶段，若其本回合造成过伤害，你可以将一张手牌当【杀】或【过河拆桥】对其使用（无距离限制）。',
  ['$ty_ex__zhuhai1'] = '霜刃出鞘，诛恶方还。',
  ['$ty_ex__zhuhai2'] = '心有不平，拔剑相向。',
}

ty_ex__zhuhai:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__zhuhai.name) and player ~= target and target.phase == Player.Finish and not player:isKongcheng() and not target.dead then
      return #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == target end) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__zhuhai_active",
      prompt = "#ty_ex__zhuhai-use:"..target.id,
      cancelable = true,
      extra_data = {ty_ex__zhuhai_victim = target.id},
    })
    if success and dat then
      event:setCostData(self, {dat.cards[1], dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(event:getCostData(self)[2])
    card:addSubcard(event:getCostData(self)[1])
    card.skillName = ty_ex__zhuhai.name
    room:useCard{
      from = player.id,
      tos =  {{target.id}},
      card = card,
      extraUse = true,
    }
  end,
})

return ty_ex__zhuhai
