local fumou = fk.CreateSkill {
  name = "fumou",
}

Fk:loadTranslationTable{
  ["fumou"] = "腹谋",
  [":fumou"] = "当你受到伤害后，你可以令至多X名角色依次选择一项：1.移动场上一张牌；2.弃置所有手牌并摸两张牌；"..
  "3.弃置装备区所有牌并回复1点体力。（X为你已损失的体力值）",

  ["#fumou-choose"] = "腹谋：你可以令至多%arg名角色依次选择执行一项",
  ["fumou1"] = "移动场上一张牌",
  ["fumou2"] = "弃置所有手牌，摸两张牌",
  ["fumou3"] = "弃置所有装备，回复1点体力",
  ["#fumou-move"] = "腹谋：请移动场上一张牌",

  ["$fumou1"] = "某有良谋，可为将军所用。",
  ["$fumou2"] = "吾负十斗之囊，其盈一石之智。",
}

fumou:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fumou.name) and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = player:getLostHp(),
      prompt = "#fumou-choose:::"..player:getLostHp(),
      skill_name = fumou.name,
      cancelable = true,
    })
    if #tos > 0 then
      local new_tos = {}
      if table.contains(tos, player) then
        table.insert(new_tos, player)
      end
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        if table.contains(tos, p) then
          table.insert(new_tos, p)
        end
      end
      event:setCostData(self, {tos = new_tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        local choices = {}
        if #room:canMoveCardInBoard() > 0 then
          table.insert(choices, "fumou1")
        end
        if not p:isKongcheng() then
          table.insert(choices, "fumou2")
        end
        if #p:getCardIds("e") > 0 then
          table.insert(choices, "fumou3")
        end
        if #choices == 0 then
          --continue
        else
          local choice = room:askToChoice(p, {
            choices = choices,
            skill_name = fumou.name,
            all_choices = {"fumou1", "fumou2", "fumou3"},
          })
          if choice == "fumou1" then
            local targets = room:askToChooseToMoveCardInBoard(p, {
              skill_name = fumou.name,
              prompt = "#fumou-move",
              cancelable = false,
            })
            room:askToMoveCardInBoard(p, {
              target_one = targets[1],
              target_two = targets[2],
              skill_name = fumou.name
            })
          elseif choice == "fumou2" then
            p:throwAllCards("h", fumou.name)
            if not p.dead then
              p:drawCards(2, fumou.name)
            end
          elseif choice == "fumou3" then
            p:throwAllCards("e", fumou.name)
            if p:isWounded() then
              room:recover{
                who = p,
                num = 1,
                recoverBy = player,
                skillName = fumou.name
              }
            end
          end
        end
      end
    end
  end,
})

return fumou
