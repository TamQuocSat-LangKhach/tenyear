local shiji = fk.CreateSkill {
  name = "shijiz",
}

Fk:loadTranslationTable{
  ["shijiz"] = "十计",
  [":shijiz"] = "一名角色的结束阶段，若其本回合未造成伤害，你可以声明一种普通锦囊牌（每轮每种牌名限一次），其可以将一张牌当你声明的牌使用"..
  "（不能指定其为目标）。",

  ["#shijiz-invoke"] = "十计：选择一种锦囊，%dest 可以将一张牌当此牌使用（不能指定其为目标）",
  ["#shijiz-use"] = "十计：你可以将一张牌当【%arg】使用",

  ["$shijiz1"] = "哼~区区十丈之城，何须丞相图画。",
  ["$shijiz2"] = "顽垒在前，可依不疑之计施为。",
}

local U = require "packages/utility/utility"

shiji:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shiji.name) and target.phase == Player.Finish and not target.dead and
      #target.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target
      end) == 0 and
      #player:getTableMark("shijiz-round") < #Fk:getAllCardNames("t") and
      not (#target:getHandlyIds() == 0 and target:isNude())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local names = table.filter(Fk:getAllCardNames("t"), function(name)
      local card = Fk:cloneCard(name)
      card.skillName = shiji.name
      return not table.contains(player:getTableMark("shijiz-round"), name) and target:canUse(card)
    end)
    local choices = U.askForChooseCardNames(room, player, names, 1, 1, shiji.name,
      "#shijiz-invoke::"..target.id, Fk:getAllCardNames("t"), true)
    if #choices == 1 then
      event:setCostData(self, {tos = {target}, choice = choices[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = target.room
    local choice = event:getCostData(self).choice
    room:addTableMark(player, "shijiz-round", choice)
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = choice,
      toast = true,
    }
    local success, dat = room:askToUseActiveSkill(target, {
      skill_name = "shijiz_viewas",
      prompt = "#shijiz-use:::"..choice,
      cancelable = true,
      extra_data = {
        shijiz_name = choice,
      },
    })
    if success and dat then
      local card = Fk:cloneCard(choice)
      card:addSubcards(dat.cards)
      card.skillName = shiji.name
      room:useCard{
        from = target,
        tos = dat.targets,
        card = card,
      }
    end
  end,
})

shiji:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and table.contains(card.skillNames, shiji.name) and from == to
  end,
})

return shiji
