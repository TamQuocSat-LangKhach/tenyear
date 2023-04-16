local extension = Package("tenyear_sp")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp"] = "十周年新服",
  ["ty"] = "新服",
}

local maxCardsSkill = fk.CreateMaxCardsSkill{  --TODO: move this!
  name = "max_cards_skill",
  global = true,
  correct_func = function(self, player)
    return player:getMark("AddMaxCards") + player:getMark("AddMaxCards-turn") - player:getMark("MinusMaxCards") - player:getMark("MinusMaxCards-turn")
  end,
}
Fk:addSkill(maxCardsSkill)

--十周年SP 2018.8
--严畯 杜畿 刘焉 潘濬 王粲 庞统 太史慈 周鲂 吕岱 刘繇 吕虔 张梁
local liuyan = General(extension, "liuyan", "qun", 3)
local tushe = fk.CreateTriggerSkill{
  name = "tushe",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card.type ~= Card.TypeEquip and
      data.firstTarget and
      #table.filter(player:getCardIds(Player.Hand), function(cid)
        return Fk:getCardById(cid).type == Card.TypeBasic end) == 0 and
      #AimGroup:getAllTargets(data.tos) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#AimGroup:getAllTargets(data.tos), self.name)
  end,
}
local limu_targetmod = fk.CreateTargetModSkill{
  name = "#limu_targetmod",
  residue_func = function(self, player, skill)
    return #player:getCardIds(Player.Judge) > 0 and 999 or 0
  end,
  distance_limit_func = function(self, player, skill)
    return #player:getCardIds(Player.Judge) > 0 and 999 or 0
  end,
}
local limu = fk.CreateActiveSkill{
  name = "limu",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player) return not player:hasDelayedTrick("indulgence") end,
  target_filter = function() return false end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local cards = use.cards
    local card = Fk:cloneCard("indulgence")
    card:addSubcards(cards)
    room:useCard{
      from = use.from,
      tos = {{use.from}},
      card = card,
    }
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name
      }
    end
  end,
}
limu:addRelatedSkill(limu_targetmod)
liuyan:addSkill(tushe)
liuyan:addSkill(limu)
Fk:loadTranslationTable{
  ["liuyan"] = "刘焉",
  ["tushe"] = "图射",
  [":tushe"] = "当你使用非装备牌指定目标后，若你没有基本牌，则你可以摸X张牌（X为此牌指定的目标数）。",
  ["limu"] = "立牧",
  [":limu"] = "出牌阶段，你可以将一张方块牌当【乐不思蜀】对自己使用，然后回复1点体力；你的判定区有牌时，你使用牌没有次数和距离限制。",

  ["$tushe1"] = "据险以图进，备策而施为！",
  ["$tushe1"] = "夫战者，可时以奇险之策而图常谋！",

  ["$limu1"] = "今诸州纷乱，当立牧以定！",
  ["$limu2"] = "此非为偏安一隅，但求一方百姓安宁！",

  ["~liuyan"] = "季玉，望你能守好者益州疆土……",
}
--司马徽
--鲍三娘
local xurong = General(extension, "xurong", "qun", 4)
local xionghuo = fk.CreateActiveSkill{
  name = "xionghuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@baoli") > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@baoli", 1)
    room:addPlayerMark(target, "@baoli", 1)
  end,
}
local xionghuo_record = fk.CreateTriggerSkill{
  name = "#xionghuo_record",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.DamageCaused, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("xionghuo", false, true) then
      if event == fk.GameStart then
        return true
      elseif event == fk.DamageCaused then
        return target == player and data.to ~= player and data.to:getMark("@baoli") > 0
      else
        return target ~= player and target:getMark("@baoli") > 0 and target.phase == Player.Play
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:addPlayerMark(player, "@baoli", 3)
    elseif event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      room:removePlayerMark(target, "@baoli", 1)
      room:addPlayerMark(target, "xionghuo-clear", 1)
      local n = 3
      if target:isNude() or player.dead then
        n = 2
      end
      local rand = math.random(1, n)
      if rand == 1 then
        room:damage {
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = "xionghuo",
        }
      elseif rand == 2 then
        room:loseHp(target, 1, "xionghuo")
        room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      else
        local dummy = Fk:cloneCard("dilu")
        if not target:isKongcheng() then
          dummy:addSubcards({ target.player_cards[Player.Hand][math.random(1, #target.player_cards[Player.Hand])] })
        end
        if #target.player_cards[Player.Equip] > 0 then
          dummy:addSubcards({ target.player_cards[Player.Equip][math.random(1, #target.player_cards[Player.Equip])] })
        end
        room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
      end
    end
  end,
}
local xionghuo_prohibit = fk.CreateProhibitSkill{
  name = "#xionghuo_prohibit",
  is_prohibited = function(self, from, to, card)
    if to:hasSkill("xionghuo") and from:getMark("xionghuo-clear") > 0 then
      return card.trueName == "slash"
    end
  end,
}
local shajue = fk.CreateTriggerSkill{
  name = "shajue",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) then
      return data.damage ~= nil and data.damage.card ~= nil and target.hp < 0 and
      player.room:getCardArea(data.damage.card) == Card.Processing
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@baoli", 1)
    room:obtainCard(player, data.damage.card, true, fk.ReasonPrey)
  end
}
xionghuo:addRelatedSkill(xionghuo_record)
xionghuo:addRelatedSkill(xionghuo_prohibit)
xurong:addSkill(xionghuo)
xurong:addSkill(shajue)
Fk:loadTranslationTable{
  ["xurong"] = "徐荣",
  ["xionghuo"] = "凶镬",
  [":xionghuo"] = "游戏开始时，你获得3个“暴戾”标记。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，你对有此标记的角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项：<br>"..
  "受到1点火焰伤害且本回合不能对你使用【杀】；<br>"..
  "流失1点体力且本回合手牌上限-1；<br>"..
  "你随机获得其一张手牌和一张装备区里的牌。",
  ["shajue"] = "杀绝",
  [":shajue"] = "锁定技，其他角色进入濒死状态时，若其需要超过一张【桃】或【酒】救回，则你获得一个“暴戾”标记，并获得使其进入濒死状态的牌。",
  ["#xionghuo_record"] = "凶镬",
  ["@baoli"] = "暴戾",

  ["$xionghuo1"] = "此镬加之于你，定有所伤！",
  ["$xionghuo2"] = "凶镬沿袭，怎会轻易无伤？",

  ["$shajue1"] = "杀伐决绝，不留后患。",
  ["$shajue2"] = "吾即出，必绝之！",

  ["~xurong"] = "此生无悔，心中无愧。",
}

local lijue = General(extension, "lijue", "qun", 4, 6)
local langxi = fk.CreateTriggerSkill{
  name = "langxi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp <= player.hp end), function(p) return p.id end), 1, 1, "#langxi-choose", self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
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
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Play and
      player:usedSkillTimes(self.name) < 1 and
      data.card.type == Card.TypeTrick and
      data.card.sub_type ~= Card.SubtypeDelayedTrick and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:obtainCard(player.id, data.card, true, fk.ReasonPrey)
  end,
}
lijue:addSkill(langxi)
lijue:addSkill(yisuan)
Fk:loadTranslationTable{
  ["lijue"] = "李傕",
  ["langxi"] = "狼袭",
  [":langxi"] = "准备阶段开始时，你可以对一名体力值不大于你的其他角色随机造成0~2点伤害。",
  ["#langxi-choose"] = "狼袭：请选择一名体力值不大于你的其他角色，对其随机造成0~2点伤害",
  ["yisuan"] = "亦算",
  [":yisuan"] = "每阶段限一次，当你于出牌阶段内使用普通锦囊牌结算结束后，你可以减1点体力上限，然后获得此牌。",
}

local guosi = General(extension, "guosi", "qun", 4)
local tanbei = fk.CreateActiveSkill{
  name = "tanbei",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
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
    room:addPlayerMark(target, choice.."-turn", 1)
    if choice == "tanbei1" then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local tanbei_prohibit = fk.CreateProhibitSkill{
  name = "#tanbei_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:hasSkill(self.name) and to:getMark("tanbei1-turn") > 0
  end,
}
local tanbei_record = fk.CreateTriggerSkill{
  name = "#tanbei_record",

  refresh_events = {fk.TargetSpecifying},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if player.room:getPlayerById(id):getMark("tanbei2-turn") > 0 then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:addCardUseHistory(data.card.trueName, -1)
  end,
}
local tanbei_distance = fk.CreateDistanceSkill{
  name = "#tanbei_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      if to:getMark("tanbei2-turn") > 0 then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
local sidao = fk.CreateTriggerSkill{
  name = "sidao",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:usedSkillTimes(self.name) == 0 and not player:isKongcheng() then
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
    local room = player.room
    local card = Fk:cloneCard("snatch")
    card:addSubcards({self.cost_data[2]})
    room:useCard({
      card = card,
      from = player.id,
      tos = {{self.cost_data[1]}},
      skillName = self.name,
    })
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget
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
tanbei:addRelatedSkill(tanbei_record)
tanbei:addRelatedSkill(tanbei_distance)
guosi:addSkill(tanbei)
guosi:addSkill(sidao)
Fk:loadTranslationTable{
  ["guosi"] = "郭汜",
  ["tanbei"] = "贪狈",
  [":tanbei"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你随机获得其区域内的一张牌，此回合不能再对其使用牌；2. 令你此回合对其使用牌没有次数和距离限制。",
  ["sidao"] = "伺盗",
  [":sidao"] = "出牌阶段限一次，当你对一名其他角色连续使用两张牌后，你可将一张手牌当【顺手牵羊】对其使用（目标须合法）。",
  ["tanbei1"] = "其随机获得你区域内的一张牌，此回合不能再对你使用牌",
  ["tanbei2"] = "此回合对你使用牌无次数和距离限制",
  ["#sidao-cost"] = "伺盗：你可将一张手牌当【顺手牵羊】对相同的目标使用",
}

local zhangji = General(extension, "zhangji", "qun", 4)
local lveming = fk.CreateActiveSkill{
  name = "lveming",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
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
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:usedSkillTimes("lveming", Player.HistoryGame) > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] < 4  --TODO: no treasure yet
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local n = player:usedSkillTimes("lveming", Player.HistoryGame)
    for i = 1, n, 1 do
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
        local equip = table.random(cards)
        room:moveCards({
          ids = {equip},
          to = target.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
        })
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = Fk:getCardById(equip),
        })
      end
    end
  end,
}
zhangji:addSkill(lveming)
zhangji:addSkill(tunjun)
Fk:loadTranslationTable{
  ["zhangji"] = "张济",
  ["lveming"] = "掠命",
  [":lveming"] = "出牌阶段限一次，你选择一名装备区装备少于你的其他角色，令其选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；不同，你随机获得其区域内的一张牌。",
  ["tunjun"] = "屯军",
  [":tunjun"] = "限定技，出牌阶段，你可以选择一名角色，令其随机使用牌堆中的X张不同类型的装备牌。（不替换原有装备，X为你发动“掠命”的次数）",
}

local fanchou = General(extension, "fanchou", "qun", 4)
local xingluan = fk.CreateTriggerSkill{
  name = "xingluan",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:usedSkillTimes(self.name) == 0 then
      return data.tos and #data.tos == 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = {getCardByPattern(room, ".|6")}
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
fanchou:addSkill(xingluan)
Fk:loadTranslationTable{
  ["fanchou"] = "樊稠",
  ["xingluan"] = "兴乱",
  [":xingluan"] = "出牌阶段限一次，当你使用的仅指定一个目标的牌结算完成后，你可以从牌堆里获得一张点数为6的牌。",
}
--张琪瑛 卫温诸葛直 吕凯 张恭 2019.4.28
local zhangqiying = General(extension, "zhangqiying", "qun", 3, 3, General.Female)
local falu = fk.CreateTriggerSkill{
  name = "falu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        self.falu_suit = {}
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local suit = Fk:getCardById(info.cardId):getSuitString()
                if player:getMark("@falu" .. suit) == 0 then
                  table.insertIfNeed(self.falu_suit, suit)
                end
              end
            end
          end
        end
        return #self.falu_suit > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    if event == fk.GameStart then
      for i = 1, 4, 1 do
        room:addPlayerMark(player, "@falu" .. suits[i], 1)
      end
    else
      for _, suit in ipairs(self.falu_suit) do
        room:addPlayerMark(player, "@falu" .. suit, 1)
      end
    end
  end,
}
local zhenyi = fk.CreateTriggerSkill {
  name = "zhenyi",
  anim_type = "control",
  events = {fk.AskForRetrial, fk.AskForPeaches, fk.DamageCaused, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AskForRetrial then
        return player:getMark("@faluspade") > 0
      elseif event == fk.AskForPeaches then
        return target == player and player.dying and player:getMark("@faluclub") > 0 and not player:isKongcheng()
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@faluheart") > 0
      elseif event == fk.Damaged then
        return target == player and player:getMark("@faludiamond") > 0 and data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForPeaches then
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForRetrial then
      room:removePlayerMark(player, "@faluspade", 1)
      local choice = room:askForChoice(player, {"spade", "heart"}, self.name, self.name)
      if choice == "spade" then
        data.card.suit = Card.Spade
      else
        data.card.suit = Card.Heart
      end
      data.card.number = 5
    elseif event == fk.AskForPeaches then
      room:removePlayerMark(player, "@faluclub", 1)
      local peach = Fk:cloneCard("peach")
      peach:addSubcards(self.cost_data)
      peach.skillName = self.name
      room:useCard({
        card = peach,
        from = player.id,
        tos = {{target.id}},
      })
    elseif event == fk.DamageCaused then
      room:removePlayerMark(player, "@faluheart", 1)
      self.zhenyi_damage = false
      local judge = {
        who = data.to,
        reason = self.name,
        pattern = ".|.|spade,club",
      }
      room:judge(judge)
      if self.zhenyi_damage then
        data.damage = data.damage + 1
      end
    elseif event == fk.Damaged then
      room:removePlayerMark(player, "@faludiamond", 1)
      local cards = {}
      table.insert(cards, getCardByPattern(room, ".|.|.|.|.|basic"))
      table.insert(cards, getCardByPattern(room, ".|.|.|.|.|trick"))
      table.insert(cards, getCardByPattern(room, ".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return data.reason == self.name
  end,
  on_refresh = function(self, event, target, player, data)
    if data.card.color == Card.Black then
      self.zhenyi_damage = true
    end
  end,
}
local dianhua = fk.CreateTriggerSkill{
  name = "dianhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and (player.phase == Player.Start or player.phase == Player.Finish) then
      self.dianhua = 0
      for _, mark in ipairs(player:getMarkNames()) do
        if string.find(mark, "@falu") then
          self.dianhua = self.dianhua + 1
        end
      end
      return self.dianhua > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(self.dianhua)) --TODO: up only
  end,
}
zhangqiying:addSkill(falu)
zhangqiying:addSkill(zhenyi)
zhangqiying:addSkill(dianhua)
Fk:loadTranslationTable{
  ["zhangqiying"] = "张琪瑛",
  ["falu"] = "法箓",
  [":falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：♠，你获得1枚“紫微”；♣，你获得1枚“后土”；♥，你获得1枚“玉清”；♦，你获得1枚“勾陈”（每种标记限拥有一个）。游戏开始时，你获得以上四种标记。",
  ["zhenyi"] = "真仪",
  [":zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或♥5；<br>"..
  "当你处于濒死状态时，你可以弃置“后土”，然后将你的一张手牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，然后你进行一次判定，若结果为黑色，此伤害+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。",
  ["dianhua"] = "点化",
  [":dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数）。若如此做，你将这些牌以任意顺序放回牌堆顶。",
  ["@faluspade"] = "♠紫微",
  ["@faluclub"] = "♣后土",
  ["@faluheart"] = "♥玉清",
  ["@faludiamond"] = "♦勾陈",
}
--沙摩柯 忙牙长 许贡 张昌蒲 2019.8.20
local shamoke = General(extension, "shamoke", "shu", 4)
local jilis = fk.CreateTriggerSkill{
  name = "jilis",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("@jilis-turn") == player:getAttackRange()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getAttackRange())
  end,

  refresh_events = {fk.CardUsing, fk.CardResponding},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@jilis-turn", 1)
  end,
}
shamoke:addSkill(jilis)
Fk:loadTranslationTable{
  ["shamoke"] = "沙摩柯",
  ["jilis"] = "蒺藜",
  [":jilis"] = "当你于一回合内使用或打出第X张牌时，你可以摸X张牌（X为你的攻击范围）。",
  ["@jilis-turn"] = "蒺藜",
}

local mangyachang = General(extension, "mangyachang", "qun", 4)
local jiedao = fk.CreateTriggerSkill{
  name = "jiedao",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player:getMark("jiedao-turn") == 0 then
        player.room:addPlayerMark(player, "jiedao-turn", 1)
        return player:isWounded()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getLostHp()
    data.damage = data.damage + n
    data.jiedao_extra = n
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not data.to.dead and data.jiedao_extra and data.jiedao_extra > 0 and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = data.jiedao_extra
    if #player.player_cards[Player.Hand] + #player.player_cards[Player.Equip] <= n then
      player:throwAllCards("he")
    else
      room:askForDiscard(player, n, n, true, self.name, false, ".", "#jiedao-discard")
    end
  end,
}
mangyachang:addSkill(jiedao)
Fk:loadTranslationTable{
  ["mangyachang"] = "忙牙长",
  ["jiedao"] = "截刀",
  [":jiedao"] = "当你每回合第一次造成伤害时，你可令此伤害至多+X（X为你损失的体力值）。然后若受到此伤害的角色没有死亡，你弃置等同于此伤害加值的牌。",
  ["#jiedao-discard"] = "截刀：你需弃置等同于此伤害加值的牌",
}

local wenyang = General(extension, "wenyang", "wei", 5)
local lvli = fk.CreateTriggerSkill{
  name = "lvli",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and #player.player_cards[Player.Hand] ~= player.hp then
      if #player.player_cards[Player.Hand] > player.hp and not player:isWounded() then return end
      local n = 1
      if player:usedSkillTimes("choujue", Player.HistoryGame) > 0 then
        if player.phase ~= Player.NotActive then
          n = 2
        end
      end
      if event == fk.Damage then
        return player:usedSkillTimes(self.name) < n
      else
        return player:usedSkillTimes("beishui", Player.HistoryGame) > 0 and player:usedSkillTimes(self.name) < n
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Hand] - player.hp
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      player.room:recover{
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = self.name
      }
    end
  end
}
local choujue = fk.CreateTriggerSkill{
  name = "choujue",
  anim_type = "special",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      return target.phase == Player.Finish and math.abs(#player.player_cards[Player.Hand] - player.hp) > 2
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "beishui", nil)
  end,
}
local beishui = fk.CreateTriggerSkill{
  name = "beishui",
  anim_type = "special",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      return player.phase == Player.Start and (#player.player_cards[Player.Hand] < 2 or player.hp < 2)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, self.name, 1)
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "qingjiao", nil)
  end,
}
local qingjiao = fk.CreateTriggerSkill{
  name = "qingjiao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h")
    local names = {"weapon", "armor", "offensive_horse", "defensive_horse"}  --no treasure yet
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic or card.type == Card.TypeTrick then
        table.insertIfNeed(names, card.trueName)
      end
    end
    local table1 = room.draw_pile
    local table2 = room.discard_pile
    for _, id in ipairs(table2) do
      table.insert(table1, id)
    end
    local cards = {}
    for i = 1, 8, 1 do
      local name = names[math.random(1, #names)]
      table.insert(cards, getCardByPattern(room, name, table1))
      table.removeOne(names, name)
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:throwAllCards("he")
  end,
}
wenyang:addSkill(lvli)
wenyang:addSkill(choujue)
Fk:addSkill(beishui)
Fk:addSkill(qingjiao)
Fk:loadTranslationTable{
  ["wenyang"] = "文鸯",
  ["lvli"] = "膂力",
  [":lvli"] = "每名角色的回合限一次，当你造成伤害后，你可以将手牌摸至与体力值相同或将体力回复至与手牌数相同。",
  ["choujue"] = "仇决",
  [":choujue"] = "觉醒技，每名角色的回合结束时，若你的手牌数和体力值相差3或更多，你减1点体力上限并获得〖背水〗，然后修改〖膂力〗为“每名其他角色的回合限一次（在自己的回合限两次）”。",
  ["beishui"] = "背水",
  [":beishui"] = "觉醒技，准备阶段，若你的手牌数或体力值小于2，你减1点体力上限并获得〖清剿〗，然后修改〖膂力〗为“当你造成或受到伤害后”。",
  ["qingjiao"] = "清剿",
  [":qingjiao"] = "出牌阶段开始时，你可以弃置所有手牌，然后从牌堆或弃牌堆中随机获得八张牌名各不相同且副类别不同的牌。若如此做，结束阶段，你弃置所有牌。",
}

local jianggan = General(extension, "jianggan", "wei", 3)
local weicheng = fk.CreateTriggerSkill{
  name = "weicheng",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and #player.player_cards[Player.Hand] < player.hp then
      for _, move in ipairs(data) do
        if move.from and move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
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
    player:drawCards(1, self.name)
  end,
}
local daoshu = fk.CreateActiveSkill{
  name = "daoshu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suits = {"spade", "heart", "club", "diamond"}
    local choice = room:askForChoice(player, suits, self.name)
    local card = room:askForCardChosen(player, target, 'h', self.name)
    room:obtainCard(player.id, card, true)
    if Fk:getCardById(card):getSuitString() == choice then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      player:addSkillUseHistory(self.name, -1)
    else
      table.removeOne(suits, Fk:getCardById(card):getSuitString())
      local ids = room:askForCard(player, 1, 1, false, self.name, false, ".|.|"..suits[1]..","..suits[2]..","..suits[3], "#daoshu-give")
      if #ids > 0 then
        room:obtainCard(target, Fk:getCardById(ids[1]), true, fk.ReasonGive)
      else
        player:showCards(player.player_cards[Player.Hand])
      end
    end
  end,
}
jianggan:addSkill(weicheng)
jianggan:addSkill(daoshu)
Fk:loadTranslationTable{
  ["jianggan"] = "蒋干",
  ["weicheng"] = "伪诚",
  [":weicheng"] = "你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于体力值，你可以摸一张牌。",
  ["daoshu"] = "盗书",
  [":daoshu"] = "出牌阶段限一次，你可以选择一名其他角色并选择一种花色，然后获得该角色一张手牌。若此牌与你选择的花色：相同，你对其造成1点伤害且此技能视为未发动过；不同，你交给该角色一张其他花色的手牌（若没有需展示所有手牌）。",
  ["#daoshu-give"] = "盗书：你需交给其一张另一种花色的手牌，若没有则展示所有手牌",
}
--管辂 葛玄 蒲元 2019.10.22
local guanlu = General(extension, "guanlu", "wei", 3)
local tuiyan = fk.CreateTriggerSkill{
  name = "tuiyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room.draw_pile < 3 then
      room:shuffleDrawPile()
      if #room.draw_pile < 3 then
        room:gameOver("")
      end
    end
    local ids = {}
    for i = 1, 3, 1 do
      table.insert(ids, room.draw_pile[i])
    end
    room:fillAG(player, ids)
    room:delay(5000)
    room:closeAG(player)
  end,
}
local busuan = fk.CreateActiveSkill {
  name = "busuan",
  anim_type = "control",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic or card.type == Card.TypeTrick then
        table.insertIfNeed(names, card.trueName)
      end
    end
    local tag = {}
    for i = 1, 2, 1 do
      local name = room:askForChoice(player, names, self.name)
      table.insert(tag, name)
      table.removeOne(names, name)
    end
    target.tag[self.name] = tag
  end,
}
local busuan_record = fk.CreateTriggerSkill {
  name = "#busuan_record",

  refresh_events = {fk.DrawNCards},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true, true) then
      return type(target.tag["busuan"]) == "table" and #target.tag["busuan"] > 0 and data.n > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, name in ipairs(target.tag["busuan"]) do
      local id = getCardByPattern(room, name)
      if id == nil then
        id = getCardByPattern(room, name, room.discard_pile)
      end
      table.insert(cards, id)
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
    target.tag["busuan"] = {}
    data.n = 0
  end,
}
local mingjie = fk.CreateTriggerSkill {
  name = "mingjie",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1)[1])
    if card.color == Card.Black then
      if player.hp > 1 then
        room:loseHp(player, 1, self.name)
      end
      return
    else
      for i = 1, 2, 1 do
        if room:askForSkillInvoke(player, self.name) then
          card = Fk:getCardById(player:drawCards(1)[1])
          if card.color == Card.Black then
            if player.hp > 1 then
              room:loseHp(player, 1, self.name)
            end
            return
          end
        else
          return
        end
      end
    end
  end,
}
busuan:addRelatedSkill(busuan_record)
guanlu:addSkill(tuiyan)
guanlu:addSkill(busuan)
guanlu:addSkill(mingjie)
Fk:loadTranslationTable{
  ["guanlu"] = "管辂",
  ["tuiyan"] = "推演",
  [":tuiyan"] = "出牌阶段开始时，你可以观看牌堆顶的三张牌。",
  ["busuan"] = "卜算",
  [":busuan"] = "出牌阶段限一次，你可以选择一名其他角色，然后选择至多两张不同的卡牌名称（限基本牌或锦囊牌）。该角色下次摸牌阶段摸牌时，改为从牌堆或弃牌堆中获得你选择的牌。",
  ["mingjie"] = "命戒",
  [":mingjie"] = "结束阶段，你可以摸一张牌，若此牌为红色，你可以重复此流程直到摸到黑色牌或摸到第三张牌。当你以此法摸到黑色牌时，若你的体力值大于1，你失去1点体力。",
}
Fk:loadTranslationTable{
  ["gexuan"] = "葛玄",
  ["lianhua"] = "炼化",
  [":lianhua"] = "你的回合外，每当有其他角色受到伤害后，你获得一个 “丹血”标记，直到你的出牌阶段开始。准备阶段，根据你获得的“丹血”标记的数量和颜色，你获得相应的游戏牌以及获得相应技能直到回合结束。3枚或以下：“英姿”和【桃】；超过3枚且红色“丹血”较多：“观星”和【无中生有】；超过3枚且黑色“丹血”较多：“直言”和【顺手牵羊】；超过3枚且红色和黑色一样多：【杀】、【决斗】和“攻心”。",
  ["zhafu"] = "札符",
  [":zhafu"] = "限定技，出牌阶段，你可以选择一名其他角色。该角色的下一个弃牌阶段开始时，其选择保留一张手牌，然后将其余的手牌交给你。",
}
--辛毗 伊籍 李肃 张温 2019.12.4
--花鬘 2020.1.31
--王双 潘凤 2020.5.14
--邢道荣 2020.7.14
local leitong = General(extension, "leitong", "shu", 4)
local kuiji = fk.CreateActiveSkill{
  name = "kuiji",
  anim_type = "offensive",
  target_num = 0,
  card_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    room:useCard{
      from = effect.from,
      tos = {{effect.from}},
      card = card,
    }
    player:drawCards(1, self.name)
    local targets = {}
    local n = 0
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp > n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp == n then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuiji-damage", self.name, true)
    if #to > 0 then
      room:damage{
        from = player,
        to = room:getPlayerById(to[1]),
        damage = 2,
        skillName = self.name,
      }
    end
  end,
}
local kuiji_record = fk.CreateTriggerSkill{
  name = "#kuiji_record",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.damage and data.damage.skillName == "kuiji"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local n = 999
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp < n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp == n and p:isWounded() then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuiji-recover", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
      player.room:recover({
        who = player.room:getPlayerById(self.cost_data),
        num = 1,
        recoverBy = player,
        skillName = "kuiji"
      })
  end,
}
kuiji:addRelatedSkill(kuiji_record)
leitong:addSkill(kuiji)
Fk:loadTranslationTable{
  ["leitong"] = "雷铜",
  ["kuiji"] = "溃击",
  [":kuiji"] = "出牌阶段限一次，你可以将一张黑色基本牌当作【兵粮寸断】对你使用，然后摸一张牌。若如此做，你可以对体力值最多的一名其他角色造成2点伤害。该角色因此进入濒死状态时，你可令另一名体力值最少的角色回复1点体力。",
  ["#kuiji-damage"] = "溃击：你可以对其他角色中体力值最大的一名角色造成2点伤害",
  ["#kuiji-recover"] = "溃击：你可以令除其以外体力值最小的一名角色回复1点体力",
}

local wulan = General(extension, "wulan", "shu", 4)
local cuoruiw = fk.CreateTriggerSkill{
  name = "cuoruiw",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if player:distanceTo(p) < 2 and not p:isAllNude() then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#cuoruiw-cost", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, room:getPlayerById(self.cost_data), "hej", self.name)
    local color = Fk:getCardById(id).color
    room:throwCard({id}, self.name, room:getPlayerById(self.cost_data), player)
    local targets = {}
    local targets1 = {}
    local targets2 = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isKongcheng() then
        table.insertIfNeed(targets, p.id)
        table.insert(targets2, p.id)
      end
      if #p.player_cards[Player.Equip] > 0 then
        for _, id in ipairs(p.player_cards[Player.Equip]) do
          if Fk:getCardById(id).color == color then
            table.insertIfNeed(targets, p.id)
            table.insert(targets1, p.id)
            break
          end
        end
      end
    end
    table.removeOne(targets, self.cost_data)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#cuoruiw-use", self.name, true)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(targets[math.random(1, #targets)])
    end
    local choices = {}
    if table.contains(targets1, to.id) then
      table.insert(choices, "cuoruiw_equip")
    end
    if table.contains(targets2, to.id) then
      table.insert(choices, "cuoruiw_hand")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "cuoruiw_equip" then
      local ids = {}
      for _, id in ipairs(to.player_cards[Player.Equip]) do
        if Fk:getCardById(id).color == color then
          table.insert(ids, id)
        end
      end
      if #ids == 1 then
        room:throwCard(ids, self.name, to, player)
      else
        local throw = {}
        room:fillAG(player, ids)
        while #ids > 0 and #throw < 2 do
          local id = room:askForAG(player, ids, true, self.name)
          if id ~= nil then
            room:takeAG(player, id, {player})
            table.insert(throw, id)
            table.removeOne(ids, id)
          else
            break
          end
        end
        room:closeAG(player)
        room:throwCard(throw, self.name, to, player)
      end
    else
      local cards = room:askForCardsChosen(player, to, 1, 2, "h", self.name)
      to:showCards(cards)
      room:delay(1500)
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).color == color then
          dummy:addSubcard(id)
        end
      end
      if #dummy.subcards > 0 then
        room:moveCards({
          from = to.id,
          ids = dummy.subcards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
wulan:addSkill(cuoruiw)
Fk:loadTranslationTable{
  ["wulan"] = "吴兰",
  ["cuoruiw"] = "挫锐",
  [":cuoruiw"] = "出牌阶段开始时，你可以弃置一名你计算与其距离不大于1的角色区域里的一张牌。若如此做，你选择一项：1.弃置另一名其他角色装备区里至多两张与此牌颜色相同的牌；2.展示另一名其他角色的至多两张手牌，然后获得其中与此牌颜色相同的牌。",
  ["#cuoruiw-cost"] = "挫锐：你可以弃置距离不大于1的角色区域里的一张牌",
  ["#cuoruiw-use"] = "挫锐：选择另一名其他角色，弃置其至多两张颜色相同的装备，或展示其至多两张手牌",
  ["cuoruiw_equip"] = "弃置其至多两张颜色相同的装备",
  ["cuoruiw_hand"] = "展示其至多两张手牌并获得其中相同颜色牌",
}

local liuzan = General(extension, "ty__liuzan", "wu", 4)
local ty__fenyin = fk.CreateTriggerSkill{
  name = "ty__fenyin",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.NotActive then
      local room = player.room
      self.fenyin_draw = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            room:addPlayerMark(player, "liji-turn", 1)  --move this to liji would be proper...
            local mark = "fenyin_"..Fk:getCardById(info.cardId):getSuitString().."-turn"
            if player:getMark(mark) == 0 then
              room:addPlayerMark(player, mark, 1)
              self.fenyin_draw = self.fenyin_draw + 1
            end
          end
        end
      end
      return self.fenyin_draw > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.fenyin_draw, self.name)
  end,
}
local liji = fk.CreateActiveSkill{
  name = "liji",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local n = 8
    if #Fk:currentRoom().alive_players < 5 then n = 4 end
    return player:getMark("liji-turn") >= n and player:usedSkillTimes(self.name) < player:getMark("liji-turn")/n
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}
liuzan:addSkill(ty__fenyin)
liuzan:addSkill(liji)
Fk:loadTranslationTable{
  ["ty__liuzan"] = "留赞",
  ["ty__fenyin"] = "奋音",
  [":ty__fenyin"] = "锁定技，你的回合内，每当有一种花色的牌进入弃牌堆后（每回合每种花色各限一次），你摸一张牌。",
  ["liji"] = "力激",
  [":liji"] = "出牌阶段限0次，你可以弃置一张牌然后对一名其他角色造成1点伤害。你的回合内，本回合进入弃牌堆的牌每次达到8的倍数张时（存活人数小于5时改为4的倍数），此技能使用次数+1。",
}
--何进 2020.10.31（原1v1技能组）
--曹性 刘辩 2020.11.22
--刘宏 朱儁 韩遂（原1v1技能组） 许劭 王荣 丁原 韩馥 2020.12.28
--华歆 2021.2.3
--郭照 2021.2.7
local guozhao = General(extension, "guozhao", "wei", 3, 3, General.Female)
local pianchong = fk.CreateTriggerSkill{
  name = "pianchong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    table.insert(cards, getCardByPattern(room, ".|.|heart,diamond"))
    table.insert(cards, getCardByPattern(room, ".|.|spade,club"))
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
    local choice = room:askForChoice(player, {"red", "black"}, self.name)
    room:setPlayerMark(player, "@pianchong", choice)
    return true
  end,

  refresh_events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) and not player.dead and player:getMark("@pianchong") ~= 0 then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        local times = 0
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local color = player:getMark("@pianchong")
                if Fk:getCardById(info.cardId):getColorString() == color then
                  times = times + 1
                end
              end
            end
          end
        end
        if times > 0 then
          player.room:setPlayerMark(player, self.name, times)
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, "@pianchong", 0)
    else
      local pattern
      local color = player:getMark("@pianchong")
      if color == "red" then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
      local n = player:getMark(self.name)
      room:setPlayerMark(player, self.name, 0)
      local cards = {}
      for i = 1, n, 1 do
        table.insert(cards, getCardByPattern(room, pattern))
      end
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
local zunwei = fk.CreateActiveSkill{
  name = "zunwei",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      local player = Fk:currentRoom():getPlayerById(Self.id)
      return (player:getMark("zunwei1") == 0 and #player.player_cards[Player.Hand] < #target.player_cards[Player.Hand]) or
       (player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip]) or
       (player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp)
    end
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {}
    if player:getMark("zunwei1") == 0 and #player.player_cards[Player.Hand] < #target.player_cards[Player.Hand] then
      table.insert(choices, "zunwei1")
    end
    if player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip] then
      table.insert(choices, "zunwei2")
    end
    if player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp then
      table.insert(choices, "zunwei3")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zunwei1" then
      player:drawCards(math.min(#target.player_cards[Player.Hand] - #player.player_cards[Player.Hand], 5))
    elseif choice == "zunwei2" then
      local n = #target.player_cards[Player.Equip] - #player.player_cards[Player.Equip]
      for i = 1, n, 1 do
        local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
        local cards = {}
        for i = 1, #room.draw_pile, 1 do
          local card = Fk:getCardById(room.draw_pile[i])
          for _, type in ipairs(types) do
            if card.sub_type == type and player:getEquipment(type) == nil then
              table.insertIfNeed(cards, room.draw_pile[i])
            end
          end
        end
        if #cards > 0 then
          local equip = cards[math.random(1, #cards)]
          room:moveCards({
            ids = {equip},
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
          })
          room:useCard({
            from = player.id,
            tos = {{player.id}},
            card = Fk:getCardById(equip),
          })
        end
      end
    elseif choice == "zunwei3" then
      room:recover{who = player, num = math.min(player:getLostHp(), target.hp - player.hp), skillName = self.name}
    end
    room:setPlayerMark(player, choice, 1)
  end,
}
guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)
Fk:loadTranslationTable{
  ["guozhao"] = "郭照",
  ["pianchong"] = "偏宠",
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，2.你每失去一张黑色牌时摸一张红色牌。",
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",
  ["@pianchong"] = "偏宠",
  ["zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["zunwei2"] = "使用装备至与其相同",
  ["zunwei3"] = "回复体力至与其相同",
}

--陆郁生 2021.3.20
--樊玉凤 2021.4.16
--赵忠 曹嵩 宗预2021.4.28
--夏侯杰 阮瑀 张邈 唐姬 梁兴
local liangxing = General(extension, "liangxing", "qun", 4)
local lulve = fk.CreateTriggerSkill{
  name = "lulve",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return (#p.player_cards[Player.Hand] >= #player.player_cards[Player.Hand] or p:isKongcheng()) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (#p.player_cards[Player.Hand] < #player.player_cards[Player.Hand] and not p:isKongcheng()) end),
      function(p) return p.id end),
      1, 1, "#lulve-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, {"lulve_give", "lulve_slash"}, self.name)
    if choice == "lulve_give" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to:getCardIds(Player.Hand))
      room:obtainCard(player.id, dummy, false, fk.ReasonGive)
      player:turnOver()
    else
      to:turnOver()
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
        room:useCard({
          card = slash,
          from = to.id,
          tos = {{player.id}},
        })
    end
  end,
}
local zhuixi = fk.CreateTriggerSkill{
  name = "zhuixi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and data.to and ((data.from.faceup and not data.to.faceup) or (not data.from.faceup and data.to.faceup))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
liangxing:addSkill(lulve)
liangxing:addSkill(zhuixi)
Fk:loadTranslationTable{
  ["liangxing"] = "梁兴",
  ["lulve"] = "掳掠",
  [":lulve"] = "出牌阶段开始时，你可以令一名有手牌且手牌数小于你的其他角色选择一项：1.将所有手牌交给你，然后你翻面；2.翻面，然后视为对你使用一张【杀】。",
  ["zhuixi"] = "追袭",
  [":zhuixi"] = "锁定技，当你对其他角色造成伤害时，或当你受到其他角色造成的伤害时，若你与其翻面状态不同，此伤害+1。",
  ["#lulve-choose"] = "掳掠：你可以令一名有手牌且手牌数小于你的其他角色选择一项",
}
--牛金 段煨 张横2021.7.18
local duanwei = General(extension, "duanwei", "qun", 4)
local langmie = fk.CreateTriggerSkill{
  name = "langmie",
  anim_type = "control",
  events = {fk.EventPhaseEnd, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) and player.phase == Player.NotActive then
      if event == fk.EventPhaseEnd then
        if target.phase == Player.Play then
          for _, mark in ipairs(target:getMarkNames()) do
            if string.find(mark, "langmie_use") and target:getMark(mark) > 1 then
              return true
            end
          end
        end
      else
        return target.phase == Player.Finish and target:getMark("langmie_damage-turn") > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      return room:askForSkillInvoke(player, self.name)
    else
      return #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#langmie-cost") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      player:drawCards(1, self.name)
    else
      player.room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.CardUsing, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name, true) and target.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(target, "langmie_use_"..data.card:getTypeString().."-turn", 1)
    else
      room:addPlayerMark(target, "langmie_damage-turn", 1)
    end
  end,
}
duanwei:addSkill(langmie)
Fk:loadTranslationTable{
  ["duanwei"] = "段煨",
  ["langmie"] = "狼灭",
  [":langmie"] = "其他角色的出牌阶段结束时，若其本阶段使用过至少两张相同类型的牌，你可以摸一张牌；其他角色的结束阶段，若其本回合造成过至少2点伤害，你可以弃置一张牌，对其造成1点伤害。",
  ["#langmie-cost"] = "狼灭：你可以弃置一张牌，对其造成1点伤害",
}

local zhangheng = General(extension, "zhangheng", "qun", 8)
local liangjue = fk.CreateTriggerSkill{
  name = "liangjue",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.hp > 1 then
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
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      self.dangzai_tos = {}
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Judge] > 0 then
          for _, j in ipairs(p.player_cards[Player.Judge]) do
            if not player:hasDelayedTrick(Fk:getCardById(j).name) then
              table.insertIfNeed(self.dangzai_tos, p.id)
              break
            end
          end
        end
      end
      return #self.dangzai_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.dangzai_tos, 1, 1, "#dangzai-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local ids = {}
    for _, j in ipairs(to.player_cards[Player.Judge]) do
      if not player:hasDelayedTrick(Fk:getCardById(j).name) then
        table.insert(ids, j)
      end
    end
    room:fillAG(player, ids)
    local id = room:askForAG(player, ids, true, self.name)
    room:closeAG(player)
    room:moveCards({
      from = to.id,
      ids = {id},
      to = player.id,
      toArea = Card.PlayerJudge,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
  end,
}
zhangheng:addSkill(liangjue)
zhangheng:addSkill(dangzai)
Fk:loadTranslationTable{
  ["zhangheng"] = "张横",
  ["liangjue"] = "粮绝",
  [":liangjue"] = "锁定技，当有黑色牌进入或者离开你的判定区或装备区时，若你的体力值大于1，你失去1点体力，然后摸两张牌。",
  ["dangzai"] = "挡灾",
  [":dangzai"] = "出牌阶段开始时，你可以将一名其他角色判定区里的一张牌移至你的判定区。",
  ["#dangzai-choose"] = "挡灾：你可以将一名其他角色判定区里的一张牌移至你的判定区",
}
--杨婉 2021.8.23
--董承 胡车儿 2021.9.19
local dongcheng = General(extension, "ty__dongcheng", "qun", 4)
local xuezhao = fk.CreateActiveSkill{
  name = "xuezhao",
  anim_type = "offensive",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function ()
    return Self.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected < Self.maxHp and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for _, to in ipairs(effect.tos) do
      local p = room:getPlayerById(to)
      if p:isNude() then
        room:addPlayerMark(p, "xuezhao-phase", 1)
      else
        local card = room:askForCard(p, 1, 1, true, self.name, true, ".", "#xuezhao-give")
        if #card > 0 then
          room:obtainCard(player, Fk:getCardById(card[1]), true, fk.ReasonGive)
          p:drawCards(1, self.name)
          room:addPlayerMark(player, "xuezhao_add-turn", 1)
        else
          room:addPlayerMark(p, "xuezhao-phase", 1)
        end
      end
    end
  end,
}
local xuezhao_targetmod = fk.CreateTargetModSkill{
  name = "#xuezhao_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("xuezhao_add-turn")
    end
  end,
}
local xuezhao_record = fk.CreateTriggerSkill{
  name = "#xuezhao_record",

  refresh_events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return p:getMark("xuezhao-phase") > 0 end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("xuezhao-phase") > 0 end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
xuezhao:addRelatedSkill(xuezhao_targetmod)
xuezhao:addRelatedSkill(xuezhao_record)
dongcheng:addSkill(xuezhao)
Fk:loadTranslationTable{
  ["ty__dongcheng"] = "董承",
  ["xuezhao"] = "血诏",
  [":xuezhao"] = "出牌阶段限一次，你可以弃置一张手牌并选择至多X名其他角色（X为你的体力上限），然后令这些角色依次选择是否交给你一张牌，若选择是，该角色摸一张牌且你本阶段使用【杀】的次数上限+1；若选择否，该角色本阶段不能响应你使用的牌。",
  ["#xuezhao-give"] = "血诏：交出一张牌并摸一张牌使其使用【杀】次数上限+1；或本阶段不能响应其使用的牌",
}
--邹氏 2021.9.23
Fk:loadTranslationTable{
  ["zoushi"] = "邹氏",
  ["huoshui"] = "祸水",
  [":huoshui"] = "准备阶段，你可以令至多X名角色（X为你已损失的体力值，至少为1且至多为3）按你选择的顺序依次执行一项：1.本回合所有非锁定技失效；2.交给你一张手牌；3.弃置装备区里的所有牌。",
  ["qingcheng"] = "倾城",
  [":qingcheng"] = "出牌阶段限一次，你可以与一名手牌数不大于你的男性角色交换手牌。",
}
--曹安民 张虎 冯熙 丘力居 何晏 糜芳傅士仁2021.9.24
--潘淑2021.10.21
Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；不小于2，你至多可以弃置场上的一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。",
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌时，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为：你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",
}
--南华 周夷 吕玲绮 杜夫人2021.11.3
Fk:loadTranslationTable{
  ["ty__nanhualaoxian"] = "南华老仙",
  ["gongxiu"] = "共修",
  [":gongxiu"] = "结束阶段，若你本回合发动过“经合”，你可以选择一项：1.令所有本回合因“经合”获得过技能的角色摸一张牌；2.令所有本回合未因“经合”获得过技能的其他角色弃置一张手牌。",
  ["jinghe"] = "经合",
  [":jinghe"] = "每回合限一次，出牌阶段，你可展示至多四张牌名各不同的手牌，选择等量的角色，从“写满技能的天书”随机展示四个技能，这些角色依次选择并获得其中一个，直到你下回合开始。",
  ["yinbingn"] = "阴兵",
  [":yinbingn"] = "锁定技，你使用【杀】即将造成的伤害视为失去体力。当其他角色失去体力后，你摸一张牌。",
  ["huoqi"] = "活气",
  [":huoqi"] = "出牌阶段限一次，你可以弃置一张牌，然后令一名体力最少的角色回复1点体力并摸一张牌。",
  ["guizhu"] = "鬼助",
  [":guizhu"] = "每回合限一次，当一名角色进入濒死状态时，你可以摸两张牌。",
  ["xianshou"] = "仙授",
  [":xianshou"] = "出牌阶段限一次，你可以令一名角色摸一张牌。若其未受伤，则多摸一张牌。",
  ["lundao"] = "论道",
  [":lundao"] = "当你受到伤害后，若伤害来源的手牌多于你，你可以弃置其一张牌；若伤害来源的手牌数少于你，你摸一张牌。",
  ["guanyue"] = "观月",
  [":guanyue"] = "结束阶段，你可以观看牌堆顶的两张牌，然后获得其中一张，将另一张置于牌堆顶。",
  ["yanzheng"] = "言政",
  [":yanzheng"] = "准备阶段，若你的手牌数大于1，你可以选择一张手牌并弃置其余的牌，然后对至多等于弃置牌数的角色各造成1点伤害。",
}

local zhouyi = General(extension, "zhouyi", "wu", 3, 3, General.Female)
local zhukou = fk.CreateTriggerSkill{
  name = "zhukou",
  anim_type = "offensive",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target == player then
      if event == fk.Damage then
        return player.room.current.phase == Player.Play and player:usedSkillTimes(self.name) == 0
      else
        return player.phase == Player.Finish and player:getMark("zhukou-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      return room:askForSkillInvoke(player, self.name)
    else
      local targets = room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
        return p.id end), 2, 2, "#zhukou-choose", self.name, true)
      if #targets == 2 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      player:drawCards(player:getMark("@zhukou-turn"), self.name)
      room:addPlayerMark(player, "zhukou-turn", 1)
      room:setPlayerMark(player, "@zhukou-turn", 0)
    else
      for _, p in ipairs(self.cost_data) do
        room:damage{
          from = player,
          to = room:getPlayerById(p),
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("zhukou-turn") == 0 and player.phase < Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhukou-turn", 1)
  end,
}
local mengqing = fk.CreateTriggerSkill{
  name = "mengqing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
     player.phase == Player.Start then
      local n = 0
      for _, p in ipairs(player.room:getAlivePlayers()) do
        if p:isWounded() then
          n = n + 1
        end
      end
      if n > player.hp then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 3)
    room:recover({
      who = player,
      num = 3,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-zhukou|yuyun", nil)
  end,
}
local yuyun = fk.CreateTriggerSkill{
  name = "yuyun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chs = {"loseHp"}
    if player.maxHp > 1 then table.insert(chs, "loseMaxHp") end
    local chc = room:askForChoice(player, chs, self.name)
    if chc == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, self.name)
    end
    local choices = {"Cancel", "yuyun1", "yuyun2", "yuyun3"}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isNude() or #p.player_cards[Player.Hand] < p.maxHp then
        if not p:isNude() then
          table.insertIfNeed(choices, "yuyun4")
        end
        if #p.player_cards[Player.Hand] < p.maxHp then
          table.insertIfNeed(choices, "yuyun5")
        end
        break
      end
    end
    local n = 1 + player:getLostHp()
    for i = 1, n, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "yuyun1" then
        player:drawCards(2, self.name)
      elseif choice == "yuyun2" then
        local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id end), 1, 1, "#yuyun2-choose", self.name)[1]
        room:damage{
          from = player,
          to = room:getPlayerById(to),
          damage = 1,
          skillName = self.name,
        }
        room:addPlayerMark(room:getPlayerById(to), "yuyun2-turn", 1)
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, "yuyun3-turn", 1)
      elseif choice == "yuyun4" then
        local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not p:isAllNude() end), function(p) return p.id end), 1, 1, "#yuyun4-choose", self.name)[1]
        local id = room:askForCardChosen(player, room:getPlayerById(to), "hej", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      elseif choice == "yuyun5" then
        local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
          return #p.player_cards[Player.Hand] < math.min(p.maxHp, 5) end), function(p) return p.id end), 1, 1, "#yuyun5-choose", self.name)[1]
        local p = room:getPlayerById(to)
        p:drawCards(math.min(p.maxHp, 5) - #p.player_cards[Player.Hand], self.name)
      end
    end
  end,

  refresh_events = {fk.TargetSpecifying},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if player.room:getPlayerById(id):getMark("yuyun2-turn") > 0 then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:addCardUseHistory(data.card.trueName, -1)
  end
}
local yuyun_distance = fk.CreateDistanceSkill{
  name = "#yuyun_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      if to:getMark("yuyun2-turn") > 0 then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
local yuyun_maxcards = fk.CreateMaxCardsSkill{
  name = "#yuyun_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) and player:getMark("yuyun3-turn") > 0 then
      return 999
    end
    return 0
  end,
}
yuyun:addRelatedSkill(yuyun_distance)
yuyun:addRelatedSkill(yuyun_maxcards)
zhouyi:addSkill(zhukou)
zhouyi:addSkill(mengqing)
Fk:addSkill(yuyun)
Fk:loadTranslationTable{
  ["zhouyi"] = "周夷",
  ["zhukou"] = "逐寇",
  [":zhukou"] = "当你于每回合的出牌阶段第一次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，你可以对两名其他角色各造成1点伤害。",
  ["mengqing"] = "氓情",
  [":mengqing"] = "觉醒技，准备阶段，若已受伤的角色数大于你的体力值，你加3点体力上限并回复3点体力，失去〖逐寇〗，获得〖玉殒〗。",
  ["yuyun"] = "玉陨",
  [":yuyun"] = "锁定技，出牌阶段开始时，你失去1点体力或体力上限（你的体力上限不能以此法被减至1以下），然后选择X+1项（X为你已损失的体力值）：1.摸两张牌；2.对一名其他角色造成1点伤害，然后本回合对其使用【杀】无距离和次数限制；3.本回合没有手牌上限；4.获得一名其他角色区域内的一张牌；5.令一名其他角色将手牌摸至体力上限（最多摸至5）。",
  ["@zhukou-turn"] = "逐寇",
  ["#zhukou-choose"] = "逐寇：你可以对两名其他角色各造成1点伤害",
  ["yuyun1"] = "摸两张牌",
  ["yuyun2"] = "对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["yuyun3"] = "本回合没有手牌上限",
  ["yuyun4"] = "获得一名其他角色区域内的一张牌",
  ["yuyun5"] = "令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["#yuyun2-choose"] = "玉陨：对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["#yuyun4-choose"] = "玉陨：获得一名其他角色区域内的一张牌",
  ["#yuyun5-choose"] = "玉陨：令一名其他角色将手牌摸至体力上限（最多摸至5）",
}

local lvlingqi = General(extension, "lvlingqi", "qun", 4, 4, General.Female)
local guowu = fk.CreateTriggerSkill{
  name = "guowu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    local card = {getCardByPattern(room, "slash", room.discard_pile)}
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if #types > 1 then
      room:addPlayerMark(player, "guowu2-phase", 1)
    end
    if #types > 2 then
      room:addPlayerMark(player, "guowu3-phase", 1)
    end
  end,

  refresh_events = {fk.TargetSpecifying},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("guowu3-phase") > 0 and data.firstTarget and
      data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) then  --TODO: target filter
        table.insertIfNeed(targets, p.id)
      end
    end
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, targets, 1, 2, "#guowu-choose", self.name, true)
      if #tos > 0 then
        TargetGroup:pushTargets(data.targetGroup, tos)  --TODO: sort by action order
      end
    end
  end,
}
local guowu_targetmod = fk.CreateTargetModSkill{
  name = "#guowu_targetmod",
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill(self.name) and player:getMark("guowu2-phase") > 0 then
      return 999
    end
  end,
  extra_target_func = function(self, player, skill)
    if player:hasSkill(self.name) and player:getMark("guowu3-phase") > 0 and skill.trueName == "slash_skill" then
      --(card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick)  FIXME: fire_attack!
      return 2
    end
  end,
}
local zhuangrong = fk.CreateTriggerSkill{
  name = "zhuangrong",
  frequency = Skill.Wake,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
     data.to == Player.NotActive and
    (#player.player_cards[Player.Hand] == 1 or player.hp == 1)
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
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    room:handleAddLoseSkills(player, "shenwei|wushuang", nil)
  end,
}
local shenwei = fk.CreateTriggerSkill{  --TODO: move this!
  name = "shenwei",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local shenwei_maxcards = fk.CreateMaxCardsSkill{
  name = "#shenwei_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return 2
    end
  end,
}
guowu:addRelatedSkill(guowu_targetmod)
shenwei:addRelatedSkill(shenwei_maxcards)
lvlingqi:addSkill(guowu)
lvlingqi:addSkill(zhuangrong)
Fk:addSkill(shenwei)
Fk:loadTranslationTable{
  ["lvlingqi"] = "吕玲绮",
  ["guowu"] = "帼武",
  [":guowu"] = "出牌阶段开始时，你可以展示所有手牌，若包含的类别数：不小于1，你从弃牌堆中获得一张【杀】；不小于2，你本阶段使用牌无距离限制；不小于3，你本阶段使用【杀】或普通锦囊牌可以多指定两个目标。",
  ["zhuangrong"] = "妆戎",
  [":zhuangrong"] = "觉醒技，一名角色的回合结束时，若你的手牌数或体力值为1，你减1点体力上限并将体力值回复至体力上限，然后将手牌摸至体力上限。若如此做，你获得技能〖神威〗和〖无双〗。",
  ["shenwei"] = "神威",
  [":shenwei"] = "锁定技，摸牌阶段，你额外摸两张牌；你的手牌上限+2。",  --TODO: this should be moved to SP!
  ["#guowu-choose"] = "帼武：可以多指定两个目标",
}

local dufuren = General(extension, "dufuren", "wei", 3, 3, General.Female)
local yise = fk.CreateTriggerSkill{
  name = "yise",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          self.yise_to = move.to
          for _, info in ipairs(move.moveInfo) do
            self.yise_color = Fk:getCardById(info.cardId).color
            if self.yise_color == Card.Red then
              return player.room:getPlayerById(move.to):isWounded()
            else
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.yise_to)
    if self.yise_color == Card.Red then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif self.yise_color == Card.Black then
      room:addPlayerMark(to, "yise_damage", 1)
    end
  end,
}
local yise_record = fk.CreateTriggerSkill{
  name = "#yise_record",
  anim_type = "offensive",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("yise_damage") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + target:getMark("yise_damage")
    player.room:setPlayerMark(target, "yise_damage", 0)
  end,
}
local shunshi = fk.CreateTriggerSkill{
  name = "shunshi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not player:isNude() then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
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
    room:obtainCard(self.cost_data[1], self.cost_data[2], false, fk.ReasonGive)
    room:addPlayerMark(player, self.name, 1)
  end,

  refresh_events = {fk.DrawNCards, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if player:getMark(self.name) > 0 then
      if event == fk.DrawNCards then
        return true
      else
        return data.to == Player.NotActive
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + player:getMark("shunshi")
    else
      player.room:setPlayerMark(player, self.name, 0)
    end
  end,
}
local shunshi_targetmod = fk.CreateTargetModSkill{
  name = "#shunshi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("shunshi") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("shunshi")
    end
  end,
}
local shunshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#shunshi_maxcards",
  correct_func = function(self, player)
    return player:getMark("shunshi")
  end,
}
yise:addRelatedSkill(yise_record)
shunshi:addRelatedSkill(shunshi_targetmod)
shunshi:addRelatedSkill(shunshi_maxcards)
dufuren:addSkill(yise)
dufuren:addSkill(shunshi)
Fk:loadTranslationTable{
  ["dufuren"] = "杜夫人",
  ["yise"] = "异色",
  [":yise"] = "当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。",
  ["shunshi"] = "顺世",
  [":shunshi"] = "准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你：摸牌阶段多摸一张牌、出牌阶段使用的【杀】次数上限+1、手牌上限+1。",
  ["#shunshi-cost"] = "顺世：你可以交给一名其他角色一张牌，然后直到你的回合结束获得效果",
}
--荀谌 张宁 万年公主 童渊 刘永2021.12.1
local wanniangongzhu = General(extension, "wanniangongzhu", "qun", 3, 3, General.Female)
local zhenge = fk.CreateTriggerSkill{
  name = "zhenge",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local p = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#zhenge-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:getMark("@zhenge") <5 then
      room:addPlayerMark(to, "@zhenge", 1)
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(to)) do
      if to:inMyAttackRange(p) then  --TODO: target filter
        if p ~= player then
          table.insert(targets, p.id)
        end
      else
        return
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhenge-slash", self.name, true)
    if #tos > 0 then
      local slash = Fk:cloneCard("slash")
      room:useCard({
        card = slash,
        from = to.id,
        tos = {{tos[1]}},
        extraUse = true,
      })
    end
  end,
}
local zhenge_attackrange = fk.CreateAttackRangeSkill{
  name = "#zhenge_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@zhenge")
  end,
}
local xinghan = fk.CreateTriggerSkill{
  name = "xinghan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target.dead and target:getMark("@zhenge") > 0 and data.card ~= nil and data.card.trueName == "slash" and target:getMark("xinghan-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(target, "xinghan-turn", 1)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
        player:drawCards(math.min(target:getAttackRange(), 5))
        return
      end
    end
    player:drawCards(1, self.name)
  end
}
zhenge:addRelatedSkill(zhenge_attackrange)
wanniangongzhu:addSkill(zhenge)
wanniangongzhu:addSkill(xinghan)
Fk:loadTranslationTable{
  ["wanniangongzhu"] = "万年公主",
  ["zhenge"] = "枕戈",
  [":zhenge"] = "准备阶段，你可以令一名角色的攻击范围+1（加值至多为5），然后若其他角色都在其的攻击范围内，你可以令其视为对另一名你选择的角色使用一张【杀】。",
  ["xinghan"] = "兴汉",
  [":xinghan"] = "锁定技，当〖枕戈〗选择过的角色使用【杀】造成伤害后，若此【杀】是本回合的第一张【杀】，你摸一张牌。若你的手牌数不是全场唯一最多的，则改为摸X张牌（X为该角色的攻击范围且最多为5）。",
  ["@zhenge"] = "枕戈",
  ["#zhenge-choose"] = "枕戈：你可以令一名角色的攻击范围+1（至多+5）",
  ["#zhenge-slash"] = "枕戈：你可以选择另一名角色，视为其对此角色使用【杀】",
}
--嵇康 曹不兴2021.12.3
--陈登2021.12.15
--曹金玉 滕公主2022.1.22
local caojinyu = General(extension, "caojinyu", "wei", 3, 3, General.Female)
local yuqi = fk.CreateTriggerSkill{
  name = "yuqi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player.dead and not target.dead and
    (target == player or player:distanceTo(target) <= player:getMark("yuqi1")) and player:getMark("yuqi-turn") < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "yuqi-turn", 1)
    --local card_ids = room:getNCards(player:getMark("yuqi2"))

    --FIXME: askForCardsChosen? or yiji?
    local n1, n2 = 0, 0
    if player:getMark("yuqi2") >= player:getMark("yuqi4") then
      n2 = player:getMark("yuqi4")
      n1 = math.min(player:getMark("yuqi3"), player:getMark("yuqi2") - player:getMark("yuqi4"))
    else
      n2 = player:getMark("yuqi2")
    end
    target:drawCards(n1)
    player:drawCards(n2)
  end,

  refresh_events = {fk.GameStart},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yuqi2", 3)
    room:setPlayerMark(player, "yuqi3", 1)
    room:setPlayerMark(player, "yuqi4", 1)
    room:setPlayerMark(player, "@" .. self.name, string.format("%d-%d-%d-%d", 0, 3, 1, 1))
  end,
}
local function AddYuqi(player, skillName, num)
  local room = player.room
  local choices = {}
  for i = 1, 4, 1 do
    if player:getMark("yuqi" .. tostring(i)) < 5 then
      table.insert(choices, "yuqi" .. tostring(i))
    end
  end
  if #choices > 0 then
    local choice = room:askForChoice(player, choices, skillName)
    local x = player:getMark(choice)
    if x + num < 6 then
      x = x + num
    else
      x = 5
    end
    room:setPlayerMark(player, choice, x)
    room:setPlayerMark(player, "@yuqi", string.format("%d-%d-%d-%d",
    player:getMark("yuqi1"),
    player:getMark("yuqi2"),
    player:getMark("yuqi3"),
    player:getMark("yuqi4")))
  end
end
local shanshen = fk.CreateTriggerSkill{
  name = "shanshen",
  anim_type = "control",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    AddYuqi(player, self.name, 2)
    if target:getMark(self.name) == 0 and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name,
      }
    end
  end,
  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name) and data.to:getMark(self.name) == 0
  end,
  on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(data.to, self.name, 1)
  end,
}
local xianjing = fk.CreateTriggerSkill{
  name = "xianjing",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      for i = 1, 4, 1 do
        if player:getMark("yuqi" .. tostring(i)) < 5 then
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    AddYuqi(player, self.name, 1)
    if not player:isWounded() then
      AddYuqi(player, self.name, 1)
    end
  end,
}
caojinyu:addSkill(yuqi)
caojinyu:addSkill(shanshen)
caojinyu:addSkill(xianjing)
Fk:loadTranslationTable{
  ["caojinyu"] = "曹金玉",
  ["yuqi"] = "隅泣",
  [":yuqi"] = "当有角色受到伤害后，若你与其距离0或者更少，你可以观看牌堆顶的三张牌，将其中至多一张交给受伤角色，至多一张自己获得，剩余的牌放回牌堆顶。（每回合限触发2次）",
  ["shanshen"] = "善身",
  [":shanshen"] = "当有角色死亡时，你可令“隅泣”中的一个数字+2（单项不能超过5）。然后若你没有对死亡角色造成过伤害，你回复1点体力。",
  ["xianjing"] = "娴静",
  [":xianjing"] = "准备阶段，你可令“隅泣”中的一个数字+1（单项不能超过5）。若你满体力值，则再令“隅泣”中的一个数字+1。",
  ["@yuqi"] = "隅泣",
  ["yuqi1"] = "距离",
  ["yuqi2"] = "观看牌数",
  ["yuqi3"] = "交给受伤角色牌数",
  ["yuqi4"] = "自己获得牌数",
}
--王桃 王悦 庞德公2022.2.28
--吴范 李采薇 祢衡2022.3.5
--孙翊2022.3.24
--千里走单骑：均未上线 2022.3.24
--赵嫣
--严夫人 郝萌 马日磾2022.4.25
--冯妤 蔡瑁张允 高览 朱灵2022.5.20
--曹髦 吉平 阎柔 来莺儿 神姜维2022.6.11
--local godjiangwei = General(extension, "godjiangwei", "god", 4)
local tianren = fk.CreateTriggerSkill {
  name = "tianren",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      self.tianren_num = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then  --TODO: REASON!!!
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeBasic or (card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick) then
              self.tianren_num = self.tianren_num + 1
            end
          end
        end
      end
      return self.tianren_num > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for i = 1, self.tianren_num, 1 do
      room:addPlayerMark(player, "@tianren", 1)
      if player:getMark("@tianren") >= player.maxHp then
        room:removePlayerMark(player, "@tianren", player.maxHp)
        room:changeMaxHp(player, 1)
        player:drawCards(2)
      end
    end
  end,
}
--godjiangwei:addSkill(tianren)
Fk:loadTranslationTable{
  ["godjiangwei"] = "神姜维",
  ["tianren"] = "天任",
  [":tianren"] = "锁定技，当一张基本牌或普通锦囊牌不是因使用而置入弃牌堆后，你获得1个“天任”标记，然后若“天任”标记数不小于X，你移去X个“天任”标记，加1点体力上限并摸两张牌（X为你的体力上限）。",
  ["jiufa"] = "九伐",
  [":jiufa"] = "当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张。",
  ["pingxiang"] = "平襄",
  [":pingxiang"] = "限定技，出牌阶段，若你的体力上限大于9，你可以减9点体力上限，然后你视为使用至多九张火【杀】。若如此做，你失去技能〖九伐〗且本局游戏内你的手牌上限等于体力上限。",
}
--骆统 张媱 张勋 滕胤 神马超 黄承彦2022.6.15
--管宁2022.7.2
--刘虞 曹华 夏侯令女 秦宜禄 黄祖 羊祜2022.7.18
--张嫙 2022.8.1
local zhangxuan = General(extension, "zhangxuan", "wu", 4, 4, General.Female)
local tongli = fk.CreateTriggerSkill{
  name = "tongli",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark(self.name) == 0 then
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      return #suits == player:getMark("@tongli-turn")
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, player:getMark("@tongli-turn"))
  end,

  refresh_events = {fk.PreCardUse, fk.PreCardRespond, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.PreCardUse or event == fk.PreCardRespond then
        return player.phase == Player.Play
      else
        return player:getMark(self.name) > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardUse or event == fk.PreCardRespond then
      room:addPlayerMark(player, "@tongli-turn", 1)
    else
      local n = player:getMark(self.name)
      local use = {
        from = data.from,
        card = Fk:cloneCard(data.card.name),
        tos = data.tos,
        nullifiedTargets = data.nullifiedTargets,
      }
      for i = 1, n, 1 do  --TODO: modify this to tenyear's effect
        if not player.dead then
          room:doCardUseEffect(use)
        end
      end
      room:setPlayerMark(player, self.name, 0)
    end
  end,
}
local shezang = fk.CreateTriggerSkill{
  name = "shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (target == player or player.phase ~= Player.NotActive) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    local cards = {}
    while #suits > 0 do
      local pattern = suits[math.random(1, #suits)]
      table.removeOne(suits, pattern)
      table.insert(cards, getCardByPattern(room, ".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
zhangxuan:addSkill(tongli)
zhangxuan:addSkill(shezang)
Fk:loadTranslationTable{
  ["zhangxuan"] = "张嫙",
  ["tongli"] = "同礼",
  [":tongli"] = "出牌阶段，当你使用牌指定目标后，若你手牌中的花色数等于你此阶段已使用牌的张数，你可令此牌效果额外执行X次（X为你手牌中的花色数）。",
  ["shezang"] = "奢葬",
  [":shezang"] = "每轮限一次，当你或你回合内有角色进入濒死状态时，你可以从牌堆获得不同花色的牌各一张。",
  ["@tongli-turn"] = "同礼",
}
--一将2022：李婉 诸葛尚 陆凯 轲比能
--王昶 冯方2022.8.27
--卞喜2022.9.6
--全惠解 胡昭 魏吕旷吕翔 黄权 孙茹 赵昂2022.9.17

Fk:loadTranslationTable{
  ["huanquan"] = "全惠解",
  ["huishu"] = "慧淑",
  [":huishu"] = "摸牌阶段结束时，你可以摸3张牌然后弃置1张手牌。若如此做，你本回合弃置超过2张牌时，从弃牌堆中随机获得一张锦囊牌。",
  ["yishu"] = "易数",
  [":yishu"] = "锁定技，当你于出牌阶段外失去牌后，〖慧淑〗中最小的一个数字+2且最大的一个数字-1。",
  ["ligong"] = "离宫",
  [":ligong"] = "觉醒技，准备阶段，若〖慧淑〗有数字达到5，你加1点体力上限并回复1点体力，失去〖慧淑〗和〖易数〗，然后从随机四个已开通的吴国女性武将中选择两个技能获得（若选择不获得技能则不失去〖慧淑〗并摸两张牌）。",
}

local huangquan = General(extension, "ty__huangquan", "shu", 3)
local quanjian = fk.CreateActiveSkill{
  name = "quanjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("quanjian1-turn") == 0 or player:getMark("quanjian2-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and to_select ~= Self.id then
      if Self:getMark("quanjian2-turn") == 0 then
        return true
      else
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if Fk:currentRoom():getPlayerById(to_select):inMyAttackRange(p) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    local choices = {}
    if player:getMark("quanjian1-turn") == 0 and #targets > 0 then
      table.insert(choices, "quanjian1")
    end
    if player:getMark("quanjian2-turn") == 0 then
      table.insert(choices, "quanjian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:addPlayerMark(player, choice.."-turn", 1)
    local to
    if choice == "quanjian1" then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#quanjian-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = targets[math.random(1, #targets)]
      end
      room:doIndicate(target.id, {to})
    end
    local choices2 = {"quanjian_cancel"}
    if choice == "quanjian1" then
      table.insert(choices2, 1, "quanjian_damage")
    else
      table.insert(choices2, 1, "quanjian_draw")
    end
    local choice2 = room:askForChoice(target, choices2, self.name)
    if choice2 == "quanjian_damage" then
      room:damage{
        from = target,
        to = room:getPlayerById(to),
        damage = 1,
        skillName = self.name,
      }
    elseif choice2 == "quanjian_draw" then
      if #target.player_cards[Player.Hand] < math.min(target:getMaxCards(), 5) then
        target:drawCards(math.min(target:getMaxCards(), 5) - #target.player_cards[Player.Hand])
      end
      if #target.player_cards[Player.Hand] > target:getMaxCards() then
        local n = #target.player_cards[Player.Hand] - target:getMaxCards()
        room:askForDiscard(target, n, n, false, self.name, false)
      end
      room:addPlayerMark(target, "quanjian_prohibit-turn", 1)
    else
      room:addPlayerMark(target, "quanjian_damage-turn", 1)
    end
  end,
}
local quanjian_prohibit = fk.CreateProhibitSkill{
  name = "#quanjian_prohibit",
  is_prohibited = function()
  end,
  prohibit_use = function(self, player, card)
    return player:getMark("quanjian_prohibit-turn") > 0
  end,
}
local quanjian_record = fk.CreateTriggerSkill{
  name = "#quanjian_record",
  anim_type = "offensive",

  refresh_events = {fk.DamageCaused, fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("quanjian_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + target:getMark("quanjian_damage-turn")
    player.room:setPlayerMark(target, "quanjian_damage-turn", 0)
  end,
}
local tujue = fk.CreateTriggerSkill{
  name = "tujue",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p) return p.id end), 1, 1, "#tujue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    dummy:addSubcards(player.player_cards[Player.Equip])
    local n = #dummy.subcards
    room:obtainCard(self.cost_data, dummy, false, fk.ReasonGive)
    room:recover({
      who = player,
      num = math.min(n, player.maxHp - player.hp),
      recoverBy = player,
      skillName = self.name
    })
    player:drawCards(n, self.name)
  end,
}
quanjian:addRelatedSkill(quanjian_prohibit)
quanjian:addRelatedSkill(quanjian_record)
huangquan:addSkill(quanjian)
huangquan:addSkill(tujue)
Fk:loadTranslationTable{
  ["ty__huangquan"] = "黄权",
  ["quanjian"] = "劝谏",
  [":quanjian"] = "出牌阶段每项限一次，你选择以下一项令一名其他角色选择是否执行：1. 对一名其攻击范围内你指定的角色造成1点伤害。2. 将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束。若其不执行，则其本回合下次受到的伤害+1。",
  ["tujue"] = "途绝",
  [":tujue"] = "限定技，当你处于濒死状态时，你可以将所有牌交给一名其他角色，然后你回复等量的体力值并摸等量的牌。",
  ["quanjian1"] = "对一名其攻击范围内你指定的角色造成1点伤害",
  ["quanjian2"] = "将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束",
  ["#quanjian-choose"] = "劝谏：选择一名其攻击范围内的角色",
  ["quanjian_damage"] = "对指定的角色造成1点伤害",
  ["quanjian_draw"] = "将手牌调整至手牌上限（最多摸到5张），不能使用手牌直到回合结束",
  ["quanjian_cancel"] = "不执行，本回合下次受到的伤害+1",
  ["#tujue-choose"] = "途绝：你可以将所有牌交给一名其他角色，然后回复等量的体力值并摸等量的牌",
}

local sunru = General(extension, "ty__sunru", "wu", 3, 3, General.Female)
local xiecui = fk.CreateTriggerSkill{
  name = "xiecui",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.from and not data.from.dead and data.from.phase ~= Player.NotActive and data.card then
      if data.from:getMark("xiecui-turn") == 0 then
        player.room:addPlayerMark(data.from, "xiecui-turn", 1)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if data.from.kingdom == "wu" and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(data.from, data.card, false)
      room:addPlayerMark(data.from, "AddMaxCards-turn", 1)
    end
  end,
}
local youxu = fk.CreateTriggerSkill{
  name = "youxu",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and data.to == Player.NotActive and #target.player_cards[Player.Hand] > target.hp and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(target), function(p)
      return p.id end), 1, 1, "#youxu-choose", self.name, false)[1]
    room:obtainCard(to, id, true, fk.ReasonGive)
    to = room:getPlayerById(to)
    if to:isWounded() then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p.hp < to.hp then
          return
        end
      end
    end
    room:recover({
      who = to,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,
}
sunru:addSkill(xiecui)
sunru:addSkill(youxu)
Fk:loadTranslationTable{
  ["ty__sunru"] = "孙茹",
  ["xiecui"] = "撷翠",
  [":xiecui"] = "当一名角色于其回合内使用牌首次造成伤害时，你可令此伤害+1。若该角色为吴势力角色，其获得此伤害牌且本回合手牌上限+1。",
  ["youxu"] = "忧恤",
  [":youxu"] = "一名角色回合结束时，若其手牌数大于体力值，你可以展示其一张手牌然后交给另一名角色。若获得牌的角色体力值全场最低，其回复1点体力。",
  ["#youxu-choose"] = "忧恤：选择获得这张牌的角色",
}
--牛辅 蔡阳2022.9.24
--张奋2022.9.29
--杜夔2022.10.9
--尹夫人2022.10.21
--管亥2022.11.3
--刘徽 陈珪 胡班2022.11.13
local chengui = General(extension, "chengui", "qun", 3)
local yingtu = fk.CreateTriggerSkill{
  name = "yingtu",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 then
      local room = player.room
      if room.current.phase == Player.Draw then return end
      for _, move in ipairs(data) do
        if move.to ~= nil and (move.from == nil or move.to ~= move.from) and move.toArea == Card.PlayerHand then
          local p = room:getPlayerById(move.to)
          if p:getNextAlive() == player or player:getNextAlive() == p then
            self.yingtu_to = p
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCardChosen(player, self.yingtu_to, "he", self.name)
    room:obtainCard(player.id, card, false, fk.ReasonPrey)
    local to
    if self.yingtu_to:getNextAlive() == player then
      to = player:getNextAlive()
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getNextAlive() == player then
          to = p
          break
        end
      end
    end
    local card = Fk:getCardById(room:askForCard(player, 1, 1, true, self.name, false, ".", "#yingtu-choose")[1])
    room:obtainCard(to.id, card, false, fk.ReasonGive)
    if card.type == Card.TypeEquip then
      room:useCard({
        from = to.id,
        tos = {{to.id}},
        card = card,
      })
    end
  end,
}
local congshi = fk.CreateTriggerSkill{
  name = "congshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card.type == Card.TypeEquip then
      local to = player.room:getPlayerById(data.tos[1][1])
      for _, p in ipairs(player.room:getOtherPlayers(to)) do
        if #p.player_cards[Player.Equip] > #to.player_cards[Player.Equip] then
          return
        end
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1)
  end,
}
chengui:addSkill(yingtu)
chengui:addSkill(congshi)
Fk:loadTranslationTable{
  ["chengui"] = "陈珪",
  ["yingtu"] = "营图",
  [":yingtu"] = "每回合限一次，当一名角色于当前回合的摸牌阶段外获得牌后，若其是你的上家或下家，你可以获得该角色的一张牌，然后交给你的下家或上家一张牌。若以此法给出的牌为装备牌，获得牌的角色使用之。",
  ["congshi"] = "从势",
  [":congshi"] = "锁定技，当一名角色使用一张装备牌结算结束后，若其装备区里的牌数为全场最多的，你摸一张牌。",
  ["#yingtu-choose"] = "营图：选择交给另一家的一张牌",
}
--王威 赵俨 雷薄 王烈2022.11.17
--丁尚涴
--卢弈 穆顺 神张飞 2022.12.17
local godzhangfei = General(extension, "godzhangfei", "god", 4)
local shencai = fk.CreateActiveSkill{
  name = "shencai",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1 + player:getMark("xunshi")
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
  end,
}
local shencai_record = fk.CreateTriggerSkill{
  name = "#shencai_record",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.TargetConfirmed, fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.Damaged then
        return target:getMark("@shencai_chi") > 0
      elseif event == fk.TargetConfirmed then
        return target:getMark("@shencai_zhang") > 0 and data.card.trueName == "slash"
      elseif event == fk.AfterCardsMove then
        self.shencai_target = nil
        for _, move in ipairs(data) do
          if move.skillName ~= "shencai" and move.from ~= nil and player.room:getPlayerById(move.from):getMark("@shencai_tu") > 0 then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                self.shencai_target = move.from
                return true
              end
            end
          end
        end
      elseif event == fk.EventPhaseStart then
        return (target:getMark("@shencai_liu") > 0 and target.phase == Player.Finish) or
          (target:getMark("@shencai_si") > #player.room.alive_players and target.phase == Player.NotActive)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:loseHp(target, data.damage, "shencai")
    elseif event == fk.TargetConfirmed then
      data.disresponsive = true
    elseif event == fk.AfterCardsMove then
      local to = room:getPlayerById(self.shencai_target)
      if not to:isKongcheng() then
        room:throwCard({table.random(to.player_cards[Player.Hand])}, "shencai", to, to)
      end
    elseif event == fk.EventPhaseStart then
      if target.phase == Player.Finish then
        target:turnOver()
      else
      room:killPlayer({who = target.id})
      end
    end
  end,

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and data.reason == "shencai"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local result = {}
    if table.contains({"peach", "analeptic", "silver_lion", "god_salvation"}, data.card.trueName) then
      table.insert(result, "@shencai_chi")
    end
    if data.card.sub_type == Card.SubtypeWeapon or data.card.name == "collateral" then
      table.insert(result, "@shencai_zhang")
    end
    if table.contains({"savage_assault", "archery_attack", "duel", "spear", "eight_diagram"}, data.card.trueName) then
      table.insert(result, "@shencai_tu")
    end
    if data.card.sub_type == Card.SubtypeDefensiveRide or data.card.sub_type == Card.SubtypeOffensiveRide or data.card.name == "snatch" or data.card.name == "supply_shortage" then
      table.insert(result, "@shencai_liu")
    end
    if #result == 0 then
      table.insert(result, "@shencai_si")
    end
    if result[1] ~= "@shencai_si" then
      for _, mark in ipairs({"@shencai_chi", "@shencai_zhang", "@shencai_tu", "@shencai_liu"}) do
        room:setPlayerMark(data.who, mark, 0)
      end
      room:obtainCard(player.id, data.card, true, fk.ReasonPrey)
    end
    for _, mark in ipairs(result) do
      room:addPlayerMark(data.who, mark, 1)
      if mark == "@shencai_si" and not data.who:isNude() then
        local card = room:askForCardChosen(player, target, "he", "shencai")
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
      end
    end
  end,
}
local shencai_maxcards = fk.CreateMaxCardsSkill {
  name = "#shencai_maxcards",
  correct_func = function(self, player)
    return -player:getMark("@shencai_si")
  end,
}
local xunshi = fk.CreateFilterSkill{
  name = "xunshi",
  card_filter = function(self, to_select, player)
    local names = {"savage_assault", "archery_attack", "amazing_grace", "god_salvation", "iron_chain"}
    return player:hasSkill(self.name) and table.contains(names, to_select.name)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", Card.NoSuit, to_select.number)  --TODO: no distance limit
    card.skillName = self.name
    return card
  end,
}
local xunshi_record = fk.CreateTriggerSkill{
  name = "#xunshi_record",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.suit == Card.NoSuit and data.tos ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(data.tos[1], p.id) then  --TODO: target filter
        table.insertIfNeed(targets, p.id)
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#xunshi-choose", self.name)
    self.cost_data = tos
    return true
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("xunshi") < 4 then
      player.room:addPlayerMark(player, "xunshi", 1)
    end
    player:addCardUseHistory(data.card.trueName, -1)
    if self.cost_data == nil then return end
    for _, p in ipairs(self.cost_data) do  --TODO: sort by action order
      table.insert(data.tos, {p})
    end
  end,
}
local xunshi_targetmod = fk.CreateTargetModSkill{
  name = "#xunshi_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill(self.name) and card ~= nil and card.color == Card.NoColor and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill(self.name) and card ~= nil and card.color == Card.NoColor then
      return 999
    end
  end,
}
shencai:addRelatedSkill(shencai_record)
shencai:addRelatedSkill(shencai_maxcards)
xunshi:addRelatedSkill(xunshi_record)
xunshi:addRelatedSkill(xunshi_targetmod)
godzhangfei:addSkill(shencai)
godzhangfei:addSkill(xunshi)
Fk:loadTranslationTable{
  ["godzhangfei"] = "神张飞",
  ["shencai"] = "神裁",
  [":shencai"] = "出牌阶段限一次，你可以令一名其他角色进行判定。若判定牌包含以下内容，你获得判定牌，其获得（已有标记则改为修改）对应标记：<br>"..
  "体力：“笞”标记，每次受到伤害后失去等量体力；<br>"..
  "武器：“杖”标记，无法响应【杀】；<br>"..
  "打出：“徒”标记，以此法外失去手牌后随机弃置一张手牌；<br>"..
  "距离：“流”标记，结束阶段将武将牌翻面；<br>"..
  "若判定牌不包含以上内容，该角色获得一个“死”标记且手牌上限减少其身上“死”标记个数。然后，你获得其区域内一张牌。“死”标记个数大于场上存活人数的角色回合结束时，其直接死亡。",
  ["xunshi"] = "巡使",
  [":xunshi"] = "锁定技，你的多目标锦囊牌均视为无色的【杀】。你使用无色牌无距离和次数限制且可以额外指定任意个目标，然后修改“神裁”的发动次数（每次修改次数+1，至多为5）。",
  ["#shencai_record"] = "神裁",
  ["@shencai_chi"] = "笞",
  ["@shencai_zhang"] = "杖",
  ["@shencai_tu"] = "徒",
  ["@shencai_liu"] = "流",
  ["@shencai_si"] = "死",
  ["#xunshi_record"] = "巡使",
  ["#xunshi-choose"] = "巡使：无距离限制且可以额外指定任意个目标",

  ["$shencai1"] = "我有三千炼狱，待汝万世轮回！",
  ["$shencai2"] = "纵汝王侯将相，亦须俯首待裁！",

  ["$xunshi1"] = "秉身为正，辟易万邪！",
  ["$xunshi2"] = "巡御两界，路寻不平！",
}
--李异谢旌 袁姬 庞会 赵直 陈矫 朱建平 2022.12.22
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["mengchi"] = "蒙斥",
  [":mengchi"] = "锁定技，若你于当前回合内没有获得过牌，你：1.不能使用牌；2.进入横置状态时，取消之；3.受到普通伤害后，回复1点体力。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌（此牌不计入你本回合的手牌上限）。",
}

local panghui = General(extension, "panghui", "wei", 5)
local yiyong = fk.CreateTriggerSkill{
  name = "yiyong",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) < 2 and data.to and data.to ~= player and not player:isNude() and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, #player.player_cards[Player.Hand] + #player.player_cards[Player.Equip], true, self.name, true, ".", "#yiyong-cost")
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(data.to, 1, #data.to.player_cards[Player.Hand] + #data.to.player_cards[Player.Equip], true, self.name, false, ".", "#yiyong-discard")
    local n1 = 0
    local n2 = 0
    for _, id in ipairs(self.cost_data) do
      n1 = n1 + Fk:getCardById(id).number
    end
    for _, id in ipairs(cards) do
      n2 = n2 + Fk:getCardById(id).number
    end
    if n1 <= n2 then
      player:drawCards(#cards, self.name)
    end
    if n1 >= n2 then
      data.damage = data.damage + 1
    end
  end,
}
panghui:addSkill(yiyong)
Fk:loadTranslationTable{
  ["panghui"] = "庞会",
  ["yiyong"] = "异勇",
  [":yiyong"] = "每回合限两次，当你对其他角色造成伤害时，你可以弃置任意张牌，令该角色弃置任意张牌。若你弃置的牌的点数之和：不大于其，你摸X张牌（X为该角色弃置的牌数）；不小于其，此伤害+1。",
  ["#yiyong-cost"] = "异勇：你可以弃置任意张牌，令目标弃置任意张牌，根据双方弃牌点数执行效果",
  ["#yiyong-disable"] = "异勇：你需弃置任意张牌，若点数大则对方摸牌，若点数小则伤害+1",
}

Fk:loadTranslationTable{
  ["zhaozhi"] = "赵直",
  ["tongguan"] = "统观",
  [":tongguan"] = "一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。",
  ["mengjie"] = "梦解",
  [":mengjie"] = "一名角色的回合结束时，若其本回合完成了其属性对应内容，你执行对应效果。<br>"..
  "武勇：造成伤害；对一名其他角色造成1点伤害<br>"..
  "刚硬：回复体力或手牌数大于体力值；令一名角色回复1点体力<br>"..
  "多谋：摸牌阶段外摸牌；摸两张牌<br>"..
  "果决：弃置或获得其他角色的牌；弃置一名其他角色区域内的至多两张牌<br>"..
  "仁智：交给其他角色牌；令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["@mengjie_wuyong"] = "武勇",
  ["@mengjie_gangying"] = "刚硬",
  ["@mengjie_duomou"] = "多谋",
  ["@mengjie_guojue"] = "果决",
  ["@mengjie_renzhi"] = "仁智",
}

Fk:loadTranslationTable{
  ["chenjiao"] = "陈矫",
  ["xieshou"] = "协守",
  [":xieshou"] = "每回合限一次，当有角色受到伤害后，若你与其距离小于等于2，你可以令你的手牌上限-1，然后其选择一项：1.回复1点体力；2.将武将牌复原并摸两张牌。",
  ["qingyan"] = "清严",
  [":qingyan"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后：若你的手牌小于体力值，你可将手牌摸至体力上限；若你的手牌数不小于体力值，你可以弃置一张手牌令手牌上限+1。",
  ["qizi"] = "弃子",
  [":qizi"] = "锁定技，其他角色处于濒死状态时，若你与其距离大于2，你不能对其使用【桃】。",
}

local zhujianping = General(extension, "zhujianping", "qun", 3)
local xiangmian = fk.CreateActiveSkill{
  name = "xiangmian",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("xiangmian_suit") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    room:setPlayerMark(target, "@xiangmian", string.format("%s-%d",
    Fk:translate(judge.card:getSuitString()),
    judge.card.number))
    room:setPlayerMark(target, "xiangmian_suit", judge.card:getSuitString())
    room:setPlayerMark(target, "xiangmian_num", judge.card.number)
  end,
}
local xiangmian_kill = fk.CreateTriggerSkill{
  name = "#xiangmian_kill",
  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:getMark("xiangmian_num") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(target, self.name, 1)
    if data.card:getSuitString() == target:getMark("xiangmian_suit") or target:getMark(self.name) == target:getMark("xiangmian_num") then
      room:setPlayerMark(target, "xiangmian_num", 0)
      room:setPlayerMark(target, "@xiangmian", 0)
      room:loseHp(target, target.hp, "xiangmian")
    end
  end,
}
local tianji = fk.CreateTriggerSkill{
  name = "tianji",
  events = {fk.FinishJudge},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = data.card
    local cards = {}
    table.insert(cards, getCardByPattern(room, ".|.|.|.|.|"..card:getTypeString()))
    table.insert(cards, getCardByPattern(room, ".|.|"..card:getSuitString()))
    table.insert(cards, getCardByPattern(room, ".|"..card.number))
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
xiangmian:addRelatedSkill(xiangmian_kill)
zhujianping:addSkill(xiangmian)
zhujianping:addSkill(tianji)
Fk:loadTranslationTable{
  ["zhujianping"] = "朱建平",
  ["xiangmian"] = "相面",
  [":xiangmian"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，当该角色使用判定花色的牌或使用第X张牌后（X为判定点数），其失去所有体力。每名其他角色限一次。",
  ["tianji"] = "天机",
  [":tianji"] = "锁定技，生效后的判定牌进入弃牌堆后，你从牌堆随机获得与该牌类型、花色和点数相同的牌各一张。",
  ["@xiangmian"] = "相面",
}

local gongsundu = General(extension, "gongsundu", "qun", 4)
local zhenze = fk.CreateTriggerSkill{
  name = "zhenze",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"zhenze_lose", "zhenze_recover"}, self.name)
    if choice == "zhenze_lose" then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if ((p.hp > player.hp) ~= (#p.player_cards[Player.Hand] > #player.player_cards[Player.Hand])) or
          ((p.hp == player.hp) ~= (#p.player_cards[Player.Hand] == #player.player_cards[Player.Hand])) or
          ((p.hp < player.hp) ~= (#p.player_cards[Player.Hand] < #player.player_cards[Player.Hand])) then
            room:loseHp(p, 1, self.name)
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isWounded() and
          (((p.hp > player.hp) and (#p.player_cards[Player.Hand] > #player.player_cards[Player.Hand])) or
          ((p.hp == player.hp) and (#p.player_cards[Player.Hand] == #player.player_cards[Player.Hand])) or
          ((p.hp < player.hp) and (#p.player_cards[Player.Hand] < #player.player_cards[Player.Hand]))) then
            room:recover({
              who = p,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
        end
      end
    end
  end,
}
local anliao = fk.CreateActiveSkill{
  name = "anliao",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.kingdom == "qun" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(self.name) < n
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "he", self.name)
    room:moveCards({
      ids = {id},
      from = effect.tos[1],
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
    })
    target:drawCards(1, self.name)
  end,
}
gongsundu:addSkill(zhenze)
gongsundu:addSkill(anliao)
Fk:loadTranslationTable{
  ["gongsundu"] = "公孙度",
  ["zhenze"] = "震泽",
  [":zhenze"] = "弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；2.令所有手牌数和体力值的大小关系与你相同的角色回复1点体力。",
  ["anliao"] = "安辽",
  [":anliao"] = "出牌阶段限X次（X为群势力角色数），你可以重铸一名角色的一张牌。",
  ["zhenze_lose"] = "手牌数和体力值的大小关系与你不同的角色失去1点体力",
  ["zhenze_recover"] = "所有手牌数和体力值的大小关系与你相同的角色回复1点体力",
}

--董贵人 是仪 程秉 孙狼 武安国 霍峻 孙寒华 薛灵芸 刘辟 关宁2023.1.18
local xuelingyun = General(extension, "xuelingyun", "wei", 3, 3, General.Female)
local xialei = fk.CreateTriggerSkill{
  name = "xialei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("xialei-turn") < 3 then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).color == Card.Red then
                return true
              end
            end
          end
        end
      else
        if target == player and data.card.color and data.card.color == Card.Red then
          return player.room:getCardArea(data.card) == Card.Processing
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    room:fillAG(player, ids)
    local chosen = room:askForAG(player, ids, false, self.name)
    table.removeOne(ids, chosen)
    room:obtainCard(player, chosen, false, fk.ReasonPrey)
    room:closeAG(player)
    if #ids > 0 then
      local choice = room:askForChoice(player, {"xialei_top", "xialei_bottom"}, self.name)
      local place = 1
      if choice == "xialei_top" then
        for i = #ids, 1, -1 do
          table.insert(room.draw_pile, 1, ids[i])
        end
      else
        for _, id in ipairs(ids) do
          table.insert(room.draw_pile, id)
        end
      end
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
}
local anzhi = fk.CreateActiveSkill{
  name = "anzhi",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("anzhi-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:setPlayerMark(player, "xialei-turn", 0)
    elseif judge.card.color == Card.Black then
      room:addPlayerMark(player, "anzhi-turn", 1)
      local ids = player:getMark("anzhi_record-turn")
      if type(ids) ~= "table" then return end
      for _, id in ipairs(ids) do
        if room:getCardArea(id) ~= Card.DiscardPile then
          table.removeOne(ids, id)
        end
      end
      if #ids == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
        return p ~= room.current end), function(p) return p.id end), 1, 1, "#anzhi-choose", self.name)
      if #to > 0 then
        local get = {}
        room:fillAG(player, ids)
        while #get < 2 and #ids > 0 do
          local id = room:askForAG(player, ids, true)
          if id == nil then break end
          table.insert(get, id)
          table.removeOne(ids, id)
          room:takeAG(player, id, {player})
        end
        room:closeAG(player)
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local anzhi_record = fk.CreateTriggerSkill{
  name = "#anzhi_record",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("anzhi-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askForUseActiveSkill(player, "anzhi", "#anzhi-invoke", true)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      local room = player.room
      local ids = player:getMark("anzhi_record-turn")
      if type(ids) ~= "table" then ids = {} end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
      room:setPlayerMark(player, "anzhi_record-turn", ids)
    end
  end,
}
anzhi:addRelatedSkill(anzhi_record)
xuelingyun:addSkill(xialei)
xuelingyun:addSkill(anzhi)
Fk:loadTranslationTable{
  ["xuelingyun"] = "薛灵芸",
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。",
  ["anzhi"] = "暗织",
  [":anzhi"] = "出牌阶段或当你受到伤害后，你可以进行一次判定，若结果为：红色，重置〖霞泪〗；黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。",
  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#anzhi-invoke"] = "你想发动技能“暗织”吗？",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",
}
--神张角 周宣2023.2.25
--local godzhangjiao = General(extension, "godzhangjiao", "god", 3)
local yizhao = fk.CreateTriggerSkill{
  name = "yizhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.number
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = tostring(player:getMark("@huang"))
    room:addPlayerMark(player, "@huang", math.min(data.card.number, 184 - player:getMark("@huang")))
    local n2 = tostring(player:getMark("@huang"))
    if #n1 == 1 then
      if #n2 == 1 then return end
    else
      if n1:sub(#n1 - 1, #n1 - 1) == n2:sub(#n2 - 1, #n2 - 1) then return end
    end
    local x = n2:sub(#n2 - 1, #n2 - 1)
    if x == 0 then x = 10 end  --yes, tenyear is so strange
    local card = {getCardByPattern(room, ".|"..x)}
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local sijun = fk.CreateTriggerSkill{
  name = "sijun",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and player:getMark("@huang") > #player.room.draw_pile
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@huang", 0)
    room:shuffleDrawPile()
    local cards = {}
    local total = 36
    local i = 0
    while total > 0 and i < 999 do
      local num = math.random(1, math.min(13, total))
      local id = getCardByPattern(room, ".|"..tostring(num))
      if id ~= nil then
        table.insert(cards, id)
        total = total - num
      end
      i = i + 1
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
--godzhangjiao:addSkill(yizhao)
--godzhangjiao:addSkill(sanshou)
--godzhangjiao:addSkill(sijun)
--godzhangjiao:addSkill(tianjie)
Fk:loadTranslationTable{
  ["godzhangjiao"] = "神张角",
  ["yizhao"] = "异兆",
  [":yizhao"] = "锁定技，当你使用或打出一张牌后，获得等同于此牌点数的“黄”标记，然后若“黄”标记数的十位数变化，你随机获得牌堆中一张点数为变化后十位数的牌。",
  ["sanshou"] = "三首",
  [":sanshou"] = "当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合所有角色均未使用过的牌的类型，防止此伤害。",
  ["sijun"] = "肆军",
  [":sijun"] = "准备阶段，若“黄”标记数大于牌堆里的牌数，你可以移去所有“黄”标记并洗牌，然后获得随机张点数之和为36的牌。",
  ["tianjie"] = "天劫",
  [":tianjie"] = "一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量且至少为1）。",
  ["@huang"] = "黄",
}

local zhouxuan = General(extension, "zhouxuan", "wei", 3)
local wumei = fk.CreateTriggerSkill{
  name = "wumei",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Start and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local p = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#wumei-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:setPlayerMark(p, "wumei_hp", p.hp)
    end
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "wumei_extra", 1)
    to:gainAnExtraTurn()
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return data.to == Player.NotActive and player:getMark("wumei_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "wumei_extra", 0)
    for _, p in ipairs(room:getAlivePlayers()) do
      p.hp = p:getMark("wumei_hp")
      room:broadcastProperty(p, "hp")
      room:setPlayerMark(p, "wumei_hp", 0)
    end
  end,
}
local zhanmeng = fk.CreateTriggerSkill{
  name = "zhanmeng",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i).."-turn") == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    self.cost_data = {}
    if player:getMark("zhanmeng1-turn") == 0 and table.contains(room:getTag("zhanmeng1"), data.card.trueName) then
      table.insert(choices, "zhanmeng1")
    end
    if player:getMark("zhanmeng2-turn") == 0 then
      table.insert(choices, "zhanmeng2")
    end
    local tos = {}
    if player:getMark("zhanmeng3-turn") == 0 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] + #p.player_cards[Player.Equip] > 1 then
          table.insertIfNeed(choices, "zhanmeng3")
          table.insert(tos, p)
        end
      end
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "Cancel" then return end
    self.cost_data[1] = choice
    if choice == "zhanmeng3" then
      local p = room:askForChoosePlayers(player, table.map(tos, function(p)
        return p.id end), 1, 1, "#zhanmeng-choose", self.name)
      if #p > 0 then
        self.cost_data[2] = p[1]
      end
    end
    return #self.cost_data > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "zhanmeng1" then
      local card = {getCardByPattern(room, "nondamage_card")}
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif choice == "zhanmeng2" then
      room:setPlayerMark(player, "zhanmeng2_invoke", data.card.trueName)
    elseif choice == "zhanmeng3" then
      local p = room:getPlayerById(self.cost_data[2])
      --FIXME: this skill may discard cards after target filted, so cards like dismantlement,snatch,collateral,fire_attack should check again before effect!
      local discards = room:askForDiscard(p, 2, 2, true, self.name, false)
      if Fk:getCardById(discards[1]).number + Fk:getCardById(discards[2]).number > 10 then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local zhanmeng_record = fk.CreateTriggerSkill{
  name = "#zhanmeng_record",

  refresh_events = {fk.CardUsing, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.CardUsing then
        return true
      else
        return player.phase == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local zhanmeng2 = room:getTag("zhanmeng2")
      if type(zhanmeng2) ~= "table" then
        zhanmeng2 = {}
      end
      if not table.contains(zhanmeng2, data.card.trueName) then
        table.insert(zhanmeng2, data.card.trueName)
        room:setTag("zhanmeng2", zhanmeng2)
      end
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("zhanmeng2_get-turn") == data.card.trueName then
          room:setPlayerMark(p, "zhanmeng2_get-turn", 0)
          local card = {getCardByPattern(room, "damage_card")}
          if #card > 0 then
            room:moveCards({
              ids = card,
              to = p.id,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonPrey,
              proposer = p.id,
              skillName = "zhanmeng",
            })
          end
        end
      end
    else
      local zhanmeng2 = room:getTag("zhanmeng2")
      if type(zhanmeng2) ~= "table" then
        zhanmeng2 = {}
      end
      room:setTag("zhanmeng1", zhanmeng2)  --cards used in last turn
      zhanmeng2 = {}
      room:setTag("zhanmeng2", zhanmeng2)  --cards used in current turn
      for _, p in ipairs(room:getAlivePlayers()) do
        if type(p:getMark("zhanmeng2_invoke")) == "string" then
          room:setPlayerMark(p, "zhanmeng2_get-turn", p:getMark("zhanmeng2_invoke"))
          room:setPlayerMark(p, "zhanmeng2_invoke", 0)
        end
      end
    end
  end,
}
zhanmeng:addRelatedSkill(zhanmeng_record)
zhouxuan:addSkill(wumei)
zhouxuan:addSkill(zhanmeng)
Fk:loadTranslationTable{
  ["zhouxuan"] = "周宣",
  ["wumei"] = "寤寐",
  [":wumei"] = "每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束时，将所有存活角色的体力值调整为此额外回合开始时的数值。",
  ["zhanmeng"] = "占梦",
  [":zhanmeng"] = "你使用牌时，可以执行以下一项（每回合每项各限一次）：1.上一回合内，若没有同名牌被使用，你获得一张非伤害牌。2.下一回合内，当同名牌首次被使用后，你获得一张伤害牌。3.令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害。",
  ["#wumei-choose"] = "寤寐: 你可以令一名角色执行一个额外的回合",
  ["zhanmeng1"] = "你获得一张非伤害牌",
  ["zhanmeng2"] = "下一回合内，当同名牌首次被使用后，你获得一张伤害牌",
  ["zhanmeng3"] = "令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-choose"] = "占梦: 令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
}
--杨彪 傅肜傅佥 向朗 孙桓 杨弘 桥蕤 秦朗 郑浑2023.3.11
--孟节 孙资刘放 2023.3.19
return extension
