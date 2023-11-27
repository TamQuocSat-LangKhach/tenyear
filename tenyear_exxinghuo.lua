local extension = Package("tenyear_exxinghuo")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_exxinghuo"] = "十周年-界星火燎原",
}

local ty_ex__sundeng = General(extension, "ty_ex__sundeng", "wu", 4)
local ty_ex__kuangbi = fk.CreateTriggerSkill {
  name = "ty_ex__kuangbi",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty_ex__kuangbi-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = room:askForCard(to, 1, 3, true, self.name, false, ".", "#ty_ex__kuangbi-card:"..player.id)
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, false, self.name)
    room:setPlayerMark(player, self.name, to.id)
  end,
}
local ty_ex__kuangbi_trigger = fk.CreateTriggerSkill {
  name = "#ty_ex__kuangbi_trigger",
  mute = true,
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("ty_ex__kuangbi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local cards = player:getPile("ty_ex__kuangbi")
      local ids = table.filter(cards, function(id) return Fk:getCardById(id).suit == data.card.suit end)
      local throw = #ids > 0 and table.random(ids) or table.random(cards)
      room:moveCards({ids = {throw}, from = player.id ,toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile })
      if not player.dead then
        player:drawCards(1, "ty_ex__kuangbi")
      end
      if #ids == 0 then return end
      local to = room:getPlayerById(player:getMark("ty_ex__kuangbi"))
      if to and not to.dead then
        room:doIndicate(player.id, {to.id})
        to:drawCards(1, "ty_ex__kuangbi")
      end
    else
      room:moveCards({ids = player:getPile("ty_ex__kuangbi"),from = player.id, toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile })
    end
  end,
}
ty_ex__kuangbi:addRelatedSkill(ty_ex__kuangbi_trigger)
ty_ex__sundeng:addSkill(ty_ex__kuangbi)
Fk:loadTranslationTable{
  ["ty_ex__sundeng"] = "界孙登",
  ["ty_ex__kuangbi"] = "匡弼",
  [":ty_ex__kuangbi"] = "出牌阶段开始时，你可以令一名其他角色将一至三张牌置于你的武将牌上，本阶段结束时将“匡弼”牌置入弃牌堆。当你于有“匡弼”牌时"..
  "使用牌时，若你：有与之花色相同的“匡弼”牌，则随机将其中一张置入弃牌堆，然后你与该角色各摸一张牌；没有与之花色相同的“匡弼”牌，则随机将一张置入弃牌堆，"..
  "然后你摸一张牌。",
  ["#ty_ex__kuangbi-choose"] = "匡弼：你可以令一名其他角色将一至三张牌置于你的武将牌上",
  ["#ty_ex__kuangbi-card"] = "匡弼：将一至三张牌置为 %src 的“匡弼”牌",

  ["$ty_ex__kuangbi1"] = "江东多娇，士当弼国以全方圆。",
  ["$ty_ex__kuangbi2"] = "吴垒锦绣，卿当匡佐使延万年。",
  ["~ty_ex__sundeng"] = "此别无期，此恨绵绵。",
}

local duji = General(extension, "ty_ex__duji", "wei", 3)
local ty_ex__andong = fk.CreateTriggerSkill{
  name = "ty_ex__andong",
  events = {fk.DamageInflicted},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__andong-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local choices = {"ty_ex__andong1", "ty_ex__andong2"}
    local to = data.from
    local prompt = "#ty_ex__andong-choice:"..player.id
    if player:getMark(self.name) > 0 then
      choices = {"ty_ex__andong1Ex", "ty_ex__andong2Ex"}
      to = player
      prompt = "#ty_ex__andong2-choice::"..data.from.id
      room:setPlayerMark(player, self.name, 0)
    end
    local choice = room:askForChoice(to, choices, self.name, prompt)
    if choice[14] == "1" then
      room:setPlayerMark(data.from, "ty_ex__andong-turn", 1)
      return true
    else
      if data.from:isKongcheng() then
        room:setPlayerMark(player, self.name, 1)
        return
      end
      U.viewCards(player, data.from:getCardIds("h"), self.name)
      local cards = table.filter(data.from:getCardIds("h"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
      if #cards > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end
    end
  end,
}
local ty_ex__andong_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty_ex__andong_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("ty_ex__andong-turn") > 0 and card.suit == Card.Heart
  end,
}
local ty_ex__yingshi = fk.CreateTriggerSkill{
  name = "ty_ex__yingshi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "ty_ex__yingshi_active", "#ty_ex__yingshi-invoke", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target1 = room:getPlayerById(self.cost_data.targets[1])
    local target2 = room:getPlayerById(self.cost_data.targets[2])
    local id = self.cost_data.cards[1]
    local card_info = {Fk:getCardById(id):getSuitString(), Fk:getCardById(id).number}
    player:showCards({id})
    if target1.dead or target2.dead then return end
    local use = room:askForUseCard(target2, "slash", "slash", "#ty_ex__yingshi-slash::"..target1.id, true,
      {must_targets = {target1.id}, bypass_distances = true, bypass_times = true})
    if use then
      room:useCard(use)
      if not target2.dead and room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, target2, fk.ReasonPrey, self.name, nil, true, target2.id)
      end
      if not target2.dead and use.damageDealt and card_info[1] ~= "nosuit" then
        local cards = room:getCardsFromPileByRule(".|"..card_info[2].."|"..card_info[1], 999)
        if #cards > 0 then
          room:moveCards({
            ids = cards,
            to = target2.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = target2.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local ty_ex__yingshi_active = fk.CreateActiveSkill{
  name = "ty_ex__yingshi_active",
  card_num = 1,
  target_num = 2,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return to_select ~= Self.id
    elseif #selected == 1 then
      return true
    else
      return false
    end
  end,
}
ty_ex__andong:addRelatedSkill(ty_ex__andong_maxcards)
Fk:addSkill(ty_ex__yingshi_active)
duji:addSkill(ty_ex__andong)
duji:addSkill(ty_ex__yingshi)
Fk:loadTranslationTable{
  ["ty_ex__duji"] = "界杜畿",
  ["ty_ex__andong"] = "安东",
  [":ty_ex__andong"] = "当你受到其他角色造成的伤害时，你可令伤害来源选择一项：1.防止此伤害，本回合弃牌阶段<font color='red'>♥</font>牌不计入手牌上限；"..
  "2.观看其手牌，若其中有<font color='red'>♥</font>牌则你获得这些牌。若选择2且其没有手牌，则下一次发动时改为由你选择。",
  ["ty_ex__yingshi"] = "应势",
  [":ty_ex__yingshi"] = "出牌阶段开始时，你可以展示一张手牌并选择一名其他角色，然后令另一名角色对其使用一张【杀】（无距离次数限制）。"..
  "若其使用了【杀】，则其获得你展示的牌；若此【杀】造成了伤害，则再获得牌堆中所有与展示牌花色点数均相同的牌。",
  ["#ty_ex__andong-invoke"] = "安东：你可以对 %dest 发动“安东”",
  ["ty_ex__andong1"] = "防止此伤害，本回合你的<font color='red'>♥</font>牌不计入手牌上限",
  ["ty_ex__andong2"] = "其观看你的手牌并获得其中的<font color='red'>♥</font>牌",
  ["ty_ex__andong1Ex"] = "防止此伤害，本回合其<font color='red'>♥</font>牌不计入手牌上限",
  ["ty_ex__andong2Ex"] = "观看其手牌并获得其中的<font color='red'>♥</font>牌",
  ["#ty_ex__andong-choice"] = "安东：选择 %src 令你执行的一项",
  ["#ty_ex__andong2-choice"] = "安东：选择对 %dest 执行的一项",
  ["ty_ex__yingshi_active"] = "应势",
  ["#ty_ex__yingshi-invoke"] = "应势：展示一张手牌并选择两名角色，后者可以对前者使用一张【杀】",
  ["#ty_ex__yingshi-slash"] = "应势：你可以对 %dest 使用一张【杀】，然后获得展示牌",

  ["$ty_ex__andong1"] = "青龙映木，星出其东则天下安。",
  ["$ty_ex__andong2"] = "以身涉险，剑伐不臣而定河东。",
  ["$ty_ex__yingshi1"] = "大势如潮，可应之而不可逆之。",
  ["$ty_ex__yingshi2"] = "应大势伐贼者，当以重酬彰之。",
  ["~ty_ex__duji"] = "公无渡河，公竟渡河。",
}

--郭皇后

local huangyueying = General(extension, "ty_ex__huangyueying", "qun", 3, 3, General.Female)
local ty__jiqiao = fk.CreateTriggerSkill{
  name = "ty__jiqiao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#ty__jiqiao-invoke", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead then return end
    local n = 0
    for _, id in ipairs(self.cost_data) do
      if Fk:getCardById(id).type == Card.TypeEquip then
        n = n + 2
      else
        n = n + 1
      end
    end
    local cards = room:getNCards(n)
    room:moveCards{
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).type ~= Card.TypeEquip then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    if #get > 0 then
      room:delay(1000)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #cards > 0 then
      room:delay(1000)
      room:moveCards{
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
    end
  end,
}
local ty__linglong = fk.CreateTriggerSkill{
  name = "ty__linglong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.every({Card.SubtypeArmor, Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide, Card.SubtypeTreasure}, function(type)
        return player:getEquipment(type) == nil end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,

  refresh_events = {fk.GameStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
          if move.to == player.id and move.toArea == Player.Equip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)  --FIXME: 虚拟装备技能应该用statusSkill而非triggerSkill
    if player:getEquipment(Card.SubtypeArmor) == nil and not player:hasSkill("#eight_diagram_skill", true) then
      player.room:handleAddLoseSkills(player, "#eight_diagram_skill", self, false, true)
    elseif player:getEquipment(Card.SubtypeArmor) ~= nil and player:hasSkill("#eight_diagram_skill", true) then
      player.room:handleAddLoseSkills(player, "-#eight_diagram_skill", nil, false, true)
    end
    if player:getEquipment(Card.SubtypeTreasure) == nil and not player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "qicai", self, false, true)
    elseif player:getEquipment(Card.SubtypeTreasure) ~= nil and player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "-qicai", nil, false, true)
    end
  end,
}
local ty__linglong_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty__linglong_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("ty__linglong") and
      player:getEquipment(Card.SubtypeOffensiveRide) == nil and player:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return 2
    end
    return 0
  end,
}
ty__linglong:addRelatedSkill(ty__linglong_maxcards)
huangyueying:addSkill(ty__jiqiao)
huangyueying:addSkill(ty__linglong)
huangyueying:addRelatedSkill("qicai")
Fk:loadTranslationTable{
  ["ty_ex__huangyueying"] = "界黄月英",
  ["ty__jiqiao"] = "机巧",
  [":ty__jiqiao"] = "出牌阶段开始时，你可以弃置任意张牌，然后你亮出牌堆顶等量的牌，你弃置的牌中每有一张装备牌，则多亮出一张牌。然后你获得其中的非装备牌。",
  ["ty__linglong"] = "玲珑",
  [":ty__linglong"] = "锁定技，若你的装备区里没有防具牌，你视为装备【八卦阵】；若你的装备区里没有坐骑牌，你的手牌上限+2；"..
  "若你的装备区里没有宝物牌，你视为拥有〖奇才〗。若均满足，你使用的【杀】和普通锦囊牌不能被响应。",
  ["#ty__jiqiao-invoke"] = "机巧：你可以弃置任意张牌，亮出牌堆顶等量牌（每有一张装备牌额外亮出一张），获得非装备牌",

  ["$ty__jiqiao1"] = "机关将作之术，在乎手巧心灵。",
  ["$ty__jiqiao2"] = "机巧藏于心，亦如君之容。",
  ["$ty__linglong1"] = "我夫所赠之玫，遗香自长存。",
  ["$ty__linglong2"] = "心有玲珑罩，不殇春与秋。",
  ["~ty_ex__huangyueying"] = "此心欲留夏，奈何秋风起……",
}

--SP太史慈

local wenpin = General(extension, "ty_ex__wenpin", "wei", 5)
local ty_ex__zhenwei = fk.CreateTriggerSkill{
  name = "ty_ex__zhenwei",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude() and data.from ~= player.id and
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.color == Card.Black)) and
      #AimGroup:getAllTargets(data.tos) == 1 and player.room:getPlayerById(data.to).hp <= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".",
    "#ty_ex__zhenwei-invoke:" .. data.from .. ":" .. data.to .. ":" .. data.card:toLogString())
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local choice = room:askForChoice(player, {"ty_ex__zhenwei_transfer", "ty_ex__zhenwei_recycle"}, self.name)
    if choice == "ty_ex__zhenwei_transfer" then
      room:drawCards(player, 1, self.name)
      if target:isProhibited(player, data.card) then return false end
      if not data.card.skill:modTargetFilter(player.id, {}, data.from, data.card, false) then return false end
      local passed_target = {player.id}
      --target_filter cheak, for collateral,diversion...
      local c_pid
      --FIXME：借刀需要补modTargetFilter，不给targetFilter传使用者真是离大谱，目前只能通过强制修改Self来实现
      local Notify_from = room:getPlayerById(data.from)
      Self = Notify_from
      local ho_spair_target = data.targetGroup[1]
      if #ho_spair_target > 1 then
        for i = 2, #ho_spair_target, 1 do
          c_pid = ho_spair_target[i]
          if not data.card.skill:targetFilter(c_pid, passed_target, {}, data.card) then return false end
          table.insert(passed_target, c_pid)
        end
      end
      data.targetGroup = { passed_target }
    else
      TargetGroup:removeTarget(data.targetGroup, data.to)
      local use_from = room:getPlayerById(data.from)
      if not use_from.dead then
        local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
        if #cardlist > 0 and table.every(cardlist, function (id)
          return room:getCardArea(id) == Card.Processing
        end) then
          use_from:addToPile(self.name, data.card, true, self.name)
        end
      end
    end
  end,
}
local ty_ex__zhenwei_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__zhenwei_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("ty_ex__zhenwei") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCards({
      from = player.id,
      ids = player:getPile("ty_ex__zhenwei"),
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      skillName = ty_ex__zhenwei.name,
      proposer = player.id,
    })
  end,
}
ty_ex__zhenwei:addRelatedSkill(ty_ex__zhenwei_delay)
wenpin:addSkill(ty_ex__zhenwei)
Fk:loadTranslationTable{
  ["ty_ex__wenpin"] = "界文聘",
  ["ty_ex__zhenwei"] = "镇卫",
  [":ty_ex__zhenwei"] = "当其他角色成为【杀】或黑色锦囊牌的唯一目标时，若该角色的体力值不大于你，你可以弃置一张牌并选择一项：1.摸一张牌，"..
  "然后将此牌转移给你；2.令此牌无效，然后当前回合结束后，使用者获得此牌。",
  ["#ty_ex__zhenwei-invoke"] = "镇卫：%src对%dest使用%arg，是否弃置一张牌发动“镇卫”？",
  ["ty_ex__zhenwei_transfer"] = "摸一张牌并将此牌转移给你",
  ["ty_ex__zhenwei_recycle"] = "取消此牌，回合结束时使用者将之收回",

  ["$ty_ex__zhenwei1"] = "想攻城，问过我没有？",
  ["$ty_ex__zhenwei2"] = "有我坐镇，我军焉能有失？",
  ["~ty_ex__wenpin"] = "没想到，敌军的攻势如此凌厉。",
}

