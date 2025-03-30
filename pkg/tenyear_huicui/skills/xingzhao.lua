local xingzhao = fk.CreateSkill{
  name = "ty__xingzhao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__xingzhao"] = "兴棹",
  [":ty__xingzhao"] = "锁定技，场上受伤的角色为1个或以上，你获得〖恂恂〗；2个或以上，你装备区进入或离开牌时摸一张牌；"..
  "3个或以上，你跳过判定和弃牌阶段；0个、4个或以上，你造成的伤害+1。",

  ["$ty__xingzhao1"] = "野棹出浅滩，借风当显威。",
  ["$ty__xingzhao2"] = "御棹水中行，前路皆助力。",
}

local function XingzhaoCount(room)
  return #table.filter(room.alive_players, function(p) return p:isWounded() end)
end

xingzhao:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(xingzhao.name) and
      XingzhaoCount(player.room) > 1 then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        elseif move.to == player and move.toArea == Card.PlayerEquip then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xingzhao.name)
  end,
})

xingzhao:addEffect(fk.EventPhaseChanging, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xingzhao.name) and
      (data.phase == Player.Judge or data.phase == Player.Discard) and
      XingzhaoCount(player.room) > 2 and
      not data.skipped
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

xingzhao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(xingzhao.name) then
      local n = XingzhaoCount(player.room)
      return n == 0 or n > 3
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

local xingzhao_spec = {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(xingzhao.name, true) and
      ((player:hasSkill("xunxun", true) and XingzhaoCount(player.room) == 0) or
      (not player:hasSkill("xunxun", true) and XingzhaoCount(player.room) > 0))
  end,
  on_refresh = function(self, event, target, player, data)
    if player:hasSkill("xunxun", true) then
      player.room:handleAddLoseSkills(player, "-xunxun")
    else
      player.room:handleAddLoseSkills(player, "xunxun")
    end
  end,
}

xingzhao:addEffect(fk.HpChanged, xingzhao_spec)
xingzhao:addEffect(fk.MaxHpChanged, xingzhao_spec)

return xingzhao
