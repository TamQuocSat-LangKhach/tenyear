local weipo = fk.CreateSkill {
  name = "ty__weipo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__weipo"] = "危迫",
  [":ty__weipo"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，你将手牌摸至体力上限。若如此做，此牌结算结束后，若你的手牌数小于"..
  "体力上限，你需交给该角色一张手牌且此技能失效直到你下回合开始。",

  ["#ty__weipo-give"] = "危迫：你需交给 %src 一张手牌",

  ["$ty__weipo1"] = "临渊勒马，进退维谷！",
  ["$ty__weipo2"] = "前狼后虎，朝不保夕！",
}

weipo:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weipo.name) and
      data.from ~= player and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), weipo.name)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__weipo_players = data.extra_data.ty__weipo_players or {}
    table.insertIfNeed(data.extra_data.ty__weipo_players, player.id)
  end,
})

weipo:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ty__weipo_players and table.contains(data.extra_data.ty__weipo_players, player.id) and
      not player.dead and player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not target.dead and not player:isKongcheng() then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        prompt = "#ty__weipo-give:"..target.id,
        skill_name = weipo.name,
        cancelable = false,
      })
      if #card > 0 then
        room:obtainCard(target, card, false, fk.ReasonGive, player, weipo.name)
      end
    end
    if player:hasSkill(weipo.name) then
      room:setPlayerMark(player, "weipo_invalidate", 1)
      room:invalidateSkill(player, weipo.name)
    end
  end,
})

weipo:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("weipo_invalidate") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "weipo_invalidate", 0)
    room:validateSkill(player, weipo.name)
  end,
})

weipo:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "weipo_invalidate", 0)
  room:validateSkill(player, weipo.name)
end)

return weipo
