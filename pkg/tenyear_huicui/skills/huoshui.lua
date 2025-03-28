local huoshui = fk.CreateSkill {
  name = "ty__huoshui",
}

Fk:loadTranslationTable{
  ["ty__huoshui"] = "祸水",
  [":ty__huoshui"] = "准备阶段，你可以令至多X名其他角色（X为你已损失体力值，至少为1，至多为3）按你选择的顺序依次执行一项："..
  "1.本回合所有非锁定技失效；2.交给你一张手牌；3.弃置装备区里的所有牌。",

  ["#ty__huoshui-choose"] = "祸水：选择至多%arg名角色，按照选择的顺序：<br>1.本回合非锁定技失效，2.交给你一张手牌，3.弃置装备区里的所有牌",
  ["ty__huoshui_tip1"] = "非锁定技失效",
  ["ty__huoshui_tip2"] = "交出手牌",
  ["ty__huoshui_tip3"] = "弃置装备",
  ["#ty__huoshui-give"] = "祸水：你需交给 %src 一张手牌",

  ["$ty__huoshui1"] = "呵呵，走不动了嘛。",
  ["$ty__huoshui2"] = "别走了，再玩一会儿嘛。",
}

Fk:addTargetTip{
  name = "ty__huoshui",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if table.contains(selected, to_select) then
      return "ty__huoshui_tip"..table.indexOf(selected, to_select)
    end
  end,
}

huoshui:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huoshui.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = math.min(player:getLostHp(), 3),
      targets = room:getOtherPlayers(player, false),
      skill_name = huoshui.name,
      prompt = "#ty__huoshui-choose:::"..math.min(player:getLostHp(), 3),
      cancelable = true,
      target_tip_name = huoshui.name,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(event:getCostData(self).tos)
    for i = 1, 3 do
      local p = tos[i]
      if not p.dead then
        if i == 1 then
          room:setPlayerMark(p, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
        elseif i == 2 then
          if not player.dead and not p:isKongcheng() then
            local cards = room:askToCards(p, {
              min_num = 1,
              max_num = 1,
              include_equip = false,
              skill_name = huoshui.name,
              prompt = "#ty__huoshui-give:"..player.id,
              cancelable = false,
            })
            room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, huoshui.name, nil, false, p)
          end
        elseif i == 3 then
          p:throwAllCards("e", huoshui.name)
        end
      end
    end
  end,
})

return huoshui
