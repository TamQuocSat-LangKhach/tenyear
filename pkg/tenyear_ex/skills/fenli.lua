local fenli = fk.CreateSkill {
  name = "ty_ex__fenli",
}

Fk:loadTranslationTable{
  ["ty_ex__fenli"] = "奋励",
  [":ty_ex__fenli"] = "若你的手牌数为全场最多，你可以跳过判定和摸牌阶段；若你的体力值为全场最多，你可以跳过出牌阶段；若你的装备区里有牌"..
  "且数量为全场最多，你可以跳过弃牌阶段。",

  ["ty_ex__fenli_judge"] = "判定和摸牌阶段",
  ["#ty_ex__fenli-invoke"] = "奋励：你可以跳过%arg",

  ["$ty_ex__fenli1"] = "兵威已振，怎能踟蹰不前？",
  ["$ty_ex__fenli2"] = "敌势汹汹，自当奋勇以对。",
}

fenli:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fenli.name) and not data.skipped then
      if data.phase == Player.Judge or data.phase == Player.Draw then
        return table.every(player.room:getOtherPlayers(player, false), function (p)
          return p:getHandcardNum() <= player:getHandcardNum()
        end)
      elseif data.phase == Player.Play then
        return table.every(player.room:getOtherPlayers(player, false), function (p)
          return p.hp <= player.hp
        end)
      elseif data.phase == Player.Discard and #player:getCardIds("e") > 0 then
        return table.every(player.room:getOtherPlayers(player, false), function (p)
          return #p:getCardIds("e") <= #player:getCardIds("e")
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local phase
    if data.phase == Player.Judge or data.phase == Player.Draw then
      phase = "ty_ex__fenli_judge"
    elseif data.phase == Player.Play then
      phase = "phase_play"
    elseif data.phase == Player.Discard then
      phase = "phase_discard"
    end
    return player.room:askToSkillInvoke(player, {
      skill_name = fenli.name,
      prompt = "#fenli-invoke:::"..phase,
    })
  end,
  on_use = function(self, event, target, player, data)
    player:skip(data.phase)
    data.skipped = true
    if data.phase == Player.Judge or data.phase == Player.Draw then
      player:skip(Player.Draw)
    elseif data.phase == Player.Draw then
      player:skip(Player.Judge)
    end
  end,
})

return fenli
