local juanlv = fk.CreateSkill {
  name = "juanlv"
}

Fk:loadTranslationTable{
  ['juanlv'] = '眷侣',
  ['#juanlv-invoke'] = '眷侣：请弃置一张手牌，否则%src摸一张牌',
  [':juanlv'] = '当你使用牌指定异性角色为目标后，你可以令其选择弃置一张手牌或令你摸一张牌。',
}

juanlv:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(juanlv.name) and
      player:compareGenderWith(player.room:getPlayerById(data.to), true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(data.to)
    if to:isKongcheng() then
      player:drawCards(1, juanlv.name)
    else
      local result = room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = juanlv.name,
        cancelable = true,
        prompt = "#juanlv-invoke:" .. player.id,
      })
      if #result == 0 then
        player:drawCards(1, juanlv.name)
      end
    end
  end,
})

return juanlv
