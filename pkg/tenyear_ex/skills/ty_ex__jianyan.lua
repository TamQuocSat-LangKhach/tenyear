local ty_ex__jianyan = fk.CreateSkill {
  name = "ty_ex__jianyan"
}

Fk:loadTranslationTable{
  ['ty_ex__jianyan'] = '荐言',
  ['#ty_ex__jianyan-give'] = '荐言：你可将 %arg 交给一名角色',
  [':ty_ex__jianyan'] = '出牌阶段各限一次，你可以声明一种牌的类别或一种牌的颜色，亮出牌堆中第一张符合你声明的牌，交给一名男性角色。',
  ['$ty_ex__jianyan1'] = '此人之才，胜吾十倍。',
  ['$ty_ex__jianyan2'] = '先生大才，请受此礼。',
}

ty_ex__jianyan:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("ty_ex__jianyan_color-phase") == 0 or player:getMark("ty_ex__jianyan_type-phase") == 0
  end,
  interaction = function(player)
    local choices = (player:getMark("ty_ex__jianyan_type-phase") == 0) and {"basic", "trick", "equip"} or {}
    if player:getMark("ty_ex__jianyan_color-phase") == 0 then
      table.insertTable(choices, {"black", "red"})
    end
    return UI.ComboBox {choices = choices }
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local pattern = self.interaction.data
    local _pattern
    if table.contains({"black", "red"}, pattern) then
      room:setPlayerMark(player, "ty_ex__jianyan_color-phase", 1)
      if pattern == "black" then
        _pattern = ".|.|spade,club"
      else
        _pattern = ".|.|heart,diamond"
      end
    else
      room:setPlayerMark(player, "ty_ex__jianyan_type-phase", 1)
      _pattern = ".|.|.|.|.|" .. pattern
    end
    local get
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id):matchPattern(_pattern) then
        get = id
        break
      end
    end
    if not get then return end
    get = Fk:getCardById(get)
    room:moveCardTo(get, Card.Processing, nil, fk.ReasonJustMove, ty_ex__jianyan.name)
    room:delay(500)
    local targets = table.map(table.filter(room.alive_players, function(p) return p:isMale() end), Util.IdMapper)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty_ex__jianyan-give:::" .. get:toLogString(),
        skill_name = ty_ex__jianyan.name,
        cancelable = false
      })[1]
      room:obtainCard(to, get, true, fk.ReasonGive, player.id)
    elseif room:getCardArea(get.id) == Card.Processing then
      room:moveCardTo(get, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, ty_ex__jianyan.name, nil, true, player.id)
    end
  end,
})

return ty_ex__jianyan
