local fangdu = fk.CreateSkill {
  name = "fangdu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fangdu"] = "芳妒",
  [":fangdu"] = "锁定技，你的回合外，你每回合第一次受到普通伤害后回复1点体力，你每回合第一次受到属性伤害后随机获得伤害来源一张手牌。",

  ["$fangdu1"] = "浮萍却红尘，何意染是非？",
  ["$fangdu2"] = "我本无意争春，奈何群芳相妒。",
}

fangdu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fangdu.name) and player.room.current ~= player then
      local room = player.room
      if data.damageType == fk.NormalDamage then
        if not player:isWounded() then return end
      else
        if data.from == nil or data.from == player or data.from:isKongcheng() then return end
      end
      local damage_events = room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        if damage.to == player then
          if data.damageType == fk.NormalDamage then
            return damage.damageType == fk.NormalDamage
          else
            return damage.damageType ~= fk.NormalDamage
          end
        end
      end, Player.HistoryTurn)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    if data.damageType == fk.NormalDamage then
      event:setCostData(self, nil)
    else
      event:setCostData(self, {tos = {data.from}})
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.NormalDamage then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = fangdu.name,
      }
    else
      room:obtainCard(player, table.random(data.from:getCardIds("h")), false, fk.ReasonPrey, player, fangdu.name)
    end
  end
})

return fangdu
