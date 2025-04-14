local jianyan = fk.CreateSkill {
  name = "ty_ex__jianyan",
}

Fk:loadTranslationTable{
  ["ty_ex__jianyan"] = "荐言",
  [":ty_ex__jianyan"] = "出牌阶段各限一次，你可以声明一种牌的类别或颜色，亮出牌堆中第一张符合你声明的牌，交给一名男性角色。",

  ["#ty_ex__jianyan"] = "荐言：声明牌的类别或颜色，将一张符合条件的牌交给一名角色",
  ["#ty_ex__jianyan-give"] = "荐言：将%arg交给一名角色",

  ["$ty_ex__jianyan1"] = "此人之才，胜吾十倍。",
  ["$ty_ex__jianyan2"] = "先生大才，请受此礼。",
}

jianyan:addEffect("active", {
  anim_type = "support",
  prompt = "#ty_ex__jianyan",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:getMark("ty_ex__jianyan_color-phase") == 0 or player:getMark("ty_ex__jianyan_type-phase") == 0
  end,
  interaction = function(self, player)
    local choices = (player:getMark("ty_ex__jianyan_type-phase") == 0) and {"basic", "trick", "equip"} or {}
    if player:getMark("ty_ex__jianyan_color-phase") == 0 then
      table.insertTable(choices, {"black", "red"})
    end
    return UI.ComboBox {choices = choices }
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local pattern = self.interaction.data
    if table.contains({"black", "red"}, pattern) then
      room:setPlayerMark(player, "ty_ex__jianyan_color-phase", 1)
      if pattern == "black" then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
    else
      room:setPlayerMark(player, "ty_ex__jianyan_type-phase", 1)
      pattern = ".|.|.|.|.|" .. pattern
    end
    local get
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id):matchPattern(pattern) then
        get = id
        break
      end
    end
    if not get then return end
    room:turnOverCardsFromDrawPile(player, { get }, jianyan.name)
    local targets = table.filter(room.alive_players, function(p)
      return p:isMale()
    end)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty_ex__jianyan-give:::" .. Fk:getCardById(get):toLogString(),
        skill_name = jianyan.name,
        cancelable = false,
      })[1]
      room:obtainCard(to, get, true, fk.ReasonGive, player, jianyan.name)
    end

    room:cleanProcessingArea({ get }, jianyan.name)
  end,
})

jianyan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "ty_ex__jianyan_color-phase", 0)
  player.room:setPlayerMark(player, "ty_ex__jianyan_type-phase", 0)
end)

return jianyan
