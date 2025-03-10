local ty_ex__zhui__zhuiyi = fk.CreateSkill {
  name = "ty_ex__zhuiyi"
}

Fk:loadTranslationTable{
  ['ty_ex__zhui__zhuiyi'] = '追忆',
  ['#ty_ex__zhuiyi-choose'] = '追忆：你可以令一名角色摸%arg张牌并回复1点体力',
  [':ty_ex__zhuiyi'] = '当你死亡时，可以令一名其他角色（杀死你的角色除外）摸X张牌（X为存活角色数）并回复1点体力。',
  ['$ty_ex__zhuiyi1'] = '别后庭中树，相思几度攀。',
  ['$ty_ex__zhuiyi2'] = '空馀宫阙恨，因此寄相思。',
}

ty_ex__zhui__zhuiyi:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__zhui__zhuiyi.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if data.damage and data.damage.from then
      table.removeOne(targets, data.damage.from.id)
    end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__zhuiyi-choose:::"..#room.alive_players,
      skill_name = ty_ex__zhui__zhuiyi.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    to:drawCards(#room.alive_players, ty_ex__zhui__zhuiyi.name)
    if not to.dead and to:isWounded() then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = ty_ex__zhui__zhuiyi.name,
      }
    end
  end,
})

return ty_ex__zhui__zhuiyi
