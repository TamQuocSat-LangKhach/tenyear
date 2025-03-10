local tunjun = fk.CreateSkill {
  name = "tunjun"
}

Fk:loadTranslationTable{
  ['tunjun'] = '屯军',
  ['#tunjun-prompt'] = '屯军：选择一名角色，令其随机使用 %arg 张装备牌',
  ['lueming'] = '掠命',
  [':tunjun'] = '限定技，出牌阶段，你可以选择一名角色，令其随机使用牌堆中的X张不同类型的装备牌（不替换原有装备，X为你发动〖掠命〗的次数）。',
  ['$tunjun1'] = '得封侯爵，屯军弘农。',
  ['$tunjun2'] = '屯军弘农，养精蓄锐。',
}

tunjun:addEffect('active', {
  anim_type = "drawcard",
  target_num = 1,
  card_num = 0,
  prompt = function (skill, player)
    return "#tunjun-prompt:::"..player:usedSkillTimes("lueming", Player.HistoryGame)
  end,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(tunjun.name, Player.HistoryGame) == 0 and player:usedSkillTimes("lueming", Player.HistoryGame) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] < 4  --TODO: no treasure yet
  end,
  on_use = function(self, room, use, player)
    local target = room:getPlayerById(use.tos[1])
    local n = player:usedSkillTimes("lueming", Player.HistoryGame)
    for _ = 1, n, 1 do
      if player.dead then break end
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        local card = Fk:getCardById(id, true)
        if card.type == Card.TypeEquip and target:getEquipment(card.sub_type) == nil and not target:prohibitUse(card) then
          table.insertIfNeed(cards, id)
        end
      end
      if #cards > 0 then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = Fk:getCardById(table.random(cards), true),
        })
      else
        break
      end
    end
  end,
})

return tunjun
