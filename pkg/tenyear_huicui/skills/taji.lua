local taji = fk.CreateSkill {
  name = "taji",
}

Fk:loadTranslationTable{
  ["taji"] = "踏寂",
  [":taji"] = "当你失去手牌后，你根据此牌的失去方式执行效果：<br>使用-弃置一名其他角色一张牌；<br>打出-摸一张牌；<br>"..
  "弃置-回复1点体力；<br>其他-你下次对其他角色造成的伤害+1。",

  ["#taji-choose"] = "踏寂：弃置一名其他角色一张牌",
  ["@taji"] = "踏寂 伤害+",

  ["$taji1"] = "仙途本寂寥，结发叹长生。",
  ["$taji2"] = "仙者不言，手执春风。",
}

local function doTaji(player, n)
  local room = player.room
  if n == 1 then
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = taji.name,
      prompt = "#taji-choose",
      cancelable = false,
    })[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = taji.name,
    })
    room:throwCard(card, taji.name, to, player)
  elseif n == 2 then
    player:drawCards(1, taji.name)
  elseif n == 3 then
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = taji.name,
      }
    end
  elseif n == 4 then
    room:addPlayerMark(player, "@taji", 1)
  end
end

taji:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(taji.name) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local index = {}
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            if move.moveReason == fk.ReasonUse then
              table.insertIfNeed(index, 1)
            elseif move.moveReason == fk.ReasonResponse then
              table.insertIfNeed(index, 2)
            elseif move.moveReason == fk.ReasonDiscard then
              table.insertIfNeed(index, 3)
            else
              table.insertIfNeed(index, 4)
            end
          end
        end
      end
    end
    for _, i in ipairs(index) do
      if player.dead then return end
      doTaji(player, i)
      if not player.dead and player:getMark("@@qinghuang-turn") > 0 then
        local nums = {1, 2, 3, 4}
        table.removeOne(nums, i)
        doTaji(player, table.random(nums))
      end
    end
  end,
})

taji:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and player:getMark("@taji") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@taji"))
    player.room:setPlayerMark(player, "@taji", 0)
  end,
})

return taji
