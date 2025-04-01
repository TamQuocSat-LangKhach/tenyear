local qibie = fk.CreateSkill {
  name = "qibie",
}

Fk:loadTranslationTable{
  ["qibie"] = "泣别",
  [":qibie"] = "一名角色死亡后，你可以弃置所有手牌，然后回复1点体力值并摸X+1张牌（X为你以此法弃置牌数）。",

  ["#qibie-invoke"] = "泣别：你可以弃置所有手牌，回复1点体力值并摸弃牌数+1张牌",

  ["$qibie1"] = "忽闻君别，泣下沾襟。",
  ["$qibie2"] = "相与泣别，承其遗志。",
}

qibie:addEffect(fk.Deathed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qibie.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      return room:askToSkillInvoke(player, {
        skill_name = qibie.name,
        prompt = "#qibie-invoke",
      })
    else
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = qibie.name,
        pattern = "false",
        prompt = "#qibie-invoke",
        cancelable = true,
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    room:throwCard(cards, qibie.name, player, player)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = qibie.name,
      }
      if player.dead then return end
    end
    player:drawCards(#cards + 1, qibie.name)
  end,
})

return qibie
