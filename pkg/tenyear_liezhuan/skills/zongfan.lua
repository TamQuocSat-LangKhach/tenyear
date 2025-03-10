local zongfan = fk.CreateSkill {
  name = "zongfan"
}

Fk:loadTranslationTable{
  ['zongfan'] = '纵反',
  ['zongfan_active'] = '纵反',
  ['#zongfan-give'] = '纵反：交给一名其他角色任意张牌，你加等量体力上限并回复等量体力',
  [':zongfan'] = '觉醒技，回合结束时，若你本回合发动〖谋逆〗使用过【杀】且未跳过出牌阶段，你交给一名其他角色任意张牌，加X点体力上限并回复X点体力（X为你交给该角色的牌数且最多为5），失去〖谋逆〗，获得〖战孤〗',
  ['$zongfan1'] = '今天下未定，有能者皆可谋之！',
  ['$zongfan2'] = '吾以千里之众，当四战之地，可反也！',
}

zongfan:addEffect(fk.TurnEnd, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zongfan.name) and
      player:usedSkillTimes(zongfan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    return player:getMark("mouni-turn") > 0 and not player.skipped_phases[Player.Play]
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if not player:isNude() then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "zongfan_active",
        prompt = "#zongfan-give",
        cancelable = false,
      })
      if success then
        room:moveCardTo(dat.cards, Card.PlayerHand, room:getPlayerById(dat.targets[1]), fk.ReasonGive, zongfan.name, nil, false, player.id)
        local n = math.min(#dat.cards, 5)
        if not player.dead then
          room:changeMaxHp(player, n)
        end
        if not player.dead and player:isWounded() then
          room:recover({
            who = player,
            num = math.min(n, player:getLostHp()),
            recoverBy = player,
            skillName = zongfan.name
          })
        end
      end
    end
    room:handleAddLoseSkills(player, "-mouni|zhangu", nil, true, false)
  end,
})

return zongfan
