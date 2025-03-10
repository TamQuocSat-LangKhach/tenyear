local jiaowang = fk.CreateSkill {
  name = "jiaowang"
}

Fk:loadTranslationTable{
  ['jiaowang'] = '骄妄',
  [':jiaowang'] = '锁定技，每轮结束时，若本轮没有角色死亡，你失去1点体力并发动〖硝焰〗。',
  ['$jiaowang1'] = '剑顾四野，马踏青山，今谁堪敌手？',
  ['$jiaowang2'] = '并土四州，带甲百万，吾可居大否？'
}

jiaowang:addEffect(fk.RoundEnd, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(jiaowang.name) then
      local logic = player.room.logic
      local deathevents = logic.event_recorder[GameEvent.Death] or Util.DummyTable
      local round_event = logic:getCurrentEvent()
      return #deathevents == 0 or deathevents[#deathevents].id < round_event.id
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:loseHp(player, 1, jiaowang.name)
    xiaoyan:use(event, target, player)
  end,
})

return jiaowang
