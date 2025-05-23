local chengshang = fk.CreateSkill {
  name = "chengshang",
}

Fk:loadTranslationTable{
  ["chengshang"] = "承赏",
  [":chengshang"] = "每阶段限一次，当你于出牌阶段内使用指定其他角色为目标的牌结算后，若此牌没有造成伤害，你可以获得牌堆中"..
  "所有与此牌花色点数均相同的牌。若你没有因此获得牌，此技能视为未发动过。",

  ["#chengshang-invoke"] = "承赏：你可以获得牌堆中所有的%arg%arg2牌",

  ["$chengshang1"] = "嘉其抗直，甚爱待之。",
  ["$chengshang2"] = "为国鞠躬，必受封赏。",
}

chengshang:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengshang.name) and player.phase == Player.Play and
      table.find(data.tos, function(p)
        return p ~= player
      end) and not data.damageDealt and
      data.card.suit ~= Card.NoSuit and data.card.number > 0 and
      player:usedSkillTimes(chengshang.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chengshang.name,
      prompt = "#chengshang-invoke:::"..data.card:getSuitString(true)..":"..data.card.number,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|"..data.card.number.."|"..data.card:getSuitString())
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = chengshang.name,
      })
    else
      player:setSkillUseHistory(chengshang.name, 0, Player.HistoryPhase)
    end
  end,
})

return chengshang
