local ty_ex__zishou = fk.CreateSkill {
  name = "ty_ex__zishou_active"
}

Fk:loadTranslationTable{
  ['ty_ex__zishou_active'] = '自守',
}

ty_ex__zishou:addEffect('active', {
  target_num = 0,
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip or player:prohibitDiscard(Fk:getCardById(to_select)) then return end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
})

return ty_ex__zishou
