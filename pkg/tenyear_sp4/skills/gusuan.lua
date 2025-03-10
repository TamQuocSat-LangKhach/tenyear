local gusuan = fk.CreateSkill {
  name = "gusuan"
}

Fk:loadTranslationTable{
  ['gusuan'] = '股算',
  ['@[geyuan]'] = '割圆',
  [':gusuan'] = '觉醒技，每个回合结束时，若圆环剩余点数为3个，你减1点体力上限，并修改“割圆”。<br><font color=>☆割圆·改：锁定技，有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你至多依次选择三名角色（按照点击他们的顺序）并依次执行其中一项：1.摸三张牌；2.弃四张牌；3.将其手牌与牌堆底五张牌交换。结算完成后，重新开始圆环。</font>',
  ['$gusuan1'] = '勾中容横，股中容直，可知其玄五。',
  ['$gusuan2'] = '累矩连索，类推衍化，开立而得法。',
}

gusuan:addEffect(fk.TurnEnd, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gusuan) and player:usedSkillTimes(gusuan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local mark = player:getMark("@[geyuan]")
    return type(mark) == "table" and #mark.all == 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
  end,
})

return gusuan
