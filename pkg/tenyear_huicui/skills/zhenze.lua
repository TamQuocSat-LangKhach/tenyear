local zhenze = fk.CreateSkill {
  name = "zhenze",
}

Fk:loadTranslationTable{
  ["zhenze"] = "震泽",
  [":zhenze"] = "弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；2.令所有手牌数和体力值的大小关系"..
  "与你相同的角色回复1点体力。",

  ["#zhenze-invoke"] = "震泽：你可以选择一项",
  ["zhenze_lose"] = "手牌数和体力值大小关系与你不同的角色失去体力",
  ["zhenze_recover"] = "手牌数和体力值大小关系与你相同的角色回复体力",

  ["$zhenze1"] = "名震千里，泽被海东。",
  ["$zhenze2"] = "施威除暴，上下咸服。",
}

zhenze:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenze.name) and player.phase == Player.Discard
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "zhenze_active",
      prompt = "#zhenze-invoke",
      cancelable = true,
      no_indicate = false,
    })
    if success and dat then
      local tos
      local a = player:getHandcardNum() - player.hp
      if dat.interaction == "zhenze_lose" then
        tos = table.filter(room.alive_players, function (p)
          return a * (p:getHandcardNum() - p.hp) <= 0 and a ~= (p:getHandcardNum() - p.hp)
        end)
      else
        tos = table.filter(room.alive_players, function (p)
          return a * (p:getHandcardNum() - p.hp) > 0 or a == (p:getHandcardNum() - p.hp)
        end)
      end
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    local choice = event:getCostData(self).choice
    for _, p in ipairs(tos) do
      if not p.dead then
        if choice == "zhenze_lose" then
          room:loseHp(p, 1, zhenze.name)
        elseif p:isWounded() and not p.dead then
          room:recover{
            who = p,
            num = 1,
            recoverBy = player,
            skillName = zhenze.name,
          }
        end
      end
    end
  end,
})

return zhenze
