local extension = Package("tenyear_activity")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_activity"] = "十周年-南征北战",
}

--文和乱武：李傕 郭汜 樊稠 张济 梁兴 唐姬 段煨 张横 牛辅

local lijue = General(extension, "lijue", "qun", 4, 6)
local langxi = fk.CreateTriggerSkill{
  name = "langxi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp <= player.hp end), Util.IdMapper), 1, 1, "#langxi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage({
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = math.random(0, 2),
      skillName = self.name,
    })
  end,
}
local yisuan = fk.CreateTriggerSkill{
  name = "yisuan",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card:isCommonTrick() and
      player.room:getCardArea(data.card) == Card.Processing and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end,
}
lijue:addSkill(langxi)
lijue:addSkill(yisuan)
Fk:loadTranslationTable{
  ["lijue"] = "李傕",
  ["#lijue"] = "奸谋恶勇",
  ["illustrator:lijue"] = "小牛",
  ["langxi"] = "狼袭",
  [":langxi"] = "准备阶段开始时，你可以对一名体力值不大于你的其他角色随机造成0~2点伤害。",
  ["#langxi-choose"] = "狼袭：请选择一名体力值不大于你的其他角色，对其随机造成0~2点伤害",
  ["yisuan"] = "亦算",
  [":yisuan"] = "出牌阶段限一次，当你使用普通锦囊牌结算后，你可以减1点体力上限，然后获得此牌。",

  ["$langxi1"] = "袭夺之势，如狼噬骨。",
  ["$langxi2"] = "引吾至此，怎能不袭掠之？",
  ["$yisuan1"] = "吾亦能善算谋划。",
  ["$yisuan2"] = "算计人心，我也可略施一二。",
  ["~lijue"] = "若无内讧，也不至如此。",
}

local guosi = General(extension, "guosi", "qun", 4)
local tanbei = fk.CreateActiveSkill{
  name = "tanbei",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {"tanbei2"}
    if not target:isNude() then
      table.insert(choices, 1, "tanbei1")
    end
    local choice = room:askForChoice(target, choices, self.name)
    local targetRecorded = type(player:getMark(choice.."-turn")) == "table" and player:getMark(choice.."-turn") or {}
    table.insertIfNeed(targetRecorded, target.id)
    room:setPlayerMark(player, choice.."-turn", targetRecorded)
    if choice == "tanbei1" then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local tanbei_prohibit = fk.CreateProhibitSkill{
  name = "#tanbei_prohibit",
  is_prohibited = function(self, from, to, card)
    local targetRecorded = from:getMark("tanbei1-turn")
    return type(targetRecorded) == "table" and table.contains(targetRecorded, to.id)
  end,
}
local tanbei_targetmod = fk.CreateTargetModSkill{
  name = "#tanbei_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    local targetRecorded = player:getMark("tanbei2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    local targetRecorded = player:getMark("tanbei2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
}
local sidao = fk.CreateTriggerSkill{
  name = "sidao",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      return self.sidao_tos and #self.sidao_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)  --TODO: target filter
    local tos, id = player.room:askForChooseCardAndPlayers(player, self.sidao_tos, 1, 1, ".|.|.|hand|.|.", "#sidao-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("snatch", {self.cost_data[2]}, player, player.room:getPlayerById(self.cost_data[1]), self.name)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget
  end,
  on_refresh = function(self, event, target, player, data)
    self.sidao_tos = {}
    local mark = player:getMark("sidao-phase")
    if mark ~= 0 and #mark > 0 and #AimGroup:getAllTargets(data.tos) > 0 then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if table.contains(mark, id) then
          table.insert(self.sidao_tos, id)
        end
      end
    end
    if #AimGroup:getAllTargets(data.tos) > 0 then
      mark = AimGroup:getAllTargets(data.tos)
      table.removeOne(mark, player.id)
    else
      mark = 0
    end
    player.room:setPlayerMark(player, "sidao-phase", mark)
  end,
}
tanbei:addRelatedSkill(tanbei_prohibit)
tanbei:addRelatedSkill(tanbei_targetmod)
guosi:addSkill(tanbei)
guosi:addSkill(sidao)
Fk:loadTranslationTable{
  ["guosi"] = "郭汜",
  ["#guosi"] = "党豺为虐",
  ["illustrator:guosi"] = "秋呆呆",
  ["tanbei"] = "贪狈",
  [":tanbei"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你随机获得其区域内的一张牌，此回合不能再对其使用牌；"..
  "2.令你此回合对其使用牌没有次数和距离限制。",
  ["sidao"] = "伺盗",
  [":sidao"] = "出牌阶段限一次，当你对一名其他角色连续使用两张牌后，你可将一张手牌当【顺手牵羊】对其使用（目标须合法）。",
  ["tanbei1"] = "其随机获得你区域内的一张牌，此回合不能再对你使用牌",
  ["tanbei2"] = "此回合对你使用牌无次数和距离限制",
  ["#sidao-cost"] = "伺盗：你可将一张手牌当【顺手牵羊】对相同的目标使用",

  ["$tanbei1"] = "此机，我怎么会错失。",
  ["$tanbei2"] = "你的东西，现在是我的了！",
  ["$sidao1"] = "连发伺动，顺手可得。	",
  ["$sidao2"] = "伺机而动，此地可窃。",
  ["~guosi"] = "伍习，你……",
}

local fanchou = General(extension, "fanchou", "qun", 4)
local xingluan = fk.CreateTriggerSkill{
  name = "xingluan",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
    data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule(".|6")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    else
      player:drawCards(6, self.name)
    end
  end,
}
fanchou:addSkill(xingluan)
Fk:loadTranslationTable{
  ["fanchou"] = "樊稠",
  ["#fanchou"] = "庸生变难",
  ["illustrator:fanchou"] = "天纵世纪",
  ["xingluan"] = "兴乱",
  [":xingluan"] = "每阶段限一次，当你于你出牌阶段使用一张仅指定一名目标角色的牌结算结束后，你可以从牌堆中获得一张点数为6的牌（若牌堆中没有点数为6的牌，改为摸六张牌）。",

  ["$xingluan1"] = "大兴兵争，长安当乱。",
  ["$xingluan2"] = "勇猛兴军，乱世当立。",
  ["~fanchou"] = "唉，稚然，疑心甚重。",
}

local zhangji = General(extension, "zhangji", "qun", 4)
local lueming = fk.CreateActiveSkill{
  name = "lueming",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #target.player_cards[Player.Equip] < #Self.player_cards[Player.Equip]
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {}
    for i = 1, 13, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askForChoice(target, choices, self.name)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if tostring(judge.card.number) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 2,
        skillName = self.name,
      }
    elseif not target:isAllNude() then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local tunjun = fk.CreateActiveSkill{
  name = "tunjun",
  anim_type = "drawcard",
  target_num = 1,
  card_num = 0,
  prompt = function ()
    return "#tunjun-prompt:::"..Self:usedSkillTimes("lueming", Player.HistoryGame)
  end,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:usedSkillTimes("lueming", Player.HistoryGame) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] < 4  --TODO: no treasure yet
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local n = player:usedSkillTimes("lueming", Player.HistoryGame)
    for _ = 1, n, 1 do
      if player.dead then break end
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        local card = Fk:getCardById(id, true)
        if card.type == Card.TypeEquip and target:getEquipment(card.sub_type) == nil and not target:prohibitUse(card) then
          table.insertIfNeed(cards, id)
        end
      end
      if #cards > 0 then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = Fk:getCardById(table.random(cards), true),
        })
      else
        break
      end
    end
  end,
}
zhangji:addSkill(lueming)
zhangji:addSkill(tunjun)
Fk:loadTranslationTable{
  ["zhangji"] = "张济",
  ["#zhangji"] = "武威雄豪",
  ["illustrator:zhangji"] = "YanBai",
  ["lueming"] = "掠命",
  [":lueming"] = "出牌阶段限一次，你选择一名装备区装备少于你的其他角色，令其选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；"..
  "不同，你随机获得其区域内的一张牌。",
  ["tunjun"] = "屯军",
  [":tunjun"] = "限定技，出牌阶段，你可以选择一名角色，令其随机使用牌堆中的X张不同类型的装备牌（不替换原有装备，X为你发动〖掠命〗的次数）。",
  ["#tunjun-prompt"] = "屯军：选择一名角色，令其随机使用 %arg 张装备牌",

  ["$lueming1"] = "劫命掠财，毫不费力。",
  ["$lueming2"] = "人财，皆掠之，哈哈！",
  ["$tunjun1"] = "得封侯爵，屯军弘农。",
  ["$tunjun2"] = "屯军弘农，养精蓄锐。",
  ["~zhangji"] = "哪，哪里来的乱箭？",
}

local liangxing = General(extension, "liangxing", "qun", 4)
local lulue = fk.CreateTriggerSkill{
  name = "lulue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (p:getHandcardNum() < #player.player_cards[Player.Hand] and not p:isKongcheng()) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#lulue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, {"lulue_give", "lulue_slash"}, self.name, "#lulue-choice:"..player.id)
    if choice == "lulue_give" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to:getCardIds(Player.Hand))
      room:obtainCard(player.id, dummy, false, fk.ReasonGive, to.id)
      player:turnOver()
    else
      to:turnOver()
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local zhuixi = fk.CreateTriggerSkill{
  name = "zhuixi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.to and
      ((data.from.faceup and not data.to.faceup) or (not data.from.faceup and data.to.faceup))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
liangxing:addSkill(lulue)
liangxing:addSkill(zhuixi)
Fk:loadTranslationTable{
  ["liangxing"] = "梁兴",
  ["#liangxing"] = "凶豺掠豹",
  ["cv:liangxing"] = "虞晓旭",
  ["illustrator:liangxing"] = "匠人绘",
  ["lulue"] = "掳掠",
  [":lulue"] = "出牌阶段开始时，你可以令一名有手牌且手牌数小于你的其他角色选择一项：1.将所有手牌交给你，然后你翻面；2.翻面，然后视为对你使用一张【杀】。",
  ["zhuixi"] = "追袭",
  [":zhuixi"] = "锁定技，当你对其他角色造成伤害时，或当你受到其他角色造成的伤害时，若你与其翻面状态不同，此伤害+1。",
  ["#lulue-choose"] = "掳掠：你可以令一名有手牌且手牌数小于你的其他角色选择一项",
  ["lulue_give"] = "将所有手牌交给其，其翻面",
  ["lulue_slash"] = "你翻面，视为对其使用【杀】",
  ["#lulue-choice"] = "掳掠：选择对 %src 执行的一项",

  ["$lulue1"] = "趁火打劫，乘危掳掠。",
  ["$lulue2"] = "天下大乱，掳掠以自保。",
  ["$zhuixi1"] = "得势追击，胜望在握！",
  ["$zhuixi2"] = "诸将得令，追而袭之！",
  ["~liangxing"] = "夏侯渊，你竟敢！",
}

local tangji = General(extension, "tangji", "qun", 3, 3, General.Female)
local kangge = fk.CreateTriggerSkill{
  name = "kangge",
  events = {fk.TurnStart, fk.AfterCardsMove, fk.Death},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TurnStart then
        if player ~= target then return false end
        local room = player.room
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = player:getMark("kangge_record")
        if x == 0 then
          local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
          for _, e in ipairs(events) do
            local current_player = e.data[1]
            if current_player == player then
              x = e.id
              room:setPlayerMark(player, "kangge_record", x)
              break
            end
          end
        end
        return turn_event.id == x
      elseif event == fk.AfterCardsMove then
        local kangge_id = player:getMark(self.name)
        if kangge_id ~= 0 and player:getMark("kangge-turn") < 3 then
          local kangge_player = player.room:getPlayerById(kangge_id)
          if kangge_player.dead or kangge_player.phase ~= Player.NotActive then return false end
          for _, move in ipairs(data) do
            if kangge_id == move.to and move.toArea == Card.PlayerHand then
              return true
            end
          end
        end
      elseif event == fk.Death then
        return player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, self.name, "special")
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#kangge-choose", self.name, false, true)
      if #to > 0 then
        room:setPlayerMark(player, self.name, to[1])
      end
    elseif event == fk.AfterCardsMove then
      local n = 0
      local kangge_id = player:getMark(self.name)
      for _, move in ipairs(data) do
        if move.to and kangge_id == move.to and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
      end
      if n > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        local x = math.min(n, 3 - player:getMark("kangge-turn"))
        room:addPlayerMark(player, "kangge-turn", x)
        if player:getMark("@kangge") == 0 then
          room:setPlayerMark(player, "@kangge", room:getPlayerById(kangge_id).general)
        end
        player:drawCards(x, self.name)
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, self.name, "negative")
      if player:getMark("@kangge") == 0 then
        room:setPlayerMark(player, "@kangge", target.general)
      end
      player:throwAllCards("he")
      if not player.dead then
        room:loseHp(player, 1, self.name)
      end
    end
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    room:setPlayerMark(player, "@kangge", 0)
  end,
}
local kangge_trigger = fk.CreateTriggerSkill{
  name = "#kangge_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("kangge") and player:getMark("kangge") == target.id and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "kangge", data, "#kangge-recover::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("kangge")
    room:notifySkillInvoked(player, "kangge", "support")
    room:doIndicate(player.id, {target.id})
    if player:getMark("@kangge") == 0 then
      room:setPlayerMark(player, "@kangge", target.general)
    end
    room:recover({
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = "kangge"
    })
  end,
}
local jielie = fk.CreateTriggerSkill{
  name = "jielie",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and
      data.from ~= player and data.from.id ~= player:getMark("kangge")
  end,
  on_cost = function(self, event, target, player, data)
    local suits = {"spade", "heart", "club", "diamond"}
    local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name, "#jielie-choice")
    if choice ~= "Cancel" then
      self.cost_data = suits[table.indexOf(choices, choice)]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = self.cost_data
    room:loseHp(player, data.damage, self.name)
    local kangge_id = player:getMark("kangge")
    if kangge_id ~= 0 then
      local to = room:getPlayerById(kangge_id)
      if to and not to.dead then
        room:setPlayerMark(player, "@kangge", to.general)
        local cards = room:getCardsFromPileByRule(".|.|"..suit, data.damage, "discardPile")
        if #cards > 0 then
          room:moveCards({
            ids = cards,
            to = to.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false
          })
        end
      end
    end
    return true
  end,
}
kangge:addRelatedSkill(kangge_trigger)
tangji:addSkill(kangge)
tangji:addSkill(jielie)
Fk:loadTranslationTable{
  ["tangji"] = "唐姬",
  ["#tangji"] = "弘农王妃",
  ["illustrator:tangji"] = "福州明暗",
  ["kangge"] = "抗歌",
  [":kangge"] = "你的第一个回合开始时，你选择一名其他角色：<br>1.当该角色于其回合外获得手牌后，你摸等量的牌（每回合最多摸三张）；<br>"..
  "2.每轮限一次，当该角色进入濒死状态时，你可以令其将体力回复至1点；<br>3.当该角色死亡时，你弃置所有牌并失去1点体力。",
  ["jielie"] = "节烈",
  [":jielie"] = "当你受到你或〖抗歌〗角色以外的角色造成的伤害时，你可以防止此伤害并选择一种花色，失去X点体力，"..
  "令〖抗歌〗角色从弃牌堆中随机获得X张此花色的牌（X为伤害值）。",
  ["#kangge-choose"] = "抗歌：请选择“抗歌”角色",
  ["@kangge"] = "抗歌",
  ["#kangge-recover"] = "抗歌：你可以令 %dest 将体力回复至1点",
  ["#jielie-choice"] = "是否发动 节烈，选择一种花色",

  ["$kangge1"] = "慷慨悲歌，以抗凶逆。",
  ["$kangge2"] = "忧惶昼夜，抗之以歌。",
  ["$jielie1"] = "节烈之妇，从一而终也！",
  ["$jielie2"] = "清闲贞静，守节整齐。",
  ["~tangji"] = "皇天崩兮后土颓……",
}

local duanwei = General(extension, "duanwei", "qun", 4)
local ty__langmie = fk.CreateTriggerSkill{
  name = "ty__langmie",
  mute = true,
  events = {fk.EventPhaseEnd, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player then
      if event == fk.EventPhaseEnd and target.phase == Player.Play then
        local count = {0, 0, 0}
        player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
          local use = e.data[1]
          if use.from == target.id then
            if use.card.type == Card.TypeBasic then
              count[1] = count[1] + 1
            elseif use.card.type == Card.TypeTrick then
              count[2] = count[2] + 1
            elseif use.card.type == Card.TypeEquip then
              count[3] = count[3] + 1
            end
          end
        end, Player.HistoryPhase)
        return table.find(count, function(i) return i > 1 end)
      elseif event == fk.EventPhaseStart and target.phase == Player.Finish and not player:isNude() then
        local n = 0
        player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
          local damage = e.data[5]
          if damage and target == damage.from then
            n = n + damage.damage
          end
        end, Player.HistoryTurn)
        return n > 1
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty__langmie-draw")
    elseif event == fk.EventPhaseStart then
      local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__langmie-damage::"..target.id, true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseEnd then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:doIndicate(player.id, {target.id})
      room:throwCard(self.cost_data, self.name, player, player)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
duanwei:addSkill(ty__langmie)
Fk:loadTranslationTable{
  ["duanwei"] = "段煨",
  ["#duanwei"] = "凉国之英",
  ["illustrator:duanwei"] = "匠人绘",
  ["ty__langmie"] = "狼灭",
  [":ty__langmie"] = "其他角色出牌阶段结束时，若其本阶段使用过至少两张相同类别的牌，你可以摸一张牌；其他角色的结束阶段，若其本回合造成过至少2点伤害，"..
  "你可以弃置一张牌，对其造成1点伤害。",
  ["#ty__langmie-draw"] = "狼灭：你可以摸一张牌",
  ["#ty__langmie-damage"] = "狼灭：你可以弃置一张牌，对 %dest 造成1点伤害",

  ["$ty__langmie1"] = "狼性凶残，不得不灭！",
  ["$ty__langmie2"] = "贪狼环伺，眈眈相向，灭之方可除虑。",
  ["~duanwei"] = "禀赡天子，终无二意。",
}

local zhangheng = General(extension, "zhangheng", "qun", 8)
local liangjue = fk.CreateTriggerSkill{
  name = "liangjue",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.hp > 1 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and (info.fromArea == Card.PlayerJudge or info.fromArea == Card.PlayerEquip) then
              return true
            end
          end
        end
        if move.to == player.id and (move.toArea == Card.PlayerJudge or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    player:drawCards(2, self.name)
  end,
}
local dangzai = fk.CreateTriggerSkill{
  name = "dangzai",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p) return p:canMoveCardsInBoardTo(player, "j") end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
      return p:canMoveCardsInBoardTo(player, "j") end), Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#dangzai-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(self.cost_data)
    room:askForMoveCardInBoard(player, src, player, self.name, "j", src)
  end,
}
zhangheng:addSkill(liangjue)
zhangheng:addSkill(dangzai)
Fk:loadTranslationTable{
  ["zhangheng"] = "张横",
  ["#zhangheng"] = "戾鹘枭鹰",
  ["illustrator:zhangheng"] = "匠人绘",
  ["liangjue"] = "粮绝",
  [":liangjue"] = "锁定技，当有黑色牌进入或者离开你的判定区或装备区时，若你的体力值大于1，你失去1点体力，然后摸两张牌。",
  ["dangzai"] = "挡灾",
  [":dangzai"] = "出牌阶段开始时，你可以将一名其他角色判定区里的一张牌移至你的判定区。",
  ["#dangzai-choose"] = "挡灾：你可以将其他角色判定区里的一张牌移至你的判定区",

  ["$liangjue1"] = "行军者，切不可无粮！",
  ["$liangjue2"] = "粮尽援绝，须另谋出路。",
  ["$dangzai1"] = "此处有我，休得放肆！",
  ["$dangzai2"] = "退后，让我来！",
  ["~zhangheng"] = "军粮匮乏。",
}

