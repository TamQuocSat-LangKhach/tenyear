local xiaoyin = fk.CreateSkill {
  name = "xiaoyin"
}

Fk:loadTranslationTable{
  ['xiaoyin_active'] = '硝引',
}

xiaoyin:addEffect('active', {
  mute = true,
  card_num = 1,
  target_num = 1,

  expand_pile = function (skill, player)
    return player:getTableMark(xiaoyin.name .. "_cards")
  end,

  card_filter = function(self, player, to_select, selected, targets)
    return #selected == 0 and table.contains(player:getTableMark(xiaoyin.name .. "_cards"), to_select)
  end,

  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player.id then
      local to = Fk:currentRoom():getPlayerById(to_select)
      if to:isRemoved() then return false end
      local targets = player:getTableMark(xiaoyin.name .. "_targets")
      if #targets == 0 then return true end
      if table.contains(targets, to_select) then return false end
      return table.find(targets, function(pid)
        local p = Fk:currentRoom():getPlayerById(pid)
        return p:getNextAlive() == to or to:getNextAlive() == p
          or (p:getNextAlive() == player and player:getNextAlive() == to)
          or (to:getNextAlive() == player and player:getNextAlive() == p)
      end)
    end
  end,
})

return xiaoyin
