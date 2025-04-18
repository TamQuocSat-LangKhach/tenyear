local weiji = fk.CreateSkill {
  name = "weijit",
}

Fk:loadTranslationTable{
  ["weijit"] = "围计",
  [":weijit"] = "当你使用牌指定其他角色为目标后，你可以秘密选择1~3中一个数字，令目标猜测你选择的数字。若目标猜错，你摸所选数字张牌。",

  ["#weijit-invoke"] = "围计：你可以声明一个数字令 %dest 猜测，若其猜错，你摸所选数字张牌",
  ["#weijit-choice"] = "围计：猜测 %src 选择的数字，若猜错，其摸所选数字张牌",

  ["$weijit1"] = "哈哈哈哈哈！庞涓当死于此树之下！",
  ["$weijit2"] = "围魏救赵，急袭大梁，攻敌所必救。",
}

weiji:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(weiji.name) and
      data.to ~= player and not data.to.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"1", "2", "3", "Cancel"},
      skill_name = weiji.name,
      prompt = "#weijit-invoke::"..data.to.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.to}, choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(data.to, {
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