local gongsunzan = General(extension, "ty_ex__gongsunzan", "qun", 4)
local ty_ex__qiaomeng = fk.CreateTriggerSkill{
  name = "ty_ex__qiaomeng",
  events = {fk.TargetSpecified},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.color == Card.Black and data.firstTarget
    and table.find(AimGroup:getAllTargets(data.tos), function(pid)
      return pid ~= player.id and not player.room:getPlayerById(pid):isNude()
    end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function(pid)
      return pid ~= player.id and not room:getPlayerById(pid):isNude()
    end)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__qiaomeng-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cid = room:askForCardChosen(player, to, "he", self.name)
    local card = Fk:getCardById(cid, true)
    if card.type == Card.TypeEquip then
      room:obtainCard(player, cid, false, fk.ReasonPrey)
    else
      room:throwCard({cid}, self.name, to, player)
      if card.type == Card.TypeTrick then
        data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      end
    end
  end,
}
gongsunzan:addSkill(ty_ex__qiaomeng)
local ty_ex__yicong = fk.CreateDistanceSkill{
  name = "ty_ex__yicong",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      return -1
    end
    if to:hasSkill(self) and to.hp < 3 then
      return 1
    end
    return 0
  end,
}
local ty_ex__yicong_audio = fk.CreateTriggerSkill{
  name = "#ty_ex__yicong_audio",
  refresh_events = {fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_ex__yicong") and not player:isFakeSkill("ty_ex__yicong")
    and player.hp < 3 and data.num < 0 and player.hp - data.num > 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, "ty_ex__yicong", "defensive")
    player:broadcastSkillInvoke("ty_ex__yicong")
  end,
}
ty_ex__yicong:addRelatedSkill(ty_ex__yicong_audio)
gongsunzan:addSkill(ty_ex__yicong)
Fk:loadTranslationTable{
  ["ty_ex__gongsunzan"] = "公孙瓒",
  ["ty_ex__qiaomeng"] = "趫猛",
  [":ty_ex__qiaomeng"] = "当你使用黑色牌指定目标后，你可以弃置其中一名其他目标角色的一张牌，若此牌为：锦囊牌，此黑色牌不能被响应；装备牌，你改为获得之。",
  ["#ty_ex__qiaomeng-choose"] = "趫猛：弃置一名其他目标角色的一张牌",
  ["ty_ex__yicong"] = "义从",
  [":ty_ex__yicong"] = "锁定技，①你计算与其他角色的距离-1；②若你已损失的体力值不小于2，其他角色计算与你的距离+1。",

  ["$ty_ex__qiaomeng1"] = "猛士骁锐，可慑百蛮失蹄！",
  ["$ty_ex__qiaomeng2"] = "锐士志猛，可凭白手夺马！",
  ["$ty_ex__yicong1"] = "恩义聚骠骑，百战从公孙！",
  ["$ty_ex__yicong2"] = "义从呼啸至，白马抖精神！",
  ["~ty_ex__gongsunzan"] = "良弓断，白马亡。",
}
return extension