local niufu = General(extension, "niufu", "qun", 4, 7)
local xiaoxi = fk.CreateTriggerSkill{
  name = "xiaoxi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"1", "2"}
    if player.maxHp == 1 then
      choices = {"1"}
    end
    local n = tonumber(room:askForChoice(player, choices, self.name, "#xiaoxi1-choice"))
    room:changeMaxHp(player, -n)
    if player.dead then return end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xiaoxi-choose", self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    choices = {"xiaoxi_prey", "xiaoxi_slash"}
    if #to:getCardIds{Player.Hand, Player.Equip} < n then
      choices = {"xiaoxi_slash"}
    elseif player:isProhibited(to, Fk:cloneCard("slash")) then
      choices = {"xiaoxi_prey"}
    end
    local choice = room:askForChoice(player, choices, self.name, "#xiaoxi2-choice::"..to.id..":"..n)
    if choice == "xiaoxi_prey" then
      local cards = room:askForCardsChosen(player, to, n, n, "he", self.name)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
    else
      for i = 1, n, 1 do
        if player.dead or to.dead then return end
        room:useVirtualCard("slash", nil, player, to, self.name, true)
      end
    end
  end,
}
local xiongrao = fk.CreateTriggerSkill{
  name = "xiongrao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xiongrao-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      room:setPlayerMark(p, "@@xiongrao-turn", 1)
    end
    local x = 7 - player.maxHp
    if x > 0 then
      room:changeMaxHp(player, x)
      player:drawCards(x, self.name)
    end
  end,
}
local xiongrao_invalidity = fk.CreateInvaliditySkill {
  name = "#xiongrao_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@xiongrao-turn") > 0 and
      skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Limited and skill.frequency ~= Skill.Wake and
      not (skill:isEquipmentSkill() or skill.name:endsWith("&"))
  end
}
xiongrao:addRelatedSkill(xiongrao_invalidity)
niufu:addSkill(xiaoxi)
niufu:addSkill(xiongrao)
Fk:loadTranslationTable{
  ["niufu"] = "牛辅",
  ["#niufu"] = "魔郎",
  ["illustrator:niufu"] = "福州明暗",
  ["xiaoxi"] = "宵袭",
  [":xiaoxi"] = "锁定技，出牌阶段开始时，你需减少1或2点体力上限，然后选择一项：1.获得你攻击范围内一名其他角色等量的牌；"..
  "2.视为对你攻击范围内的一名其他角色使用等量张【杀】。",
  ["xiongrao"] = "熊扰",
  [":xiongrao"] = "限定技，准备阶段，你可以令所有其他角色本回合除锁定技、限定技、觉醒技以外的技能全部失效，"..
  "然后你将体力上限增加至7并摸等同于增加体力上限张数的牌。",
  ["#xiaoxi1-choice"] = "宵袭：你需减少1或2点体力上限",
  ["#xiaoxi-choose"] = "宵袭：选择攻击范围内一名角色，获得其等量牌或视为对其使用等量【杀】",
  ["#xiaoxi2-choice"] = "宵袭：选择对 %dest 执行的一项（X为%arg）",
  ["xiaoxi_prey"] = "获得其X张牌",
  ["xiaoxi_slash"] = "视为对其使用X张【杀】",
  ["#xiongrao-invoke"] = "熊扰：你可以令其他角色本回合非锁定技无效，你体力上限增加至7！",
  ["@@xiongrao-turn"] = "熊扰",

  ["$xiaoxi1"] = "夜深枭啼，亡命夺袭！",
  ["$xiaoxi2"] = "以夜为幕，纵兵逞凶！",
  ["$xiongrao1"] = "势如熊罴，威震四海！",
  ["$xiongrao2"] = "啸聚熊虎，免走狐惊！",
  ["~niufu"] = "胡儿安敢杀我！",
}

