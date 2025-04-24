local weiji = fk.CreateSkill {
  name = "weijit",
}

Fk:loadTranslationTable{
  ["weijit"] = "围计",
  [":weijit"] = "当你使用牌指定后，你可以选择1~3中一个数字，令其中一名其他目标角色秘密猜测你选择的数字。若其猜错，你摸所选数字张牌。",

  ["#weijit-choose"] = "围计：你可以选择其中一名目标角色发动“围计”",
  ["#weijit-invoke"] = "围计：你可以声明一个数字令 %dest 猜测，若其猜错，你摸所选数字张牌",
  ["#weijit-choice"] = "围计：猜测 %src 选择的数字，若猜错，其摸所选数字张牌",

  ["$weijit1"] = "哈哈哈哈哈！庞涓当死于此树之下！",
  ["$weijit2"] = "围魏救赵，急袭大梁，攻敌所必救。",
}

weiji:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(weiji.name) and data.firstTarget and
      table.find(data.use.tos, function (p)
        return p ~= player and not p.dead
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = table.filter(data.use.tos, function (p)
      return p ~= player and not p.dead
    end)
    if #to > 1 then
      to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = to,
        skill_name = weiji.name,
        prompt = "#weijit-choose",
        cancelable = true,
      })
      if #to == 0 then return end
    end
    to = to[1]
    local choice = room:askToChoice(player, {
      choices = {"1", "2", "3", "Cancel"},
      skill_name = weiji.name,
      prompt = "#weijit-invoke::"..to.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {to}, choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = room:askToChoice(to, {
      choices = {"1", "2", "3"},
      skill_name = weiji.name,
      prompt = "#weijit-choice:"..player.id,
    })
    if tonumber(choice) ~= event:getCostData(self).choice then
      player:drawCards(event:getCostData(self).choice, weiji.name)
    end
  end,
})

return weiji
