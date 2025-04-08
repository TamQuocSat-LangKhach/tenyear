local tongguan = fk.CreateSkill {
  name = "tongguan",
}

Fk:loadTranslationTable{
  ["tongguan"] = "统观",
  [":tongguan"] = "一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。",

  ["tg_wuyong"] = "武勇",
  [":tg_wuyong"] = "回合结束时，若其本回合造成过伤害，你对一名其他角色造成1点伤害",
  ["tg_gangying"] = "刚硬",
  [":tg_gangying"] = "回合结束时，若其手牌数大于体力值，或其本回合回复过体力，你令一名角色回复1点体力",
  ["tg_duomou"] = "多谋",
  [":tg_duomou"] = "回合结束时，若其本回合摸牌阶段外摸过牌，你摸两张牌",
  ["tg_guojue"] = "果决",
  [":tg_guojue"] = "回合结束时，若其本回合弃置或获得过其他角色的牌，你弃置一名其他角色区域内的至多两张牌",
  ["tg_renzhi"] = "仁智",
  [":tg_renzhi"] = "回合结束时，若其本回合交给其他角色牌，你令一名其他角色将手牌摸至体力上限（至多摸五张）",

  ["#tongguan-choice"] = "统观：为 %dest 选择一项属性（每种属性至多被选择两次）",
  ["@[private]:tongguan"] = "统观",

  ["$tongguan1"] = "极目宇宙，可观如织之命数。",
  ["$tongguan2"] = "命河长往，唯我立于川上。",
}

local U = require "packages/utility/utility"

local tg_list = { "tg_wuyong", "tg_gangying", "tg_duomou", "tg_guojue", "tg_renzhi" }

tongguan:addEffect(fk.TurnStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tongguan.name) and target:getMark("tongguan_info") == 0 and not target.dead then
      local events = player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function(e)
        return e.data.who == target
      end, Player.HistoryGame)
      return #events > 0 and events[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local record = room:getBanner("tongguan_record") or {2, 2, 2, 2, 2}
    local choices = {}
    for i = 1, 5 do
      if record[i] > 0 then
        table.insert(choices, tg_list[i])
      end
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = tongguan.name,
      prompt = "#tongguan-choice::" .. target.id,
      detailed = true,
    })
    room:setPlayerMark(target, "tongguan_info", choice)
    local i = table.indexOf(tg_list, choice)
    record[i] = record[i] - 1
    room:setBanner("tongguan_record", record)
    U.setPrivateMark(target, ":tongguan", {choice}, {player.id})
  end,
})

return tongguan
