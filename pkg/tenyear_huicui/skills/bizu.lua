local bizu = fk.CreateSkill {
  name = "bizu",
}

Fk:loadTranslationTable{
  ["bizu"] = "庇族",
  [":bizu"] = "出牌阶段，你可以令所有手牌数与你相等的角色各摸一张牌，若这些角色与你本回合此前发动此技能时选择的角色完全相同，此技能本回合失效。",

  ["#bizu-last"] = "庇族：令所有手牌数与你相同的角色各摸一张牌（发动后本回合失效）",
  ["#bizu"] = "庇族：令所有手牌数与你相同的角色各摸一张牌",

  ["$bizu1"] = "花既繁于枝，当为众乔灌荫。",
  ["$bizu2"] = "手执金麾伞，可为我族遮风挡雨。",
}

bizu:addEffect("active", {
  anim_type = "support",
  prompt = function(self, player)
    local x = player:getHandcardNum()
    local tos = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:getHandcardNum() == x then
        table.insert(tos, p.id)
      end
    end
    local mark = player:getTableMark("bizu_targets-turn")
    if table.find(mark, function(tos2)
      return #tos == #tos2 and table.every(tos, function(pid)
        return table.contains(tos2, pid)
      end)
    end) then
      return "#bizu-last"
    else
      return "#bizu"
    end
  end,
  card_num = 0,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if to_select:getHandcardNum() == player:getHandcardNum() then
      return { {content = "draw_card", type = "normal"} }
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local x = player:getHandcardNum()
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p:getHandcardNum() == x
    end)
    room:doIndicate(player, targets)
    local tos = table.map(targets, Util.IdMapper)
    local mark = player:getTableMark("bizu_targets-turn")
    if table.find(mark, function(tos2)
      return #tos == #tos2 and table.every(tos, function(pid)
        return table.contains(tos2, pid)
      end)
    end) then
      room:invalidateSkill(player, bizu.name, "-turn")
    else
      table.insert(mark, tos)
      room:setPlayerMark(player, "bizu_targets-turn", mark)
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(1, bizu.name)
      end
    end
  end,
})

return bizu
