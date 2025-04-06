local shefu = fk.CreateSkill{
  name = "ty__shefu",
}

Fk:loadTranslationTable{
  ["ty__shefu"] = "设伏",
  [":ty__shefu"] = "结束阶段，你可以将一张牌扣置于武将牌上并记录一个基本牌或锦囊牌的名称，称为“伏兵”（须与其他“伏兵”记录的名称均不同）。"..
  "当其他角色于你的回合外使用手牌时，你可以将记录的牌名与此牌相同的一张“伏兵”置入弃牌堆，然后此牌无效。"..
  "若此时是使用者的回合，其本回合所有技能失效。",

  ["#ty__shefu-ask"] = "设伏：你可以将一张牌扣置为“伏兵”",
  ["$ty__shefu"] = "伏兵",
  ["@ty__shefu"] = "伏兵",
  ["#ty__shefu-invoke"] = "设伏：是否令 %dest 使用的%arg无效？",
  ["@@ty__shefu-turn"] = "设伏 技能失效",

  ["$ty__shefu1"] = "吾已埋下伏兵，敌兵一来，管教他瓮中捉鳖。",
  ["$ty__shefu2"] = "我已设下重重圈套，就等敌军入彀矣。",
}

shefu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "$ty__shefu",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shefu.name) and player.phase == Player.Finish and
      not player:isNude() and #player:getPile("$ty__shefu") < #Fk:getAllCardNames("btd")
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty__shefu_active",
      prompt = "#ty__shefu-ask",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards
    local name = event:getCostData(self).choice
    room:moveCardTo(card, Card.PlayerSpecial, player, fk.ReasonJustMove, shefu.name, "$ty__shefu", false, player,
      {"@ty__shefu", Fk:translate(name)})
  end,
})

shefu:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shefu.name) and target ~= player and player.room.current ~= player and
      (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
      data:IsUsingHandcard(target) and
      table.find(player:getPile("$ty__shefu"), function (id)
        return Fk:getCardById(id):getMark("@ty__shefu") == Fk:translate(data.card.trueName)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shefu.name,
      prompt = "#shefu-invoke::"..target.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.toCard = nil
    data:removeAllTargets()
    local id = table.filter(player:getPile("$ty__shefu"), function (id)
      return Fk:getCardById(id):getMark("@ty__shefu") == Fk:translate(data.card.trueName)
    end)
    room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, shefu.name, nil, true, player)
    if room.current == target and not target.dead then
      room:setPlayerMark(target, "@@ty__shefu-turn", 1)
    end
  end,
})

shefu:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@ty__shefu-turn") > 0 and skill:isPlayerSkill(from)
  end,
})

shefu:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "$ty__shefu" then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@ty__shefu", 0)
          end
        end
      end
    end
  end,
})

return shefu
