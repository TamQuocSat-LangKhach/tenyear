local weidang = fk.CreateSkill {
  name = "weidang"
}

Fk:loadTranslationTable{
  ['#weidang_active'] = '伪谠',
}

weidang:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return Fk:translate(Fk:getCardById(to_select).trueName, "zh_CN"):len() == skill.weidang_num
    end
  end,
})

weidang:onClick(function(self, room, log)
  local player = log.from
  local from = player

  if not self:isAvailable(player) then return false end

  local num = (Fk:getCardById(from.player:currentHandCards()[1]):toString("zh"):len() + 2) % 4 + 3
  self.weidang_num = num

  room:broadcastSkillInvoke(self.name)

  local cards = room:askToCards(player, {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|hand",
    skill_name = self.name,
  })

  if not cards then return false end

  local card_id = cards[1]
  local card = Fk:getCardById(card_id)

  room:moveCardTo(card, from.player, nil, 4, false)

  local to_discard = {}
  for _, p in ipairs(room:getAlivePlayers()) do
    if p ~= player and #p.player:getHandcards() > num then
      table.insert(to_discard, p)
    end
  end

  room:askToDiscard(player, {
    min_num = 0,
    max_num = #to_discard * (num + 1),
    skill_name = self.name,
  })

  return false
end)

return weidang
