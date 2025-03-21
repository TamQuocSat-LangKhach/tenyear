local yuguan = fk.CreateSkill {
  name = "yuguan"
}

Fk:loadTranslationTable{
  ['yuguan'] = '御关',
  ['#yuguan-invoke'] = '御关：你可以减1点体力上限，令至多%arg名角色将手牌摸至体力上限',
  ['#yuguan-choose'] = '御关：令至多%arg名角色将手牌摸至体力上限',
  [':yuguan'] = '每个回合结束时，若你是损失体力值最多的角色，你可以减1点体力上限，然后令至多X名角色将手牌摸至体力上限（X为你已损失的体力值）。',
  ['$yuguan1'] = '城后即为汉土，吾等无路可退！',
  ['$yuguan2'] = '舍身卫关，身虽死而志犹在。',
}

yuguan:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuguan.name) and
      table.every(player.room:getOtherPlayers(player), function (p) return p:getLostHp() <= player:getLostHp() end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yuguan.name,
      prompt = "#yuguan-invoke:::"..math.max(0, player:getLostHp() - 1)
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead and player:getLostHp() > 0 then
      local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
        return #p.player_cards[Player.Hand] < p.maxHp end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = player:getLostHp(),
        prompt = "#yuguan-choose:::"..player:getLostHp(),
        skill_name = yuguan.name,
        cancelable = false
      })
      if #tos == 0 then
        tos = {player.id}
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        p:drawCards(p.maxHp - #p.player_cards[Player.Hand], yuguan.name)
      end
    end
  end,
})

return yuguan
