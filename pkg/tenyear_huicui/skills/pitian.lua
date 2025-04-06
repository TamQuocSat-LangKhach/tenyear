local pitian = fk.CreateSkill {
  name = "pitian",
}

Fk:loadTranslationTable{
  ["pitian"] = "辟田",
  [":pitian"] = "当你的牌因弃置而进入弃牌堆后或当你受到伤害后，你的手牌上限+1。结束阶段，若你的手牌数小于手牌上限，"..
  "你可以将手牌摸至手牌上限（最多摸五张），然后重置因此技能而增加的手牌上限。",

  ["#pitian-invoke"] = "辟田：你可以将手牌摸至手牌上限，然后重置“辟田”增加的手牌上限",
  ["@pitian"] = "辟田",

  ["$pitian1"] = "此间辟地数旬，必成良田千亩。",
  ["$pitian2"] = "民以物力为天，物力唯田可得。",
}

pitian:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(pitian.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@pitian", 1)
  end,
})

pitian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pitian.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@pitian", 1)
  end,
})

pitian:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pitian.name) and player.phase == Player.Finish and
      player:getHandcardNum() < player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = pitian.name,
      prompt = "#pitian-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local n = math.min(player:getMaxCards() - player:getHandcardNum(), 5)
    player.room:setPlayerMark(player, "@pitian", 0)
    player:drawCards(n, pitian.name)
  end,
})

pitian:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("@pitian")
  end,
})

pitian:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if player:getMark("@pitian") > 0 then
    room:addPlayerMark(player, MarkEnum.AddMaxCards, player:getMark("@pitian"))
    room:setPlayerMark(player, "@pitian", 0)
  end
end)

return pitian
