local ty_ex__fenli = fk.CreateSkill {
  name = "ty_ex__fenli"
}

Fk:loadTranslationTable{
  ['ty_ex__fenli'] = '奋励',
  ['phase_judge_and_draw'] = '判定和摸牌阶段',
  ['#ty_ex__fenli-invoke'] = '奋励：你可以跳过 %arg',
  [':ty_ex__fenli'] = '若你的手牌数为全场最多，你可以跳过判定和摸牌阶段；若你的体力值为全场最多，你可以跳过出牌阶段；若你的装备区里有牌且数量为全场最多，你可以跳过弃牌阶段。',
  ['$ty_ex__fenli1'] = '兵威已振，怎能踟蹰不前？',
  ['$ty_ex__fenli2'] = '敌势汹汹，自当奋勇以对。',
}

ty_ex__fenli:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(ty_ex__fenli) then return false end
    if data.to == Player.Draw or data.to == Player.Judge then
      return table.every(player.room:getOtherPlayers(player), function (p)
        return p:getHandcardNum() <= player:getHandcardNum() end)
    elseif data.to == Player.Play then
      return table.every(player.room:getOtherPlayers(player), function (p) return p.hp <= player.hp end)
    elseif data.to == Player.Discard and #player.player_cards[Player.Equip] > 0 then
      return table.every(player.room:getOtherPlayers(player), function (p)
        return #p.player_cards[Player.Equip] <= #player.player_cards[Player.Equip] end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local phase = "phase_discard"
    if data.to == Player.Draw or data.to == Player.Judge then
      phase = "phase_judge_and_draw"
    elseif data.to == Player.Play then
      phase = "phase_play"
    end
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__fenli.name,
      prompt = "#ty_ex__fenli-invoke:::" .. phase
    })
  end,
  on_use = function(self, event, target, player, data)
    player:skip(data.to)
    if data.to == Player.Draw then
      player:skip(Player.Judge)
    elseif data.to == Player.Judge then
      player:skip(Player.Draw)
    end
    return true
  end,
})

return ty_ex__fenli
