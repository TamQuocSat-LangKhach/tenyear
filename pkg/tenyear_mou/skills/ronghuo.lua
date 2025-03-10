local ronghuo = fk.CreateSkill {
  name = "ronghuo"
}

Fk:loadTranslationTable{
  ['ronghuo'] = '融火',
  [':ronghuo'] = '锁定技，当你因执行火【杀】或【火攻】的效果而对一名角色造成伤害时，你令伤害值+X（X为势力数-1）。',
  ['$ronghuo1'] = '火莲绽江矶，炎映三千弱水。',
  ['$ronghuo2'] = '奇志吞樯橹，潮平百万寇贼。',
}

ronghuo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ronghuo.name) and data.card and
      table.contains({"fire_attack", "fire__slash"}, data.card.name) then
      local room = player.room
      if not room.logic:damageByCardEffect() then return false end
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      local x = #kingdoms - 1
      if x > 0 then
        event:setCostData(self, x)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + event:getCostData(self)
  end,
})

return ronghuo
