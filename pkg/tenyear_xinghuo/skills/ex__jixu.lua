local jixu = fk.CreateSkill {
  name = "ty_ex__jixu",
}

Fk:loadTranslationTable{
  ["ty_ex__jixu"] = "击虚",
  [":ty_ex__jixu"] = "出牌阶段限一次，你可以令至多你体力值数量的其他角色各猜测你的手牌中是否有【杀】。若你的手牌中：有【杀】，"..
  "此阶段你使用【杀】次数上限+X且可以额外指定所有猜错的角色为目标；没有【杀】，你弃置所有猜错的角色各一张牌。然后你摸X张牌（X为猜错的角色数）。",

  ["#ty_ex__jixu"] = "击虚：令至多%arg名角色猜测你手牌中是否有【杀】",
  ["#ty_ex__jixu-choice"] = "击虚：猜测 %src 的手牌中是否有【杀】",
  ["@@ty_ex__jixu-phase"] = "击虚",
  ["#ty_ex__jixu-invoke"] = "击虚：是否额外指定所有“击虚”猜错的角色为目标？",

  ["$ty_ex__jixu1"] = "辨坚识钝，可解充栋之牛！",
  ["$ty_ex__jixu2"] = "以锐欺虚，可击泰山之踵！",
}

jixu:addEffect("active", {
  anim_type = "control",
  prompt = function(self, player)
    return "#ty_ex__jixu:::"..player.hp
  end,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(self, player)
    return player.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jixu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < player.hp and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local result = room:askToJointChoice(player, {
      players = effect.tos,
      choices = {"yes", "no"},
      skill_name = jixu.name,
      prompt = "#ty_ex__jixu-choice:"..player.id,
      send_log = true,
    })
    local right = table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end) and "yes" or "no"
    local n = 0
    for _, p in ipairs(effect.tos) do
      if player.dead then return end
      local choice = result[p]
      if choice ~= right then
        n = n + 1
        if not p.dead then
          room:doIndicate(player, {p})
          if right == "yes" then
            room:setPlayerMark(p, "@@ty_ex__jixu-phase", 1)
          else
            if not p:isNude() then
              local id = room:askToChooseCard(player, {
                target = p,
                flag = "he",
                skill_name = jixu.name
              })
              room:throwCard(id, jixu.name, p, player)
              if player.dead then return end
            end
          end
        end
      end
    end
    if n > 0 and not player.dead then
      if right == "yes" then
        room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", n)
      end
      player:drawCards(n, jixu.name)
    end
  end,
})

jixu:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(jixu.name, Player.HistoryTurn) > 0 and
      data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@ty_ex__jixu-phase") > 0 and table.contains(data:getExtraTargets({bypass_distances = true}), p)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player, false), function(p)
      return p:getMark("@@ty_ex__jixu-phase") > 0 and table.contains(data:getExtraTargets({bypass_distances = true}), p)
    end)
    if room:askToSkillInvoke(player, {
      skill_name = jixu.name,
      prompt = "#ty_ex__jixu-invoke",
    }) then
      room:sortByAction(targets)
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return jixu
