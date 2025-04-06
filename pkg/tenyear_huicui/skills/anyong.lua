local anyong = fk.CreateSkill {
  name = "anyong",
}

Fk:loadTranslationTable{
  ["anyong"] = "暗涌",
  [":anyong"] = "当一名角色于其回合内第一次造成伤害后，若此伤害值为1，你可以弃置一张牌对受到伤害的角色造成1点伤害。",

  ["#anyong-invoke"] = "暗涌：你可以弃置一张牌，对 %dest 造成1点伤害",

  ["$anyong1"] = "殿上太守且相看，殿下几人还拥韩？",
  ["$anyong2"] = "冀州暗潮汹涌，群士居危思变。",
}

anyong:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(anyong.name) and not player:isNude() and target and target == player.room.current and
      not data.to.dead and data.damage == 1 then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target
      end, Player.HistoryTurn)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = anyong.name,
      cancelable = true,
      prompt = "#anyong-invoke::" .. data.to.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {data.to}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, anyong.name, player, player)
    if data.to.dead then return end
    room:damage{
      from = player,
      to = data.to,
      damage = 1,
      skillName = anyong.name,
    }
  end,
})

return anyong
