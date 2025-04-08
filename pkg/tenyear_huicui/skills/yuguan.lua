local yuguan = fk.CreateSkill {
  name = "yuguan",
}

Fk:loadTranslationTable{
  ["yuguan"] = "御关",
  [":yuguan"] = "每个回合结束时，若你是损失体力值最多的角色，你可以减1点体力上限，然后令至多X名角色将手牌摸至体力上限（X为你已损失的体力值）。",

  ["#yuguan-invoke"] = "御关：你可以减1点体力上限，令已损失的体力值数量的角色将手牌摸至体力上限",
  ["#yuguan-choose"] = "御关：令至多%arg名角色将手牌摸至体力上限",

  ["$yuguan1"] = "城后即为汉土，吾等无路可退！",
  ["$yuguan2"] = "舍身卫关，身虽死而志犹在。",
}

yuguan:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuguan.name) and
      table.every(player.room:getOtherPlayers(player, false), function (p)
        return p:getLostHp() <= player:getLostHp()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yuguan.name,
      prompt = "#yuguan-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead and player:getLostHp() > 0 then
      local targets = table.filter(room.alive_players, function(p)
        return p:getHandcardNum() < p.maxHp
      end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = player:getLostHp(),
        prompt = "#yuguan-choose:::"..player:getLostHp(),
        skill_name = yuguan.name,
        cancelable = false,
      })
      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead and p:getHandcardNum() < p.maxHp then
          p:drawCards(p.maxHp - p:getHandcardNum(), yuguan.name)
        end
      end
    end
  end,
})

return yuguan
