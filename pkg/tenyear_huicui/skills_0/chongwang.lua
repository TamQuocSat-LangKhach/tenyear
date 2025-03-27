local chongwang = fk.CreateSkill {
  name = "chongwang"
}

Fk:loadTranslationTable{
  ['chongwang'] = '崇望',
  ['chongwang2'] = '此牌无效',
  ['chongwang1'] = '其获得此牌',
  ['#chongwang-invoke'] = '崇望：你可以令 %dest 对%arg执行的一项',
  ['@@chongwang'] = '崇望',
  [':chongwang'] = '其他角色使用一张基本牌或普通锦囊牌时，若你为上一张牌的使用者，你可令其获得其使用的牌或令该牌无效。',
  ['$chongwang1'] = '乡人所崇者，烈之义行也。',
  ['$chongwang2'] = '诸家争讼曲直，可质于我。',
}

chongwang:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chongwang) and target ~= player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      local logic = player.room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      local last_find = false
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          if e.data[1].from == player.id then
            return true
          end
          return false
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel", "chongwang2"}
    if player.room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, 2, "chongwang1")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = chongwang.name,
      prompt = "#chongwang-invoke::" .. target.id .. ":" .. data.card:toLogString(),
      all_choices = {"chongwang1", "chongwang2", "Cancel"}
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(skill)
    if cost_data == "chongwang1" then
      player.room:obtainCard(target, data.card, true, fk.ReasonPrey)
    else
      if data.toCard ~= nil then
        data.toCard = nil
      else
        data.nullifiedTargets = table.map(player.room.players, Util.IdMapper)
      end
    end
  end,
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return player:hasSkill(chongwang, true)
    else
      return data == chongwang and target == player
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    if event == fk.CardUsing and target == player then
      x = 1
    elseif event == fk.EventAcquireSkill then
      local events = player.room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      if #events > 0 and events[#events].data[1].from == player.id then
        x = 1
      end
    end
    if player:getMark("@@chongwang") ~= x then
      player.room:setPlayerMark(player, "@@chongwang", x)
    end
  end,
})

return chongwang
