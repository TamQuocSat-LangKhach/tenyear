local fengxiang = fk.CreateSkill {
  name = "fengxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengxiang"] = "封乡",
  [":fengxiang"] = "锁定技，当你受到伤害后，手牌中“隙”唯一最多的角色回复1点体力（没有唯一最多的角色则改为你摸一张牌）；"..
  "当有角色因手牌数改变而使“隙”唯一最多的角色改变后，你摸一张牌。",

  ["$fengxiang1"] = "北风摧蜀地，王爵换乡侯。",
  ["$fengxiang2"] = "汉皇可负我，我不负父兄。",
}

local function getFengxiangPlayer(room)
  local nums = table.map(room.alive_players, function(p)
    return #table.filter(p:getCardIds("h"), function(id)
      return Fk:getCardById(id, true):getMark("@@zhuning-inhand") > 0
    end)
  end)
  local n = math.max(table.unpack(nums))
  if #table.filter(room.alive_players, function(p)
      return #table.filter(p:getCardIds("h"), function(id)
        return Fk:getCardById(id, true):getMark("@@zhuning-inhand") > 0
      end) == n
    end) > 1 then
      return 0
  else
    return room.alive_players[table.indexOf(nums, n)].id
  end
end

fengxiang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengxiang.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = getFengxiangPlayer(room)
    if to ~= 0 then
      to = room:getPlayerById(to)
      room:doIndicate(player, {to})
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = fengxiang.name
        }
      end
    else
      player:drawCards(1, fengxiang.name)
    end
  end,
})

fengxiang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fengxiang.name) then
      local to = getFengxiangPlayer(player.room)
      for _, move in ipairs(data) do
        if move.extra_data and move.extra_data.fengxiang and move.extra_data.fengxiang ~= to then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, fengxiang.name)
  end,
})

fengxiang:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(fengxiang.name, true) then
      for _, move in ipairs(data) do
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
        if move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      move.extra_data = move.extra_data or {}
      move.extra_data.fengxiang = getFengxiangPlayer(player.room)
    end
  end,
})

return fengxiang
