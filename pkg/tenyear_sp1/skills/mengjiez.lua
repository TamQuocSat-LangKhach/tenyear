local mengjiez = fk.CreateSkill {
  name = "mengjiez"
}

Fk:loadTranslationTable{
  ['mengjiez'] = '梦解',
  ['tg_wuyong'] = '武勇',
  ['tg_gangying'] = '刚硬',
  ['tg_duomou'] = '多谋',
  ['tg_guojue'] = '果决',
  ['tg_renzhi'] = '仁智',
  ['#mengjiez1-invoke'] = '梦解：对一名其他角色造成1点伤害',
  ['#mengjiez2-invoke'] = '梦解：令一名角色回复1点体力',
  ['#mengjiez4-invoke'] = '梦解：弃置一名其他角色区域内至多两张牌',
  ['#mengjiez5-invoke'] = '梦解：令一名其他角色将手牌摸至体力上限（至多摸五张）',
  [':tongguan'] = '一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。',
  [':mengjiez'] = '一名角色的回合结束时，若其本回合完成了其属性对应内容，你执行对应效果。<br>武勇：造成伤害；对一名其他角色造成1点伤害<br>刚硬：回复体力或手牌数大于体力值；令一名角色回复1点体力<br>多谋：摸牌阶段外摸牌；摸两张牌<br>果决：弃置或获得其他角色的牌；弃置一名其他角色区域内的至多两张牌<br>仁智：交给其他角色牌；令一名其他角色将手牌摸至体力上限（至多摸五张）',
  ['$mengjiez1'] = '唇舌之语，难言虚实之境。',
  ['$mengjiez2'] = '解梦之术，如镜中观花尔。',
}

mengjiez:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    local mark = target:getMark("tongguan_info")
    local room = player.room
    if player:hasSkill(skill.name) and mark ~= 0 then
      if mark == "tg_wuyong" then
        return #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == target end) > 0
      elseif mark == "tg_gangying" then
        if target:getHandcardNum() > target.hp then return true end
        local _event = room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e)
          return e.data[1].who == target
        end, Player.HistoryTurn)
        return #_event > 0
      elseif mark == "tg_duomou" then
        local phase_ids = {}
        room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
          if e.data[2] == Player.Draw then
            table.insert(phase_ids, {e.id, e.end_id})
          end
          return false
        end, Player.HistoryTurn)
        local _event = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          local in_draw = false
          for _, ids in ipairs(phase_ids) do
            if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
              in_draw = true
              break
            end
          end
          if not in_draw then
            for _, move in ipairs(e.data) do
              if move.to == target.id and move.moveReason == fk.ReasonDraw then
                return true
              end
            end
          end
          return false
        end, Player.HistoryTurn)
        return #_event > 0
      elseif mark == "tg_guojue" then
        local _event = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if move.from ~= target.id and move.proposer == target.id
              and (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey)
              and table.find(move.moveInfo, function(info)
                return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
              end) then
              return true
            end
          end
          return false
        end, Player.HistoryTurn)
        return #_event > 0
      elseif mark == "tg_renzhi" then
        local _event = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if (move.from == target.id or move.proposer == target.id) and move.to and move.to ~= move.from and move.moveReason == fk.ReasonGive then
              return true
            end
          end
          return false
        end, Player.HistoryTurn)
        return #_event > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local mark = target:getMark("tongguan_info")
    if mark == "tg_duomou" then
      player:drawCards(2, mengjiez.name)
    else
      local targets = room:getOtherPlayers(player)
      local prompt = "#mengjiez1-invoke"
      if mark == "tg_gangying" then
        targets = room:getAlivePlayers()
        prompt = "#mengjiez2-invoke"
      elseif mark == "tg_guojue"  then
        prompt = "#mengjiez4-invoke"
      elseif mark == "tg_renzhi" then
        prompt = "#mengjiez5-invoke"
      end
      if #targets == 0 then return false end
      local to = room:getPlayerById(room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        skill_name = mengjiez.name,
        cancelable = false,
      })[1])
      if mark == "tg_wuyong" then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = mengjiez.name,
        }
      elseif mark == "tg_gangying" then
        if to:isWounded() then
          room:recover({
            who = to,
            num = 1,
            recoverBy = player,
            skillName = mengjiez.name
          })
        end
      elseif mark == "tg_guojue" then
        if not to:isAllNude() then
          local cards = room:askToChooseCards(player, {
            target = to,
            min = 1,
            max = 2,
            flag = "hej",
            skill_name = mengjiez.name,
          })
          room:throwCard(cards, mengjiez.name, to, player)
        end
      elseif mark == "tg_renzhi" then
        if to:getHandcardNum() < to.maxHp then
          to:drawCards(math.min(5, to.maxHp - to:getHandcardNum()), mengjiez.name)
        end
      end
    end
    U.showPrivateMark(target, ":tongguan")
  end,
})

return mengjiez
