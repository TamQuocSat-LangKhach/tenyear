local qinwang = fk.CreateSkill {
  name = "ty_ex__qinwang",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["ty_ex__qinwang"] = "勤王",
  [":ty_ex__qinwang"] = "主公技，出牌阶段限一次，你可以令其他蜀势力角色依次选择是否交给你一张【杀】，然后你可以令所有交给你【杀】的角色摸一张牌"..
  "（以此法获得的【杀】于本回合不会被〖战绝〗使用）。",

  ["#ty_ex__qinwang"] = "勤王：令蜀势力角色选择是否交给你一张【杀】，你可以令这些角色各摸一张牌",
  ["#ty_ex__qinwang-ask"] = "勤王：你可以交给 %src 一张【杀】",
  ["#ty_ex__qinwang-draw"] = "勤王：你可以令所有交给你【杀】的角色摸一张牌",
  ["@@ty_ex__qinwang-inhand-turn"] = "勤王",

  ["$ty_ex__qinwang1"] = "泰山倾崩，可有坚贞之臣？",
  ["$ty_ex__qinwang2"] = "大江潮来，怎无忠勇之士？",
}

qinwang:addEffect("active", {
  anim_type = "support",
  prompt = "#ty_ex__qinwang",
  can_use = function(self, player)
    return player:usedSkillTimes(qinwang.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p ~= player and p.kingdom == "shu" and not p:isKongcheng()
      end)
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:doIndicate(player, table.filter(room:getOtherPlayers(player, false), function (p)
      return p.kingdom == "shu" and not p:isKongcheng()
    end))
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
          skill_name = qinwang.name
        })
        if #cards > 0 then
          table.insert(loyal, p)
          local mark = player:hasSkill("ty_ex__zhanjue", true) and "@@ty_ex__qinwang-inhand-turn" or nil
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, qinwang.name, nil, true, p, mark)
        end
      end
    end
    if not player.dead and #loyal > 0 and room:askToSkillInvoke(player, {
      skill_name = qinwang.name,
      prompt = "#ty_ex__qinwang-draw",
    }) then
      for _, p in ipairs(loyal) do
        if not p.dead then
          p:drawCards(1, qinwang.name)
        end
      end
    end
  end,
})

return qinwang
