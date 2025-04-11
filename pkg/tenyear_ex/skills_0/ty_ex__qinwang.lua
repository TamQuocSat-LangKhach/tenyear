local ty_ex__qinwang = fk.CreateSkill {
  name = "ty_ex__qinwang$"
}

Fk:loadTranslationTable{
  ['#ty_ex__qinwang-ask'] = '勤王：可以交给 %src 一张【杀】',
  ['@@ty_ex__qinwang-inhand-turn'] = '勤王',
  ['#ty_ex__qinwang-draw'] = '勤王：你可以令所有交给你【杀】的角色摸一张牌',
}

ty_ex__qinwang:addEffect('active', {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__qinwang.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local loyal = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then break end
      if not p.dead and p.kingdom == "shu" and not p:isKongcheng() then
        local cards = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          pattern = "slash",
          prompt = "#ty_ex__qinwang-ask:" .. player.id,
          skill_name = ty_ex__qinwang.name
        })
        if #cards > 0 then
          table.insert(loyal, p)
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, ty_ex__qinwang.name, "", true, p.id, "@@ty_ex__qinwang-inhand-turn")
        end
      end
    end
    if not player.dead and #loyal > 0 and room:askToSkillInvoke(player, {
      skill_name = ty_ex__qinwang.name,
      prompt = "#ty_ex__qinwang-draw"
    }) then
      for _, p in ipairs(loyal) do
        if not p.dead then
          p:drawCards(1, ty_ex__qinwang.name)
        end
      end
    end
  end,
})

return ty_ex__qinwang
