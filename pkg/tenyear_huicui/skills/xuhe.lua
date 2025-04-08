local xuhe = fk.CreateSkill {
  name = "xuhe",
}

Fk:loadTranslationTable{
  ["xuhe"] = "虚猲",
  [":xuhe"] = "出牌阶段开始时，你可以减1点体力上限，然后你弃置距离1以内的每名角色各一张牌或令这些角色各摸一张牌。出牌阶段结束时，"..
  "若你体力上限不为全场最高，你加1点体力上限，然后回复1点体力或摸两张牌。",

  ["#xuhe-invoke"] = "虚猲：你可以减1点体力上限，然后弃置距离1以内每名角色各一张牌或令这些角色各摸一张牌",
  ["xuhe_discard"] = "弃置距离1以内角色各一张牌",
  ["xuhe_draw"] = "距离1以内角色各摸一张牌",

  ["$xuhe1"] = "说出吾名，吓汝一跳！",
  ["$xuhe2"] = "我乃是零陵上将军！"
}

xuhe:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuhe.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xuhe.name,
      prompt = "#xuhe-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead or player:isRemoved() then return end
    local choice = room:askToChoice(player, {
      choices = {"xuhe_discard", "xuhe_draw"},
      skill_name = xuhe.name,
    })
    local targets = table.filter(room.alive_players, function (p)
      return player:distanceTo(p) < 2 and not p:isRemoved()
    end)
    if #targets == 0 then return end
    room:sortByAction(targets)
    room:doIndicate(player, targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        if choice == "xuhe_draw" then
          p:drawCards(1, xuhe.name)
        else
          if player.dead then return end
          if not p:isNude() then
            if p == player then
              room:askToDiscard(player, {
                min_num = 1,
                max_num = 1,
                include_equip = true,
                skill_name = xuhe.name,
                cancelable = false,
              })
            else
              local id = room:askToChooseCard(player, {
                target = p,
                flag = "he",
                skill_name = xuhe.name,
              })
              room:throwCard(id, xuhe.name, p, player)
            end
          end
        end
      end
    end
  end,
})

xuhe:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuhe.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p.maxHp > player.maxHp
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xuhe.name
    })
    if choice == "draw2" then
      player:drawCards(2, xuhe.name)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = xuhe.name,
      }
    end
  end,
})

return xuhe
