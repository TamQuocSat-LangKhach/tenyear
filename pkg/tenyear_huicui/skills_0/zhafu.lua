local zhafu = fk.CreateSkill {
  name = "zhafu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zhafu"] = "札符",
  ["#zhafu"] = "选择一名其他角色：其下个弃牌阶段选择保留一张手牌，其余手牌交给你",
  ["@@zhafu"] = "札符",
  ["#zhafu_delay"] = "札符",
  ["#zhafu-invoke"] = "札符：选择一张保留的手牌，其他手牌全部交给 %src ！",
  [":zhafu"] = "限定技，出牌阶段，你可以选择一名其他角色。该角色的下个弃牌阶段开始时，其选择保留一张手牌，将其余手牌交给你。",
  ["$zhafu1"] = "垂恩广救，慈悲在怀。",
  ["$zhafu2"] = "行符敕鬼，神变善易。",
}

-- 主动技能部分
zhafu:addEffect("active", {
  name = "zhafu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#zhafu",
  can_use = function(self, player)
    return player:usedSkillTimes(zhafu.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@zhafu", player.id)
  end,
})

-- 触发技部分
zhafu:addEffect("trigger", {
  name = "#zhafu_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and player:getMark("@@zhafu") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(player:getMark("@@zhafu"))
    room:setPlayerMark(player, "@@zhafu", 0)
    if player:getHandcardNum() < 2 or src.dead then return end
    room:doIndicate(src.id, {player.id})
    src:broadcastSkillInvoke("zhafu")
    room:notifySkillInvoked(src, "zhafu", "control")
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      pattern = ".|.|.|hand",
      prompt = "#zhafu-invoke:" .. src.id
    })[1]
    local cards = table.filter(player.player_cards[Player.Hand], function(id) return id ~= card end)
    room:obtainCard(src, cards, false, fk.ReasonGive, player.id, "zhafu")
  end,
})

return zhafu