local dongxie = General(extension, "dongxie", "qun", 4, 4, General.Female)
local jiaoxia = fk.CreateTriggerSkill{
  name = "jiaoxia",
  events = {fk.EventPhaseStart, fk.CardUseFinished, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    if event == fk.TargetSpecified then
      return data.card.trueName == "slash" and player.phase == player.Play and
      not table.contains(U.getMark(player, "jiaoxia_target-phase"), data.to)
    elseif event == fk.CardUseFinished then
      if table.contains(data.card.skillNames, "jiaoxia") and data.damageDealt then
        local card = Fk:getCardById(data.card:getEffectiveId())
        return player:canUse(card) and not player:prohibitUse(card) and player.room:getCardArea(card) == Card.Processing
      end
    elseif event == fk.EventPhaseStart then
      return player.phase == player.Play
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then 
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiaoxia-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local mark = U.getMark(player, "jiaoxia_target-phase")
      table.insert(mark, data.to)
      room:setPlayerMark(player, "jiaoxia_target-phase", mark)
    elseif event == fk.CardUseFinished then
      local ids = Card:getIdList(data.card)
      U.askForUseRealCard(room, player, ids, ".", self.name, "#jiaoxia-use:::"..Fk:getCardById(ids[1]):toLogString(),
      { expand_pile = ids, bypass_times = false, extraUse = false })
    elseif event == fk.EventPhaseStart then
      room:setPlayerMark(player, "@@jiaoxia-phase", 1)
      player:filterHandcards()
    end
  end,
}
local jiaoxia_filter = fk.CreateFilterSkill{
  name = "#jiaoxia_filter",
  card_filter = function(self, to_select, player)
    return player:hasSkill(jiaoxia) and player:getMark("@@jiaoxia-phase") > 0 and
    table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", to_select.suit, to_select.number)
    card.skillName = jiaoxia.name
    return card
  end,
}
local jiaoxia_targetmod = fk.CreateTargetModSkill{
  name = "#jiaoxia_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(jiaoxia) and card and card.trueName == "slash" and to and
    not table.contains(U.getMark(player, "jiaoxia_target-phase"), to.id)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(jiaoxia) and card and card.trueName == "slash" and to and
    not table.contains(U.getMark(player, "jiaoxia_target-phase"), to.id)
  end,
}
local humei = fk.CreateActiveSkill{
  name = "humei",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    return "#humei:::"..Self:getMark("@humei-phase")
  end,
  interaction = function(self)
    local choices = {}
    for i = 1, 3, 1 do
      if Self:getMark("humei"..i.."-phase") == 0 then
        table.insert(choices, "humei"..i.."-phase")
      end
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    for i = 1, 3, 1 do
      if player:getMark("humei"..i.."-phase") == 0 then
        return true
      end
    end
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 and target.hp <= Self:getMark("@humei-phase") then
      if self.interaction.data == "humei1-phase" then
        return true
      elseif self.interaction.data == "humei2-phase" then
        return not target:isNude()
      elseif self.interaction.data == "humei3-phase" then
        return target:isWounded()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "humei1-phase" then
      target:drawCards(1, self.name)
    elseif self.interaction.data == "humei2-phase" then
      local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#humei-give:"..player.id)
      room:obtainCard(player, card[1], false, fk.ReasonGive, target.id)
    elseif self.interaction.data == "humei3-phase" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
local humei_trigger = fk.CreateTriggerSkill{
  name = "#humei_trigger",
  events = {fk.Damage},
  main_skill = humei,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(humei) and player.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room  = player.room
    room:notifySkillInvoked(player, humei.name, "special")
    player:broadcastSkillInvoke(humei.name)
    room:addPlayerMark(player, "@humei-phase", data.damage)
  end,
}
jiaoxia:addRelatedSkill(jiaoxia_targetmod)
jiaoxia:addRelatedSkill(jiaoxia_filter)
humei:addRelatedSkill(humei_trigger)
dongxie:addSkill(jiaoxia)
dongxie:addSkill(humei)
Fk:loadTranslationTable{
  ["dongxie"] = "董翓",
  ["#dongxie"] = "暗夜豺狐",
  ["designer:dongxie"] = "步穗",
  ["illustrator:dongxie"] = "凝聚永恒",
  ["jiaoxia"] = "狡黠",
  [":jiaoxia"] = "出牌阶段开始时，你可以令本阶段你的手牌均视为【杀】。若你以此法使用的【杀】造成了伤害，"..
  "此【杀】结算后你可以视为使用原卡牌（有次数限制）。出牌阶段，你对每名角色使用第一张【杀】无距离和次数限制。",
  ["humei"] = "狐魅",
  [":humei"] = "出牌阶段每项限一次，你可以选择一项，令一名体力值不大于X的角色执行（X为你本阶段造成伤害点数）："..
  "1.摸一张牌；2.交给你一张牌；3.回复1点体力。",

  ["#jiaoxia-invoke"] = "狡黠：你可以令本阶段你的手牌均视为【杀】，且结算后你可以使用原卡牌！",
  ["#jiaoxia_filter"] = "狡黠",
  ["@@jiaoxia-phase"] = "狡黠",
  ["#jiaoxia-use"] = "狡黠：你可以使用【%arg】",
  ["#humei_trigger"] = "狐魅",
  ["@humei-phase"] = "狐魅",
  ["#humei"] = "狐魅：令一名体力值不大于%arg的角色执行一项",
  ["humei1-phase"] = "摸一张牌",
  ["humei2-phase"] = "交给你一张牌",
  ["humei3-phase"] = "回复1点体力",
  ["#humei-give"] = "狐魅：请交给 %src 一张牌",

  ["$jiaoxia1"] = "暗剑匿踪，现时必捣黄龙！",
  ["$jiaoxia2"] = "袖中藏刃，欲取诸君之头！",
  ["$humei1"] = "尔为靴下之臣，当行顺我之事。",
  ["$humei2"] = "妾身一笑，可倾将军之城否？",
  ["~dongxie"] = "覆巢之下，断无完卵余生……",
}

--逐鹿天下：张恭 吕凯 卫温诸葛直
local zhanggong = General(extension, "zhanggong", "wei", 3)
local qianxinz = fk.CreateActiveSkill{
  name = "qianxinz",
  anim_type = "control",
  prompt = "#qianxinz",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("qianxinz_canuse") > 0
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Hand and
      #selected < Self:getMark("qianxinz_canuse") // (#Fk:currentRoom().alive_players - 1)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local moveInfos = {}
    local n = #room.draw_pile // #room.alive_players
    local position = 1
    table.shuffle(effect.cards)
    for _, id in ipairs(effect.cards) do
      table.insert(moveInfos, {
        ids = {id},
        from = player.id,
        fromArea = Card.PlayerHand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
        drawPilePosition = position * #room.alive_players
      })
      position = position + 1
    end
    room:moveCards(table.unpack(moveInfos))
    room:setPlayerMark(player, "qianxinz_using", 1)
    room:setPlayerMark(target, "@@zhanggong_mail", 1)
    for _, id in ipairs(effect.cards) do
      room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 1)
    end
  end,
}
local qianxinz_trigger = fk.CreateTriggerSkill{
  name = "#qianxinz_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:getMark("qianxinz_using") > 0 and target:getMark("@@zhanggong_mail") > 0 and target.phase == Player.Discard and
      table.find(target:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") > 0 end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("qianxinz")
    room:notifySkillInvoked(player, "qianxinz", "control")
    room:doIndicate(player.id, {target.id})
    for _, id in ipairs(target:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
    end
    if table.every(Fk:getAllCardIds(), function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") == 0 end) then
      room:setPlayerMark(player, "qianxinz_using", 0)
      room:setPlayerMark(target, "@@zhanggong_mail", 0)
    end
    local choices = {"qianxinz2"}
    if player:getHandcardNum() < 4 then
      table.insert(choices, 1, "qianxinz1:"..player.id)
    end
    local choice = room:askForChoice(target, choices, "qianxinz", nil, nil, {"qianxinz1:"..player.id, "qianxinz2"})
    if choice ~= "qianxinz2" then
      player:drawCards(4 - player:getHandcardNum(), "qianxinz")
    else
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
    end
  end,

  refresh_events = {fk.StartPlayCard, fk.AfterCardsMove, fk.Death, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.StartPlayCard then
      return target == player and player:hasSkill(self)
    elseif event == fk.AfterCardsMove and player:getMark("qianxinz_using") > 0 then
      local room = player.room
      for _, move in ipairs(data) do
        if not move.to or move.toArea ~= Card.PlayerHand or
          room:getPlayerById(move.to):getMark("@@zhanggong_mail") == 0 or
          room:getPlayerById(move.to).phase == Player.NotActive then
          return true
        end
      end
    elseif event == fk.Death then
      return target == player and player:getMark("qianxinz_using") > 0
    elseif event == fk.EventLoseSkill then
      return data == self and player:getMark("qianxinz_using") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.StartPlayCard then
      if table.find(room.draw_pile, function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") > 0 end) then
        room:setPlayerMark(player, "qianxinz_canuse", 0)
      else
        room:setPlayerMark(player, "qianxinz_canuse", #room.draw_pile)
      end
    elseif event == fk.AfterCardsMove then
      local to = table.filter(room.alive_players, function(p) return p:getMark("@@zhanggong_mail") > 0 end)
      if #to == 0 then
        room:setPlayerMark(player, "qianxinz_using", 0)
        for _, id in ipairs(Fk:getAllCardIds()) do
          room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
        end
      else
        to = to[1]
        for _, move in ipairs(data) do
          if not move.to or move.to ~= to.id or move.toArea ~= Card.PlayerHand or to.phase == Player.NotActive then
            for _, info in ipairs(move.moveInfo) do
              room:setCardMark(Fk:getCardById(info.cardId), "@@zhanggong_mail", 0)
            end
          end
        end
        if table.every(Fk:getAllCardIds(), function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") == 0 end) then
          room:setPlayerMark(player, "qianxinz_using", 0)
          room:setPlayerMark(to, "@@zhanggong_mail", 0)
        end
      end
    else
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "@@zhanggong_mail", 0)
      end
      for _, id in ipairs(Fk:getAllCardIds()) do
        room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
      end
    end
  end,
}
local zhenxing = fk.CreateTriggerSkill{
  name = "zhenxing",
  anim_type = "masochism",
  events = {fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.Damaged then
        return true
      else
        return player.phase == Player.Finish
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    local can_get = table.filter(cards, function(id)
      return not table.find(cards, function(id2)
        return id ~= id2 and Fk:getCardById(id).suit == Fk:getCardById(id2).suit
      end)
    end)
    local card, choice = U.askforChooseCardsAndChoice(player, can_get,  {"OK"}, self.name, "#zhenxing-get", {"Cancel"}, 0, 1, cards)
    local get = card[1]
    if get then
      table.removeOne(cards, get)
    end
    for i = #cards, 1, -1 do
      table.insert(room.draw_pile, 1, cards[i])
    end
    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)
    if get then
      room:obtainCard(player.id, card[1], false, fk.ReasonJustMove)
    end
  end,
}
qianxinz:addRelatedSkill(qianxinz_trigger)
zhanggong:addSkill(qianxinz)
zhanggong:addSkill(zhenxing)
Fk:loadTranslationTable{
  ["zhanggong"] = "张恭",
  ["#zhanggong"] = "西域长歌",
  ["illustrator:zhanggong"] = "B_LEE",
  ["qianxinz"] = "遣信",
  [":qianxinz"] = "出牌阶段限一次，若牌堆中没有“信”，你可以选择一名角色并将任意张手牌置于牌堆中X倍数的位置（X为存活人数），称为“信”。"..
  "该角色弃牌阶段开始时，若其手牌中有本回合获得的“信”，其选择一项：1.你将手牌摸至四张；2.其本回合手牌上限-2。",
  ["zhenxing"] = "镇行",
  [":zhenxing"] = "结束阶段开始时或当你受到伤害后，你可以观看牌堆顶三张牌，然后获得其中与其余牌花色均不同的一张牌。",
  ["#qianxinz"] = "遣信：选择“遣信”目标，将任意张手牌作为“信”置入牌堆",
  ["@@zhanggong_mail"] = "信",
  ["#zhenxing-get"] = "镇行：你可以获得其中一张牌",
  ["qianxinz1"] = "%src将手牌摸至四张",
  ["qianxinz2"] = "你本回合手牌上限-2",

  ["$qianxinz1"] = "遣信求援，前后合围。",
  ["$qianxinz2"] = "信中所言，吾知计策一二。",
  ["$zhenxing1"] = "兵行万土，得御安危。",
  ["$zhenxing2"] = "边境镇威，万军难进。",
  ["~zhanggong"] = "边关失守，我之过失！",
}

local lvkai = General(extension, "lvkai", "shu", 3)
local tunan = fk.CreateActiveSkill{
  name = "tunan",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#tunan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:getNCards(1)
    local card = Fk:getCardById(cards[1])
    local choices = {}  --选项一无距离限制，选项二有距离限制，不能用interaction……
    if U.getDefaultTargets(target, card, false, true) then
      table.insert(choices, "tunan1:::"..card:toLogString())
    end
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    slash:addSubcard(card)
    if U.getDefaultTargets(target, slash, true, false) then
      table.insert(choices, "tunan2:::"..card:toLogString())
    end
    if #choices == 0 then
      table.insert(room.draw_pile, 1, cards[1])
      return
    end
    local choice = room:askForChoice(target, choices, self.name, nil, nil,
      {"tunan1:::"..card:toLogString(), "tunan2:::"..card:toLogString()})
    local success, dat
    if choice[6] == "1" then
      U.askForUseRealCard(room, target, cards, ".", self.name, nil, {expand_pile = cards, bypass_distances = true}, false, false)
    else
      U.askForUseVirtualCard(room, target, "slash", cards, self.name, "#tunan2-use:::"..card:toLogString(), false, true, false, true)
    end
  end,
}
local bijing = fk.CreateTriggerSkill{
  name = "bijing",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player, 1, 2, false, self.name, true, ".", "#bijing-invoke")
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(self.cost_data) do
      player.room:setCardMark(Fk:getCardById(id), "@@bijing", 1)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then
      for _, move in ipairs(data) do
        if move.from and move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@bijing") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from and move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@bijing", 0)
        end
      end
    end
    if room.current and not room.current.dead then
      room:setPlayerMark(room.current, "bijing_invoking-turn", player.id)
    end
  end,
}
local bijing_trigger = fk.CreateTriggerSkill{
  name = "#bijing_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if player.phase == Player.Discard then
        return player:getMark("bijing_invoking-turn") ~= 0 and not player:isNude()
      elseif player.phase == Player.Start then
        return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@bijing") > 0 end)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Discard then
      local src = room:getPlayerById(player:getMark("bijing_invoking-turn"))
      src:broadcastSkillInvoke("bijing")
      room:notifySkillInvoked(src, "bijing", "control")
      room:doIndicate(src.id, {player.id})
      room:askForDiscard(player, 2, 2, true, "bijing", false)
    else
      player:broadcastSkillInvoke("bijing")
      room:notifySkillInvoked(player, "bijing", "drawcard")
      local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@bijing") > 0 end)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@bijing", 0)
      end
      room:recastCard(cards, player, "bijing")
    end
  end,
}
bijing:addRelatedSkill(bijing_trigger)
lvkai:addSkill(tunan)
lvkai:addSkill(bijing)
Fk:loadTranslationTable{
  ["lvkai"] = "吕凯",
  ["#lvkai"] = "铁心司南",
  ["illustrator:lvkai"] = "大佬荣&alien",
  ["tunan"] = "图南",
  [":tunan"] = "出牌阶段限一次，你可令一名其他角色观看牌堆顶一张牌，然后该角色选择一项：1.使用此牌（无距离限制）；2.将此牌当【杀】使用。",
  ["bijing"] = "闭境",
  [":bijing"] = "结束阶段，你可以选择至多两张手牌标记为“闭境”。若你于回合外失去“闭境”牌，当前回合角色的弃牌阶段开始时，其需弃置两张牌。"..
  "准备阶段，你重铸手牌中的“闭境”牌。",
  ["#tunan"] = "图南：令一名角色观看牌堆顶牌，其可以使用此牌或将此牌当【杀】使用",
  ["tunan1"] = "使用%arg（无距离限制）",
  ["tunan2"] = "将%arg当【杀】使用",
  ["tunan_viewas"] = "图南",
  ["#tunan2-use"] = "图南：将%arg当【杀】使用",
  ["#bijing-invoke"] = "闭境：你可以将至多两张手牌标记为“闭境”牌",
  ["@@bijing"] = "闭境",

  ["$tunan1"] = "敢问丞相，何时挥师南下？",
  ["$tunan2"] = "攻伐之道，一念之间。",
  ["$bijing1"] = "拒吴闭境，臣誓保永昌！",
  ["$bijing2"] = "一臣无二主，可战不可降！",
  ["~lvkai"] = "守节不易，吾愿舍身为蜀。",
}

local weiwenzhugezhi = General(extension, "weiwenzhugezhi", "wu", 4)
local fuhaiw = fk.CreateActiveSkill{
  name = "fuhaiw",
  anim_type = "special",
  card_num = 0,
  target_num = 1,
  prompt = "#fuhaiw",
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("fuhaiw_invalid-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return (target:getNextAlive() == Self or Self:getNextAlive() == target) and
        target:getMark("fuhaiw-phase") == 0 and not target:isKongcheng()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local order = player:getNextAlive() == target and "right" or "left"
    while not player.dead do
      room:doIndicate(player.id, {target.id})
      room:addPlayerMark(player, "fuhaiw_count-phase", 1)
      room:setPlayerMark(target, "fuhaiw-phase", 1)
      local card1 = room:askForCard(player, 1, 1, false, self.name, false, ".", "#fuhaiw1-show::"..target.id)
      local n1 = Fk:getCardById(card1[1]).number
      player:showCards(card1)
      if player.dead or target.dead or target:isKongcheng() then return end
      local card2 = room:askForCard(target, 1, 1, false, self.name, false, ".", "#fuhaiw2-show:"..player.id)
      local n2 = Fk:getCardById(card2[1]).number
      target:showCards(card2)
      if player.dead or target.dead then return end
      if n1 >= n2 then
        if room:getCardOwner(card1[1]) == player and room:getCardArea(card1[1]) == Card.PlayerHand then
          room:throwCard(card1, self.name, player, player)
        end
      else
        if room:getCardOwner(card2[1]) == target and room:getCardArea(card2[1]) == Card.PlayerHand then
          room:setPlayerMark(player, "fuhaiw_invalid-phase", 1)
          room:throwCard(card2, self.name, target, target)
          if not player.dead then
            player:drawCards(player:getMark("fuhaiw_count-phase"), self.name)
          end
          if not target.dead then
            target:drawCards(player:getMark("fuhaiw_count-phase"), self.name)
          end
          return
        end
      end
      if player:isKongcheng() or player.dead then return end
      if order == "right" then
        target = target:getNextAlive()
      else
        target = target:getLastAlive()
      end
      if target:isKongcheng() or target:getMark("fuhaiw-phase") > 0 then return end
    end
  end,
}
weiwenzhugezhi:addSkill(fuhaiw)
Fk:loadTranslationTable{
  ["weiwenzhugezhi"] = "卫温诸葛直",
  ["#weiwenzhugezhi"] = "帆至夷洲",
  ["illustrator:weiwenzhugezhi"] = "秋呆呆",
  ["fuhaiw"] = "浮海",
  [":fuhaiw"] = "出牌阶段对每名角色限一次，你可以展示一张手牌并选择上家或下家，该角色展示一张手牌。若你的牌点数：不小于其，你弃置你展示的牌，然后对其"..
  "上家或下家重复此流程；小于其，其弃置其展示的牌，然后你与其各摸X张牌（X为你本阶段发动此技能选择过的角色数），本阶段你不能再发动〖浮海〗。",
  ["#fuhaiw"] = "浮海：选择一名目标，双方各展示一张手牌",
  ["#fuhaiw1-show"] = "浮海：对 %dest 发动“浮海”，展示一张手牌",
  ["#fuhaiw2-show"] = "浮海：请响应 %src 的“浮海”，展示一张手牌",

  ["$fuhaiw1"] = "宦海沉浮，生死难料！",
  ["$fuhaiw2"] = "跨海南征，波涛起浮。",
  ["~weiwenzhugezhi"] = "吾皆海岱清士，岂料生死易逝……",
}

--自走棋：沙摩柯 忙牙长 许贡 张昌蒲
local shamoke = General(extension, "shamoke", "shu", 4)
local jilis = fk.CreateTriggerSkill{
  name = "jilis",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local x, y = player:getAttackRange(), player:getMark("jilis_times-turn")
      if x >= y then
        local room = player.room
        local logic = room.logic
        local end_id = player:getMark("jilis_record-turn")
        local e = logic:getCurrentEvent()
        if end_id == 0 then
          local turn_event = e:findParent(GameEvent.Turn, false)
          if turn_event == nil then return false end
          end_id = turn_event.id
        end
        room:setPlayerMark(player, "jilis_record-turn", logic.current_event_id)
        local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        events = logic.event_recorder[GameEvent.RespondCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        room:setPlayerMark(player, "jilis_times-turn", y)
        return x == y
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getAttackRange())
  end,
}
shamoke:addSkill(jilis)
Fk:loadTranslationTable{
  ["shamoke"] = "沙摩柯",
  ["#shamoke"] = "五溪蛮夷",
  ["illustrator:shamoke"] = "Ray",
  ["jilis"] = "蒺藜",
  [":jilis"] = "当你于一回合内使用或打出第X张牌时，你可以摸X张牌（X为你的攻击范围）。",

  ["$jilis1"] = "蒺藜骨朵，威震慑敌！",
  ["$jilis2"] = "看我一招，铁蒺藜骨朵！",
  ["~shamoke"] = "五溪蛮夷，不可能输！",
}

local mangyachang = General(extension, "mangyachang", "qun", 4)
local jiedao = fk.CreateTriggerSkill{
  name = "jiedao",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player:getMark("jiedao-turn") == 0 then
        player.room:addPlayerMark(player, "jiedao-turn", 1)
        return player:isWounded()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiedao-invoke::"..data.to.id..":"..player:getLostHp())
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getLostHp()
    data.damage = data.damage + n
    data.extra_data = data.extra_data or {}
    data.extra_data.jiedao = n
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.to.dead and data.extra_data and data.extra_data.jiedao and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = data.extra_data.jiedao
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      room:askForDiscard(player, n, n, true, self.name, false, ".", "#jiedao-discard:::"..n)
    end
  end,
}
mangyachang:addSkill(jiedao)
Fk:loadTranslationTable{
  ["mangyachang"] = "忙牙长",
  ["#mangyachang"] = "截头蛮锋",
  ["illustrator:mangyachang"] = "北★MAN",
  ["jiedao"] = "截刀",
  [":jiedao"] = "当你每回合第一次造成伤害时，你可令此伤害至多+X（X为你损失的体力值）。然后若受到此伤害的角色没有死亡，你弃置等同于此伤害加值的牌。",
  ["#jiedao-invoke"] = "截刀：你可以令你对 %dest 造成的伤害+%arg",
  ["#jiedao-discard"] = "截刀：你需弃置等同于此伤害加值的牌（%arg张）",

  ["$jiedao1"] = "截头大刀的威力，你来尝尝？",
  ["$jiedao2"] = "我这大刀，可是不看情面的。",
  ["~mangyachang"] = "黄骠马也跑不快了……",
}

local xugong = General(extension, "ty__xugong", "wu", 3)
local biaozhao = fk.CreateTriggerSkill{
  name = "biaozhao",
  mute = true,
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  derived_piles = "biaozhao_message",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return (player.phase == Player.Finish and #player:getPile("biaozhao_message") == 0) or
      (player.phase == Player.Start and #player:getPile("biaozhao_message") > 0)
    elseif event == fk.AfterCardsMove and #player:getPile("biaozhao_message") > 0 then
      local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      local cards = room:askForCard(player, 1, 1, true, self.name, true, ".", "#biaozhao-cost")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      if player.phase == Player.Finish then
        player:addToPile("biaozhao_message", self.cost_data, true, self.name)
      else
        room:moveCards({
          from = player.id,
          ids = player:getPile("biaozhao_message"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        local targets = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#biaozhao-choose", self.name, false)
        if #targets > 0 then
          local to = room:getPlayerById(targets[1])
          if to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = self.name,
            }
          end
          if not to.dead then
            local x = 0
            for _, p in ipairs(room.alive_players) do
              x = math.max(x, p:getHandcardNum())
            end
            x = x - to:getHandcardNum()
            if x > 0 then
              room:drawCards(to, math.min(5, x), self.name)
            end
          end
        end
      end
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name)
      local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
      local targets = {}
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from ~= nil and
        move.from ~= player.id and not room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local card = Fk:getCardById(info.cardId)
              if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
                table.insertIfNeed(targets, move.from)
              end
            end
          end
        end
      end
      if #targets > 1 then
        targets = room:askForChoosePlayers(player, targets, 1, 1, "#biaozhao-target:::" .. pile:toLogString(), self.name, false)
      end
      if #targets > 0 then
        room:obtainCard(targets[1], pile, false, fk.ReasonPrey)
      end
      if #targets == 0 then
        room:moveCards({
          from = player.id,
          ids = {pile.id},
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        if not player.dead then
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
local yechou = fk.CreateTriggerSkill{
  name = "yechou",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true) and table.find(player.room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
    local p = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#yechou-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "@@yechou", 1)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yechou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yechou", 0)
  end,
}
local yechou_delay = fk.CreateTriggerSkill{
  name = "#yechou_delay",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and player:getMark("@@yechou") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, yechou.name)
  end,
}
yechou:addRelatedSkill(yechou_delay)
xugong:addSkill(biaozhao)
xugong:addSkill(yechou)
Fk:loadTranslationTable{
  ["ty__xugong"] = "许贡",
  ["#ty__xugong"] = "独计击流",
  ["illustrator:ty__xugong"] = "红字虾",
  ["biaozhao"] = "表召",
  [":biaozhao"] = "结束阶段，你可将一张牌置于武将牌上，称为“表”。当一张与“表”花色点数均相同的牌进入弃牌堆时，若此牌是其他角色弃置的牌，"..
  "则其获得“表”，否则你移去“表”并失去1点体力。准备阶段，你移去“表”，令一名角色回复1点体力，其将手牌摸至与手牌最多的角色相同（至多摸五张）。",
  ["yechou"] = "业仇",
  ["#yechou_delay"] = "业仇",
  [":yechou"] = "你死亡时，你可以选择一名已损失的体力值大于1的角色。若如此做，每名角色的结束阶段，其失去1点体力，直到其下回合开始。",

  ["biaozhao_message"] = "表",
  ["#biaozhao-cost"] = "你可以发动表召，选择一张牌作为表置于武将牌上",
  ["#biaozhao-choose"] = "表召：选择一名角色，令其回复1点体力并补充手牌",
  ["#biaozhao-target"] = "表召：选择一名角色，令其获得你的“表”%arg",
  ["#yechou-choose"] = "你可以发动表召，选择一名角色，令其于下个回合开始之前的每名角色的结束阶段都会失去1点体力",
  ["@@yechou"] = "业仇",

  ["$biaozhao1"] = "此人有祸患之像，望丞相慎之。",
  ["$biaozhao2"] = "孙策宜加贵宠，须召还京邑！",
  ["$yechou1"] = "会有人替我报仇的！",
  ["$yechou2"] = "我的门客，是不会放过你的！",
  ["~ty__xugong"] = "终究……还是被其所害……",
}

local zhangchangpu = General(extension, "ty__zhangchangpu", "wei", 3, 3, General.Female)
local yanjiao = fk.CreateActiveSkill{
  name = "yanjiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#yanjiao",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = 4 + player:getMark("@yanjiao")
    room:setPlayerMark(player, "@yanjiao", 0)
    local cards = room:getNCards(n)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local result = room:askForCustomDialog(target, self.name, "packages/tenyear/qml/YanjiaoBox.qml", {
        cards,
        player.general,
        target.general,
      })
    local rest, pile1, pile2 = {}, {}, {}
    if result ~= "" then
      local d = json.decode(result)
      rest = d[1]
      pile1 = d[2]
      pile2 = d[3]
    else
      rest = cards
    end
    local moveInfos = {}
    if #pile1 > 0 then
      table.insert(moveInfos, {
        ids = pile1,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = target.id,
        skillName = self.name,
        moveVisible = true,
      })
    end
    if #pile2 > 0 then
      table.insert(moveInfos, {
        ids = pile2,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = target.id,
        skillName = self.name,
        moveVisible = true,
      })
    end
    if #rest > 0 then
      table.insert(moveInfos, {
        ids = rest,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        proposer = target.id,
        skillName = self.name,
      })
      if #rest > 1 then
        room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      end
    end
    room:moveCards(table.unpack(moveInfos))
  end,
}
local xingshen = fk.CreateTriggerSkill{
  name = "xingshen",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function(p) return p:getHandcardNum() >= player:getHandcardNum() end) then
      player:drawCards(2, self.name)
    else
      player:drawCards(1, self.name)
    end
    if player.dead or player:getMark("@yanjiao") > 5 then return end
    if table.every(room.alive_players, function(p) return p.hp >= player.hp end) then
      room:addPlayerMark(player, "@yanjiao", player:getMark("@yanjiao") > 4 and 1 or 2)
    else
      room:addPlayerMark(player, "@yanjiao", 1)
    end
  end,
}
zhangchangpu:addSkill(yanjiao)
zhangchangpu:addSkill(xingshen)
Fk:loadTranslationTable{
  ["ty__zhangchangpu"] = "张昌蒲",
  ["#ty__zhangchangpu"] = "矜严明训",
  ["illustrator:ty__zhangchangpu"] = "biou09",
  ["yanjiao"] = "严教",
  [":yanjiao"] = "出牌阶段限一次，你可以选择一名其他角色并亮出牌堆顶的四张牌，然后令该角色将这些牌分成点数之和相等的两组牌分配给你与其，"..
  "剩余未分组的牌置入弃牌堆。若未分组的牌超过一张，你本回合手牌上限-1。",
  ["xingshen"] = "省身",
  [":xingshen"] = "当你受到伤害后，你可以摸一张牌并令下一次发动〖严教〗亮出的牌数+1。若你的手牌数为全场最少，则改为摸两张牌；"..
  "若你的体力值为全场最少，则下一次发动〖严教〗亮出的牌数改为+2（加值总数至多为6）。",
  ["#yanjiao"]= "严教：对一名其他角色发动“严教”",
  ["#yanjiao-distribute"] = "严教：请分成点数之和相等的两组",
  ["@yanjiao"] = "严教",

  ["$yanjiao1"] = "会虽童稚，勤见规诲。",
  ["$yanjiao2"] = "性矜严教，明于教训。",
  ["$xingshen1"] = "居上不骄，制节谨度。",
  ["$xingshen2"] = "君子之行，皆积小以致高大。",
  ["~ty__zhangchangpu"] = "我还是小看了，孙氏的伎俩……",
}

--上兵伐谋：辛毗 张温 李肃
local xinpi = General(extension, "xinpi", "wei", 3)
local chijie = fk.CreateTriggerSkill{
  name = "chijie",
  anim_type = "control",
  events = {fk.CardEffecting , fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardEffecting then
      return player:hasSkill(self) and data.from ~= player.id and target == player and player:getMark("chijie_a-turn") == 0
      and data.card.sub_type ~= Card.SubtypeDelayedTrick and data.tos and #TargetGroup:getRealTargets(data.tos) > 1
    else
      if target ~= player and player:hasSkill(self) and not data.damageDealt and player:getMark("chijie_b-turn") == 0 and data.tos and
        table.contains(TargetGroup:getRealTargets(data.tos), player.id) then
        local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
        return table.find(cardList, function(id) return not player.room:getCardOwner(id) end)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffecting then
      return room:askForSkillInvoke(player, self.name, nil, "#chijie-nullify:::"..data.card.name)
    else
      return room:askForSkillInvoke(player, self.name, nil, "#chijie-give:::"..data.card.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffecting then
      room:addPlayerMark(player, "chijie_a-turn")
      local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e and e.data[1] then
        local use = e.data[1]
        local list = use.nullifiedTargets or {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          table.insertIfNeed(list, p.id)
        end
        use.nullifiedTargets = list
      end
    else
      room:addPlayerMark(player, "chijie_b-turn")
      local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
      local cards = table.filter(cardList, function(id) return not room:getCardOwner(id) end)
      if #cards == 0 then return end
      local dummy = Fk:cloneCard("slash")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, true, fk.ReasonJustMove)
    end
  end,
}
xinpi:addSkill(chijie)
local yinju = fk.CreateActiveSkill{
  name = "yinju",
  anim_type = "support",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, use)
    local to = room:getPlayerById(use.tos[1])
    room:setPlayerMark(to, "@@yinju-turn", 1)
  end,
}
local yinju_trigger = fk.CreateTriggerSkill{
  name = "#yinju_trigger",
  anim_type = "support",
  events = {fk.DamageCaused, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player then
      if event == fk.DamageCaused then
        return data.to ~= player and data.to:getMark("@@yinju-turn") > 0
      else
        return data.to ~= player.id and player.room:getPlayerById(data.to):getMark("@@yinju-turn") > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yinju")
    if event == fk.DamageCaused then
      if data.to:isWounded() then
        room:recover { num = data.damage, skillName = self.name, who = data.to , recoverBy = player}
      end
      return true
    else
      local to = room:getPlayerById(data.to)
      player:drawCards(1, self.name)
      if not to.dead then
        to:drawCards(1, self.name)
      end
    end
  end,
}
yinju:addRelatedSkill(yinju_trigger)
xinpi:addSkill(yinju)
Fk:loadTranslationTable{
  ["xinpi"] = "辛毗",
  ["#xinpi"] = "一节肃六军",
  ["illustrator:xinpi"] = "石蝉",
  ["chijie"] = "持节",
  [":chijie"] = "每回合每项各限一次，<br>①当其他角色使用牌对你生效时，你可以令此牌在接下来的结算中对其他角色无效；<br>②当其他角色使用牌结算结束后，"..
  "若你是目标之一且此牌没有造成过伤害，你可以获得之。",
  ["#chijie-nullify"] = "持节：你可以令 %arg 在接下来的结算中对其他角色无效",
  ["#chijie-give"] = "持节：你可以获得此 %arg",
  ["yinju"] = "引裾",
  [":yinju"] = "限定技，出牌阶段，你可以选择一名其他角色。本回合：1.当你对其造成伤害时，改为令其回复等量的体力；2.当你使用牌指定该角色为目标后，"..
  "你与其各摸一张牌。",
  ["@@yinju-turn"] = "引裾",
  ["#yinju_trigger"] = "引裾",

  ["$chijie1"] = "持节阻战，奉帝赐诏。",
  ["$chijie2"] = "此战不在急，请仲达明了。",
  ["$yinju1"] = "据理直谏，吾人臣本分。",
  ["$yinju2"] = "迁徙之计，危涉万民。",
  ["~xinpi"] = "失民心，且无食。",
}

local zhangwen = General(extension, "ty__zhangwen", "wu", 3)
local ty__songshu = fk.CreateActiveSkill{
  name = "ty__songshu",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    else
      if not player.dead then
        player:drawCards(2, self.name)
      end
      if not target.dead then
        target:drawCards(2, self.name)
      end
    end
  end,
}
local sibian = fk.CreateTriggerSkill{
  name = "sibian",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local min, max = 13, 1
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).number < min then
        min = Fk:getCardById(id).number
      end
      if Fk:getCardById(id).number > max then
        max = Fk:getCardById(id).number
      end
    end
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).number == min or Fk:getCardById(cards[i]).number == max then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    room:delay(1000)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(get)
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    if #cards > 0 then
      local n = #player.player_cards[Player.Hand]
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] < n then
          n = #p.player_cards[Player.Hand]
        end
      end
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if #p.player_cards[Player.Hand] == n then
          table.insert(targets, p.id)
        end
      end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#sibian-choose", self.name, true)
      if #to > 0 then
        local dummy2 = Fk:cloneCard("dilu")
        dummy2:addSubcards(cards)
        room:obtainCard(room:getPlayerById(to[1]), dummy2, false, fk.ReasonGive, player.id)
      else
        room:moveCards({
          ids = cards,
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
      end
    end
    return true
  end,
}
zhangwen:addSkill(ty__songshu)
zhangwen:addSkill(sibian)
Fk:loadTranslationTable{
  ["ty__zhangwen"] = "张温",
  ["#ty__zhangwen"] = "冲天孤鹭",
  ["illustrator:ty__zhangwen"] = "zoo",
  ["ty__songshu"] = "颂蜀",
  [":ty__songshu"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你没赢，你和该角色各摸两张牌；若你赢，视为本阶段此技能未发动过。",
  ["sibian"] = "思辩",
  [":sibian"] = "摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶的4张牌，你获得其中所有点数最大和最小的牌，然后你可以将剩余的牌交给一名手牌数最少的角色。",
  ["#sibian-choose"] = "思辩：你可以将剩余的牌交给一名手牌数最少的角色",

  ["$ty__songshu1"] = "称颂蜀汉，以表诚心。",
  ["$ty__songshu2"] = "吴蜀两和，方可安稳。",
  ["$sibian1"] = "才藻俊茂，辨思如涌。",
  ["$sibian2"] = "弘雅之素，英秀之德。",
  ["~ty__zhangwen"] = "暨艳过错，强牵吾罪。",
}

local lisu = General(extension, "ty__lisu", "qun", 2)
local lixun = fk.CreateTriggerSkill{
  name = "lixun",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (event == fk.DamageInflicted or (event == fk.EventPhaseStart and player.phase == Player.Play))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageInflicted then
      room:notifySkillInvoked(player, self.name, "defensive")
      room:addPlayerMark(player, "@lisu_zhu", data.damage)
      return true
    else
      room:notifySkillInvoked(player, self.name, "negative")
      local pattern = ".|A~"..(player:getMark("@lisu_zhu") - 1)
      if player:getMark("@lisu_zhu") <= 1 then
        pattern = "."
      end
      local judge = {
        who = player,
        reason = self.name,
        pattern = pattern,
      }
      room:judge(judge)
      local n = player:getMark("@lisu_zhu")
      if judge.card.number < n then
        local cards = room:askForDiscard(player, n, n, false, self.name, false)
        if #cards < n then
          room:loseHp(player, n - #cards)
        end
      end
    end
  end,
}
local kuizhul = fk.CreateTriggerSkill{
  name = "kuizhul",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() and table.every(player.room:getOtherPlayers(player), function(p2)
        return p.hp >= p2.hp
        end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() and table.every(room:getOtherPlayers(player), function(p2)
        return p.hp >= p2.hp
        end)
      end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuizhul-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if math.min(to:getHandcardNum(), 5) > player:getHandcardNum() then
      player:drawCards(math.min(to:getHandcardNum(), 5) - player:getHandcardNum(), player.id)
    end
    if player.dead or to.dead or player:isKongcheng() or to:isKongcheng() then return end
    local cards = table.filter(to:getCardIds("h"), function(id) return not to:prohibitDiscard(Fk:getCardById(id)) end)
    if #cards == 0 then
      U.viewCards(to, player:getCardIds("h"), self.name)
      return
    end
    local results = U.askForExchange(to, player.general, to.general, player:getCardIds("h"), cards, "#kuizhul-exchange:"..player.id, 999)
    if #results == 0 then return end
    local to_throw = table.filter(results, function(id) return table.contains(to:getCardIds("h"), id) end)
    room:throwCard(to_throw, self.name, to, to)
    if to.dead or player.dead then return end
    local to_get = table.filter(results, function(id) return table.contains(player:getCardIds("h"), id) end)
    if #to_get == 0 then return end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(to_get)
    room:moveCardTo(dummy, Card.PlayerHand, to, fk.ReasonPrey, self.name, nil, false, to.id)
    if player.dead or #to_get < 2 then return end
    local targets = table.map(table.filter(room.alive_players, function(p) return to:inMyAttackRange(p) end), Util.IdMapper)
    if #targets > 0 then
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#kuizhul-damage::"..to.id, self.name, true, true)
      if #targets > 0 then
        room:doIndicate(to.id, targets)
        room:damage{
          from = to,
          to = room:getPlayerById(targets[1]),
          damage = 1,
          skillName = self.name,
        }
        return
      end
    end
    room:removePlayerMark(player, "@lisu_zhu", 1)
  end,
}
lisu:addSkill(lixun)
lisu:addSkill(kuizhul)
Fk:loadTranslationTable{
  ["ty__lisu"] = "李肃",
  ["#ty__lisu"] = "魔使",
  ["illustrator:ty__lisu"] = "alien",
  ["lixun"] = "利熏",
  [":lixun"] = "锁定技，当你受到伤害时，你防止此伤害，然后获得等同于伤害值的“珠”标记。出牌阶段开始时，你进行一次判定，若结果点数小于“珠”数，"..
  "你弃置等同于“珠”数的手牌，若弃牌数不足，则失去不足数量的体力值。",
  ["kuizhul"] = "馈珠",
  [":kuizhul"] = "出牌阶段结束时，你可以选择体力值全场最大的一名其他角色，将手牌摸至与该角色相同（最多摸至五张），然后该角色观看你的手牌，"..
  "弃置任意张手牌并从观看的牌中获得等量的牌，若其获得的牌数大于1，则你选择一项：1.移去一个“珠”；2.令其对其攻击范围内的一名角色造成1点伤害。",
  ["@lisu_zhu"] = "珠",
  ["#kuizhul-choose"] = "馈珠：你可以将手牌补至与一名角色相同，其可以获得你的手牌",
  ["#kuizhul-exchange"] = "馈珠：你可以弃置任意张手牌，获得%src等量的手牌",
  ["#kuizhul-damage"] = "馈珠：选择一名角色令 %dest 对其造成伤害，或点“取消”移去一个“珠”",

  ["$lixun1"] = "利欲熏心，财权保命。",
  ["$lixun2"] = "利益当前，岂不心动？",
  ["$kuizhul1"] = "与君同谋，赠君金珠。",
  ["$kuizhul2"] = "金珠熠熠，都归将军了。",
  ["~ty__lisu"] = "金银珠宝再多，也难买命啊。",
}

--戚宦之争：何进 冯方 赵忠 穆顺
local hejin = General(extension, "ty__hejin", "qun", 4)
local ty__mouzhu = fk.CreateActiveSkill{
  name = "ty__mouzhu",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and (target:distanceTo(Self) == 1 or target.hp == Self.hp) and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(effect.tos) do
      local target = room:getPlayerById(p)
      if player.dead or target.dead then return end
      if not target:isKongcheng() then
        local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#mouzhu-give::"..player.id)
        room:obtainCard(player, card[1], false, fk.ReasonGive, target.id)
        if #player.player_cards[Player.Hand] > #target.player_cards[Player.Hand] then
          local choice = room:askForChoice(target, {"slash", "duel"}, self.name)
          room:useVirtualCard(choice, nil, target, player, self.name, true)
        end
      end
    end
  end,
}
local ty__yanhuo = fk.CreateTriggerSkill{
  name = "ty__yanhuo",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yanhuo-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setTag("yanhuo", true)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag("yanhuo") and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
hejin:addSkill(ty__mouzhu)
hejin:addSkill(ty__yanhuo)
Fk:loadTranslationTable{
  ["ty__hejin"] = "何进",
  ["#ty__hejin"] = "色厉内荏",
  ["cv:ty__hejin"] = "冷泉月夜",
  ["illustrator:ty__hejin"] = "凝聚永恒",
  ["ty__mouzhu"] = "谋诛",
  [":ty__mouzhu"] = "出牌阶段限一次，你可以选择任意名与你距离为1或体力值与你相同的其他角色，依次将一张手牌交给你，然后若其手牌数小于你，"..
  "其视为对你使用一张【杀】或【决斗】。",
  ["ty__yanhuo"] = "延祸",
  [":ty__yanhuo"] = "当你死亡时，你可以令本局接下来所有【杀】的伤害基数值+1。",
  ["#mouzhu-give"] = "谋诛：交给%dest一张手牌，然后若你手牌数小于其，视为你对其使用【杀】或【决斗】",
  ["#yanhuo-invoke"] = "延祸：你可以令本局接下来所有【杀】的伤害基数值+1！",

  ["$ty__mouzhu1"] = "尔等祸乱朝纲，罪无可赦，按律当诛！",
  ["$ty__mouzhu2"] = "天下人之怨皆系于汝等，还不快认罪伏法？",
  ["$ty__yanhuo1"] = "你们，都要为我殉葬！",
  ["$ty__yanhuo2"] = "杀了我，你们也别想活！",
  ["~ty__hejin"] = "诛宦不成，反遭其害，遗笑天下人矣……",
}

local fengfang = General(extension, "fengfang", "qun", 3)
local diting = fk.CreateTriggerSkill{
  name = "diting",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and not target:isKongcheng() and
      target:inMyAttackRange(player) and player.hp > 0  --fxxk buqu
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#diting-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = table.random(target:getCardIds("h"), math.min(target:getHandcardNum(), player.hp))
    local id = room:askForCardsChosen(player, target, 1, 1, {card_data = {{target.general, cards}}}, self.name)[1]
    room:setPlayerMark(target, "diting_"..player.id.."-phase", id)
  end,
}
local diting_trigger = fk.CreateTriggerSkill{
  name = "#diting_trigger",
  mute = true,
  events = {fk.TargetSpecified, fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("diting", Player.HistoryPhase) > 0 and target:getMark("diting_"..player.id.."-phase") ~= 0 and not player.dead then
      if event == fk.TargetSpecified then
        return data.card:getEffectiveId() == target:getMark("diting_"..player.id.."-phase") and
          table.contains(AimGroup:getAllTargets(data.tos), player.id)
      elseif event == fk.CardUsing then
        return data.card:getEffectiveId() == target:getMark("diting_"..player.id.."-phase") and
          (not data.tos or not table.contains(TargetGroup:getRealTargets(data.tos), player.id))
      elseif event == fk.EventPhaseEnd then
        return target.phase == Player.Play and table.contains(target:getCardIds("h"), target:getMark("diting_"..player.id.."-phase"))
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("diting")
    if event == fk.TargetSpecified then
      room:notifySkillInvoked(player, "diting", "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
    elseif event == fk.CardUsing then
      room:notifySkillInvoked(player, "diting", "drawcard")
      player:drawCards(2, "diting")
    elseif event == fk.EventPhaseEnd then
      room:notifySkillInvoked(player, "diting", "control")
      local id = target:getMark("diting_"..player.id.."-phase")
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local bihuo = fk.CreateTriggerSkill{
  name = "bihuo",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= data.to
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = (event == fk.Damaged) and "#bihuo-plus" or "#bihuo-minus"
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local to = room:getPlayerById(self.cost_data)
    if event == fk.Damaged then
      room:notifySkillInvoked(player, self.name, "support")
      room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") + 1)
    else
      room:notifySkillInvoked(player, self.name, "control")
      room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") - 1)
    end
  end,
}
local bihuo_trigger = fk.CreateTriggerSkill{
  name = "#bihuo_trigger",
  mute = true,
  events = {fk.TurnStart, fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.TurnStart then
        return player:getMark("@bihuo") ~= 0
      else
        return player:getMark("@bihuo-turn") ~= 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:setPlayerMark(player, "@bihuo-turn", player:getMark("@bihuo"))
      room:setPlayerMark(player, "@bihuo", 0)
    else
      data.n = data.n + player:getMark("@bihuo-turn")
    end
  end,
}
diting:addRelatedSkill(diting_trigger)
bihuo:addRelatedSkill(bihuo_trigger)
fengfang:addSkill(diting)
fengfang:addSkill(bihuo)
Fk:loadTranslationTable{
  ["fengfang"] = "冯方",
  ["#fengfang"] = "监彻京师",
  ["illustrator:fengfang"] = "游漫美绘",
  ["diting"] = "谛听",
  [":diting"] = "其他角色出牌阶段开始时，若你在其攻击范围内，你可以观看其X张手牌（X为你的体力值），然后秘密选择其中一张。若如此做，本阶段"..
  "该角色使用此牌指定你为目标后，此牌对你无效；若没有指定你为目标，你摸两张牌；若本阶段结束时此牌仍在其手牌中，你获得之。",
  ["bihuo"] = "避祸",
  [":bihuo"] = "当你受到其他角色造成的伤害后，你可令一名角色下回合摸牌阶段摸牌数+1；当你对其他角色造成伤害后，你可令一名角色下回合摸牌阶段摸牌数-1。",
  ["#diting-invoke"] = "谛听：你可以观看 %dest 的手牌并秘密选择一张产生效果",
  ["#bihuo-plus"] = "避祸：你可以令一名角色下回合摸牌阶段摸牌数+1",
  ["#bihuo-minus"] = "避祸：你可以令一名角色下回合摸牌阶段摸牌数-1",
  ["@bihuo"] = "避祸",
  ["@bihuo-turn"] = "避祸",

  ["$diting1"] = "奉命查验，还请配合。",
  ["$diting2"] = "且容我查验一二。",
  ["$bihuo1"] = "董卓乱政，京师不可久留。",
  ["$bihuo2"] = "权臣当朝，不如早日脱身。",
  ["~fengfang"] = "掌控校事，为人所忌。",	
}

local zhaozhong = General(extension, "zhaozhong", "qun", 6)
local yangzhong = fk.CreateTriggerSkill{
  name = "yangzhong",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not data.from.dead and not data.to.dead and
      #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(data.from, 2, 2, true, self.name, true, ".", "#yangzhong-invoke::"..data.to.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, 1, self.name)
  end
}
local huangkong = fk.CreateTriggerSkill{
  name = "huangkong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng() and player.phase == Player.NotActive and
      (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
zhaozhong:addSkill(yangzhong)
zhaozhong:addSkill(huangkong)
Fk:loadTranslationTable{
  ["zhaozhong"] = "赵忠",
  ["#zhaozhong"] = "骄纵窃幸",
  ["illustrator:zhaozhong"] = "mumu",
  ["yangzhong"] = "殃众",
  [":yangzhong"] = "当你造成或受到伤害后，伤害来源可以弃置两张牌，令受到伤害的角色失去1点体力。",
  ["huangkong"] = "惶恐",
  [":huangkong"] = "锁定技，你的回合外，当你成为【杀】或普通锦囊牌的目标后，若你没有手牌，你摸两张牌。",
  ["#yangzhong-invoke"] = "殃众：你可以弃置两张牌，令 %dest 失去1点体力",

  ["$yangzhong1"] = "窃权利己，弄祸殃众！",
  ["$yangzhong2"] = "宦祸所起，池鱼所终！",
  ["$huangkong1"] = "满腹忠心，如履薄冰！",
  ["$huangkong2"] = "咱家乃皇帝之母，能有什么坏心思？",
  ["~zhaozhong"] = "咱家忠心可鉴啊！！",
}

local mushun = General(extension, "mushun", "qun", 4)
local jinjianm = fk.CreateTriggerSkill{
  name = "jinjianm",
  anim_type = "defensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@mushun_jin", 1)
    if event == fk.Damaged then
      local to = data.from
      if to and not to.dead and to ~= player and not player:isKongcheng() and not to:isKongcheng() and
        room:askForSkillInvoke(player, self.name, nil, "#jinjianm-invoke::"..to.id) then
        local pindian = player:pindian({to}, self.name)
        if pindian.results[to.id].winner == player and player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    end
  end
}
local jinjianm_attackrange = fk.CreateAttackRangeSkill{
  name = "#jinjianm_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@mushun_jin")
  end,
}
local shizhao = fk.CreateTriggerSkill{
  name = "shizhao",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:isKongcheng() and player.phase == Player.NotActive and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@mushun_jin") > 0 then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:removePlayerMark(player, "@mushun_jin", 1)
      player:drawCards(2, self.name)
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      room:addPlayerMark(player, "@shizhao-turn", 1)
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@shizhao-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@shizhao-turn")
    player.room:setPlayerMark(player, "@shizhao-turn", 0)
  end,
}
jinjianm:addRelatedSkill(jinjianm_attackrange)
mushun:addSkill(jinjianm)
mushun:addSkill(shizhao)
Fk:loadTranslationTable{
  ["mushun"] = "穆顺",
  ["#mushun"] = "疾风劲草",
  ["illustrator:mushun"] = "君桓文化",
  ["jinjianm"] = "劲坚",
  [":jinjianm"] = "当你造成或受到伤害后，你获得一个“劲”标记，然后你可以与伤害来源拼点：若你赢，你回复1点体力。每有一个“劲”你的攻击范围+1。",
  ["shizhao"] = "失诏",
  [":shizhao"] = "锁定技，你的回合外，当你每回合第一次失去最后一张手牌时：若你有“劲”，你移去一个“劲”并摸两张牌；没有“劲”，你本回合下一次受到的伤害值+1。",
  ["@mushun_jin"] = "劲",
  ["#jinjianm-invoke"] = "劲坚：你可以与 %dest 拼点，若赢，你回复1点体力",
  ["@shizhao-turn"] = "失诏",

  ["$jinjianm1"] = "卑微之人，脊中亦有七寸硬骨！",
  ["$jinjianm2"] = "目不识丁，胸中却含三分浩气！",
  ["$shizhao1"] = "并无夹带，阁下多心了。",
  ["$shizhao2"] = "将军多虑，顺安有忤逆之心？",
  ["~mushun"] = "这，何来的大风？",
}

--兵临城下：牛金 糜芳傅士仁 李采薇 赵俨 王威 李异谢旌 孙桓 孟达 是仪 孙狼
local niujin = General(extension, "ty__niujin", "wei", 4)
local cuirui = fk.CreateActiveSkill{
  name = "cuirui",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < Self.hp and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      local card = room:askForCardChosen(player, p, "h", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
}
local ty__liewei = fk.CreateTriggerSkill{
  name = "ty__liewei",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and
    (player.phase ~= Player.NotActive or player:usedSkillTimes(self.name) < player.hp)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
niujin:addSkill(cuirui)
niujin:addSkill(ty__liewei)
Fk:loadTranslationTable{
  ["ty__niujin"] = "牛金",
  ["#ty__niujin"] = "独进的兵胆",
  ["illustrator:ty__niujin"] = "游漫美绘",
  ["cuirui"] = "摧锐",
  [":cuirui"] = "限定技，出牌阶段，你可以选择至多X名其他角色（X为你的体力值），你获得这些角色各一张手牌。",
  ["ty__liewei"] = "裂围",
  [":ty__liewei"] = "每回合限X次（X为你的体力值，你的回合内无此限制），有角色进入濒死状态时，你可以摸一张牌。",

  ["$cuirui1"] = "摧折锐气，未战先衰。",
  ["$cuirui2"] = "挫其锐气，折其旌旗。",
  ["$ty__liewei1"] = "都给我交出来！",
  ["$ty__liewei2"] = "还有点用，暂且饶你一命！",
  ["~ty__niujin"] = "这酒有毒！",
}

local ty__mifangfushiren = General(extension, "ty__mifangfushiren", "shu", 4)
local ty__fengshih = fk.CreateTriggerSkill{
  name = "ty__fengshih",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TargetSpecified then
        if not data.firstTarget then return false end
        local room = player.room
        local n = player:getHandcardNum()
        local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
          local to = room:getPlayerById(id)
          return not to.dead and to:getHandcardNum() < n and not to:isKongcheng()
        end)
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      else
        local from = player.room:getPlayerById(data.from)
        if not from.dead and from:getHandcardNum() > player:getHandcardNum() then
          self.cost_data = {data.from}
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data)
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#ty__fengshih-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#ty__fengshih-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:askForDiscard(player, 1, 1, true, self.name, false)
    if player.dead then return false end
    if not to:isNude() then
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({card}, self.name, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__fengshih = data.extra_data.ty__fengshih or {}
    if event == fk.TargetSpecified then
      table.insert(data.extra_data.ty__fengshih, to.id)
    else
      table.insert(data.extra_data.ty__fengshih, player.id)
    end
  end,
}
local ty__fengshih_delay = fk.CreateTriggerSkill {
  name = "#ty__fengshih_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    return use.extra_data and use.extra_data.ty__fengshih and table.contains(use.extra_data.ty__fengshih, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
ty__fengshih:addRelatedSkill(ty__fengshih_delay)
ty__mifangfushiren:addSkill(ty__fengshih)

Fk:loadTranslationTable{
  ["ty__mifangfushiren"] = "糜芳傅士仁",
  ["#ty__mifangfushiren"] = "进退维谷",
  ["illustrator:ty__mifangfushiren"] = "游漫美绘",
  ["ty__fengshih"] = "锋势",
  [":ty__fengshih"] = "当你使用牌指定第一个目标后，若其中一名目标角色手牌数小于你，你可以弃置你与其各一张牌，然后此牌对其伤害+1；"..
  "当你成为其他角色使用牌的目标后，若你的手牌数小于其，你可以弃置你与其各一张牌，然后此牌对你伤害+1。",

  ["#ty__fengshih-invoke"] = "是否对 %dest 发动 锋势，弃置你与其各一张牌",
  ["#ty__fengshih-choose"] = "是否发动 锋势，弃置你与一名目标角色的各一张牌",
  ["#ty__fengshih_delay"] = "锋势",

  ["$ty__fengshih1"] = "锋芒之锐，势不可挡！",
  ["$ty__fengshih2"] = "势须砥砺，就其锋芒。",
  ["~ty__mifangfushiren"] = "愧对将军。",
}

local licaiwei = General(extension, "licaiwei", "qun", 3, 3, General.Female)
local yijiao = fk.CreateActiveSkill{
  name = "yijiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 4,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("yijiao1") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    if not self.interaction.data then self.interaction.data = 1 end  --for AI
    room:addPlayerMark(target, "yijiao1", 10 * self.interaction.data)
    room:setPlayerMark(target, "@yijiao", target:getMark("yijiao1"))
    room:setPlayerMark(target, "yijiao_src", effect.from)
  end,
}
local yijiao_record = fk.CreateTriggerSkill{
  name = "#yijiao_record",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and target:getMark("yijiao_src") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("yijiao2") - target:getMark("yijiao1")
    room:doIndicate(player.id, {target.id})
    if n < 0 then
      player:broadcastSkillInvoke("yijiao", 1)
      room:notifySkillInvoked(player, "yijiao", "control")
      if not target:isKongcheng() then
        local cards = table.filter(target.player_cards[Player.Hand], function (id)
          return not target:prohibitDiscard(Fk:getCardById(id))
        end)
        if #cards > 0 then
          local x = math.random(1, math.min(3, #cards))
          if x < #cards then
            cards = table.random(cards, x)
          end
          room:throwCard(cards, "yijiao", target, target)
        end
      end
    elseif n == 0 then
      player:broadcastSkillInvoke("yijiao", 2)
      room:notifySkillInvoked(player, "yijiao", "support")
      player:drawCards(2, "yijiao")
      target:gainAnExtraTurn(true)
    else
      player:broadcastSkillInvoke("yijiao", 2)
      room:notifySkillInvoked(player, "yijiao", "drawcard")
      player:drawCards(3, "yijiao")
    end
  end,

  refresh_events = {fk.CardUsing, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and player:getMark("yijiao1") ~= 0 and player.phase ~= Player.NotActive and data.card.number > 0
    elseif event == fk.AfterTurnEnd then
      return target == player and player:getMark("yijiao1") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "yijiao2", data.card.number)
      room:setPlayerMark(player, "@yijiao", string.format("%d/%d", target:getMark("yijiao1"), target:getMark("yijiao2")))
    elseif event == fk.AfterTurnEnd then
      room:setPlayerMark(player, "yijiao1", 0)
      room:setPlayerMark(player, "yijiao2", 0)
      room:setPlayerMark(player, "@yijiao", 0)
      room:setPlayerMark(player, "yijiao_src", 0)
    end
  end,
}
local qibie = fk.CreateTriggerSkill{
  name = "qibie",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qibie-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum()
    player:throwAllCards("h")
    if player.dead then return end
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    player:drawCards(n + 1, self.name)
  end,
}
yijiao:addRelatedSkill(yijiao_record)
licaiwei:addSkill(yijiao)
licaiwei:addSkill(qibie)
Fk:loadTranslationTable{
  ["licaiwei"] = "李采薇",
  ["#licaiwei"] = "啼雨孤鸯",
  ["illustrator:licaiwei"] = "Jzeo",
  ["yijiao"] = "异教",
  [":yijiao"] = "出牌阶段限一次，你可以选择一名其他角色并选择一个1~4的数字，该角色获得十倍的“异”标记；"..
  "有“异”标记的角色结束阶段，若其本回合使用牌的点数之和：<br>"..
  "1.小于“异”标记数，其随机弃置一至三张手牌；<br>"..
  "2.等于“异”标记数，你摸两张牌且其于本回合结束后进行一个额外的回合；<br>"..
  "3.大于“异”标记数，你摸三张牌。",
  ["qibie"] = "泣别",
  [":qibie"] = "一名角色死亡后，你可以弃置所有手牌，然后回复1点体力值并摸X+1张牌（X为你以此法弃置牌数）。",
  ["@yijiao"] = "异",
  ["#yijiao_record"] = "异教",
  ["#qibie-invoke"] = "泣别：你可以弃置所有手牌，回复1点体力值并摸弃牌数+1张牌",

  ["$yijiao1"] = "攻乎异教，斯害也已。",
  ["$yijiao2"] = "非我同盟，其心必异。",
  ["$qibie1"] = "忽闻君别，泣下沾襟。",
  ["$qibie2"] = "相与泣别，承其遗志。",
  ["~licaiwei"] = "随君而去……",
}

local zhaoyan = General(extension, "ty__zhaoyan", "wei", 3)
local funing = fk.CreateTriggerSkill{
  name = "funing",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#funing-invoke:::"..player:usedSkillTimes(self.name, Player.HistoryTurn) + 1)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    player.room:askForDiscard(player, n, n, true, self.name, false)
  end,
}
local bingji = fk.CreateActiveSkill{
  name = "bingji",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#bingji",
  can_use = function(self, player)
    if not player:isKongcheng() then
      local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString(true)
      return not table.contains(U.getMark(player, "@bingji-phase"), suit)
      and table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getSuitString(true) == suit end)
    end
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local mark = U.getMark(player, "@bingji-phase")
    local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString(true)
    table.insert(mark, suit)
    room:setPlayerMark(player, "@bingji-phase", mark)
    player:showCards(player.player_cards[Player.Hand])
    local targets = {["peach"] = {}, ["slash"] = {}}
    local choices = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true}) then
        table.insert(targets["slash"], p.id)
      end
      local peach = Fk:cloneCard("peach")
      if not player:prohibitUse(peach) and not player:isProhibited(p, peach) and p:isWounded() then
        table.insert(targets["peach"], p.id)
      end
    end
    if #targets["peach"] > 0 then table.insert(choices, "peach") end
    if #targets["slash"] > 0 then table.insert(choices, "slash") end
    if #choices == 0 then return end
    local choice = room:askForChoice(player, choices, self.name, "#bingji-choice", false, {"slash", "peach"})
    local tos = room:askForChoosePlayers(player, targets[choice], 1, 1, "#bingji-choose:::"..choice, self.name, false)
    local to = room:getPlayerById(tos[1])
    room:useVirtualCard(choice, nil, player, to, self.name, true)
  end
}
zhaoyan:addSkill(funing)
zhaoyan:addSkill(bingji)
Fk:loadTranslationTable{
  ["ty__zhaoyan"] = "赵俨",
  ["#ty__zhaoyan"] = "扬历干功",
  ["cv:ty__zhaoyan"] = "冰霜墨菊",
  ["illustrator:ty__zhaoyan"] = "游漫美绘",

  ["funing"] = "抚宁",
  [":funing"] = "当你使用一张牌时，你可以摸两张牌然后弃置X张牌（X为此技能本回合发动次数）。",
  ["bingji"] = "秉纪",
  [":bingji"] = "出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】（有距离限制且不计入次数）或一张【桃】。",
  ["#funing-invoke"] = "抚宁：你可以摸两张牌，然后弃置%arg张牌",
  ["@bingji-phase"] = "秉纪",
  ["#bingji-choice"] = "秉纪：选择对其他角色使用的牌名",
  ["#bingji-choose"] = "秉纪：视为对一名其他角色使用【%arg】",
  ["#bingji"] = "秉纪：展示所有手牌，视为对一名其他角色使用【杀】或【桃】",

  ["$funing1"] = "为国效力，不可逞一时之气。",
  ["$funing2"] = "诸将和睦，方为国家之幸。",
  ["$bingji1"] = "权其轻重，而后施令。",
  ["$bingji2"] = "罪而后赦，以立恩威。",
  ["~ty__zhaoyan"] = "背信食言，当有此劫……",
}

local wangwei = General(extension, "wangwei", "qun", 4)
local ruizhan = fk.CreateTriggerSkill{
  name = "ruizhan",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Start and target:getHandcardNum() >= target.hp and
      not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ruizhan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    if target.dead or player:isProhibited(target, Fk:cloneCard("slash")) then return end
    if pindian.results[target.id].winner == player or
      pindian.fromCard.trueName == "slash" or pindian.results[target.id].toCard.trueName == "slash" then
      local card = Fk:cloneCard("slash")
      card.skillName = self.name
      local use = {
        from = player.id,
        tos = {{target.id}},
        card = card,
      }
      room:useCard(use)
      if pindian.results[target.id].winner == player and
        (pindian.fromCard.trueName == "slash" or pindian.results[target.id].toCard.trueName == "slash")
        and use.damageDealt and use.damageDealt[target.id] and not player.dead and not target.dead and not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name, "#ruizhan-prey::"..target.id)
        room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end
}
local shilie = fk.CreateActiveSkill{
  name = "shilie",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  derived_piles = "shilie",
  prompt = function (self)
    return "#shilie-"..self.interaction.data
  end,
  interaction = function(self)
    return UI.ComboBox { choices = {"recover", "loseHp"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "recover" then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
      if not player:isNude() then
        local cards = room:askForCard(player, math.min(#player:getCardIds("he"), 2), 2, true, self.name, false, ".", "#shilie-put")
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        player:addToPile(self.name, dummy, false, self.name)
        local n = #player:getPile(self.name) - #room.players
        if n > 0 then
          local dummy2 = Fk:cloneCard("dilu")
          for i = 1, n, 1 do
            dummy2:addSubcard(player:getPile(self.name)[i])
          end
          room:moveCardTo(dummy2, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
        end
      end
    else
      room:loseHp(player, 1, self.name)
      if player.dead then return end
      local cards = room:askForCard(player, math.min(#player:getPile(self.name), 2), 2, false, self.name, false,
        ".|.|.|shilie", "#shilie-get", self.name)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
    end
  end,
}
local shilie_trigger = fk.CreateTriggerSkill{
  name = "#shilie_trigger",
  mute = true,
  main_skill = shilie,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true) and #player:getPile("shilie") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    if data.damage and data.damage.from then
      table.removeOne(targets, data.damage.from.id)
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#shilie-choose", "shilie", true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shilie")
    room:notifySkillInvoked(player, "shilie", "support")
    local to = room:getPlayerById(self.cost_data)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("shilie"))
    room:moveCardTo(dummy, Card.PlayerHand, to, fk.ReasonJustMove, "shilie", nil, false, player.id)
  end,
}
shilie:addRelatedSkill(shilie_trigger)
wangwei:addSkill(ruizhan)
wangwei:addSkill(shilie)
Fk:loadTranslationTable{
  ["wangwei"] = "王威",
  ["#wangwei"] = "苍心辟道",
  ["illustrator:wangwei"] = "荧光笔工作室",
  ["ruizhan"] = "锐战",
  [":ruizhan"] = "其他角色准备阶段，若其手牌数不小于体力值，你可以与其拼点：若你赢或者拼点牌中有【杀】，你视为对其使用一张【杀】；"..
  "若两项均满足且此【杀】造成伤害，你获得其一张牌。",
  ["shilie"] = "示烈",
  [":shilie"] = "出牌阶段限一次，你可以选择一项：1.回复1点体力，然后将两张牌置为“示烈”牌（不足则全放，总数不能大于游戏人数）；"..
  "2.失去1点体力，然后获得两张“示烈”牌。<br>你死亡时，你可将“示烈”牌交给除伤害来源外的一名其他角色。",
  ["#ruizhan-invoke"] = "锐战：你可与 %dest 拼点，若赢或拼点牌中有【杀】，视为对其使用【杀】",
  ["#ruizhan-prey"] = "锐战：获得 %dest 一张牌",
  ["#shilie-recover"] = "示烈：回复1点体力，将两张牌置为“示烈”牌",
  ["#shilie-loseHp"] = "示烈：失去1点体力，获得两张牌“示烈”牌",
  ["#shilie-put"] = "示烈：将两张牌置为“示烈”牌",
  ["#shilie-get"] = "示烈：获得两张“示烈”牌",
  ["#shilie-choose"] = "示烈：你可以将所有“示烈”牌交给一名角色",

  ["$ruizhan1"] = "敌势汹汹，当急攻以挫其锐。",
  ["$ruizhan2"] = "威愿领骑兵千人，以破敌前军。",
  ["$shilie1"] = "荆州七郡，亦有怀义之人！",
  ["$shilie2"] = "食禄半生，安能弃旧主而去！",
  ["~wangwei"] = "后有追兵，主公先行！",
}

local liyixiejing = General(extension, "liyixiejing", "wu", 4)
local douzhen = fk.CreateFilterSkill{
  name = "douzhen",
  anim_type = "switch",
  switch_skill_name = "douzhen",
  card_filter = function(self, card, player)
    if player:hasSkill(self) and player.phase ~= Player.NotActive and card.type == Card.TypeBasic and
    table.contains(player.player_cards[Player.Hand], card.id) then
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        return card.color == Card.Black
      else
        return card.color == Card.Red
      end
    end
  end,
  view_as = function(self, card, player)
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return Fk:cloneCard("duel", card.suit, card.number)
    else
      return Fk:cloneCard("slash", card.suit, card.number)
    end
  end,
}
local douzhen_trigger = fk.CreateTriggerSkill{
  name = "#douzhen_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "douzhen") and data.tos and
      player:getSwitchSkillState("douzhen", true) == fk.SwitchYang and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return not player.room:getPlayerById(id):isNude() end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        local c = room:askForCardChosen(player, p, "he", "douzhen")
        room:obtainCard(player, c, false, fk.ReasonPrey)
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.PreCardRespond},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "douzhen")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, MarkEnum.SwithSkillPreName .. "douzhen", player:getSwitchSkillState("douzhen", true))
    player:addSkillUseHistory("douzhen")
  end,
}
local douzhen_targetmod = fk.CreateTargetModSkill{
  name = "#douzhen_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card.trueName == "slash" and table.contains(card.skillNames, "douzhen") and scope == Player.HistoryPhase then
      return 999
    end
  end,
}
douzhen:addRelatedSkill(douzhen_trigger)
douzhen:addRelatedSkill(douzhen_targetmod)
liyixiejing:addSkill(douzhen)
Fk:loadTranslationTable{
  ["liyixiejing"] = "李异谢旌",
  ["#liyixiejing"] = "踵蹑袭进",
  ["illustrator:liyixiejing"] = "匠人绘",
  ["douzhen"] = "斗阵",
  [":douzhen"] = "转换技，锁定技，你的回合内，阳：你的黑色基本牌视为【决斗】，且使用时获得目标一张牌；阴：你的红色基本牌视为【杀】，且使用时无次数限制。",

  ["$douzhen1"] = "擂鼓击柝，庆我兄弟凯旋。",
  ["$douzhen2"] = "匹夫欺我江东无人乎。",
  ["~liyixiejing"] = "蜀军凶猛，虽力战犹不敌……",
}

local sunhuan = General(extension, "sunhuan", "wu", 4)
local niji = fk.CreateTriggerSkill{
  name = "niji",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip
    elseif event == fk.EventPhaseStart then
      return target.phase == Player.Finish and not player:isKongcheng() and
        table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return player.room:askForSkillInvoke(player, self.name, nil, "#niji-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      local id = player:drawCards(1, self.name)[1]
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        room:setCardMark(Fk:getCardById(id), "@@niji-inhand", 1)
      end
    else
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
      if player:hasSkill(self) then
        U.askForUseRealCard(room, player, cards, ".", self.name, "#niji-use")
      end
      if not player.dead then
        room:delay(800)
        cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
        room:throwCard(cards, self.name, player, player)
      end
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      player.room:setCardMark(Fk:getCardById(id), "@@niji-inhand", 0)
    end
  end,
}
sunhuan:addSkill(niji)
Fk:loadTranslationTable{
  ["sunhuan"] = "孙桓",
  ["#sunhuan"] = "扼龙决险",
  ["designer:sunhuan"] = "坑坑",
  ["illustrator:sunhuan"] = "一意动漫",

  ["niji"] = "逆击",
  [":niji"] = "当你成为非装备牌的目标后，你可以摸一张牌，本回合结束阶段弃置这些牌，弃置前你可以先使用其中一张牌。",
  ["@@niji-inhand"] = "逆击",
  ["#niji-invoke"] = "逆击：你可以摸一张牌，本回合结束阶段弃置之",
  ["#niji-use"] = "逆击：即将弃置所有“逆击”牌，你可以先使用其中一张牌",
  
  ["$niji1"] = "善战者后动，一击而毙敌。",
  ["$niji2"] = "我所善者，后发制人尔。",
  ["~sunhuan"] = "此建功立业之时，奈何……",
}

local mengda = General(extension, "ty__mengda", "wei", 4)
mengda.subkingdom = "shu"
local libang = fk.CreateActiveSkill{
  name = "libang",
  anim_type = "control",
  card_num = 1,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    room:sortPlayersByAction(effect.tos, false)
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    local id1 = room:askForCardChosen(player, target1, "he", self.name)
    local id2 = room:askForCardChosen(player, target2, "he", self.name)
    room:obtainCard(player.id, id1, true, fk.ReasonPrey)
    room:obtainCard(player.id, id2, true, fk.ReasonPrey)
    player:showCards({id1, id2})
    local pattern = "."
    if Fk:getCardById(id1, true).color == Fk:getCardById(id2, true).color then
      if Fk:getCardById(id1, true).color == Card.Black then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
    end
    local judge = {
      who = player,
      reason = self.name,
      pattern = pattern,
      extra_data = {effect.tos, {id1, id2}},
    }
    room:judge(judge)
  end,
}
local libang_delay = fk.CreateTriggerSkill{
  name = "#libang_delay",
  mute = true,
  events = {fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == "libang" and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.NoColor then return end
    local targets = data.extra_data[1]
    for i = 2, 1, -1 do
      if room:getPlayerById(targets[i]).dead then
        table.removeOne(targets, targets[i])
      end
    end
    if data.card.color ~= Fk:getCardById(data.extra_data[2][1], true).color and
      data.card.color ~= Fk:getCardById(data.extra_data[2][2], true).color then
      if #targets == 0 or #player:getCardIds{Player.Hand, Player.Equip} < 2 then
        room:loseHp(player, 1, "libang")
      else
        local _,dat = room:askForUseActiveSkill(player, "libang_active", "#libang-card", true, {targets = targets})
        if dat then
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(dat.cards)
          room:obtainCard(dat.targets[1], dummy, false, fk.ReasonGive, player.id)
        else
          room:loseHp(player, 1, "libang")
        end
      end
    else
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      targets = table.filter(targets, function(id) return not player:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#libang-slash", "libang", false)
      room:useVirtualCard("slash", nil, player, room:getPlayerById(tos[1]), "libang")
    end
  end,
}
local libang_active = fk.CreateActiveSkill{
  name = "libang_active",
  card_num = 2,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(self.targets, to_select) and #selected_cards == 2
  end,
}
local wujie = fk.CreateTriggerSkill{
  name = "wujie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared, fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.AfterCardUseDeclared then
        return player:hasSkill(self) and data.card.color == Card.NoColor
      else
        return player:hasSkill(self, false, true) and not player.room:getTag("SkipNormalDeathProcess")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      if not data.extraUse then
        data.extraUse = true
        player:addCardUseHistory(data.card.trueName, -1)
      end
    else
      player.room:setTag("SkipNormalDeathProcess", true)
      player.room:setTag(self.name, true)
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setTag("SkipNormalDeathProcess", false)
    player.room:setTag(self.name, false)
  end,
}
local wujie_targetmod = fk.CreateTargetModSkill{
  name = "#wujie_targetmod",
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(wujie) and card and card.color == Card.NoColor
  end,
}
Fk:addSkill(libang_active)
libang:addRelatedSkill(libang_delay)
wujie:addRelatedSkill(wujie_targetmod)
mengda:addSkill(libang)
mengda:addSkill(wujie)
Fk:loadTranslationTable{
  ["ty__mengda"] = "孟达",
  ["#ty__mengda"] = "据国向己",
  ["designer:ty__mengda"] = "傍晚的水豚巴士",
  ["illustrator:ty__mengda"] = "六道目",
  ["libang"] = "利傍",
  [":libang"] = "出牌阶段限一次，你可以弃置一张牌，获得两名其他角色各一张牌并展示，然后你判定，若结果与这两张牌的颜色："..
  "均不同，你交给其中一名角色两张牌或失去1点体力；至少一张相同，你获得判定牌并视为对其中一名角色使用一张【杀】。",
  ["wujie"] = "无节",
  [":wujie"] = "锁定技，你使用的无色牌不计入次数且无距离限制；其他角色杀死你后不执行奖惩。",
  ["#libang-card"] = "利傍：交给其中一名角色两张牌，否则失去1点体力",
  ["#libang-slash"] = "利傍：视为对其中一名角色使用一张【杀】",
  ["libang_active"] = "利傍",
  ["#libang_delay"] = "利傍",

  ["$libang1"] = "天下熙攘，所为者利尔。",
  ["$libang2"] = "我有武力傍身，必可待价而沽。",
  ["$wujie1"] = "腹中有粮则脊自直，非节盈之。",
  ["$wujie2"] = "气节？可当粟米果腹乎！",
  ["~ty__mengda"] = "司马老贼害我，诸葛老贼误我……",
}

local shiyi = General(extension, "shiyi", "wu", 3)
local cuichuan = fk.CreateActiveSkill{
  name = "cuichuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      for _, type in ipairs(types) do
        if card.sub_type == type and target:getEquipment(type) == nil then
          table.insertIfNeed(cards, room.draw_pile[i])
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo({table.random(cards)}, Player.Equip, target, fk.ReasonJustMove, self.name)
    end
    local n = #target.player_cards[Player.Equip]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    if #cards > 0 and n > 3 then
      room:handleAddLoseSkills(player, "-cuichuan|zuojian", nil, true, false)
      target:gainAnExtraTurn(true)
    end
  end,
}
local zhengxu = fk.CreateTriggerSkill{
  name = "zhengxu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("zhengxu1-turn") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu1-invoke")
  end,
  on_use = Util.TrueFunc,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 1)
  end,
}
local zhengxu_trigger = fk.CreateTriggerSkill{
  name = "#zhengxu_trigger",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getMark("zhengxu2-turn") > 0 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      self.cost_data = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              self.cost_data = self.cost_data + 1
            end
          end
        end
      end
      return self.cost_data > 0
    end
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu2-invoke:::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 1)
  end,
}
local zuojian = fk.CreateTriggerSkill{
  name = "zuojian",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("zuojian-phase") >= player.hp and
      (#table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end) > 0 or
      #table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local targets1 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end)
    local targets2 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end)
    if #targets1 > 0 then
      table.insert(choices, "zuojian1")
    end
    if #targets2 > 0 then
      table.insert(choices, "zuojian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zuojian1" then
      room:doIndicate(player.id, table.map(targets1, Util.IdMapper))
      for _, p in ipairs(targets1) do
        p:drawCards(1, self.name)
      end
    end
    if choice == "zuojian2" then
      room:doIndicate(player.id, table.map(targets2, Util.IdMapper))
      for _, p in ipairs(targets2) do
        local id = room:askForCardChosen(player, p, "h", self.name)
        room:throwCard({id}, self.name, p, player)
      end
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play then
      if event == fk.CardUsing then
        return target == player
      else
        return data == self and player.room:getTag("RoundCount")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "zuojian-phase", 1)
      if player:hasSkill(self, true) then
        room:addPlayerMark(player, "@zuojian-phase", 1)
      end
    else
      local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryPhase)
      room:addPlayerMark(player, "zuojian-phase", #events)
      room:addPlayerMark(player, "@zuojian-phase", #events)
    end
  end,
}
zhengxu:addRelatedSkill(zhengxu_trigger)
shiyi:addSkill(cuichuan)
shiyi:addSkill(zhengxu)
shiyi:addRelatedSkill(zuojian)
Fk:loadTranslationTable{
  ["shiyi"] = "是仪",
  ["#shiyi"] = "清恪贞佐",
  ["designer:shiyi"] = "神壕",
  ["illustrator:shiyi"] = "福州乐战",

  ["cuichuan"] = "榱椽",
  [":cuichuan"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名角色，从牌堆中将一张随机装备牌置入其装备区空位，你摸X张牌（X为其装备区牌数）。"..
  "若其装备区内的牌因此达到4张或以上，你失去〖榱椽〗并获得〖佐谏〗，然后令其在此回合结束后获得一个额外回合。",
  ["zhengxu"] = "正序",
  [":zhengxu"] = "每回合各限一次，当你失去牌后，你本回合下一次受到伤害时，你可以防止此伤害；当你受到伤害后，你本回合下一次失去牌后，你可以摸等量的牌。",
  ["zuojian"] = "佐谏",
  [":zuojian"] = "出牌阶段结束时，若你此阶段使用的牌数大于等于你的体力值，你可以选择一项：1.令装备区牌数大于你的角色摸一张牌；"..
  "2.弃置装备区牌数小于你的每名角色各一张手牌。",
  ["#zhengxu_trigger"] = "正序",
  ["#zhengxu1-invoke"] = "正序：你可以防止你受到的伤害",
  ["#zhengxu2-invoke"] = "正序：你可以摸%arg张牌",
  ["@zuojian-phase"] = "佐谏",
  ["zuojian1"] = "装备区牌数大于你的角色各摸一张牌",
  ["zuojian2"] = "你弃置装备区牌数小于你的角色各一张手牌",

  ["$cuichuan1"] = "老臣在，必不使吴垒倾颓。",
  ["$cuichuan2"] = "舍老朽之躯，擎广厦之柱。",
  ["$zhengxu1"] = "陛下怜子无序，此取祸之道。",
  ["$zhengxu2"] = "古语有云，上尊而下卑。",
  ["$zuojian1"] = "关羽者，刘备之枭将，宜除之。",
  ["$zuojian2"] = "主公虽非赵简子，然某可为周舍。",
  ["~shiyi"] = "吾故后，务从省约……",
}

local sunlang = General(extension, "sunlang", "shu", 4)
local tingxian = fk.CreateTriggerSkill{
  name = "tingxian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    return player.room:askForSkillInvoke(player, self.name, nil, "#tingxian-invoke:::"..n)
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    player:drawCards(n, self.name)
    local targets = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, n, "#tingxian-choose:::"..n, self.name, true)
    if #targets > 0 then
      table.insertTable(data.nullifiedTargets, targets)
    end
  end,
}
local benshi = fk.CreateTriggerSkill{
  name = "benshi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = TargetGroup:getRealTargets(data.tos)
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) and not table.contains(targets, p.id) and
      not player:isProhibited(p, data.card) then
        room:doIndicate(player.id, {p.id})
        TargetGroup:pushTargets(data.tos, p.id)
      end
    end
  end,
}
local benshi_attackrange = fk.CreateAttackRangeSkill{
  name = "#benshi_attackrange",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    if from:hasSkill(self) then
      local fix = 1
      if from:getEquipment(Card.SubtypeWeapon) then
        fix = fix + 1 - Fk:getCardById(from:getEquipment(Card.SubtypeWeapon)).attack_range
      end
      return fix
    end
    return 0
  end,
}
benshi:addRelatedSkill(benshi_attackrange)
sunlang:addSkill(tingxian)
sunlang:addSkill(benshi)
Fk:loadTranslationTable{
  ["sunlang"] = "孙狼",
  ["#sunlang"] = "恶惮远役",
  ["illustrator:sunlang"] = "六道目",
  ["tingxian"] = "铤险",
  [":tingxian"] = "每回合限一次，你使用【杀】指定目标后，你可以摸X张牌，然后令此【杀】对其中至多X个目标无效（X为你装备区的牌数+1）。",
  ["benshi"] = "奔矢",
  [":benshi"] = "锁定技，你装备区内的武器牌不提供攻击范围，你的攻击范围+1，你使用【杀】须指定攻击范围内所有角色为目标。",
  ["#tingxian-invoke"] = "铤险：你可以摸%arg张牌，然后可以令此【杀】对至多等量的目标无效",
  ["#tingxian-choose"] = "铤险：你可以令此【杀】对至多%arg名目标无效",

  ["$tingxian1"] = "大争之世，当举兵行义。",
  ["$tingxian2"] = "聚兵三千众，可为天下先。",
  ["$benshi1"] = "今，或为鱼肉，或为刀俎。",
  ["$benshi2"] = "所征徭者必死，可先斩之。",
  ["~sunlang"] = "为关将军死，无憾……",
}

--千里单骑：关羽 杜夫人 秦宜禄 卞喜 胡班 胡金定 关宁
local guanyu = General(extension, "ty__guanyu", "wei", 4)
local ty__danji = fk.CreateTriggerSkill{
  name = "ty__danji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "mashu|nuchen", nil, true, false)
  end,
}
local nuchen = fk.CreateActiveSkill{
  name = "nuchen",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id)
    local suit = Fk:getCardById(id):getSuitString()
    if suit == "nosuit" then return end
    local cards = room:askForDiscard(player, 1, 999, true, self.name, true, ".|.|"..suit, "#nuchen-card::"..target.id..":"..suit)
    if #cards > 0 then
      room:damage{
        from = player,
        to = target,
        damage = #cards,
        skillName = self.name,
      }
    else
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(target.player_cards[Player.Hand]) do
        if Fk:getCardById(id):getSuitString() == suit then
          dummy:addSubcard(id)
        end
      end
      room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    end
  end,
}
guanyu:addSkill("ex__wusheng")
guanyu:addSkill(ty__danji)
guanyu:addRelatedSkill(nuchen)
Fk:loadTranslationTable{
  ["ty__guanyu"] = "关羽",
  ["#ty__guanyu"] = "汉寿亭侯",
  ["illustrator:ty__guanyu"] = "写之火工作室",
  ["ty__wusheng"] = "武圣",
  [":ty__wusheng"] = "你可以将一张红色牌当【杀】使用或打出；你使用<font color='red'>♦</font>【杀】无距离限制。",
  ["ty__danji"] = "单骑",
  [":ty__danji"] = "觉醒技，准备阶段，若你的手牌数大于体力值，你减1点体力上限，回复体力至体力上限，然后获得〖马术〗和〖怒嗔〗。",
  ["nuchen"] = "怒嗔",
  [":nuchen"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你选择一项：1.弃置任意张相同花色的牌，对其造成等量的伤害；"..
  "2.获得其手牌中所有此花色的牌。",
  ["#nuchen-card"] = "怒嗔：你可以弃置任意张%arg牌对 %dest 造成等量伤害，或获得其全部此花色手牌",

  ["$ex__wusheng_ty__guanyu1"] = "以义传魂，以武入圣！",
  ["$ex__wusheng_ty__guanyu2"] = "义击逆流，武安黎庶。",
  ["$ty__danji1"] = "单骑护嫂千里，只为桃园之义！	",
  ["$ty__danji2"] = "独身远涉，赤心归国！",
  ["$nuchen1"] = "触关某之逆鳞者，杀无赦！",
  ["$nuchen2"] = "天下碌碌之辈，安敢小觑关某？！",
  ["~ty__guanyu"] = "樊城一去，死亦无惧……",
}

local dufuren = General(extension, "dufuren", "wei", 3, 3, General.Female)
local yise = fk.CreateTriggerSkill{
  name = "yise",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id
        and not room:getPlayerById(move.to).dead and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color ~= Card.NoColor then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local list = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and not room:getPlayerById(move.to).dead and
      move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color ~= Card.NoColor then
            list[move.to] = list[move.to] or {}
            table.insertIfNeed(list[move.to], Fk:getCardById(info.cardId).color)
          end
        end
      end
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if not player:hasSkill(self) then break end
      if not p.dead and list[p.id] then
        self:doCost(event, p, player, list[p.id])
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if table.contains(data, Card.Red) and (not target:isWounded() or
    not player.room:askForSkillInvoke(player, self.name, nil, "#yise-invoke::"..target.id)) then
      table.removeOne(data, Card.Red)
    end
    return #data > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.contains(data, Card.Red) then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if table.contains(data, Card.Black) and not target.dead then
      room:addPlayerMark(target, "@yise", 1)
    end
  end,
}
local yise_delay = fk.CreateTriggerSkill{
  name = "#yise_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yise") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@yise")
    player.room:setPlayerMark(player, "@yise", 0)
  end,
}
local shunshi = fk.CreateTriggerSkill{
  name = "shunshi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and not player:isNude() then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return player ~= player.room.current
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if event == fk.EventPhaseStart or (event == fk.Damaged and p ~= data.from) then
        table.insert(targets, p.id)
      end
    end
    local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".", "#shunshi-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(self.cost_data[2], Card.PlayerHand, room:getPlayerById(self.cost_data[1]), fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead then return end
    room:addPlayerMark(player, "@shunshi", 1)
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@shunshi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@shunshi", 0)
  end,
}
local shunshi_delay = fk.CreateTriggerSkill{
  name = "#shunshi_delay",
  mute = true,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@shunshi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@shunshi")
  end,
}
local shunshi_targetmod = fk.CreateTargetModSkill{
  name = "#shunshi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@shunshi")
    end
  end,
}
local shunshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#shunshi_maxcards",
  correct_func = function(self, player)
    return player:getMark("@shunshi")
  end,
}
yise:addRelatedSkill(yise_delay)
shunshi:addRelatedSkill(shunshi_delay)
shunshi:addRelatedSkill(shunshi_targetmod)
shunshi:addRelatedSkill(shunshi_maxcards)
dufuren:addSkill(yise)
dufuren:addSkill(shunshi)
Fk:loadTranslationTable{
  ["dufuren"] = "杜夫人",
  ["#dufuren"] = "沛王太妃",
  ["designer:dufuren"] = "步穗",
  ["illustrator:dufuren"] = "匠人绘",
  ["yise"] = "异色",
  [":yise"] = "当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。",
  ["shunshi"] = "顺世",
  [":shunshi"] = "准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你：摸牌阶段多摸一张牌、"..
  "出牌阶段使用的【杀】次数上限+1、手牌上限+1。",
  ["#yise-invoke"] = "异色：你可以令 %dest 回复1点体力",
  ["#shunshi-cost"] = "顺世：你可以交给一名其他角色一张牌，然后直到你的回合结束获得效果",
  ["#yise_delay"] = "异色",
  ["#shunshi_delay"] = "顺世",
  ["@yise"] = "异色",
  ["@shunshi"] = "顺世",

  ["$yise1"] = "明丽端庄，双瞳剪水。",
  ["$yise2"] = "姿色天然，貌若桃李。",
  ["$shunshi1"] = "顺应时运，得保安康。",
  ["$shunshi2"] = "随遇而安，宠辱不惊。",
  ["~dufuren"] = "往事云烟，去日苦多。",
}

local qinyilu = General(extension, "qinyilu", "qun", 3)
local piaoping = fk.CreateTriggerSkill{
  name = "piaoping",
  anim_type = "switch",
  switch_skill_name = "piaoping",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("piaoping_invalid-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player:usedSkillTimes(self.name, Player.HistoryTurn), player.hp)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(n, self.name)
    else
      room:askForDiscard(player, n, n, true, self.name, false, ".", "#piaoping-discard:::"..n, false)
    end
  end,
}
local tuoxian = fk.CreateTriggerSkill{
  name = "tuoxian",
  anim_type = "spcial",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) < player:getMark(self.name) then
      for _, move in ipairs(data) do
        if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if player.room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper),
      1, 1, "#tuoxian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local dummy = Fk:cloneCard("dilu")
    for _, move in ipairs(data) do
      if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if room:getCardArea(info.cardId) == Card.DiscardPile then
            dummy:addSubcard(info.cardId)
          end
        end
      end
    end
    room:moveCardTo(dummy, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    local choices = {}
    local n = #dummy.subcards
    if not to.dead and #to:getCardIds("hej") >= n then
      table.insert(choices, "tuoxian1:::"..n)
    end
    if not player.dead then
      table.insert(choices, "tuoxian2:"..player.id)
    end
    local choice = room:askForChoice(to, choices, self.name, "#tuoxian-choice:"..player.id)
    if choice[8] == "1" then
      local cards = room:askForCardsChosen(to, to, n, n, "hej", self.name, "#tuoxian-discard:::"..n)
      room:throwCard(cards, self.name, to, to)
    else
      room:setPlayerMark(player, "piaoping_invalid-turn", 1)
    end
    return true
  end,
}
local zhuili = fk.CreateTriggerSkill{
  name = "zhuili",
  anim_type = "spcial",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.color == Card.Black and data.from ~= player.id and
      player:hasSkill("piaoping", true) and player:getMark("zhuili_invalid-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("piaoping", false) == fk.SwitchYang then
      room:addPlayerMark(player, "tuoxian", 1)
      room:setPlayerMark(player, "zhuili_invalid-turn", 1)
    else
      room:setPlayerMark(player, MarkEnum.SwithSkillPreName.."piaoping", fk.SwitchYang)
    end
  end,
}
qinyilu:addSkill(piaoping)
qinyilu:addSkill(tuoxian)
qinyilu:addSkill(zhuili)
Fk:loadTranslationTable{
  ["qinyilu"] = "秦宜禄",
  ["#qinyilu"] = "尘垢粃糠",
  ["designer:qinyilu"] = "追风少年",
  ["illustrator:qinyilu"] = "君桓文化",
  ["piaoping"] = "漂萍",
  [":piaoping"] = "锁定技，转换技，当你使用一张牌时，阳：你摸X张牌；阴：你弃置X张牌（X为本回合〖漂萍〗发动次数且至多为你当前体力值）。",
  ["tuoxian"] = "托献",
  [":tuoxian"] = "每局游戏限零次，当你因〖漂萍〗弃置的牌进入弃牌堆后，你可以改为将这些牌交给一名其他角色，然后其选择一项：1.其弃置其区域内等量的牌；"..
  "2.令〖漂萍〗本回合失效。",
  ["zhuili"] = "惴栗",
  [":zhuili"] = "锁定技，当你成为其他角色使用黑色牌的目标后，若此时〖漂萍〗状态为：阳，令〖托献〗可使用次数+1，然后此技能本回合失效；"..
  "阴，令〖漂萍〗状态转换为阳。",
  ["#piaoping-discard"] = "漂萍：请弃置%arg张牌",
  ["#tuoxian-choose"] = "托献：你可以将这些牌交给一名其他角色，其选择弃置等量牌或令你的〖漂萍〗失效",
  ["tuoxian1"] = "弃置你区域内%arg张牌",
  ["tuoxian2"] = "令 %src 本回合〖漂萍〗失效",
  ["#tuoxian-choice"] = "托献：%src 令你选择一项",
  ["#tuoxian-discard"] = "托献：弃置你区域内%arg张牌",

  ["$piaoping1"] = "奔波四处，前途未明。",
  ["$piaoping2"] = "辗转各地，功业难寻。",
  ["$tuoxian1"] = "一贵一贱，其情乃见。",
  ["$tuoxian2"] = "一死一生，乃知交情。",
  ["$zhuili1"] = "近况艰难，何不忧愁？",
  ["$zhuili2"] = "形势如此，惴惕难当。",
  ["~qinyilu"] = "我竟落得如此下场……",
}

local bianxi = General(extension, "bianxi", "wei", 4)
local dunxi = fk.CreateTriggerSkill{
  name = "dunxi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.is_damage_card and data.tos
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1, "#dunxi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), "@bianxi_dun", 1)
  end,
}
local dunxi_delay = fk.CreateTriggerSkill{
  name = "#dunxi_delay",
  anim_type = "negative",
  events = {fk.CardUsing, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      if player == target and player:getMark("@bianxi_dun") > 0 and
      (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and #TargetGroup:getRealTargets(data.tos) == 1 then
        for _, p in ipairs(player.room.alive_players) do
          if p.dying then
            return false
          end
        end
        return true
      end
    elseif event == fk.CardUseFinished then
      return not player.dead and data.extra_data and data.extra_data.dunxi_record and
        table.contains(data.extra_data.dunxi_record, player.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:removePlayerMark(player, "@bianxi_dun")
      local orig_to = data.tos[1]
      local targets = {}
      if #orig_to > 1 then
        --target_filter check, for collateral,diversion...
        local c_pid
        --FIXME：借刀需要补modTargetFilter，不给targetFilter传使用者真是离大谱，目前只能通过强制修改Self来实现
        local Notify_from = room:getPlayerById(data.from)
        Self = Notify_from
        for _, p in ipairs(room.alive_players) do
          if not player:isProhibited(p, data.card) and data.card.skill:modTargetFilter(p.id, {}, data.from, data.card, false) then
            local ho_spair_target = {}
            local ho_spair_check = true
            for i = 2, #orig_to, 1 do
              c_pid = orig_to[i]
              if not data.card.skill:targetFilter(c_pid, ho_spair_target, {}, data.card) then
                ho_spair_check = false
                break
              end
              table.insert(ho_spair_target, c_pid)
            end
            if ho_spair_check then
              table.insert(targets, p.id)
            end
          end
        end
      else
        for _, p in ipairs(room.alive_players) do
          if not player:isProhibited(p, data.card) and (data.card.sub_type == Card.SubtypeDelayedTrick or
          data.card.skill:modTargetFilter(p.id, {}, data.from, data.card, false)) then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local random_target = table.random(targets)
        if random_target == orig_to[1] then
          data.extra_data = data.extra_data or {}
          local dunxi_record = data.extra_data.dunxi_record or {}
          table.insert(dunxi_record, player.id)
          data.extra_data.dunxi_record = dunxi_record
        else
          orig_to[1] = random_target
          data.tos = {orig_to}
        end
      else
        data.tos = {}
      end
    elseif event == fk.CardUseFinished then
      room:loseHp(player, 1, self.name)
      if player.phase == Player.Play then
        player:endPlayPhase()
      end
    end
  end,
}
dunxi:addRelatedSkill(dunxi_delay)
bianxi:addSkill(dunxi)
Fk:loadTranslationTable{
  ["bianxi"] = "卞喜",
  ["#bianxi"] = "伏龛蛇影",
  ["illustrator:bianxi"] = "君桓文化",
  ["dunxi"] = "钝袭",
  [":dunxi"] = "当你使用伤害牌时，你可令其中一个目标获得1个“钝”标记。有“钝”标记的角色使用基本牌或锦囊牌时，"..
  "若目标数为1且没有处于濒死状态的角色，其移去一个“钝”，然后目标改为随机一名角色。"..
  "若随机的目标与原本目标相同，则其于此牌结算结束后失去1点体力并结束出牌阶段。",

  --濒死使用桃不会触发，引申为隐藏条件：没有处于濒死状态的角色
  --其实不对，濒死用酒会触发技能
  --有距离限制，延迟锦囊牌无使用目标的限制（兵粮寸断能不能指定远位存疑，只知道能转移给给自己），如果没有合法目标则会取消掉所有目标
  --借刀杀人的逻辑依旧采取对原目标的副目标使用【杀】（实测并非如此，但测试结果有限，无法总结规律）
  --实测结果：会随机到没有武器牌的角色，但是又存在能指定原目标的时候取消掉目标的情况
  --最接近实测结果的逻辑推测是：先随机选取一名其他角色，若能对原副目标出杀则转移目标，不能则取消目标
  --个人觉得不太好，故不采用

  ["#dunxi-choose"] = "钝袭：你可以令一名角色获得“钝”标记，其使用下一张牌目标改为随机角色",
  ["@bianxi_dun"] = "钝",
  ["#dunxi_delay"] = "钝袭",

  ["$dunxi1"] = "看锤！",
  ["$dunxi2"] = "且吃我一锤！",
  ["~bianxi"] = "以力破巧，难挡其锋……",
}

local huban = General(extension, "ty__huban", "wei", 4)
local chongyi = fk.CreateTriggerSkill{
  name = "chongyi",
  anim_type = "support",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0 then
      local tag = player.tag[self.name]
      if event == fk.CardUsing then
        return #tag == 1 and tag[1] == "slash"
      else
        local name = tag[#tag]
        player.tag[self.name] = {}
        return name == "slash"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if event == fk.CardUsing then
      prompt = "#chongyi-draw::"
    else
      prompt = "#chongyi-maxcards::"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      target:drawCards(2, self.name)
      room:addPlayerMark(target, "chongyi-turn", 1)
    else
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true) and target.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insert(player.tag[self.name], data.card.trueName)
  end,
}
local chongyi_targetmod = fk.CreateTargetModSkill{
  name = "#chongyi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("chongyi-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
chongyi:addRelatedSkill(chongyi_targetmod)
huban:addSkill(chongyi)
Fk:loadTranslationTable{
  ["ty__huban"] = "胡班",
  ["#ty__huban"] = "血火照路",
  ["illustrator:ty__huban"] = "君桓文化",
  ["chongyi"] = "崇义",
  [":chongyi"] = "一名角色出牌阶段内使用的第一张牌若为【杀】，你可令其摸两张牌且此阶段使用【杀】次数上限+1；一名角色出牌阶段结束时，"..
  "若其此阶段使用的最后一张牌为【杀】，你可令其本回合手牌上限+1。",
  ["#chongyi-draw"] = "崇义：你可以令 %dest 摸两张牌且此阶段使用【杀】次数上限+1",
  ["#chongyi-maxcards"] = "崇义：你可以令 %dest 本回合手牌上限+1",

  ["$chongyi1"] = "班虽卑微，亦知何为大义。",
  ["$chongyi2"] = "大义当头，且助君一臂之力。",
  ["~ty__huban"] = "行义而亡，虽死无憾。",
}

local hujinding = General(extension, "ty__hujinding", "shu", 3, 6, General.Female)
local deshi = fk.CreateTriggerSkill{
  name = "deshi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("slash", 1, "allPiles")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if not player.dead then
      room:changeMaxHp(player, -1)
    end
    return true
  end,
}
local ty__wuyuan = fk.CreateActiveSkill{
  name = "ty__wuyuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__wuyuan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
    if not target.dead then
      if card.color == Card.Red and target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      local n = card.name ~= "slash" and 2 or 1
      target:drawCards(n, self.name)
    end
  end,
}
hujinding:addSkill(deshi)
hujinding:addSkill(ty__wuyuan)
hujinding:addSkill("huaizi")
Fk:loadTranslationTable{
  ["ty__hujinding"] = "胡金定",
  ["#ty__hujinding"] = "怀子求怜",
  ["illustrator:ty__hujinding"] = "匠人绘",
  ["deshi"] = "德释",  --为了不被管宁拿到改了技能名，不愧是狗ch
  [":deshi"] = "锁定技，当你受到【杀】造成的伤害时，若你已受伤，你防止此伤害并获得一张【杀】，然后减1点体力上限。",
  ["ty__wuyuan"] = "武缘",
  [":ty__wuyuan"] = "出牌阶段限一次，你可以将一张【杀】交给一名其他角色，然后你回复1点体力并与其各摸一张牌；若此【杀】为：红色，其回复1点体力；"..
  "属性【杀】，其多摸一张牌。",
  ["#ty__wuyuan"] = "武缘：将一张【杀】交给一名角色，你回复1点体力并与其各摸一张牌",

  ["$deshi1"] = "你我素无仇怨，何故欺之太急。",
  ["$deshi2"] = "恃强凌弱，非大丈夫之所为。",
  ["$ty__wuyuan1"] = "生为关氏之妇，虽死亦不悔。",
  ["$ty__wuyuan2"] = "我夫关长生，乃盖世之英雄。",
  ["~ty__hujinding"] = "妾不畏死，唯畏君断情。",
}

local guannings = General(extension, "guannings", "shu", 3)
local xiuwen = fk.CreateTriggerSkill{
  name = "xiuwen",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not table.contains(U.getMark(player, self.name), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local mark = U.getMark(player, self.name)
    table.insert(mark, data.card.trueName)
    player.room:setPlayerMark(player, self.name, mark)
    player:drawCards(1, self.name)
  end,
}
local longsong = fk.CreateTriggerSkill{
  name = "longsong",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local tos, cid = player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper),
    1, 1, ".|.|heart,diamond", "#longsong-invoke", self.name, true)
    if cid then
      self.cost_data = {tos[1], cid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:moveCardTo(Fk:getCardById(self.cost_data[2]), Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead then return end
    local skills = {}
    for _, s in ipairs(to.player_skills) do  --实际是许劭技能池。这不加强没法玩
      if not (s.attached_equip or s.name[#s.name] == "&") and not player:hasSkill(s, true) and s.frequency < 4 then
        if s:isInstanceOf(ActiveSkill) or s:isInstanceOf(ViewAsSkill) then
          table.insertIfNeed(skills, s.name)
        elseif s:isInstanceOf(TriggerSkill) then
          local str = Fk:translate(":"..s.name)
          if string.sub(str, 1, 12) == "出牌阶段" and string.sub(str, 13, 15) ~= "开始" and string.sub(str, 13, 15) ~= "结束" then
            table.insertIfNeed(skills, s.name)
          end
        end
      end
    end
    if #skills > 0 then
      room:setPlayerMark(player, "longsong-phase", skills)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
      end)
    end
  end,
}
local longsong_invalidity = fk.CreateInvaliditySkill {
  name = "#longsong_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("longsong-phase") ~= 0 and table.contains(from:getMark("longsong-phase"), skill.name) and
      from:usedSkillTimes(skill.name, Player.HistoryPhase) > 0
  end
}
longsong:addRelatedSkill(longsong_invalidity)
guannings:addSkill(xiuwen)
guannings:addSkill(longsong)
Fk:loadTranslationTable{
  ["guannings"] = "关宁",
  ["#guannings"] = "承义秉文",
  ["designer:guannings"] = "韩旭",
  ["illustrator:guannings"] = "黯荧岛工作室",
  ["xiuwen"] = "修文",
  [":xiuwen"] = "你使用一张牌时，若此牌名是你本局游戏第一次使用，你摸一张牌。",
  ["longsong"] = "龙诵",
  [":longsong"] = "出牌阶段开始时，你可以交给一名其他角色一张红色牌，然后你此阶段获得其拥有的“出牌阶段”的技能（每回合限发动一次）。<br>"..
  "<font color='grey'>可以获得的技能包括：<br>非限定技的转化技、主动技，和技能描述前四个字为“出牌阶段”且五~六字不为“开始”和“结束”的触发技<br/>",
  ["#longsong-invoke"] = "龙诵：你可以交给一名其他角色一张红色牌，本阶段获得其拥有的“出牌阶段”技能",
  ["longsong_active"] = "龙诵",

  ["$xiuwen1"] = "书生笔下三尺剑，毫锋可杀人。",
  ["$xiuwen2"] = "吾以书执剑，可斩世间魍魉。",
  ["$longsong1"] = "百家诸子，且听九霄龙吟。",
  ["$longsong2"] = "朗朗书声，岂虚于刀斧铮鸣。",
  ["~guannings"] = "为国捐生，虽死无憾……",
}

--烽火连天：南华老仙 童渊 张宁 庞德公
local nanhualaoxian = General(extension, "ty__nanhualaoxian", "qun", 4)
local gongxiu = fk.CreateTriggerSkill{
  name = "gongxiu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      player:usedSkillTimes("jinghe", Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel"}
    local all_choices = {"gongxiu_draw", "gongxiu_discard", "Cancel"}
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe-turn") == 0 and not p:isKongcheng() end) then
      table.insert(choices, "gongxiu_discard")
    end
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe-turn") ~= 0 end) then
      table.insert(choices, "gongxiu_draw")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#gongxiu-invoke", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[10] == "r" then
      for _, p in ipairs(room.alive_players) do
        if p:getMark("jinghe-turn") ~= 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          p:drawCards(1, self.name)
        end
      end
    else
      for _, p in ipairs(room.alive_players) do
        if p:getMark("jinghe-turn") == 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          if not p:isKongcheng() then
            room:askForDiscard(p, 1, 1, false, self.name, false)
          end
        end
      end
    end
  end,
}
local jinghe = fk.CreateActiveSkill{
  name = "jinghe",
  anim_type = "support",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#jinghe",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if #selected < 4 and Fk:currentRoom():getCardArea(to_select) == Player.Hand then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id) return Fk:getCardById(to_select).trueName ~= Fk:getCardById(id).trueName end)
      end
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < #selected_cards
  end,
  feasible = function (self, selected, selected_cards)
    return #selected > 0 and #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local mark = U.getMark(player, "jinghe_data")
    player:showCards(effect.cards)
    local skills = table.random(
      {"ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao", "guanyue", "yanzhengn",
      "ex__biyue", "ex__tuxi", "mingce", "zhiyan"
    }, 4)
    local selected = {}
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = table.filter(skills, function(s) return not p:hasSkill(s, true) and not table.contains(selected, s) end)
        if #choices > 0 then
          local choice = room:askForChoice(p, choices, self.name, "#jinghe-choice", true, skills)
          table.insert(selected, choice)
          room:handleAddLoseSkills(p, choice, nil, true, false)
          table.insert(mark, {p.id, choice})
          room:setPlayerMark(p, "jinghe-turn", 1)
        end
      end
    end
    room:setPlayerMark(player, "jinghe_data", mark)
  end,
}
local jinghe_trigger = fk.CreateTriggerSkill {
  name = "#jinghe_trigger",
  mute = true,
  events = {fk.TurnStart, fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("jinghe_data") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("jinghe_data")
    room:setPlayerMark(player, "jinghe_data", 0)
    for _, dat in ipairs(mark) do
      local p = room:getPlayerById(dat[1])
      room:handleAddLoseSkills(p, "-"..dat[2], nil, true, false)
    end
  end,
}
jinghe:addRelatedSkill(jinghe_trigger)
nanhualaoxian:addSkill(gongxiu)
nanhualaoxian:addSkill(jinghe)
local ex__leiji = fk.CreateTriggerSkill{
  name = "ex__leiji",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.card.name == "jink"
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#ex__leiji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade then
      room:damage{
        from = player,
        to = to,
        damage = 2,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    elseif judge.card.suit == Card.Club then
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local yinbingn = fk.CreateTriggerSkill{
  name = "yinbingn",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage, fk.HpLost},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.PreDamage then
        return target == player and data.card and data.card.trueName == "slash"
      else
        return target ~= player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreDamage then
      room:loseHp(data.to, data.damage, self.name)
      return true
    else
      player:drawCards(1, self.name)
    end
  end,
}
local huoqi = fk.CreateActiveSkill{
  name = "huoqi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#huoqi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return target:isWounded() and table.every(Fk:currentRoom().alive_players, function(p) return target.hp <= p.hp end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not target.dead then
      target:drawCards(1, self.name)
    end
  end,
}
local guizhu = fk.CreateTriggerSkill{
  name = "guizhu",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local xianshou = fk.CreateActiveSkill{
  name = "xianshou",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#xianshou",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = not target:isWounded() and 2 or 1
    target:drawCards(n, self.name)
  end
}
local lundao = fk.CreateTriggerSkill{
  name = "lundao",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and
      data.from:getHandcardNum() ~= player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    if data.from:getHandcardNum() > player:getHandcardNum() then
      return player.room:askForSkillInvoke(player, self.name, nil, "#lundao-invoke::"..data.from.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    if data.from:getHandcardNum() > player:getHandcardNum() then
      room:doIndicate(player.id, {from.id})
      local id = room:askForCardChosen(player, from, "he", self.name)
      room:throwCard({id}, self.name, from, player)
    else
      player:drawCards(1, self.name)
    end
  end
}
local guanyue = fk.CreateTriggerSkill{
  name = "guanyue",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askForGuanxing(player, room:getNCards(2), {1, 1}, {1, 1}, self.name, true, {"Top", "prey"})
    if #result.top > 0 then
      table.insert(room.draw_pile, 1, result.top[1])
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = 1,
        arg2 = 0,
      }
    end
    if #result.bottom > 0 then
      room:obtainCard(player.id, result.bottom[1], false, fk.ReasonJustMove)
    end
  end,
}
local yanzhengn = fk.CreateTriggerSkill{
  name = "yanzhengn",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(player.room.alive_players, Util.IdMapper)
    local tos, card = player.room:askForChooseCardAndPlayers(player, targets, 1, player:getHandcardNum() - 1, ".|.|.|hand",
      "#yanzhengn-invoke:::"..(player:getHandcardNum() - 1), self.name, true)
    if #tos > 0 and card then
      self.cost_data = {tos, card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = player:getCardIds("h")
    table.removeOne(ids, self.cost_data[2])
    room:throwCard(ids, self.name, player, player)
    for _, id in ipairs(self.cost_data[1]) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
nanhualaoxian:addRelatedSkill(ex__leiji)
nanhualaoxian:addRelatedSkill(yinbingn)
nanhualaoxian:addRelatedSkill(huoqi)
nanhualaoxian:addRelatedSkill(guizhu)
nanhualaoxian:addRelatedSkill(xianshou)
nanhualaoxian:addRelatedSkill(lundao)
nanhualaoxian:addRelatedSkill(guanyue)
nanhualaoxian:addRelatedSkill(yanzhengn)
nanhualaoxian:addRelatedSkill("ex__biyue")
nanhualaoxian:addRelatedSkill("ex__tuxi")
nanhualaoxian:addRelatedSkill("mingce")
nanhualaoxian:addRelatedSkill("zhiyan")
Fk:loadTranslationTable{
  ["ty__nanhualaoxian"] = "南华老仙",
  ["#ty__nanhualaoxian"] = "仙人指路",
  ["illustrator:ty__nanhualaoxian"] = "君桓文化",
  ["gongxiu"] = "共修",
  [":gongxiu"] = "结束阶段，若你本回合发动过〖经合〗，你可以选择一项：1.令所有本回合因〖经合〗获得过技能的角色摸一张牌；"..
  "2.令所有本回合未因〖经合〗获得过技能的其他角色弃置一张手牌。",
  ["jinghe"] = "经合",
  [":jinghe"] = "出牌阶段限一次，你可展示至多四张牌名各不同的手牌，选择等量的角色，从“写满技能的天书”随机展示四个技能，这些角色依次选择并"..
  "获得其中一个，直到你下回合开始或你死亡。",
  ["#gongxiu-invoke"] = "共修：你可以执行一项",
  ["gongxiu_draw"] = "令“经合”角色各摸一张牌",
  ["gongxiu_discard"] = "令非“经合”角色各弃置一张手牌",
  ["#jinghe"] = "经合：展示至多四张牌名各不同的手牌，令等量的角色获得技能",
  ["#jinghe-choice"] = "经合：选择你要获得的技能",
  ["ex__leiji"] = "雷击",
  [":ex__leiji"] = "当你使用或打出【闪】后，你可以令一名其他角色进行一次判定，若结果为：♠，你对其造成2点雷电伤害；♣，你回复1点体力，对其造成1点雷电伤害。",
  ["#ex__leiji-choose"] = "雷击：令一名角色进行判定，若为♠，你对其造成2点雷电伤害；若为♣，你回复1点体力，对其造成1点雷电伤害",
  ["yinbingn"] = "阴兵",
  [":yinbingn"] = "锁定技，你使用【杀】即将造成的伤害视为失去体力。当其他角色失去体力后，你摸一张牌。",
  ["huoqi"] = "活气",
  [":huoqi"] = "出牌阶段限一次，你可以弃置一张牌，然后令一名体力最少的角色回复1点体力并摸一张牌。",
  ["#huoqi"] = "活气：弃置一张牌，令一名体力最少的角色回复1点体力并摸一张牌",
  ["guizhu"] = "鬼助",
  [":guizhu"] = "每回合限一次，当一名角色进入濒死状态时，你可以摸两张牌。",
  ["xianshou"] = "仙授",
  [":xianshou"] = "出牌阶段限一次，你可以令一名角色摸一张牌。若其未受伤，则多摸一张牌。",
  ["#xianshou"] = "仙授：令一名角色摸一张牌，若其未受伤则多摸一张牌",
  ["lundao"] = "论道",
  [":lundao"] = "当你受到伤害后，若伤害来源的手牌多于你，你可以弃置其一张牌；若伤害来源的手牌数少于你，你摸一张牌。",
  ["#lundao-invoke"] = "论道：你可以弃置 %dest 一张牌",
  ["guanyue"] = "观月",
  [":guanyue"] = "结束阶段，你可以观看牌堆顶的两张牌，然后获得其中一张，将另一张置于牌堆顶。",
  ["prey"] = "获得",
  ["yanzhengn"] = "言政",
  [":yanzhengn"] = "准备阶段，若你的手牌数大于1，你可以选择一张手牌并弃置其余的牌，然后对至多等于弃置牌数的角色各造成1点伤害。",
  ["#yanzhengn-invoke"] = "言政：你可以选择保留一张手牌，弃置其余的手牌，对至多%arg名角色各造成1点伤害",

  ["$gongxiu1"] = "福祸与共，业山可移。",
  ["$gongxiu2"] = "修行退智，遂之道也。",
  ["$jinghe1"] = "大哉乾元，万物资始。",
  ["$jinghe2"] = "无极之外，复无无极。",
  ["~ty__nanhualaoxian"] = "道亦有穷时……",
}

local ty__tongyuan = General(extension, "ty__tongyuan", "qun", 4)
local chaofeng = fk.CreateTriggerSkill{
  name = "chaofeng",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isKongcheng() and data.card and player.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#chaofeng-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local card = Fk:getCardById(self.cost_data[1])
    local n = (data.card.color == card.color) and 2 or 1
    if not player.dead then
      player:drawCards(n, self.name)
    end
    if data.card.type == card.type then
      data.damage = data.damage + 1
    end
  end,
}
ty__tongyuan:addSkill(chaofeng)
local chuanshu = fk.CreateTriggerSkill{
  name = "chuanshu",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.Death, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self,false,true) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      return event == fk.Death or (player.phase == Player.Start and player:isWounded())
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#chuanshu-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:handleAddLoseSkills(to, "chaofeng")
    room:handleAddLoseSkills(player, "longdan|congjian|chuanyun")
  end,
}
ty__tongyuan:addSkill(chuanshu)
local chuanyun = fk.CreateTriggerSkill{
  name = "chuanyun",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" 
    and #player.room:getPlayerById(data.to):getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chuanyun-invoke::"..data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local card = table.random(to:getCardIds("e"))
    room:throwCard({card}, self.name, to, to)
  end,
}
ty__tongyuan:addRelatedSkill("longdan")
ty__tongyuan:addRelatedSkill("congjian")
ty__tongyuan:addRelatedSkill(chuanyun)
Fk:loadTranslationTable{
  ["ty__tongyuan"] = "童渊",
  ["#ty__tongyuan"] = "蓬莱枪神散人",
  ["illustrator:ty__tongyuan"] = "目游",
  ["chaofeng"] = "朝凤",
  [":chaofeng"] = "每阶段限一次，当你于出牌阶段使用牌造成伤害时，你可以弃置一张手牌，然后摸一张牌。若弃置的牌与造成伤害的牌：颜色相同，则多摸一张牌；"..
  "类型相同，则此伤害+1。",
  ["#chaofeng-invoke"] = "朝凤：你可以弃置弃置一张手牌，摸一张牌",
  ["chuanshu"] = "传术",
  [":chuanshu"] = "限定技，准备阶段若你已受伤，或当你死亡时，你可令一名其他角色获得〖朝凤〗，然后你获得〖龙胆〗、〖从谏〗、〖穿云〗。",
  ["#chuanshu-choose"] = "传术：你可令一名其他角色获得〖朝凤〗，你获得〖龙胆〗、〖从谏〗、〖穿云〗",
  ["chuanyun"] = "穿云",
  [":chuanyun"] = "当你使用【杀】指定目标后，你可令该角色随机弃置一张装备区里的牌。",
  ["#chuanyun-invoke"] = "穿云：你可令 %dest 随机弃置一张装备区里的牌",

  ["$chaofeng1"] = "鸾凤归巢，百鸟齐鸣。",
  ["$chaofeng2"] = "鸾凤之响，所闻皆朝。",
  ["$chuanshu1"] = "此术不传子，独传于贤。",
  ["$chuanshu2"] = "定倾之术，贤者可习之。",
  ["$longdan_ty__tongyuan"] = "能进能退，方显名将本色。",
  ["$congjian_ty__tongyuan"] = "察言纳谏，安身立命之道也。",
  ["$chuanyun"] = "吾枪所至，人马俱亡！",
  ["~ty__tongyuan"] = "一门三杰，无憾矣！",
}

local zhangning = General(extension, "ty__zhangning", "qun", 3, 3, General.Female)
local tianze = fk.CreateTriggerSkill{
  name = "tianze",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and data.card.color == Card.Black and
      player:usedSkillTimes(self.name) == 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|spade,club|hand,equip", "#tianze-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:throwCard(self.cost_data, self.name, player, player)
    room:damage{ from = player, to = target, damage = 1, skillName = self.name}
  end,
}
local tianze_draw = fk.CreateTriggerSkill{
  name = "#tianze_draw",
  events = {fk.FinishJudge},
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(tianze.name) and data.card.color == Card.Black
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(tianze.name)
    player.room:notifySkillInvoked(player, tianze.name, self.anim_type)
    player.room:drawCards(player, 1, self.name)
  end,
}
local difa = fk.CreateTriggerSkill{
  name = "difa",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 and player.phase ~= Player.NotActive then
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand and
          table.find(move.moveInfo, function (info)
          return info.fromArea == Card.DrawPile and player.room:getCardOwner(info.cardId) == player and
            player.room:getCardArea(info.cardId) == Player.Hand and Fk:getCardById(info.cardId).color == Card.Red end) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile and player.room:getCardOwner(info.cardId) == player and
          player.room:getCardArea(info.cardId) == Player.Hand and Fk:getCardById(info.cardId).color == Card.Red then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    if #ids == 0 then return false end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, tostring(Exppattern{ id = ids }), "#difa-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeTrick and not card.is_derived then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    local name = room:askForChoice(player, names, self.name)
    local cards = room:getCardsFromPileByRule(name, 1, "discardPile")
    if #cards == 0 then
      cards = room:getCardsFromPileByRule(name, 1)
    end
    if #cards > 0 then
      room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
  end,
}
tianze:addRelatedSkill(tianze_draw)
zhangning:addSkill(tianze)
zhangning:addSkill(difa)
Fk:loadTranslationTable{
  ["ty__zhangning"] = "张宁",
  ["#ty__zhangning"] = "大贤后人",
  ["illustrator:ty__zhangning"] = "君桓文化",
  ["tianze"] = "天则",
  [":tianze"] = "其他角色的出牌阶段限一次，其使用黑色牌结算后，你可以弃置一张黑色牌对其造成1点伤害；其他角色的黑色判定牌生效后，你摸一张牌。",
  ["difa"] = "地法",
  [":difa"] = "你的回合内限一次，当你从牌堆摸到红色牌后，你可以弃置此牌，然后选择一种锦囊牌的牌名，从牌堆或弃牌堆获得一张。",

  ["#tianze-invoke"] = "天则：你可弃置一张黑色牌来对%dest造成1点伤害",
  ["#difa-invoke"] = "地法：你可弃置一张摸到的红色牌，然后检索一张锦囊牌",
  ["$tianze1"] = "观天则，以断人事。",
  ["$tianze2"] = "乾元用九，乃见天则。",
  ["$difa1"] = "地蕴天成，微妙玄通。",
  ["$difa2"] = "观地之法，吉在其中。",
  ["~ty__zhangning"] = "全气之地，当葬其止……",
}

local pangdegong = General(extension, "ty__pangdegong", "qun", 3)
local heqia = fk.CreateTriggerSkill{
  name = "heqia",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and (not player:isNude() or
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "heqia_active", "#heqia-invoke", true, nil, false)
    if success and dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player
    local dummy = Fk:cloneCard("dilu")
    if #self.cost_data.cards > 0 then
      to = room:getPlayerById(self.cost_data.targets[1])
      dummy:addSubcards(self.cost_data.cards)
    else
      local src = room:getPlayerById(self.cost_data.targets[1])
      local cards = room:askForCard(src, 1, 999, true, self.name, false, ".", "#heqia-give:"..player.id)
      dummy:addSubcards(cards)
    end
    room:moveCardTo(dummy, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if to.dead or to:isKongcheng() then return end
    room:setPlayerMark(to, "heqia-tmp", #dummy.subcards)
    local success, dat = room:askForUseActiveSkill(to, "heqia_viewas", "#heqia-use:::"..#dummy.subcards, true)
    if success and dat then
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      room:useCard{
        from = to.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end
  end,
}
local heqia_active = fk.CreateActiveSkill{
  name = "heqia_active",
  min_card_num = 0,
  target_num = 1,
  interaction = function()
    local choices = {}
    if not Self:isNude() then table.insert(choices, "heqia_give") end
    if table.find(Fk:currentRoom().alive_players, function(p) return Self ~= p and not p:isNude() end) then
      table.insert(choices, "heqia_prey")
    end
    return UI.ComboBox {choices = choices}
  end,
  card_filter = function(self, to_select, selected)
    if not self.interaction.data or self.interaction.data == "heqia_prey" then return false end
    return true
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if not self.interaction.data or #selected > 0 or to_select == Self.id then return false end
    if self.interaction.data == "heqia_give" then
      return #selected_cards > 0
    else
      return not Fk:currentRoom():getPlayerById(to_select):isNude()
    end
  end,
}
local heqia_viewas = fk.CreateActiveSkill{
  name = "heqia_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and Self:canUse(card) and not Self:prohibitUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return false end
    if #selected >= Self:getMark("heqia-tmp") then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = "heqia"
    if Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), to_use) then return false end
    return to_use.skill:modTargetFilter(to_select, selected, Self.id, to_use, false)
  end,
  feasible = function(self, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = "heqia"
    if to_use.skill:getMinTargetNum() == 0 then
      return (#selected == 0 or table.contains(selected, Self.id)) and to_use.skill:feasible(selected, selected_cards, Self, to_use)
    else
      return #selected > 0
    end
  end,
}
local yinyi = fk.CreateTriggerSkill{
  name = "yinyi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self) and data.damageType == fk.NormalDamage and
      data.from and data.from:getHandcardNum() ~= player:getHandcardNum() and data.from.hp ~= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = Util.TrueFunc,
}
Fk:addSkill(heqia_active)
Fk:addSkill(heqia_viewas)
pangdegong:addSkill(heqia)
pangdegong:addSkill(yinyi)
Fk:loadTranslationTable{
  ["ty__pangdegong"] = "庞德公",
  ["#ty__pangdegong"] = "友睦风疏",
  ["designer:ty__pangdegong"] = "步穗",
  ["illustrator:ty__pangdegong"] = "君桓文化",
  ["heqia"] = "和洽",
  [":heqia"] = "出牌阶段开始时，你可以选择一项：1.你交给一名其他角色至少一张牌；2.令一名有手牌的其他角色交给你至少一张牌。然后获得牌的角色可以将一张手牌当任意基本牌使用（无距离次数限制），且此牌目标上限改为X（X为其本次获得的牌数）。",
  ["yinyi"] = "隐逸",
  [":yinyi"] = "锁定技，每回合限一次，当你受到非属性伤害时，若伤害来源的手牌数与体力值均与你不同，防止此伤害。",
  ["heqia_active"] = "和洽",
  ["#heqia-invoke"] = "和洽：交给一名其他角色至少一张牌，或选择一名角色将至少一张牌交给你",
  ["heqia_give"] = "交给一名其他角色至少一张牌",
  ["heqia_prey"] = "令一名角色将至少一张牌交给你",
  ["#heqia-give"] = "和洽：交给 %src 至少一张牌",
  ["heqia_viewas"] = "和洽",
  ["#heqia-use"] = "和洽：你可以将一张手牌当任意基本牌使用，可以指定%arg个目标",

  ["$heqia1"] = "守望相助，则百姓和洽。",
  ["$heqia2"] = "阳方仁爱，全真敦笃，物咸和洽。",
  ["$yinyi1"] = "但求得其栖宿而已，天下非所保也。",
  ["$yinyi2"] = "居岘山之南，沔水上，未尝入城府。",
  ["~ty__pangdegong"] = "天地闭，贤人隐。",
}

return extension
