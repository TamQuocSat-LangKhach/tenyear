local jiedao = fk.CreateSkill {
  name = "jiedao",
}

Fk:loadTranslationTable{
  ["jiedao"] = "截刀",
  [":jiedao"] = "当你每回合第一次造成伤害时，你可以令此伤害至多+X（X为你损失的体力值）。然后若受到此伤害的角色没有死亡，你弃置等同于此伤害加值的牌。",

  ["#jiedao-invoke"] = "截刀：你可以令你对 %dest 造成的伤害至多+%arg",

  ["$jiedao1"] = "截头大刀的威力，你来尝尝？",
  ["$jiedao2"] = "我这大刀，可是不看情面的。",
}

jiedao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jiedao.name) and player:isWounded() then
      local damage_events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 1, player:getLostHp() do
      table.insert(choices, tostring(i))
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jiedao.name,
      prompt = "#jiedao-invoke::"..data.to.id..":"..player:getLostHp(),
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.to}, choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    data:changeDamage(n)
    local damage_event = room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if damage_event then
      damage_event:addCleaner(function()
        if not data.to.dead and not player.dead then
          room:askToDiscard(player, {
            min_num = n,
            max_num = n,
            include_equip = true,
            skill_name = jiedao.name,
            cancelable = false,
          })
        end
      end)
    end
  end,
})

return jiedao
