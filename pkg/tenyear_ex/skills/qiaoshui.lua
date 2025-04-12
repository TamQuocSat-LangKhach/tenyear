local qiaoshui = fk.CreateSkill {
  name = "ty_ex__qiaoshui",
}

Fk:loadTranslationTable{
  ["ty_ex__qiaoshui"] = "巧说",
  [":ty_ex__qiaoshui"] = "出牌阶段，你可以与一名角色拼点。若你赢，本回合你使用下一张基本牌或普通锦囊牌可以增加或减少一个目标"..
  "（无距离限制）；若你没赢，你结束出牌阶段且本回合锦囊牌不计入手牌上限。",

  ["#ty_ex__qiaoshui"] = "巧说：与一名角色拼点，若赢，下一张基本牌或普通锦囊牌可以增加或减少一个目标",
  ["@@ty_ex__qiaoshui-turn"] = "巧说",
  ["#ty_ex__qiaoshui-choose"] = "巧说：你可以为%arg增加或减少一个目标",

  ["$ty_ex__qiaoshui1"] = "慧心妙舌，难题可解。",
  ["$ty_ex__qiaoshui2"] = "巧言善辩，应对自如。",
}

qiaoshui:addEffect("active", {
  anim_type = "control",
  prompt = "#ty_ex__qiaoshui",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, qiaoshui.name)
    if player.dead then return end
    if pindian.results[target].winner == player then
      room:addPlayerMark(player, "@@ty_ex__qiaoshui-turn", 1)
    else
      room:setPlayerMark(player, "ty_ex__qiaoshui_fail-turn", 1)
      player:endPlayPhase()
    end
  end,
})

qiaoshui:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ty_ex__qiaoshui-turn") > 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty_ex__qiaoshui-turn", 0)
    local targets = data:getExtraTargets({bypass_distances = true})
    table.insertTable(targets, data.tos)
    local to = room:askToChoosePlayers(player, {
      skill_name = qiaoshui.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ty_ex__qiaoshui-choose:::"..data.card:toLogString(),
      cancelable = true,
      extra_data = table.map(data.tos, Util.IdMapper),
      target_tip_name = "addandcanceltarget_tip",
    })
    if #to > 0 then
      to = to[1]
      if table.contains(data.tos, to) then
        data:removeTarget(to)
      else
        data:addTarget(to)
      end
    end
  end,
})

qiaoshui:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:getMark("ty_ex__qiaoshui_fail-turn") > 0 and card.type == Card.TypeTrick
  end,
})

return qiaoshui
