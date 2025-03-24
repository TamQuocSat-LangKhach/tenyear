local gushe = fk.CreateSkill {
  name = "ty__gushe",
}

Fk:loadTranslationTable{
  ["ty__gushe"] = "鼓舌",
  [":ty__gushe"] = "出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项: 1.弃置一张牌；2.令你摸一张牌。若你没赢，"..
  "获得一个“饶舌”标记；若你有7个“饶舌”标记，你死亡。当你一回合内累计七次拼点赢时（每有一个“饶舌”标记，此累计次数减1），本回合此技能失效。",

  ["#ty__gushe"] = "鼓舌：与至多三名角色拼点！",
  ["@ty__raoshe"] = "饶舌",
  ["#ty__gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %src 摸一张牌",
  ["#ty__gushe2-discard"] = "鼓舌：你需弃置一张牌",

  ["$ty__gushe1"] = "承寇贼之要，相时而后动，择地而后行，一举更无余事。",
  ["$ty__gushe2"] = "春秋之义，求诸侯莫如勤王。今天王在魏都，宜遣使奉承王命。",
}

gushe:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__gushe",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 3 and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local tos = table.simpleClone(effect.tos)
    room:sortByAction(tos)
    local pindian = player:pindian(effect.tos, gushe.name)
    for to, result in pairs(pindian.results) do
      if not player.dead and result.winner ~= player then
        room:addPlayerMark(player, "@ty__raoshe", 1)
        if player:getMark("@ty__raoshe") >= 7 then
          room:killPlayer({who = player})
        end
        if not player.dead then
          if #room:askToDiscard(player, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = gushe.name,
            cancelable = true,
            prompt = "#ty__gushe-discard:" .. player.id,
          }) == 0 then
            player:drawCards(1, gushe.name)
          end
        end
      end
      if not to.dead and result.winner ~= to then
        if #room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = gushe.name,
          cancelable = not player.dead,
          prompt = "#ty__gushe-discard:"..player.id,
        }) == 0 and not player.dead then
          player:drawCards(1, gushe.name)
        end
      end
    end
  end,
})

gushe:addEffect(fk.PindianResultConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return data.winner and data.winner == player and player:hasSkill(gushe.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    room.logic:getEventsOfScope(GameEvent.Pindian, 1, function(e)
      local pindian = e.data
      for _, result in pairs(pindian.results) do
        if result.winner == player then
          n = n + 1
        end
      end
    end, Player.HistoryTurn)
    if player:getMark("@ty__raoshe") + n > 6 then
      room:invalidateSkill(player, gushe.name, "-turn")
    end
  end,
})

gushe:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ty__raoshe", 0)
end)

return gushe
