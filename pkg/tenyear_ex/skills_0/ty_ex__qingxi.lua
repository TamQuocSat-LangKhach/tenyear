local ty_ex__qingxi = fk.CreateSkill {
  name = "ty_ex__qingxi"
}

Fk:loadTranslationTable{
  ['ty_ex__qingxi'] = '倾袭',
  ['#ty_ex__qingxi'] = '倾袭：可令 %dest 选一项：1.弃 %arg 张手牌并弃置你的武器；2.伤害+1且你判定，为红不能响应',
  ['#ty_ex__qingxi-discard'] = '倾袭：你需弃置 %arg 张手牌，否则伤害+1且其判定，结果为红你不能响应',
  [':ty_ex__qingxi'] = '当你使用【杀】或【决斗】指定一名角色为目标后，你可以令其选择一项：1.弃置等同于你攻击范围内的角色数张手牌（至多为2，若你武器区里有武器牌则改为至多为4），然后弃置你装备区里的武器牌；2.令此牌对其造成的基础伤害值+1且你进行一次判定，若结果为红色，该角色不能响应此牌。',
  ['$ty_ex__qingxi1'] = '虎豹骑倾巢而动，安有不胜之理？',
  ['$ty_ex__qingxi2'] = '任尔等固若金汤，虎豹骑可破之！',
}

ty_ex__qingxi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__qingxi.name) and (data.card.trueName == "slash" or data.card.trueName == "duel")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) then
        n = n + 1
      end
    end
    local max_num = #player:getEquipments(Card.SubtypeWeapon) > 0 and 4 or 2
    n = math.min(n, max_num)
    if room:askToSkillInvoke(player, {
      skill_name = ty_ex__qingxi.name,
      prompt = "#ty_ex__qingxi::" .. data.to..":"..n
    }) then
      event:setCostData(self, n)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local num = event:getCostData(self)
    if #room:askToDiscard(to, {
      min_num = num,
      max_num = num,
      include_equip = false,
      skill_name = ty_ex__qingxi.name,
      cancelable = true,
      pattern = ".",
      prompt = "#ty_ex__qingxi-discard:::"..num
    }) == num then
      local weapon = player:getEquipments(Card.SubtypeWeapon)
      if #weapon > 0 then
        room:throwCard(weapon, ty_ex__qingxi.name, player, to)
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__qingxi = data.to
      local judge = {
        who = player,
        reason = ty_ex__qingxi.name,
        pattern = ".|.|heart,diamond",
      }
      room:judge(judge)
      if judge.card.color == Card.Red then
        data.disresponsive = true
      end
    end
  end,
})

ty_ex__qingxi:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        if use.extra_data and use.extra_data.ty_ex__qingxi == data.to.id then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

return ty_ex__qingxi
