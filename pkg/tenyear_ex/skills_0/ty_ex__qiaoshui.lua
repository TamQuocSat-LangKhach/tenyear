local ty_ex__qiaoshui = fk.CreateSkill {
  name = "ty_ex__qiaoshui"
}

Fk:loadTranslationTable{
  ['ty_ex__qiaoshui'] = '巧说',
  ['#ty_ex__qiaoshui-prompt'] = '巧说:与一名角色拼点，若赢，下一张基本牌或普通锦囊牌可增加或取消一个目标',
  ['@@ty_ex__qiaoshui-turn'] = '巧说',
  ['#ty_ex__qiaoshui-choose'] = '巧说：你可以为%arg增加/减少一个目标',
  [':ty_ex__qiaoshui'] = '出牌阶段，你可以与一名角色拼点。若你赢，本回合你使用下一张基本牌或普通锦囊牌可以多或少选择一个目标（无距离限制）；若你没赢，你结束出牌阶段且本回合锦囊牌不计入手牌上限。',
  ['$ty_ex__qiaoshui1'] = '慧心妙舌，难题可解。',
  ['$ty_ex__qiaoshui2'] = '巧言善辩，应对自如。',
}

-- 主动技
ty_ex__qiaoshui:addEffect('active', {
  anim_type = "control",
  prompt = "#ty_ex__qiaoshui-prompt",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and player:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({to}, ty_ex__qiaoshui.name)
    if player.dead then return end
    if pindian.results[to.id].winner == player then
      room:addPlayerMark(player, "@@ty_ex__qiaoshui-turn", 1)
    else
      room:setPlayerMark(player, "ty_ex__qiaoshui_fail-turn", 1)
      player:endPlayPhase()
    end
  end,
})

-- 触发技
ty_ex__qiaoshui:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ty_ex__qiaoshui-turn") > 0
      and data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty_ex__qiaoshui-turn", 0)
    local targets = room:getUseExtraTargets(data, true)
    if #TargetGroup:getRealTargets(data.tos) > 1 then
      table.insertTable(targets, TargetGroup:getRealTargets(data.tos))
    end
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__qiaoshui-choose:::"..data.card:toLogString(),
      skill_name = ty_ex__qiaoshui.name,
      cancelable = true,
      no_indicate = false,
      target_tip_name = "addandcanceltarget_tip",
    }, TargetGroup:getRealTargets(data.tos))
    if #tos == 0 then return false end
    if table.contains(TargetGroup:getRealTargets(data.tos), tos[1]) then
      TargetGroup:removeTarget(data.tos, tos[1])
      room:sendLog{ type = "#RemoveTargetsBySkill", from = target.id, to = tos, arg = ty_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    else
      table.insert(data.tos, tos)
      room:sendLog{ type = "#AddTargetsBySkill", from = target.id, to = tos, arg = ty_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    end
  end,
})

-- 最大手牌技能
ty_ex__qiaoshui:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return player:getMark("ty_ex__qiaoshui_fail-turn") > 0 and card.type == Card.TypeTrick
  end,
})

return ty_ex__qiaoshui
