local fenglue = fk.CreateSkill {
  name = "ty__fenglue",
}

Fk:loadTranslationTable{
  ["ty__fenglue"] = "锋略",
  [":ty__fenglue"] = "出牌阶段限一次，你可以和一名角色拼点。若：你赢，你获得其区域里的两张牌；你与其均没赢，"..
  "你获得你的拼点牌且此技能视为未发动过；其赢，其获得你拼点的牌。",

  ["#ty__fenglue"] = "锋略：与一名角色拼点，赢者获得对方的牌",

  ["$ty__fenglue1"] = "当今敢称贤者，唯袁氏本初一人！",
  ["$ty__fenglue2"] = "冀州宝地，本当贤者居之！",
}

fenglue:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__fenglue",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(fenglue.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, fenglue.name)
    local winner = pindian.results[target].winner
    if winner == player then
      if target:isAllNude() or player.dead then return end
      local cards = target:getCardIds("hej")
      if #cards > 2 then
        cards = room:askToChooseCards(player, {
          min = 2,
          max = 2,
          target = target,
          flag = "hej",
          skill_name = fenglue.name,
        })
      end
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, fenglue.name)
    elseif winner == target then
      if room:getCardArea(pindian.fromCard) == Card.DiscardPile and not target.dead then
        room:obtainCard(target, pindian.fromCard, true, fk.ReasonJustMove, target, fenglue.name)
      end
    elseif not player.dead then
      if room:getCardArea(pindian.fromCard) == Card.DiscardPile then
        room:obtainCard(player, pindian.fromCard, true, fk.ReasonJustMove, player, fenglue.name)
      end
      player:setSkillUseHistory(fenglue.name, 0, Player.HistoryPhase)
    end
  end,
})

return fenglue
