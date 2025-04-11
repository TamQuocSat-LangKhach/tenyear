local ty_ex__huituo = fk.CreateSkill {
  name = "ty_ex__huituo"
}

Fk:loadTranslationTable{
  ['ty_ex__huituo'] = '恢拓',
  ['@@ty_ex__mingjian'] = '明鉴',
  ['#ty_ex__huituo-choose'] = '你可以发动 恢拓，令一名角色判定，若为红色，其回复1点体力；黑色，其摸%arg张牌',
  [':ty_ex__huituo'] = '当你受到伤害后，你可以令一名角色判定，若结果为：红色，其回复1点体力；黑色，其摸X张牌（X为伤害值）。',
  ['$ty_ex__huituo1'] = '拓土复疆，扬大魏鸿威！',
  ['$ty_ex__huituo2'] = '制律弘法，固天下社稷！',
}

ty_ex__huituo:addEffect({fk.Damaged, fk.Damage}, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty_ex__huituo.name) then return false end
    if event == fk.Damaged then
      return target == player
    elseif event == fk.Damage then
      if target and target:getMark("@@ty_ex__mingjian") > 0 and target.phase ~= Player.NotActive then
        local room = player.room
        local damage_event = room.logic:getCurrentEvent()
        if not damage_event then return false end
        local x = target:getMark("ty_ex__huituo_record-turn")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
            local reason = e.data[3]
            if reason == "damage" then
              local first_damage_event = e:findParent(GameEvent.Damage)
              if first_damage_event and first_damage_event.data[1].from == target then
                x = first_damage_event.id
                room:setPlayerMark(target, "ty_ex__huituo_record-turn", x)
                return true
              end
            end
          end, Player.HistoryTurn)
        end
        return damage_event.id == x
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__huituo-choose:::" .. tostring(data.damage),
      skill_name = ty_ex__huituo.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local judge = {
      who = to,
      reason = ty_ex__huituo.name,
      pattern = ".",
    }
    room:judge(judge)
    if to.dead then return false end
    if judge.card.color == Card.Red then
      if to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = ty_ex__huituo.name
        })
      end
    elseif judge.card.color == Card.Black then
      to:drawCards(data.damage, ty_ex__huituo.name)
    end
  end,
})

return ty_ex__huituo
