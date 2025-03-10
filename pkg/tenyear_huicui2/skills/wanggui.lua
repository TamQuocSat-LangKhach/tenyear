local wanggui = fk.CreateSkill {
  name = "wanggui"
}

Fk:loadTranslationTable{
  ['wanggui'] = '望归',
  ['#wanggui1-choose'] = '望归：你可以对一名势力与你不同的角色造成1点伤害',
  ['#wanggui2-choose'] = '望归：你可以令一名势力与你相同的角色摸一张牌，若不为你，你也摸一张牌',
  [':wanggui'] = '当你造成伤害后，你可以对与你势力不同的一名角色造成1点伤害（每回合限一次）；当你受到伤害后，你可令一名与你势力相同的角色摸一张牌，若不为你，你也摸一张牌。',
  ['$wanggui1'] = '存志太虚，安心玄妙。',
  ['$wanggui2'] = '礼法有度，良德才略。',
}

wanggui:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(wanggui) then
      return player:getMark("wanggui-turn") == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt = {}, ""
    targets = table.map(table.filter(room.alive_players, function(p)
      return p.kingdom ~= player.kingdom
    end), Util.IdMapper)
    prompt = "#wanggui1-choose"

    if #targets == 0 then return end

    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = prompt,
      skill_name = wanggui.name,
      cancelable = true
    })

    if #to > 0 then
      event:setCostData(skill, to[1]:objectName())
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))

    room:setPlayerMark(player, "wanggui-turn", 1)
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = wanggui.name,
    }
  end,
})

wanggui:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(wanggui) then
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt = {}, ""

    targets = table.map(table.filter(room.alive_players, function(p)
      return p.kingdom == player.kingdom
    end), Util.IdMapper)
    prompt = "#wanggui2-choose"

    if #targets == 0 then return end

    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = prompt,
      skill_name = wanggui.name,
      cancelable = true
    })

    if #to > 0 then
      event:setCostData(skill, to[1]:objectName())
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))

    to:drawCards(1, wanggui.name)

    if to ~= player then
      player:drawCards(1, wanggui.name)
    end
  end,
})

return wanggui
