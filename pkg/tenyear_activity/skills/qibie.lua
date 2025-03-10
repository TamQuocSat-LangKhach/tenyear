local qibie = fk.CreateSkill {
  name = "qibie"
}

Fk:loadTranslationTable{
  ['qibie'] = '泣别',
  ['#qibie-invoke'] = '泣别：你可以弃置所有手牌，回复1点体力值并摸弃牌数+1张牌',
  [':qibie'] = '一名角色死亡后，你可以弃置所有手牌，然后回复1点体力值并摸X+1张牌（X为你以此法弃置牌数）。',
  ['$qibie1'] = '忽闻君别，泣下沾襟。',
  ['$qibie2'] = '相与泣别，承其遗志。',
}

qibie:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(qibie.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {skill_name = qibie.name, prompt = "#qibie-invoke"})
  end,
  on_use = function(self, event, target, player)
    local n = player:getHandcardNum()
    player:throwAllCards("h")
    if player.dead then return end
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = qibie.name
      })
    end
    player:drawCards(n + 1, qibie.name)
  end,
})

return qibie
