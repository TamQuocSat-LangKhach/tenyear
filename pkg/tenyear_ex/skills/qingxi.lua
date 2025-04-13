local qingxi = fk.CreateSkill {
  name = "ty_ex__qingxi",
}

Fk:loadTranslationTable{
  ["ty_ex__qingxi"] = "倾袭",
  [":ty_ex__qingxi"] = "当你使用【杀】或【决斗】指定目标后，你可以令其选择一项：1.弃置等同于你攻击范围内的角色数张手牌"..
  "（至多为2，若你装备区有武器牌则改为至多为4），然后弃置你的武器；2.令此牌对其伤害+1且你进行一次判定，若结果为红色，该角色不能响应此牌。",

  ["#ty_ex__qingxi"] = "倾袭：是否对 %dest 发动“倾袭”，令其选择一项？",
  ["#ty_ex__qingxi-discard"] = "倾袭：弃置 %arg 张手牌，或点“取消”伤害+1且其判定，结果为红你不能响应",

  ["$ty_ex__qingxi1"] = "虎豹骑倾巢而动，安有不胜之理？",
  ["$ty_ex__qingxi2"] = "任尔等固若金汤，虎豹骑可破之！",
}

qingxi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingxi.name) and
      (data.card.trueName == "slash" or data.card.trueName == "duel")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = qingxi.name,
      prompt = "#ty_ex__qingxi::" .. data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p)
    end)
    n = math.min(n, #player:getEquipments(Card.SubtypeWeapon) > 0 and 4 or 2)
    if n == 0 or #room:askToDiscard(data.to, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = qingxi.name,
      cancelable = true,
      prompt = "#ty_ex__qingxi-discard:::"..n,
    }) == 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__qingxi = data.to
      local judge = {
        who = player,
        reason = qingxi.name,
        pattern = ".|.|heart,diamond",
      }
      room:judge(judge)
      if judge:matchPattern() then
        data.disresponsive = true
      end
    elseif #player:getEquipments(Card.SubtypeWeapon) > 0 then
      room:throwCard(player:getEquipments(Card.SubtypeWeapon), qingxi.name, player, data.to)
    end
  end,
})

qingxi:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data
        if use.extra_data and use.extra_data.ty_ex__qingxi == data.to then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return qingxi
