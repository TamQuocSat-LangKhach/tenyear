local mouni = fk.CreateSkill {
  name = "mouni",
}

Fk:loadTranslationTable{
  ["mouni"] = "谋逆",
  [":mouni"] = "准备阶段，你可对一名其他角色依次使用你手牌中所有的【杀】直到该角色进入濒死状态。若以此法使用的【杀】中有未造成伤害的【杀】，"..
  "你本回合跳过出牌阶段和弃牌阶段。",

  ["#mouni-invoke"] = "谋逆：你可以对一名角色使用你手牌中所有【杀】！",

  ["$mouni1"] = "反制于人，不以鄙乎！",
  ["$mouni2"] = "与诸君终为敌，吾欲先手。",
}

mouni:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mouni.name) and player.phase == Player.Start and
      not player:isKongcheng() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#mouni-invoke",
      skill_name = mouni.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    if #ids == 0 then return end
    ids = table.reverse(ids)  --十周年是手牌从右往左使用
    for _, id in ipairs(ids) do
      if player.dead or to.dead then return end
      if table.contains(player:getCardIds("h"), id) then
        local card = Fk:getCardById(id)
        if player:canUseTo(card, to, { bypass_times = true, bypass_distances = true }) then
          local use = {
            from = player,
            tos = {to},
            card = card,
            extraUse = true,
          }
          use.extra_data = use.extra_data or {}
          use.extra_data.mouni_use = player.id
          room:useCard(use)
          if not use.damageDealt then
            player:skip(Player.Play)
            player:skip(Player.Discard)
          end
          if use.extra_data.mouni_dying then
            break
          end
        end
      end
    end
  end,
})

mouni:addEffect(fk.EnterDying, {
  can_refresh = function (self, event, target, player, data)
    if data.damage and data.damage.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data
        return use.extra_data and use.extra_data.mouni_use == player.id
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data
      use.extra_data = use.extra_data or {}
      use.extra_data.mouni_dying = true
    end
  end,
})

return mouni
