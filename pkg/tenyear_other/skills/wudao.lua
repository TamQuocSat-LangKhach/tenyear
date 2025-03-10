local wudao = fk.CreateSkill {
  name = "wudao"
}

Fk:loadTranslationTable{
  ['wudao'] = '悟道',
  ['@wudao-turn'] = '悟道',
  ['#wudao-invoke'] = '悟道：你可以令当前结算结束后，本回合你使用 %arg 伤害+1且不可被响应',
  [':wudao'] = '每回合每种类别限一次，当你使用基本牌或锦囊牌时，若此牌与你使用的上一张牌类别相同，你可以令此牌结算结束后，你本回合使用此类型的牌不能被响应且造成的伤害+1。',
  ['$wudao1'] = '众所周知，能力越大，能力也就越大。',
  ['$wudao2'] = '龙争虎斗彼岸花，约翰给你一个家。',
  ['$wudao3'] = '唯一能够打破命运牢笼的，只有我们自己。',
}

wudao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(wudao.name) and data.card.type ~= Card.TypeEquip then
      local mark = player:getTableMark("@wudao-turn")
      if table.contains(mark, data.card:getTypeString().."_char") then
        return data.card.sub_type ~= Card.SubtypeDelayedTrick
      else
        local use_e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if not use_e then return false end
        local events = player.room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #events, 1, -1 do
          local e = events[i]
          local use = e.data[1]
          if use.from == player.id then
            if e.id < use_e.id then
              return use.card.type == data.card.type
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return table.contains(player:getTableMark("@wudao-turn"), data.card:getTypeString().."_char") or
      player.room:askToSkillInvoke(player, {skill_name = wudao.name, prompt = "#wudao-invoke:::" .. data.card:getTypeString()})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@wudao-turn")
    local type_name = data.card:getTypeString().."_char"
    if table.contains(mark, type_name) then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      end
    else
      table.insert(mark, type_name)
      room:setPlayerMark(player, "@wudao-turn", mark)
    end
  end,
})

return wudao
