local lianhua = fk.CreateSkill {
  name = "lianhua",
}

Fk:loadTranslationTable{
  ["lianhua"] = "炼化",
  [":lianhua"] = "你的回合外，当其他角色受到伤害后，你获得一枚“丹血”标记（阵营与你相同为红色，不同则为黑色，颜色不可见）"..
  "直到你出牌阶段开始。<br>"..
  "准备阶段，根据“丹血”标记的数量和颜色，你获得相应的牌和相应的技能直到回合结束：<br>"..
  "3枚或以下：【桃】和〖英姿〗；<br>"..
  "超过3枚且红色“丹血”较多：【无中生有】和〖观星〗；<br>"..
  "超过3枚且黑色“丹血”较多：【顺手牵羊】和〖直言〗；<br>"..
  "超过3枚且红色和黑色一样多：【杀】、【决斗】和〖攻心〗。",

  ["@lianhua"] = "丹血",

  ["$lianhua1"] = "白日青山，飞升化仙。",
  ["$lianhua2"] = "草木精炼，万物化丹。",
}

lianhua:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lianhua.name) and target ~= player and player.room.current ~= player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local color = "black"
    if table.contains({"lord", "loyalist"}, player.role) and table.contains({"lord", "loyalist"}, target.role) or
      (player.role == target.role) then
      color = "red"
    end
    room:addPlayerMark(player, "lianhua-"..color, 1)
    room:setPlayerMark(player, "@lianhua", player:getMark("lianhua-red") + player:getMark("lianhua-black"))
  end,
})

lianhua:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianhua.name) and player.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern, name
    if player:getMark("@lianhua") < 4 then
      pattern, name = "peach", "ex__yingzi"
    else
      if player:getMark("lianhua-red") > player:getMark("lianhua-black") then
        pattern, name = "ex_nihilo", "ex__guanxing"
      elseif player:getMark("lianhua-red") < player:getMark("lianhua-black") then
        pattern, name = "snatch", "ty_ex__zhiyan"
      elseif player:getMark("lianhua-red") == player:getMark("lianhua-black") then
        pattern, name = "slash", "gongxin"
      end
    end
    local cards = room:getCardsFromPileByRule(pattern)
    if player:getMark("@lianhua") > 3 and player:getMark("lianhua-red") == player:getMark("lianhua-black") then
      table.insertTable(cards, room:getCardsFromPileByRule("duel"))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        name = lianhua.name,
      })
    end
    if not player:hasSkill(name, true) and not player.dead then
      room:handleAddLoseSkills(player, name)
      room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..name)
      end)
    end
  end,
})

lianhua:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@lianhua", 0)
    room:setPlayerMark(player, "lianhua-red", 0)
    room:setPlayerMark(player, "lianhua-black", 0)
  end,
})

return lianhua
