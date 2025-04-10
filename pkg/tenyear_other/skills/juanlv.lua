local juanlv = fk.CreateSkill {
  name = "juanlv",
}

Fk:loadTranslationTable{
  ["juanlv"] = "眷侣",
  [":juanlv"] = "当你使用牌指定异性角色为目标后，你可以令其选择弃置一张手牌或令你摸一张牌。",

  ["#juanlv-invoke"] = "眷侣：是否令 %dest 选择弃一张手牌或令你摸一张牌？",
  ["#juanlv-discard"] = "眷侣：请弃置一张手牌，否则 %src 摸一张牌",
}

juanlv:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juanlv.name) and
      player:compareGenderWith(data.to, true)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = juanlv.name,
      prompt = "#juanlv-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.to:isKongcheng() or
      #room:askToDiscard(data.to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = juanlv.name,
        cancelable = true,
        prompt = "#juanlv-discard:" .. player.id,
      }) == 0 then
      player:drawCards(1, juanlv.name)
    end
  end,
})

return juanlv
