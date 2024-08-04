local extension = Package("tenyear_mou")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_mou"] = "十周年-谋定天下",
  ["tymou"] = "新服谋",
  ["tymou2"] = "新服谋",
}

local function setTYMouSwitchSkillState(player, generalName, skillName, isYang)
  if isYang == nil then
    isYang = player:getSwitchSkillState(skillName, true) == fk.SwitchYang
  else
    local switch_state = isYang and fk.SwitchYin or fk.SwitchYang
    if player:getSwitchSkillState(skillName, true) == switch_state then
      player.room:setPlayerMark(player, MarkEnum.SwithSkillPreName .. skillName, switch_state)
      player:setSkillUseHistory(skillName, 0, Player.HistoryGame)
    end
  end

  if Fk.generals["tymou2__" .. generalName] == nil then return end

  local from_name = "tymou__" .. generalName
  local to_name = "tymou__" .. generalName
  if isYang then
    to_name = "tymou2__" .. generalName
  else
    from_name = "tymou2__" .. generalName
  end
  if player.general == from_name then
    player.general = to_name
    player.room:broadcastProperty(player, "general")
  end
  if player.deputyGeneral == from_name then
    player.deputyGeneral = to_name
    player.room:broadcastProperty(player, "deputyGeneral")
  end
end

Fk:loadTranslationTable{
  ["tymou_switch"] = "%arg · %arg2",
  ["#tymou_switch-transer"] = "请选择 %arg 的阴阳状态",
}

--谋定天下：周瑜、鲁肃、司马懿、贾诩
local tymou__zhouyu = General(extension, "tymou__zhouyu", "wu", 4)
local ronghuo = fk.CreateTriggerSkill{
  name = "ronghuo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and
    table.contains({"fire_attack", "fire__slash"}, data.card.name) then
      local room = player.room
      if not U.damageByCardEffect(room) then return false end
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      local x = #kingdoms - 1
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + self.cost_data
  end,
}
local yingmou = fk.CreateTriggerSkill{
  name = "yingmou",
  anim_type = "switch",
  switch_skill_name = "yingmou",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id and not player.room:getPlayerById(id).dead end) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id) return not room:getPlayerById(id).dead end)
    local prompt
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      prompt = "#yingmou_yang-invoke"
    elseif player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
      prompt = "#yingmou_yin-invoke"
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    setTYMouSwitchSkillState(player, "zhouyu", self.name)
    local to = room:getPlayerById(self.cost_data)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      if player:getHandcardNum() < to:getHandcardNum() then
        player:drawCards(math.min(to:getHandcardNum() - player:getHandcardNum(), 5), self.name)
      end
      if not player.dead and not to.dead and not to:isKongcheng() then
        room:useVirtualCard("fire_attack", nil, player, to, self.name)
      end
    elseif player:getSwitchSkillState(self.name, true) == fk.SwitchYin then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return table.every(room.alive_players, function(p2)
          return p:getHandcardNum() >= p2:getHandcardNum()
        end)
      end), Util.IdMapper)
      if room:getPlayerById(targets[1]):getHandcardNum() == 0 then return end
      local src
      if #targets == 1 then
        src = targets[1]
      else
        src = room:askForChoosePlayers(player, targets, 1, 1, "#yingmou-choose::"..to.id, self.name, false, true)[1]
      end
      src = room:getPlayerById(src)
      local cards = table.filter(src:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
      if #cards > 0 then
        cards = table.reverse(cards)
        for i = #cards, 1, -1 do
          if src.dead or to.dead or to:isKongcheng() then
            break
          end
          if table.contains(src:getCardIds("h"), cards[i]) then
            local card = Fk:getCardById(cards[i])
            if src:canUseTo(card, to, { bypass_distances = true, bypass_times = true}) then
              room:useCard({
                from = src.id,
                tos = {{to.id}},
                card = card,
                extraUse = true,
              })
            end
          end
        end
      else
        local n = src:getHandcardNum() - player:getHandcardNum()
        if n > 0 then
          room:askForDiscard(src, n, n, false, self.name, false)
        end
      end
    end
  end,
}
local yingmou_switch = fk.CreateTriggerSkill{
  name = "#yingmou_switch",
  events = {fk.GameStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingmou)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    setTYMouSwitchSkillState(player, "zhouyu", "yingmou",
    player.room:askForChoice(player, { "tymou_switch:::yingmou:yang", "tymou_switch:::yingmou:yin" },
    "yingmou", "#tymou_switch-transer:::yingmou") == "tymou_switch:::yingmou:yin")
  end,
}
yingmou:addRelatedSkill(yingmou_switch)
tymou__zhouyu:addSkill(ronghuo)
tymou__zhouyu:addSkill(yingmou)

local tymou2__zhouyu = General(extension, "tymou2__zhouyu", "wu", 4)
tymou2__zhouyu.hidden = true
tymou2__zhouyu:addSkill("ronghuo")
tymou2__zhouyu:addSkill("yingmou")

Fk:loadTranslationTable{
  ["tymou__zhouyu"] = "谋周瑜",
  ["#tymou__zhouyu"] = "炽谋英隽",
  --["illustrator:tymou__zhouyu"] = "",
  ["ronghuo"] = "融火",
  [":ronghuo"] = "锁定技，当你因执行火【杀】或【火攻】的效果而对一名角色造成伤害时，你令伤害值+X（X为势力数-1）。",
  ["yingmou"] = "英谋",
  [":yingmou"] = "转换技，游戏开始时可自选阴阳状态，每回合限一次，当你对其他角色使用牌结算后，你可以选择其中一个目标角色，阳：你将手牌摸至与其相同（至多摸五张），然后视为对其使用"..
  "一张【火攻】；阴：令一名手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌，若没有则将手牌弃至与你相同。",
  ["#yingmou_yang-invoke"] = "英谋：选择一名角色，你将手牌补至与其相同，然后视为对其使用【火攻】",
  ["#yingmou_yin-invoke"] = "英谋：选择一名角色，然后令手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌",
  ["#yingmou-choose"] = "英谋：选择手牌数最多的一名角色，其对 %dest 使用手牌中所有【杀】和伤害锦囊牌",
  ["#yingmou_switch"] = "英谋",

  --阳形态
  ["$ronghuo1"] = "火莲绽江矶，炎映三千弱水。",
  ["$ronghuo2"] = "奇志吞樯橹，潮平百万寇贼。",
  ["$yingmou1"] = "行计以险，纵略以奇，敌虽百万亦戏之如犬豕。",
  ["$yingmou2"] = "若生铸剑为犁之心，须有纵钺止戈之力。",
  ["~tymou__zhouyu"] = "人生之艰难，犹如不息之长河……",

  --阴形态
  ["tymou2__zhouyu"] = "谋周瑜",
  ["#tymou2__zhouyu"] = "炽谋英隽",
  --["illustrator:tymou2__zhouyu"] = "",
  ["$ronghuo_tymou2__zhouyu1"] = "江东多锦绣，离火起曹贼毕，九州同忾。",
  ["$ronghuo_tymou2__zhouyu2"] = "星火乘风，风助火势，其必成燎原之姿。",
  ["$yingmou_tymou2__zhouyu1"] = "既遇知己之明主，当福祸共之，荣辱共之。",
  ["$yingmou_tymou2__zhouyu2"] = "将者，贵在知敌虚实，而后避实而击虚。",
  ["~tymou2__zhouyu"] = "大业未成，奈何身赴黄泉……",
}

local tymou__lusu = General(extension, "tymou__lusu", "wu", 3)
local mingshil = fk.CreateTriggerSkill{
  name = "mingshil",
  events = {fk.EventPhaseEnd},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:hasSkill(self)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:drawCards(player, 2, self.name)
    if player.dead or player:getHandcardNum() < 3 or #room.alive_players < 2 then return false end
    local tos, cards = room:askForChooseCardsAndPlayers(player, 3, 3, table.map(room:getOtherPlayers(player, false),
    Util.IdMapper), 1, 1, ".|.|.|hand", "#mingshil-give", "mingshil", false)
    player:showCards(cards)
    cards = table.filter(cards, function(id) return table.contains(player:getCardIds("h"), id) end)
    local to = room:getPlayerById(tos[1])
    if to.dead or #cards == 0 then return end
    local card = U.askforChooseCardsAndChoice(to, cards, {"OK"}, "mingshil", "#mingshil-choose", nil, 1, 1)
    room:moveCardTo(Fk:getCardById(card[1]), Card.PlayerHand, to, fk.ReasonPrey, "mingshil", nil, true, to.id)
  end,
}
local mengmou = fk.CreateTriggerSkill{
  name = "mengmou",
  anim_type = "switch",
  switch_skill_name = "mengmou",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getMark("mengmou_"..player:getSwitchSkillState(self.name, false, true).."-turn") == 0 then
      local targets = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand then
          if move.from == player.id and move.to and move.to ~= player.id and not table.contains(targets, move.to) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.to)
                break
              end
            end
          elseif move.to == player.id and move.from and move.from ~= player.id and not table.contains(targets, move.from) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.from)
                break
              end
            end
          end
        end
      end
      local room = player.room
      targets = table.filter(targets, function (id)
        return not room:getPlayerById(id).dead
      end)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.simpleClone(self.cost_data)
    local room = player.room
    local prompt = (player:getSwitchSkillState(self.name, false) == fk.SwitchYang) and "#mengmou-yang" or "#mengmou-yin"
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, prompt.."-invoke::"..targets[1]..":"..player.maxHp) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets[1]
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, prompt.."-choose::"..targets[1]..":"..player.maxHp, self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "mengmou_"..player:getSwitchSkillState(self.name, true, true).."-turn", 1)
    local to = room:getPlayerById(self.cost_data)
    room:doIndicate(player.id, {to.id})
    setTYMouSwitchSkillState(player, "lusu", self.name)
    local n = player.maxHp
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local use = room:askForUseCard(to, "slash", "slash", "#mengmou-slash:::"..i..":"..n, true, { bypass_times = true })
        if use then
          use.extraUse = true
          room:useCard(use)
          if use.damageDealt then
            for _, p in ipairs(room.players) do
              if use.damageDealt[p.id] then
                count = count + use.damageDealt[p.id]
              end
            end
          end
        else
          break
        end
      end
      if not to.dead and to:isWounded() and count > 0 then
        room:recover({
          who = to,
          num = math.min(to:getLostHp(), count),
          recoverBy = player,
          skillName = self.name,
        })
      end
    else
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local cardResponded = room:askForResponse(to, "slash", "slash", "#mengmou-ask:::"..i..":"..n, false)
        if cardResponded then
          count = i
          room:responseCard({
            from = to.id,
            card = cardResponded,
          })
        else
          break
        end
      end
      if not to.dead and n > count then
        room:loseHp(to, n - count, self.name)
      end
    end
  end,
}
local mengmou_switch = fk.CreateTriggerSkill{
  name = "#mengmou_switch",
  events = {fk.GameStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mengmou)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    setTYMouSwitchSkillState(player, "lusu", "mengmou",
    player.room:askForChoice(player, { "tymou_switch:::mengmou:yang", "tymou_switch:::mengmou:yin" },
    "mengmou", "#tymou_switch-transer:::mengmou") == "tymou_switch:::mengmou:yin")
  end,
}
mengmou:addRelatedSkill(mengmou_switch)
tymou__lusu:addSkill(mingshil)
tymou__lusu:addSkill(mengmou)
local tymou2__lusu = General(extension, "tymou2__lusu", "wu", 3)
tymou2__lusu.hidden = true
tymou2__lusu:addSkill("mingshil")
tymou2__lusu:addSkill("mengmou")
Fk:loadTranslationTable{
  ["tymou__lusu"] = "谋鲁肃",
  ["#tymou__lusu"] = "鸿谋翼远",
  --["illustrator:tymou__lusu"] = "",
  ["mingshil"] = "明势",
  [":mingshil"] = "摸牌阶段结束时，你可以摸两张牌，然后展示三张手牌并令一名其他角色获得其中一张。",
  ["mengmou"] = "盟谋",
  [":mengmou"] = "转换技，游戏开始时可自选阴阳状态，每回合各限一次，当你获得其他角色的手牌后，或当其他角色获得你的手牌后，你可以令该角色执行（其中X为你的体力上限）：<br>"..
  "阳：使用X张【杀】，每造成1点伤害回复1点体力；<br>阴：打出X张【杀】，每少打出一张失去1点体力。",
  ["#mingshil-give"] = "明势：展示3张手牌，令1名其他角色获得其中1张",
  ["#mingshil-choose"] = "明势：获得其中一张牌",
  ["#mengmou-yang-invoke"] = "你可以发动 盟谋（阳），令 %dest 使用%arg张【杀】，造成伤害后其回复体力",
  ["#mengmou-yin-invoke"] = "你可以发动 盟谋（阴），令 %dest 打出%arg张【杀】，每少打出一张其失去1点体力",
  ["#mengmou-yang-choose"] = "你可以发动 盟谋（阳），令一名角色使用%arg张【杀】，造成伤害后其回复体力",
  ["#mengmou-yin-choose"] = "你可以发动 盟谋（阴），令一名角色打出%arg张【杀】，每少打出一张其失去1点体力",
  ["#mengmou-slash"] = "盟谋：你可以连续使用【杀】，造成伤害后你回复体力（第%arg张，共%arg2张）",
  ["#mengmou-ask"] = "盟谋：你需连续打出【杀】，每少打出一张你失去1点体力（第%arg张，共%arg2张）",
  ["#mengmou_switch"] = "盟谋",

  --阳形态
  ["$mingshil1"] = "联刘以抗曹，此可行之大势。",
  ["$mingshil2"] = "强敌在北，唯协力可御之。",
  ["$mengmou1"] = "南北同仇，请皇叔移驾江东，共观花火。",
  ["$mengmou2"] = "孙刘一家，慕英雄之意，忾窃汉之敌。",
  ["~tymou__lusu"] = "虎可为之用，亦可为之伤……",

  --阴形态
  ["tymou2__lusu"] = "谋鲁肃",
  ["#tymou2__lusu"] = "鸿谋翼远",
  --["illustrator:tymou2__lusu"] = "",
  ["$mingshil_tymou2__lusu1"] = "今天下春秋已定，君不见南北沟壑乎？",
  ["$mingshil_tymou2__lusu2"] = "善谋者借势而为，其化万物为己用。",
  ["$mengmou_tymou2__lusu1"] = "合左抑右，定两家之盟。",
  ["$mengmou_tymou2__lusu2"] = "求同存异，邀英雄问鼎。",
  ["~tymou2__lusu"] = "青龙已巢，以何驱之……",
}

local tymou__simayi = General(extension, "tymou__simayi", "wei", 3)
local pingliao = fk.CreateTriggerSkill{
  name = "pingliao",
  anim_type = "control",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return player:inMyAttackRange(p)
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local tos = TargetGroup:getRealTargets(data.tos)
    local drawcard = false
    local targets2 = {}
    for _, p in ipairs(targets) do
      local card = room:askForResponse(p, self.name, ".|.|heart,diamond|.|.|basic", "#pingliao-ask:" .. player.id, true)
      if card then
        room:responseCard{
          from = p.id,
          card = card
        }
        if not table.contains(tos, p.id) then
          drawcard = true
        end
      elseif table.contains(tos, p.id) then
        table.insert(targets2, p)
      end
    end
    for _, p in ipairs(targets2) do
      room:setPlayerMark(p, "@@pingliao-turn", 1)
    end
    if player.dead then return false end
    if drawcard then
      player:drawCards(2, self.name)
      room:addPlayerMark(player, MarkEnum.SlashResidue .. "-phase")
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return player == target and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    data.noIndicate = true
  end,
}
local pingliao_prohibit = fk.CreateProhibitSkill{
  name = "#pingliao_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@pingliao-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@pingliao-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
}
local quanmou = fk.CreateActiveSkill{
  name = "quanmou",
  anim_type = "switch",
  switch_skill_name = "quanmou",
  card_num = 0,
  target_num = 1,
  prompt = function ()
    return Self:getSwitchSkillState("quanmou", false) == fk.SwitchYang and "#quanmou-Yang" or "#quanmou-Yin"
  end,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and not table.contains(U.getMark(Self, "quanmou_targets-phase"), to_select) then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return not target:isNude() and Self:inMyAttackRange(target)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = U.getMark(player, "quanmou_targets-phase")
    table.insert(mark, target.id)
    room:setPlayerMark(player, "quanmou_targets-phase", mark)

    setTYMouSwitchSkillState(player, "simayi", self.name)
    local switch_state = player:getSwitchSkillState(self.name, true, true)

    local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#quanmou-give::"..player.id)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive, target.id)
    if player.dead or target.dead then return false end
    room:setPlayerMark(target, "@quanmou-phase", switch_state)
    local mark_name = "quanmou_" .. switch_state .. "-phase"
    mark = U.getMark(player, mark_name)
    table.insert(mark, target.id)
    room:setPlayerMark(player, mark_name, mark)
  end,
}
local quanmou_switch = fk.CreateTriggerSkill{
  name = "#quanmou_switch",
  events = {fk.GameStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(quanmou)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    setTYMouSwitchSkillState(player, "simayi", "quanmou",
    player.room:askForChoice(player, { "tymou_switch:::quanmou:yang", "tymou_switch:::quanmou:yin" },
    "quanmou", "#tymou_switch-transer:::quanmou") == "tymou_switch:::quanmou:yin")
  end,
}
local quanmou_delay = fk.CreateTriggerSkill{
  name = "#quanmou_delay",
  events = {fk.DamageCaused, fk.Damage},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or player.phase ~= Player.Play or player ~= target then return false end
    if event == fk.DamageCaused then
      return table.contains(U.getMark(player, "quanmou_yang-phase"), data.to.id)
    elseif event == fk.Damage then
      return table.contains(U.getMark(player, "quanmou_yin-phase"), data.to.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(data.to, "@quanmou-phase", 0)
    if event == fk.DamageCaused then
      local mark = U.getMark(player, "quanmou_yang-phase")
      table.removeOne(mark, data.to.id)
      room:setPlayerMark(player, "quanmou_yang-phase", mark)
      room:notifySkillInvoked(player, "quanmou", "defensive")
      if player:getSwitchSkillState("quanmou", false) == fk.SwitchYang then
        player:broadcastSkillInvoke("quanmou")
      end
      return true
    elseif event == fk.Damage then
      local mark = U.getMark(player, "quanmou_yin-phase")
      table.removeOne(mark, data.to.id)
      room:setPlayerMark(player, "quanmou_yin-phase", mark)
      room:notifySkillInvoked(player, "quanmou", "offensive")
      if player:getSwitchSkillState("quanmou", false) == fk.SwitchYin then
        player:broadcastSkillInvoke("quanmou")
      end
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and p ~= data.to
      end)
      if #targets == 0 then return false end
      targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 3, "#quanmou-damage", "quanmou")
      if #targets == 0 then return false end
      room:sortPlayersByAction(targets)
      for _, id in ipairs(targets) do
        local p = room:getPlayerById(id)
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = "quanmou",
          }
        end
      end
    end
  end,
}
pingliao:addRelatedSkill(pingliao_prohibit)
quanmou:addRelatedSkill(quanmou_delay)
quanmou:addRelatedSkill(quanmou_switch)
tymou__simayi:addSkill(pingliao)
tymou__simayi:addSkill(quanmou)

local tymou2__simayi = General(extension, "tymou2__simayi", "wei", 3)
tymou2__simayi.hidden = true
tymou2__simayi:addSkill("pingliao")
tymou2__simayi:addSkill("quanmou")

Fk:loadTranslationTable{
  ["tymou__simayi"] = "谋司马懿",
  ["#tymou__simayi"] = "韬谋韫势",
  ["illustrator:tymou__simayi"] = "米糊PU",
  ["pingliao"] = "平辽",
  [":pingliao"] = "锁定技，当你使用【杀】时，不公开指定的目标，你攻击范围内的角色依次选择是否打出一张红色基本牌，"..
  "若此【杀】的目标未打出基本牌，其本回合无法使用或打出手牌；若有至少一名非目标打出基本牌，你摸两张牌且此阶段使用【杀】的次数上限+1。",
  ["quanmou"] = "权谋",
  [":quanmou"] = "转换技，游戏开始时可自选阴阳状态，出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，"..
  "阳：防止你此阶段下次对其造成的伤害；阴：你此阶段下次对其造成伤害后，可以对至多三名该角色外的其他角色各造成1点伤害。",

  ["#pingliao-ask"] = "平辽：%src 使用了一张【杀】，你可以打出一张红色基本牌",
  ["@@pingliao-turn"] = "平辽",
  ["#quanmou-Yang"] = "发动 权谋（阳），选择攻击范围内的一名角色",
  ["#quanmou-Yin"] = "发动 权谋（阴），选择攻击范围内的一名角色",
  ["#quanmou-give"] = "权谋：选择一张牌交给 %dest ",
  ["@quanmou-phase"] = "权谋",
  ["#quanmou_switch"] = "权谋",
  ["#quanmou_delay"] = "权谋",
  ["#quanmou-damage"] = "权谋：你可以选择1-3名角色，对这些角色各造成1点伤害",

  --阳形态
  ["$pingliao1"] = "烽烟起大荒，戎军远役，问不臣者谁？",
  ["$pingliao2"] = "挥斥千军之贲，长驱万里之远。",
  ["$quanmou1"] = "洛水为誓，皇天为证，吾意不在刀兵。",
  ["$quanmou2"] = "以谋代战，攻形不以力，攻心不以勇。",
  ["~tymou__simayi"] = "以权谋而立者，必失大义于千秋……",

  --阴形态
  ["tymou2__simayi"] = "谋司马懿",
  ["#tymou2__simayi"] = "韬谋韫势",
  ["illustrator:tymou2__simayi"] = "鬼画府",
  ["$pingliao_tymou2__simayi1"] = "率土之滨皆为王臣，辽土亦居普天之下。",
  ["$pingliao_tymou2__simayi2"] = "青云远上，寒锋试刃，北雁当寄红翎。",
  ["$quanmou_tymou2__simayi1"] = "鸿门之宴虽歇，会稽之胆尚悬，孤岂姬、项之辈？",
  ["$quanmou_tymou2__simayi2"] = "昔藏青锋于沧海，今潮落，可现兵！",
  ["~tymou2__simayi"] = "人立中流，非已力可向，实大势所迫……",
}

local jiaxu = General(extension, "tymou__jiaxu", "qun", 3)
local fumouj = fk.CreateActiveSkill{
  name = "fumouj",
  anim_type = "switch",
  switch_skill_name = "fumouj",
  card_num = 0,
  target_num = 1,
  prompt = function ()
    return Self:getSwitchSkillState("fumouj", false) == fk.SwitchYang and "#fumouj-Yang" or "#fumouj-Yin"
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    setTYMouSwitchSkillState(player, "jiaxu", self.name)
    local switch_state = player:getSwitchSkillState(self.name, true)

    local cids = target:getCardIds(Player.Hand)
    local x = (#cids +1)//2
    cids = room:askForCardsChosen(player, target, 1, x, {
      card_data = {
        { "$Hand", cids }
      }
    }, self.name, "#fumouj-show::".. target.id.. ":".. x)
    target:showCards(cids)
    room:delay(1000)
    if switch_state == fk.SwitchYang then
      local tos = {}
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p ~= target then
          table.insert(tos, p.id)
        end
      end
      if #tos == 0 then return end
      tos = room:askForChoosePlayers(player, tos, 1, 1, "#fumouj-choose::".. target.id, self.name, false, true)
      if #tos == 0 then return end
      room:obtainCard(tos[1], cids, true, fk.ReasonPrey, tos[1], self.name)
      x = #cids
      if not player.dead then
        player:drawCards(x, self.name)
      end
      if not target.dead then
        target:drawCards(x, self.name)
      end
    else
      local card
      local extra_data = {bypass_times = true, bypass_distances = true}
      local disresponsive_list = table.map(room.players, Util.IdMapper)
      for _, id in ipairs(cids) do
        if target.dead then break end
        if table.contains(target:getCardIds(Player.Hand), id) then
          card = Fk:getCardById(id)
          if U.getDefaultTargets(target, card, true, true) then
            local use = U.askForUseRealCard(room, target, {id}, nil, self.name,
            "#fumouj-use:::"..card:toLogString(), extra_data, true, false)
            if use then
              use.disresponsiveList = disresponsive_list
              room:useCard(use)
            end
          end
        end
      end
    end
  end,
}
local fumouj_switch = fk.CreateTriggerSkill{
  name = "#fumouj_switch",
  events = {fk.GameStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fumouj)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    setTYMouSwitchSkillState(player, "jiaxu", "fumouj",
    player.room:askForChoice(player, { "tymou_switch:::fumouj:yang", "tymou_switch:::fumouj:yin" },
    "fumouj", "#tymou_switch-transer:::fumouj") == "tymou_switch:::fumouj:yin")
  end,
}
local sushen = fk.CreateActiveSkill{
  name = "sushen",
  anim_type = "control",
  prompt = "#sushen-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "sushen_hp", player.hp)
    room:setPlayerMark(player, "sushen_handcardnum", player:getHandcardNum())
    if player:hasSkill(fumouj, true) then
      room:setPlayerMark(player, "sushen_state", player:getSwitchSkillState("fumouj", false, true))
    end
    room:handleAddLoseSkills(player, "rushi", nil, true, false)
  end,
}
local rushi = fk.CreateActiveSkill{
  name = "rushi",
  anim_type = "control",
  prompt = function ()
    return "#rushi-active:::" .. Self:getMark("sushen_hp") .. ":" .. Self:getMark("sushen_handcardnum")
    --..":" .. Self:getMark("sushen_state")
  end,
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player.hp - player:getMark("sushen_hp")
    if n > 0 then
      room:loseHp(player, n, self.name)
    elseif n < 0 and player:isWounded() then
      room:recover({
        who = player,
        num = math.min(-n, player:getLostHp()),
        recoverBy = player,
        skillName = self.name
      })
    end
    if player.dead then return end
    n = player:getHandcardNum() - player:getMark("sushen_handcardnum")
    if n > 0 then
      room:askForDiscard(player, n, n, false, self.name, false)
    elseif n < 0 then
      player:drawCards(-n, self.name)
    end
    if player:hasSkill(fumouj, true) then
      setTYMouSwitchSkillState(player, "jiaxu", "fumouj", player:getMark("sushen_state") == "yin")
      if player:usedSkillTimes("fumouj", Player.HistoryPhase) > 0 then
        player:setSkillUseHistory("fumouj", 0, Player.HistoryPhase)
      end
    end
  end,
}
jiaxu:addSkill(sushen)
fumouj:addRelatedSkill(fumouj_switch)
jiaxu:addSkill(fumouj)
jiaxu:addRelatedSkill(rushi)

local tymou2__jiaxu = General(extension, "tymou2__jiaxu", "qun", 3)
tymou2__jiaxu.hidden = true
tymou2__jiaxu:addSkill("sushen")
tymou2__jiaxu:addSkill("fumouj")
tymou2__jiaxu:addRelatedSkill("rushi")

Fk:loadTranslationTable{
  ["tymou__jiaxu"] = "谋贾诩",
  ["#tymou__jiaxu"] = "晦谋独善",
  ["illustrator:tymou__jiaxu"] = "鬼画府",
  ["sushen"] = "肃身",
  [":sushen"] = "限定技，出牌阶段，你可以记录你的体力值、手牌数和〖覆谋〗的阴阳状态，然后获得〖入世〗。",
  ["rushi"] = "入世",
  [":rushi"] = "限定技，出牌阶段，你可以将体力值、手牌数和〖覆谋〗的阴阳状态依次调整为〖肃身〗记录值且视为于此阶段内未发动过〖覆谋〗。",
  ["fumouj"] = "覆谋",
  [":fumouj"] = "转换技，游戏开始时可自选阴阳状态，出牌阶段限一次，你可以观看一名其他角色的所有手牌，"..
  "展示其中至多一半的牌（向上取整），阳：令另一名其他角色获得这些牌（正面朝上移动），你与失去牌的角色各摸等量张牌。"..
  "阴：令其按你选择的顺序依次使用这些牌（无距离限制且不能被响应）。",

  ["#sushen-active"] = "发动 肃身，记录你的体力值、手牌数和〖覆谋〗的阴阳状态",
  ["#rushi-active"] = "发动 入世，将体力值调整为%arg；将手牌数调整为%arg2",--；将〖覆谋〗调整为%arg3状态（FIXME:不支持arg3）
  ["#fumouj-Yang"] = "发动 覆谋（阳），观看1名其他角色的手牌，并将其中一半的牌交给另一名其他角色",
  ["#fumouj-Yin"] = "发动 覆谋（阴），观看1名其他角色的手牌，令其依次使用其中一半的牌",
  ["#fumouj-show"] = "覆谋：展示%dest的至多%arg张手牌",
  ["#fumouj-choose"] = "覆谋：选择1名其他角色，令其获得%dest展示的这些卡牌",
  ["#fumouj-use"] = "覆谋：使用 %arg（无距离限制且不能被响应）",
  ["#fumouj_switch"] = "覆谋",

  --阳形态
  ["$sushen1"] = "谋先于行则昌，行先于谋则亡。",
  ["$sushen2"] = "天行五色，雪覆林间睡狐，独我执白。",
  ["$rushi1"] = "孤立川上，观逝者如东去之流水。",
  ["$rushi2"] = "九州如画，怎可空老人间？",
  ["$fumouj1"] = "恩仇付浊酒，荡平劫波，且做英雄吼。",
  ["$fumouj2"] = "人无恒敌，亦无恒友，唯有恒利。",
  ["~tymou__jiaxu"] = "辛者抱薪，妄燃烽火以戏诸侯……",

  --阴形态
  ["tymou2__jiaxu"] = "谋贾诩",
  ["#tymou2__jiaxu"] = "晦谋独善",
  ["illustrator:tymou2__jiaxu"] = "鬼画府",
  ["$sushen_tymou2__jiaxu1"] = "我有三窟之筹谋，不蹈背水之维谷。",
  ["$sushen_tymou2__jiaxu2"] = "已积千里跬步，欲履万里河山。",
  ["$rushi_tymou2__jiaxu1"] = "曾寄青鸟凌云志，归来城头看王旗。",
  ["$rushi_tymou2__jiaxu2"] = "烽火照长安，淯水洗枯骨，今日对弈何人？",
  ["$fumouj_tymou2__jiaxu1"] = "不周之柱已折，这世间，当起一阵风、落一场雨！",
  ["$fumouj_tymou2__jiaxu2"] = "善谋者，不与善战者争功。",
  ["~tymou2__jiaxu"] = "未见青山草木，枯骨徒付浊流……",
}










--冢虎狼顾：蒋济、王凌、司马师、曹爽
local jiangji = General(extension, "tymou__jiangji", "wei", 3)
local shiju = fk.CreateActiveSkill{
  name = "shiju",
  anim_type = "support",
  prompt = "#shiju_self-active",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local id = effect.cards[1]
    if room:getCardArea(id) == Card.PlayerEquip then
      room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
    if player.dead or room:getCardArea(id) ~= Card.PlayerHand or room:getCardOwner(id) ~= player then return end
    local card = Fk:getCardById(id)
    if card.type ~= Card.TypeEquip then return end
    if
      not (player:canUseTo(card, player) and
      room:askForSkillInvoke(player, self.name, nil, "#shiju_self-use:::" .. card:toLogString()))
    then
      return
    end
    local no_draw = table.every(player:getCardIds(Player.Equip), function (cid)
      return Fk:getCardById(cid).sub_type ~= card.sub_type
    end)
    room:useCard({
      from = player.id,
      tos = {{ player.id }},
      card = card,
    })
    if player:isAlive() then
      local x = #player:getCardIds(Player.Equip)
      if x > 0 then
        x = x + player:getMark("shiju-turn")
        room:setPlayerMark(player, "shiju-turn", x)
        room:setPlayerMark(player, "@shiju-turn", "+" .. tostring(x))
      end
    end
    if not no_draw and player:isAlive() then
      room:drawCards(player, 2, self.name)
      room:drawCards(player, 2, self.name)
    end
  end,
}
local shijuTrigger = fk.CreateTriggerSkill{
  name = "#shiju_trigger",

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == shiju
    elseif event == fk.BuryVictim then
      return target:hasSkill(shiju, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function(p) return not p:hasSkill(shiju, true) or p == player end) then
      if player:hasSkill("shiju&", true, true) then
        room:handleAddLoseSkills(player, "-shiju&", nil, false, true)
      end
    else
      if not player:hasSkill("shiju&", true, true) then
        room:handleAddLoseSkills(player, "shiju&", nil, false, true)
      end
    end
  end,
}
local shiju_active = fk.CreateActiveSkill{
  name = "shiju&",
  anim_type = "support",
  prompt = "#shiju-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = U.getMark(player, "shiju_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(shiju) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(shiju) and
    not table.contains(U.getMark(Self, "shiju_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:broadcastSkillInvoke("shiju")
    local targetRecorded = U.getMark(player, "shiju_targets-phase")
    table.insertIfNeed(targetRecorded, target.id)
    room:setPlayerMark(player, "shiju_targets-phase", targetRecorded)
    local id = effect.cards[1]
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if target.dead or room:getCardArea(id) ~= Card.PlayerHand or room:getCardOwner(id) ~= target then return end
    local card = Fk:getCardById(id)
    if card.type ~= Card.TypeEquip then return end
    if not (target:canUseTo(card, target) and room:askForSkillInvoke(target, "shiju", nil, "#shiju-use:"..player.id.."::"..card:toLogString())) then return end
    local no_draw = table.every(target:getCardIds(Player.Equip), function (cid)
      return Fk:getCardById(cid).sub_type ~= card.sub_type
    end)
    room:useCard({
      from = target.id,
      tos = {{target.id}},
      card = card,
    })
    if not player.dead and not target.dead then
      local x = #target:getCardIds(Player.Equip)
      if x > 0 then
        x = x + player:getMark("shiju-turn")
        room:setPlayerMark(player, "shiju-turn", x)
        room:setPlayerMark(player, "@shiju-turn", "+" .. tostring(x))
      end
    end
    if no_draw then return end
    if not target.dead then
      room:drawCards(target, 2, self.name)
    end
    if not player.dead then
      room:drawCards(player, 2, self.name)
    end
  end,
}
local shiju_attackrange = fk.CreateAttackRangeSkill{
  name = "#shiju_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("shiju-turn")
  end,
}
local yingshij = fk.CreateTriggerSkill{
  name = "yingshij",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player:getMark("yingshij_nullified-turn") == 0 and
      data.firstTarget and
      data.card:isCommonTrick() and
      not table.contains(data.card.skillNames, self.name) and
      table.find(AimGroup:getAllTargets(data.tos), function(pId) return player.room:getPlayerById(pId):isAlive() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = AimGroup:getAllTargets(data.tos)
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#yingshij-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#yingshij-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local equipNum = #player:getCardIds(Player.Equip)
    if equipNum > 0 and #room:askForDiscard(to, equipNum, equipNum, true, self.name, true, ".",
      "#yingshij-discard:" .. player.id .. "::" .. tostring(equipNum) .. ":" .. data.card:toLogString()) > 0 then
      room:setPlayerMark(player, "yingshij_nullified-turn", 1)
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.yingshij = {
        from = player.id,
        to = to.id,
        subTargets = data.subTargets
      }
    end
  end,
}
local yingshij_delay = fk.CreateTriggerSkill{
  name = "#yingshij_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.yingshij and not player.dead then
      local use = table.simpleClone(data.extra_data.yingshij)
      if use.from == player.id then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = "yingshij"
        if player:prohibitUse(card) then return false end
        use.card = card
        local room = player.room
        local to = room:getPlayerById(use.to)
        if not to.dead and U.canTransferTarget(to, use, false) then
          local tos = {use.to}
          if use.subTargets then
            table.insertTable(tos, use.subTargets)
          end
          self.cost_data = {
            from = player.id,
            tos = table.map(tos, function(pid) return { pid } end),
            card = card,
            extraUse = true
          }
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:useCard(table.simpleClone(self.cost_data))
  end,
}
Fk:addSkill(shiju_active)
shiju:addRelatedSkill(shijuTrigger)
shiju:addRelatedSkill(shiju_attackrange)
yingshij:addRelatedSkill(yingshij_delay)
jiangji:addSkill(shiju)
jiangji:addSkill(yingshij)
Fk:loadTranslationTable{
  ["tymou__jiangji"] = "谋蒋济",
  ["#tymou__jiangji"] = "策论万机",
  ["illustrator:tymou__jiangji"] = "错落宇宙",
  ["designer:tymou__jiangji"] = "坑坑",

  ["shiju"] = "势举",
  [":shiju"] = "一名角色的出牌阶段限一次，其可以将一张牌交给你（若其为你，则改为你选择你的一张牌，若此牌为你装备区里的牌，你获得之），" ..
  "若此牌为装备牌，你可以使用之，并令其攻击范围于此回合内+X（X为你装备区里的牌数），"..
  "若你于使用此牌之前的装备区里有与此牌副类别相同的牌，你与其各摸两张牌。",
  ["yingshij"] = "应时",
  [":yingshij"] = "当你不因此技能使用普通锦囊牌指定第一个目标后，你可以令一名目标角色选择："..
  "1.当此牌结算后，你视为对其使用相同牌名的牌；2.弃置X张牌（X为你装备区里的牌数），然后此技能于当前回合内无效。",

  ["shiju&"] = "势举",
  [":shiju&"] = "出牌阶段限一次，你可以将一张牌交给谋蒋济。",
  ["#shiju_self-active"] = "势举：你可以选择你的一张牌，若此牌为装备牌则使用之并获得收益",
  ["#shiju_self-use"] = "势举：你可以使用%arg，令你增加攻击范围",
  ["#shiju-active"] = "发动 势举，选择一张牌交给一名拥有“势举”的角色",
  ["#shiju-use"] = "势举：你可以使用%arg，令%src增加攻击范围",
  ["@shiju-turn"] = "势举范围",
  ["#yingshij-invoke"] = "是否对%dest发动 应时",
  ["#yingshij-choose"] = "是否发动 应时，选择一名目标角色",
  ["#yingshij-discard"] = "应时：弃置%arg张牌，令%src的“应时”本回合失效，或者取消令此牌对你额外结算一次",
  ["#yingshij_delay"] = "应时",

  ["$shiju1"] = "借力为己用，可攀青云直上。",
  ["$shiju2"] = "应势而动，事半而功倍。",
  ["$yingshij1"] = "今君失道寡助，何不审时以降？",
  ["$yingshij2"] = "君既掷刀于地，可保富贵无虞。",
  ["~tymou__jiangji"] = "大醉解忧，然忧无解，唯忘耳……",
}


local wangling = General(extension, "tymou__wangling", "wei", 4)
local jichouw_distribution = fk.CreateActiveSkill{
  name = "jichouw_distribution",
  target_num = 1,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(self.jichouw_cards, to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and not table.contains(self.jichouw_targets, to_select)
  end,
  can_use = Util.FalseFunc,
}
Fk:addSkill(jichouw_distribution)
local jichouw = fk.CreateTriggerSkill{
  name = "jichouw",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local room = player.room
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      local names = {}
      local cards = {}
      U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id then
          if table.contains(names, use.card.trueName) then
            cards = {}
            return true
          end
          table.insert(names, use.card.trueName)
          table.insertTableIfNeed(cards, Card:getIdList(use.card))
        end
      end, phase_event.id)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(self.cost_data)
    local targets = {}
    local moveInfos = {}
    local names = {}
    while true do
      local success, dat = room:askForUseActiveSkill(player, "jichouw_distribution", "#jichouw-distribution", true,
      { expand_pile = cards, jichouw_cards = cards , jichouw_targets = targets }, true)
      if success then
        local to = dat.targets[1]
        local give_cards = dat.cards
        table.insert(targets, to)
        table.removeOne(cards, give_cards[1])
        table.insertIfNeed(names, Fk:getCardById(give_cards[1]).trueName)
        table.insert(moveInfos, {
          ids = give_cards,
          fromArea = Card.DiscardPile,
          to = to,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          proposer = player.id,
          skillName = self.name,
        })
        if #cards == 0 then break end
      else
        break
      end
    end
    if #moveInfos > 0 then
      local x = 0
      local mark = U.getMark(player, "@$jichouw")
      for _, name in ipairs(names) do
        if table.insertIfNeed(mark, name) then
          x = x + 1
        end
      end
      if x > 0 then
        room:setPlayerMark(player, "@$jichouw", mark)
      end
      room:moveCards(table.unpack(moveInfos))
      if x > 0 and not player.dead then
        player:drawCards(x, self.name)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@$jichouw") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$jichouw", 0)
  end,
}
local ty__mouli = fk.CreateTriggerSkill{
  name = "ty__mouli",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #U.getMark(player, "@$jichouw") > 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return false end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "ty__zifu", nil, true, false)
  end,
}
local ty__zifu_filter = fk.CreateActiveSkill{
  name = "ty__zifu_filter",
  target_num = 0,
  card_num = function(self)
    local names = {}
    for _, id in ipairs(Self:getCardIds(Player.Hand)) do
      table.insertIfNeed(names, Fk:getCardById(id).trueName)
    end
    return #names
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Hand then return false end
    local name = Fk:getCardById(to_select).trueName
    return table.every(selected, function(id)
      return name ~= Fk:getCardById(id).trueName
    end)
  end,
  target_filter = Util.FalseFunc,
  can_use = Util.FalseFunc,
}
Fk:addSkill(ty__zifu_filter)
local ty__zifu = fk.CreateTriggerSkill{
  name = "ty__zifu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
    player:getHandcardNum() < math.min(5, player.maxHp)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(5, player.maxHp)-player:getHandcardNum(), self.name)
    if player.dead then return false end
    local cards = {}
    local names = {}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local name = card.trueName
      if table.contains(names, name) then
        if not player:prohibitDiscard(card) then
          table.insert(cards, id)
        end
      else
        table.insert(names, name)
      end
    end
    if #names == player:getHandcardNum() then return false end
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ty__zifu_filter", "#ty__zifu-select", false)
    if success then
      cards = table.filter(player:getCardIds(Player.Hand), function (id)
        return not (table.contains(dat.cards, id) or player:prohibitDiscard(Fk:getCardById(id)))
      end)
    end
    if #cards > 0 then
      room:throwCard(cards, self.name, player, player)
    end
  end,
}
wangling:addSkill(jichouw)
wangling:addSkill(ty__mouli)
wangling:addRelatedSkill(ty__zifu)

Fk:loadTranslationTable{
  ["tymou__wangling"] = "谋王凌",
  ["#tymou__wangling"] = "风节格尚",
  ["illustrator:tymou__wangling"] = "鬼画府",

  ["jichouw"] = "集筹",
  [":jichouw"] = "出牌阶段结束时，若你于此阶段内使用过的牌的牌名各不相同，你可以将弃牌堆中的这些牌交给你选择的角色各一张。"..
  "然后你摸X张牌（X为其中此前没有以此法给出过的牌名数）。",
  ["ty__mouli"] = "谋立",
  [":ty__mouli"] = "觉醒技，回合结束时，若你因〖集筹〗给出的牌名不同的牌超过了5种，你加1点体力上限，回复1点体力，获得〖自缚〗。",
  ["ty__zifu"] = "自缚",
  [":ty__zifu"] = "锁定技，出牌阶段开始时，你将手牌摸至体力上限（至多摸至5张）。"..
  "若你因此摸牌，你保留手牌中每种牌名的牌各一张，弃置其余的牌。",

  ["#jichouw-distribution"] = "集筹：你可以将本回合使用过的牌交给每名角色各一张",
  ["jichouw_distribution"] = "集筹",
  ["@$jichouw"] = "集筹",
  ["ty__zifu_filter"] = "自缚",
  ["#ty__zifu-select"] = "自缚：选择每种牌名的牌各一张保留，弃置其余的牌",

  ["$jichouw1"] = "备武枕戈，待天下风起之时。",
  ["$jichouw2"] = "定淮联兖，邀群士共襄大义。",
  ["$ty__mouli1"] = "君上暗弱，以致受制于强臣。",
  ["$ty__mouli2"] = "吾闻楚王彪有智勇，可迎之于许都。",
  ["$ty__zifu1"] = "今势穷，吾自缚于斯，请太傅发落。",
  ["$ty__zifu2"] = "凌有罪，公劳师而来，唯系首待斩。",
  ["~tymou__wangling"] = "曹魏之盛，再难复梦……",
}

local simashi = General(extension, "tymou__simashi", "wei", 3)
local sanshi = fk.CreateTriggerSkill{
  name = "sanshi",
  events = {fk.CardUsing, fk.TurnEnd, fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUsing then
      return player == target and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not data.card:isVirtual() and table.contains(U.getMark(player, self.name), data.card.id)
    elseif event == fk.TurnEnd then
      local room = player.room
      local cards = table.filter(U.getMark(player, self.name), function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards == 0 then return false end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local ids = {}
      U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.removeOne(cards, id) then
              if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
                if move.moveReason == fk.ReasonUse then
                  local use_event = e:findParent(GameEvent.UseCard)
                  if use_event == nil or use_event.data[1].from ~= player.id then
                    table.insert(ids, id)
                  end
                else
                  table.insert(ids, id)
                end
              end
            end
          end
        end
      end, turn_event.id)
      if #ids > 0 then
        self.cost_data = ids
        return true
      end
    elseif event == fk.GameStart then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(player.room.players, Util.IdMapper)
    elseif event == fk.TurnEnd then
      room:moveCardTo(table.simpleClone(self.cost_data), Card.PlayerHand, player, fk.ReasonPrey, self.name)
    elseif event == fk.GameStart then
      local cardmap = {}
      for i = 1, 13, 1 do
        table.insert(cardmap, {})
      end
      for _, id in ipairs(room.draw_pile) do
        local n = Fk:getCardById(id).number
        if n > 0 and n < 14 then
          table.insert(cardmap[n], id)
        end
      end
      local cards = {}
      for _, ids in ipairs(cardmap) do
        if #ids > 0 then
          table.insert(cards, table.random(ids))
        end
      end
      room:setPlayerMark(player, self.name, cards)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and #U.getMark(player, self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = U.getMark(player, self.name)
    local handcards = player:getCardIds(Player.Hand)
    for _, cid in ipairs(cards) do
      local card = Fk:getCardById(cid)
      if table.contains(handcards, cid) and card:getMark("@@expendables-inhand") == 0 then
        room:setCardMark(card, "@@expendables-inhand", 1)
      end
    end
  end,
}
local zhenrao = fk.CreateTriggerSkill{
  name = "zhenrao",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if target == player then
      if not data.firstTarget then return false end
      local tos = AimGroup:getAllTargets(data.tos)
      local targets = {}
      local mark = U.getMark(player, "zhenrao-turn")
      for _, p in ipairs(player.room.alive_players) do
        if p:getHandcardNum() > player:getHandcardNum() and
        table.contains(tos, p.id) and not table.contains(mark, p.id) then
          table.insert(targets, p.id)
        end
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    else
      if data.to == player.id and not target.dead and player:getHandcardNum() < target:getHandcardNum() and
      not table.contains(U.getMark(player, "zhenrao-turn"), target.id) then
        self.cost_data = {target.id}
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.simpleClone(self.cost_data)
    local room = player.room
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#zhenrao-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets[1]
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#zhenrao-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "zhenrao-turn")
    table.insert(mark, self.cost_data)
    room:setPlayerMark(player, "zhenrao-turn", mark)
    room:damage{
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,
}
local chenlue = fk.CreateActiveSkill{
  name = "chenlue",
  anim_type = "drawcard",
  prompt = "#chenlue-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and #U.getMark(player, "sanshi") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local areas = {Card.PlayerEquip, Card.PlayerJudge, Card.DrawPile, Card.DiscardPile}
    local cards = table.filter(U.getMark(player, "sanshi"), function (id)
      local area = room:getCardArea(id)
      return table.contains(areas, area) or (area == Card.PlayerHand and room:getCardOwner(id) ~= player)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      room:setPlayerMark(player, "chenlue-phase", cards)
    end
  end,
}
local chenlue_delay = fk.CreateTriggerSkill{
  name = "#chenlue_delay",
  events = {fk.EventPhaseEnd},
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player.dead or player:getMark("chenlue-phase") == 0 then return false end
    local areas = {Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}
    local room = player.room
    local cards = table.filter(U.getMark(player, "chenlue-phase"), function (id)
      return table.contains(areas, room:getCardArea(id))
    end)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:addToPile("#chenlue", table.simpleClone(self.cost_data), true, self.name)
  end,
}
chenlue:addRelatedSkill(chenlue_delay)
simashi:addSkill(sanshi)
simashi:addSkill(zhenrao)
simashi:addSkill(chenlue)
Fk:loadTranslationTable{
  ["tymou__simashi"] = "谋司马师",
  ["#tymou__simashi"] = "唯几成务",
  ["illustrator:tymou__simashi"] = "鬼画府",

  ["sanshi"] = "散士",
  [":sanshi"] = "锁定技，游戏开始时，你将牌堆里每个点数的随机一张牌标记为“死士”牌。"..
  "一名角色的回合结束时，你获得弃牌堆里于本回合非因你使用或打出而移至此区域的“死士”牌。"..
  "当你使用“死士”牌时，你令此牌不可被响应。",
  ["zhenrao"] = "震扰",
  [":zhenrao"] = "每回合对每名角色限一次，当你使用牌指定第一个目标后，或其他角色使用牌指定你为目标后，"..
  "你可以选择手牌数大于你的其中一个目标或使用者，对其造成1点伤害。",
  ["chenlue"] = "沉略",
  [":chenlue"] = "限定技，出牌阶段，你可以从牌堆、弃牌堆、场上或其他角色的手牌中获得所有“死士”牌，"..
  "此阶段结束时，将这些牌移出游戏直到你死亡。",
  ["@@expendables-inhand"] = "死士",
  ["#zhenrao-choose"] = "是否发动 震扰，对其中手牌数大于你的1名角色造成1点伤害",
  ["#zhenrao-invoke"] = "是否发动 震扰，对%dest造成1点伤害",
  ["#chenlue-active"] = "发动 沉略，获得所有被标记的“死士”牌（回合结束后移出游戏）",
  ["#chenlue_delay"] = "沉略",
  ["#chenlue"] = "沉略",

  ["$sanshi1"] = "春雨润物，未觉其暖，已见其青。",
  ["$sanshi2"] = "养士效孟尝，用时可得千臂之助力。",
  ["$zhenrao1"] = "此病需静养，怎堪兵戈铁马之扰。",
  ["$zhenrao2"] = "孤值有疾，竟为文家小儿所扰。",
  ["$chenlue1"] = "怀泰山之重，必立以千仞。",
  ["$chenlue2"] = "万世之勋待取，此乃亮剑之时。",
  ["~tymou__simashi"] = "东兴之败，此我过也，诸将何罪……",
}

local caoshuang = General(extension, "tymou__caoshuang", "wei", 4)
local function doJianzhuan(player, choice, x)
  local room = player.room
  if choice == "jianzhuan1" then
    local targets = room:getOtherPlayers(player, false)
    if #targets == 0 then return end
    targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
    "#jianzhuan-target:::" .. tostring(x), "jianzhuan", false)
    room:askForDiscard(room:getPlayerById(targets[1]), x, x, true, "jianzhuan", false)
  elseif choice == "jianzhuan2" then
    player:drawCards(x, "jianzhuan")
  elseif choice == "jianzhuan3" then
    x = math.min(x, #player:getCardIds("he"))
    if x > 0 then
      local cards = room:askForCard(player, x, x, true, "jianzhuan", false, ".", "#jianzhuan-recast:::" .. tostring(x))
      room:recastCard(cards, player, "jianzhuan")
    end
  elseif choice == "jianzhuan4" then
    room:askForDiscard(player, x, x, true, "jianzhuan", false)
  end
end
local jianzhuan = fk.CreateTriggerSkill{
  name = "jianzhuan",
  anim_type = "drawcard",
  mute = true,
  events = {fk.CardUsing, fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local choices, all_choices = {}, {}
      for i = 1, 4, 1 do
        local mark = "jianzhuan"..tostring(i)
        if player:getMark(mark) == 0 then
          table.insert(all_choices, mark)
          if player:getMark(mark .. "-phase") == 0 then
            table.insert(choices, mark)
          end
        end
      end
      if event == fk.CardUsing and #choices > 0 then
        self.cost_data = {choices, all_choices}
        return true
      elseif event == fk.EventPhaseEnd and #choices == 0 and #all_choices > 1 then
        self.cost_data = all_choices
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUsing then
      room:notifySkillInvoked(player, self.name)
      local choices = table.simpleClone(self.cost_data)
      local x = player:usedSkillTimes(self.name, Player.HistoryPhase)
      local choice = room:askForChoice(player, choices[1], self.name, "#jianzhuan-choice:::"..tostring(x), nil, choices[2])
      room:setPlayerMark(player, choice .. "-phase", 1)
      doJianzhuan(player, choice, x)
    else
      room:notifySkillInvoked(player, self.name, "negative")
      room:setPlayerMark(player, table.random(self.cost_data), 1)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jianzhuan1", 0)
    room:setPlayerMark(player, "jianzhuan2", 0)
    room:setPlayerMark(player, "jianzhuan3", 0)
    room:setPlayerMark(player, "jianzhuan4", 0)
  end,
}
local fanshi = fk.CreateTriggerSkill{
  name = "fanshi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:hasSkill(self)
    and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    if player:hasSkill(jianzhuan, true) then
      local x = 0
      for i = 1, 4, 1 do
        if player:getMark("jianzhuan"..tostring(i)) == 0 then
          x = x + 1
        end
      end
      return x < 2
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = ""
    for i = 1, 4, 1 do
      choice = "jianzhuan"..tostring(i)
      if player:getMark(choice) == 0 then
        for j = 1, 3, 1 do
          doJianzhuan(player, choice, 1)
          if player.dead then return false end
        end
        break
      end
    end
    room:changeMaxHp(player, 2)
    if player.dead then return false end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 2,
        recoverBy = player,
        skillName = self.name,
      })
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "-jianzhuan|fudou", nil, true, false)
  end,
}
local fudou = fk.CreateTriggerSkill{
  name = "fudou",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player ~= target or data.to == player.id then return false end
    local room = player.room
    local to = room:getPlayerById(data.to)
    if to.dead or not U.isOnlyTarget(to, data, event) then return false end
    local mark = U.getMark(player, "fudou_record")
    if table.contains(mark, data.to) then
      return data.card.color == Card.Black
    else
      if #U.getActualDamageEvents(room, 1, function (e)
        local damage = e.data[1]
        if damage.from == to and damage.to == player then
          return true
        end
      end, nil, 0) > 0 then
        table.insert(mark, data.to)
        room:setPlayerMark(player, "fudou_record", mark)
        return data.card.color == Card.Black
      else
        return data.card.color == Card.Red
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local opinion = data.card.color == Card.Black and "loseHp" or "draw1"
    if room:askForSkillInvoke(player, self.name, nil, "#fanshi-invoke::"..data.to .. ":" .. opinion) then
      room:doIndicate(player.id, {data.to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local to = room:getPlayerById(data.to)
    if data.card.color == Card.Red then
      room:notifySkillInvoked(player, self.name, "support")
      player:drawCards(1, self.name)
      if not to.dead then
        to:drawCards(1, self.name)
      end
    elseif data.card.color == Card.Black then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:loseHp(player, 1, self.name)
      if not to.dead then
        room:loseHp(to, 1, self.name)
      end
    end
  end,
}
caoshuang:addSkill(jianzhuan)
caoshuang:addSkill(fanshi)
caoshuang:addRelatedSkill(fudou)
Fk:loadTranslationTable{
  ["tymou__caoshuang"] = "谋曹爽",
  ["#tymou__caoshuang"] = "托孤傲臣",
  ["illustrator:tymou__caoshuang"] = "鬼画府",
  ["designer:tymou__caoshuang"] = "韩旭",

  ["jianzhuan"] = "渐专",
  [":jianzhuan"] = "锁定技，当你于出牌阶段内使用牌时，你选择于此阶段内未选择过的一项："..
  "1.令一名其他角色弃置X张牌；2.摸X张牌；3.重铸X张牌；4.弃置X张牌。"..
  "出牌阶段结束时，若选项数大于1且所有选项于此阶段内都被选择过，你随机删除一个选项。（X为你于此阶段内发动过此技能的次数）",
  ["fanshi"] = "返势",
  [":fanshi"] = "觉醒技，结束阶段。若〖渐专〗的选项数小于2，你依次执行3次剩余项，加2点体力上限，回复2点体力，失去〖渐专〗，获得〖覆斗〗。",
  ["fudou"] = "覆斗",
  [":fudou"] = "当你使用黑色/红色牌指定其他角色为唯一目标后，若其对你造成过伤害/没有对你造成过伤害，你可以与其各失去1点体力/摸一张牌。",

  ["#jianzhuan-choice"] = "渐专：选择执行的一项（其中X为%arg）",
  ["jianzhuan1"] = "令一名角色弃置X张牌",
  ["jianzhuan2"] = "摸X张牌",
  ["jianzhuan3"] = "重铸X张牌",
  ["jianzhuan4"] = "弃置X张牌",
  ["#jianzhuan-target"] = "渐专：选择一名角色，令其弃置%arg张牌",
  ["#jianzhuan-recast"] = "渐专：选择%arg张牌重铸",
  ["#fanshi-invoke"] = "是否发动 覆斗，与%dest各 %arg",

  ["$jianzhuan1"] = "今作擎天之柱，何怜八方风雨？",
  ["$jianzhuan2"] = "吾寄百里之命，当居万丈危楼。",
  ["$fanshi1"] = "垒巨木为寨，发屯兵自守。",
  ["$fanshi2"] = "吾居伊周之位，怎可以罪见黜？",
  ["$fudou1"] = "既作困禽，何妨铤险以覆车？",
  ["$fudou2"] = "据将覆之巢，必作犹斗之困兽。",
  ["~tymou__caoshuang"] = "我度太傅之意，不欲伤我兄弟耳……",
}

--子敬邀刀：诸葛瑾、关平

local zhugejin = General(extension, "tymou__zhugejin", "wu", 3)
local zijin = fk.CreateTriggerSkill{
  name = "zijin",
  events = {fk.CardUseFinished},
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and not data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#zijin-discard") == 0 then
      room:loseHp(player, 1, self.name)
    end
  end,
}
local taozhou = fk.CreateActiveSkill{
  name = "taozhou",
  anim_type = "control",
  prompt = "#taozhou-active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 3,
    }
  end,
  can_use = function(self, player)
    return player:getMark(self.name) == 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return not (target:isKongcheng() or target:hasSkill(zijin))
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = self.interaction.data
    room:setPlayerMark(player, self.name, n)
    local cards = room:askForCard(target, 1, 3, false, self.name, true, ".|.|.|hand", "#taozhou-give:"..player.id)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, player.id)
    end
    if #cards < n then
      if target.dead then return end
      n = n - #cards
      room:addPlayerMark(target, "@taozhou_damage", n)
      if n > 1 then
        if not player.dead then
          room:useVirtualCard("slash", {}, target, player, self.name, true)
        end
        if not target.dead then
          room:handleAddLoseSkills(target, "zijin", nil)
        end
      end
    else
      if not player.dead then
        player:drawCards(1, self.name)
      end
      if not target.dead then
        target:drawCards(1, self.name)
      end
    end
  end,
}
local taozhou_trigger = fk.CreateTriggerSkill{
  name = "#taozhou_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@taozhou_damage") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@taozhou_damage", 1)
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.RoundEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("taozhou") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "taozhou", 1)
  end,
}
local houde = fk.CreateTriggerSkill{
  name = "houde",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local room = player.room
      if room.current == player or room.current.phase ~= Player.Play then return false end
      if data.card.trueName == "slash" then
        if data.card.color ~= Card.Red or player:isNude() then return false end
        local mark = player:getMark("houde_slash-phase")
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return false end
        if mark == 0 then
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data[1]
            if use.card.trueName == "slash" and use.card.color == Card.Red and
            table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
              mark = e.id
              room:setPlayerMark(player, "houde_slash-phase", mark)
              return true
            end
          end, Player.HistoryPhase)
        end
        return mark == use_event.id
      elseif data.card:isCommonTrick() then
        if data.card.color ~= Card.Black or room.current.dead or room.current:isNude() then return false end
        local mark = player:getMark("houde_trick-phase")
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return false end
        if mark == 0 then
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data[1]
            if use.card:isCommonTrick() and use.card.color == Card.Black and
            table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
              mark = e.id
              room:setPlayerMark(player, "houde_trick-phase", mark)
              return true
            end
          end, Player.HistoryPhase)
        end
        return mark == use_event.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if data.card.trueName == "slash" then
      local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".",
      "#houde-slash-invoke::" .. data.from .. ":" .. data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      local room = player.room
      if room:askForSkillInvoke(player, self.name, nil,
      "#houde-trick-invoke:".. room.current.id ..":" .. data.from .. ":" .. data.card:toLogString()) then
        room:doIndicate(player.id, {room.current.id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.card.trueName == "slash" then
      player.room:throwCard(self.cost_data, self.name, player, player)
    else
      local room = player.room
      local id = room:askForCardChosen(player, room.current, "he", self.name)
      room:throwCard({id}, self.name, room.current, player)
    end
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
taozhou:addRelatedSkill(taozhou_trigger)
zhugejin:addSkill(taozhou)
zhugejin:addSkill(houde)
zhugejin:addRelatedSkill(zijin)

Fk:loadTranslationTable{
  ["tymou__zhugejin"] = "谋诸葛瑾",
  ["#tymou__zhugejin"] = "清雅德纯",
  ["illustrator:tymou__zhugejin"] = "君桓文化",
  --["designer:tymou__zhugejin"] = "",

  ["taozhou"] = "讨州",
  [":taozhou"] = "出牌阶段，你可以从1-3中秘密选择一个数字并选择一名有手牌且没有〖自矜〗的其他角色，此技能失效至对应轮数后恢复，"..
  "其可以将至多三张手牌交给你，若其以此法交给你的牌数：大于等于你选择的数字，你与其各摸一张牌；"..
  "小于你选择的数字，其下X次受到的伤害+1（X为两者差值），若X大于1，则其视为对你使用【杀】，其获得〖自矜〗。",
  ["houde"] = "厚德",
  [":houde"] = "当你于其他角色的出牌阶段内第一次成为红色【杀】/黑色普通锦囊牌的目标后，你可以弃置一张牌/弃置其一张牌，"..
  "此【杀】/锦囊牌对你无效。",
  ["zijin"] = "自矜",
  [":zijin"] = "锁定技，当牌使用结算结束后，若使用者为你且此牌未造成过伤害，你选择：1.弃置一张牌；2.失去1点体力。",

  ["#taozhou-active"] = "发动 讨州，从1-3中选择一个数字并选择一名有手牌的其他角色",
  ["#taozhou-give"] = "讨州：你可以选择1-3张手牌交给 %src",
  ["#taozhou_trigger"] = "讨州",
  ["@taozhou_damage"] = "讨州",
  ["#houde-slash-invoke"] = "是否发动 厚德，弃置一张牌，令%dest使用的%arg对你无效",
  ["#houde-trick-invoke"] = "是否发动 厚德，弃置%dest的一张牌，令%dest使用的%arg对你无效",
  ["#zijin-discard"] = "自矜：你需要弃置一张牌，否则你失去1点体力",


  ["$taozhou1"] = "皇叔借荆州久矣，谨特来讨要。",
  ["$taozhou2"] = "荆州弹丸之地，诸君岂可食言而肥？",
  ["$houde1"] = "君子有德，可以载天下之重。",
  ["$houde2"] = "南山有松，任尔风雨雷霆。",
  ["~tymou__zhugejin"] = "吾数梦，琅琊旧园……",
}

local guanping = General(extension, "tymou__guanping", "shu", 4)
local wuwei = fk.CreateViewAsSkill{
  name = "wuwei",
  anim_type = "offensive",
  prompt = "#wuwei-active",
  interaction = function()
    local reds, blacks = {}, {}
    local colors = {}
    local color
    for _, id in ipairs(Self:getCardIds(Player.Hand)) do
      color = Fk:getCardById(id).color
      if color == Card.Red then
        table.insert(reds, id)
      elseif color == Card.Black then
        table.insert(blacks, id)
      end
    end
    if #reds > 0 then
      local card = Fk:cloneCard("slash")
      card:addSubcards(reds)
      card.skillName = "wuwei"
      if not Self:prohibitUse(card) then
        table.insert(colors, "red")
      end
    end
    if #blacks > 0 then
      local card = Fk:cloneCard("slash")
      card:addSubcards(blacks)
      card.skillName = "wuwei"
      if not Self:prohibitUse(card) then
        table.insert(colors, "black")
      end
    end
    return UI.ComboBox {choices = colors, all_choices = {"red", "black"}}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card:addSubcards(table.filter(Self:getCardIds(Player.Hand), function(id)
      return Fk:getCardById(id):getColorString() == self.interaction.data
    end))
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local types = {}
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    use.extra_data = use.extra_data or {}
    use.extra_data.wuwei_num = {player.id, #types}
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) <= player:getMark("wuwei_addtimes-turn") and
    not player:isKongcheng()
  end,
}
local wuwei_targetmod = fk.CreateTargetModSkill{
  name = "#wuwei_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, wuwei.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, wuwei.name)
  end,
}
local wuwei_trigger = fk.CreateTriggerSkill{
  name = "#wuwei_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.extra_data and data.extra_data.wuwei_num and data.extra_data.wuwei_num[1] == player.id then
      self.cost_data = data.extra_data.wuwei_num[2]
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local choices = {}
    for i = 1, x, 1 do
      local choice = room:askForChoice(player, {"draw1", "wuwei_invalidity", "wuwei_addtimes"}, "wuwei",
      "#wuwei-choose:::" .. i .. ":" .. x)
      table.insertIfNeed(choices, choice)
      if choice == "draw1" then
        player:drawCards(1, "wuwei")
        if player.dead then break end
      elseif choice == "wuwei_invalidity" then
        for _, pid in ipairs(TargetGroup:getRealTargets(data.tos)) do
          local to = room:getPlayerById(pid)
          if not to.dead then
            room:addPlayerMark(to, "@@wuwei-turn")
            room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
          end
        end
      elseif choice == "wuwei_addtimes" then
        room:addPlayerMark(player, "wuwei_addtimes-turn")
      end
    end
    if #choices == 3 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
wuwei:addRelatedSkill(wuwei_targetmod)
wuwei:addRelatedSkill(wuwei_trigger)
guanping:addSkill(wuwei)
Fk:loadTranslationTable{
  ["tymou__guanping"] = "谋关平",
  ["#tymou__guanping"] = "百战烈烈",
  --["designer:tymou__guanping"] = "",
  ["illustrator:tymou__guanping"] = "黯荧岛",

  ["wuwei"] = "武威",
  [":wuwei"] = "出牌阶段限一次，你可以将一种颜色的所有手牌当【杀】使用（无距离和次数限制），"..
  "当此【杀】被使用时，你依次选择X次（X为转化前这些牌的类别数）：1.摸一张牌；2.目标角色的所有不带“锁定技”标签的技能于此回合内无效；"..
  "3.此技能于此回合内发动的次数上限+1。若你选择了所有项，此【杀】的伤害值基数+1。",

  ["#wuwei-active"] = "发动 武威，将一种颜色的所有手牌当【杀】使用，并根据类别数选择等量的效果",
  ["#wuwei_trigger"] = "武威",
  ["#wuwei-choose"] = "武威：选择一项执行（%arg/%arg2）",
  ["wuwei_invalidity"] = "目标非锁定技失效",
  ["wuwei_addtimes"] = "此技能发动次数+1",
  ["@@wuwei-turn"] = "武威",

  ["$wuwei1"] = "残阳洗长刀，漫卷天下帜。",
  ["$wuwei2"] = "武效万人敌，复行千里路。",
  ["~tymou__guanping"] = "生未屈刀兵，死罢战黄泉……",
}

--毒士鸩计：曹昂 张绣 典韦

local caoang = General(extension, "tymou__caoang", "wei", 4)
local fengmin = fk.CreateTriggerSkill{
  name = "fengmin",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getMark("@@fengmin-turn") == 0 then
      for _, move in ipairs(data) do
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return move.from and player.room:getPlayerById(move.from).phase ~= Player.NotActive and
              #player.room:getPlayerById(move.from):getCardIds("e") < 5
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(5 - #player.room.current:getCardIds("e"), self.name)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) > player:getLostHp() then
      player.room:setPlayerMark(player, "@@fengmin-turn", 1)
    end
  end,
}
local zhiwang = fk.CreateTriggerSkill{
  name = "zhiwang",
  anim_type = "special",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true) and data.damage and data.damage.card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#zhiwang-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage.from = nil
    local to = room:getPlayerById(self.cost_data)
    local mark = U.getMark(to, "@@zhiwang-turn")
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(to, "@@zhiwang-turn", mark)
  end,
}
local zhiwang_delay = fk.CreateTriggerSkill{
  name = "#zhiwang_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@zhiwang-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "@@zhiwang-turn")
    local cards = {}
    for _, id in ipairs(mark) do
      local p = room:getPlayerById(id)
      room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        if e.data[1].who == p.id and e.data[1].damage and e.data[1].damage.card and U.isPureCard(e.data[1].damage.card) then
          if table.contains(room.discard_pile, e.data[1].damage.card.id) then
            table.insertIfNeed(cards, e.data[1].damage.card.id)
          end
        end
        return false
      end, Player.HistoryTurn)
    end
    if #cards == 0 then return false end
    while not player.dead and #cards > 0 do
      local use = U.askForUseRealCard(room, player, cards, ".", "zhiwang", "#zhiwang-use",
        {expand_pile = cards, bypass_times = true, extraUse = true}, true)
      if use then
        table.removeOne(cards, use.card:getEffectiveId())
        room:useCard(use)
      else
        return
      end
    end
  end,
}
zhiwang:addRelatedSkill(zhiwang_delay)
caoang:addSkill(fengmin)
caoang:addSkill(zhiwang)
Fk:loadTranslationTable{
  ["tymou__caoang"] = "谋曹昂",
  ["#tymou__caoang"] = "两全忠孝",
  --["illustrator:tymou__caoang"] = "",

  ["fengmin"] = "丰愍",
  [":fengmin"] = "锁定技，一名角色于其回合内失去装备区的牌后，你摸其装备区空位数的牌。若此技能发动次数大于你已损失体力值，本回合失效。",
  ["zhiwang"] = "质亡",
  [":zhiwang"] = "每回合限一次，当你受到牌造成的伤害进入濒死状态时，你可以将此伤害改为无来源伤害并选择一名其他角色，当前回合结束时，"..
  "其使用弃牌堆中令你进入濒死状态的牌。",
  ["@@fengmin-turn"] = "丰愍失效",
  ["#zhiwang-choose"] = "质亡：将伤害改为无伤害来源，并令一名角色本回合结束可以使用使你进入濒死状态的牌",
  ["@@zhiwang-turn"] = "质亡",
  ["#zhiwang-use"] = "质亡：请使用这些牌",
}

local zhangxiu = General(extension, "tymou__zhangxiu", "qun", 4)
local fuxi = fk.CreateTriggerSkill{
  name = "fuxi",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and not target.dead and player ~= target and
    table.every(player.room.alive_players, function (p)
      return p == target or p:getHandcardNum() <= target:getHandcardNum()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel", "fuxi_discard"}
    if not player:isNude() then
      table.insert(choices, "fuxi_give")
    end
    local choice = room:askForChoice(player, choices, self.name, "#fuxi-choice::" .. target.id, false,
    {"fuxi_give", "fuxi_discard", "Cancel"})
    if choice == "Cancel" then return false end
    room:doIndicate(player.id, {target.id})
    self.cost_data = choice
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
      player:broadcastSkillInvoke(self.name)
    if self.cost_data == "fuxi_give" then
      room:notifySkillInvoked(player, self.name, "support")
      local cards = room:askForCard(player, 1, 1, true, self.name, false, ".", "#fuxi-give::" .. target.id)
      room:obtainCard(target, cards, false, fk.ReasonGive, player.id, self.name)
      if not player.dead then
        player:drawCards(2, self.name)
      end
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({card}, self.name, target, player)
        if player.dead or target.dead then return false end
      end
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
local haoyi = fk.CreateTriggerSkill{
  name = "haoyi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.Finish then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      local cards = {}
      U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if room:getCardArea(info.cardId) == Card.DiscardPile and Fk:getCardById(info.cardId, true).is_damage_card then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
        return false
      end, end_id)
      if #cards == 0 then return false end
      local damage
      U.getActualDamageEvents(room, 1, function (e)
        damage = e.data[1]
        if damage.card then
          for _, id in ipairs(Card:getIdList(damage.card)) do
            if table.removeOne(cards, id) and #cards == 0 then
              return true
            end
          end
        end
      end, nil, end_id)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(self.cost_data)
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player.id, self.name)
    if player.dead then return false end
    cards = table.filter(player:getCardIds(Player.Hand), function (id)
      return table.contains(cards, id)
    end)
    if #cards > 0 then
      U.askForDistribution(player, cards, room:getOtherPlayers(player), self.name)
    end
  end,
}
zhangxiu:addSkill(fuxi)
zhangxiu:addSkill(haoyi)
Fk:loadTranslationTable{
  ["tymou__zhangxiu"] = "谋张绣",
  ["#tymou__zhangxiu"] = "凌枪破宛",
  ["illustrator:tymou__zhangxiu"] = "君桓文化",

  ["fuxi"] = "附袭",
  [":fuxi"] = "其他角色的出牌阶段开始时，若其为手牌数最多的角色，你可以选择："..
  "1.将一张牌交给其，你摸两张牌；2.弃置其一张牌，视为对其使用【杀】。",
  ["haoyi"] = "豪义",
  [":haoyi"] = "结束阶段，你可以获得弃牌堆里于此回合内移至此区域的未造成过伤害的所有伤害类牌，然后你可以将这些牌中的任意张交给其他角色。",

  ["#fuxi-choice"] = "是否对 %dest 发动 附袭，选择一项操作",
  ["fuxi_give"] = "将一张牌交给该角色，你摸两张牌",
  ["fuxi_discard"] = "弃置其一张牌，视为对其使用【杀】",
  ["#fuxi-give"] = "附袭：选择一张牌，交给 %dest",

  ["$fuxi1"] = "可因势而附，亦可因势而袭。",
  ["$fuxi2"] = "仗剑在手，或亮之，或藏之。",
  ["$haoyi1"] = "今缴丧敌之炙，且宴麾下袍泽。",
  ["$haoyi2"] = "龙骧枯荣一体，岂曰同袍无衣。",
  ["~tymou__zhangxiu"] = "曹贼……欺我太甚！",
}

local dianwei = General(extension, "tymou__dianwei", "wei", 4, 5)
local kuangzhan = fk.CreateActiveSkill{
  name = "kuangzhan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#kuangzhan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getHandcardNum() < player.maxHp
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player.maxHp - player:getHandcardNum()
    player:drawCards(n, self.name)
    for i = 1, n, 1 do
      if player.dead then return end
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return player:canPindian(p) end), Util.IdMapper)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuangzhan-choose:::"..i..":"..n, self.name, false)
      to = room:getPlayerById(to[1])
      local pindian = player:pindian({to}, self.name)
      if pindian.results[to.id].winner == player then
        local tos = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room.logic:getEventsOfScope(GameEvent.Pindian, 1, function(e)
            local dat = e.data[1]
              if dat.results[p.id] and dat.results[p.id].winner ~= p then
                table.insertIfNeed(tos, p)
              end
            return false
          end, Player.HistoryTurn)
        end
        if #tos > 0 then
          room:useVirtualCard("slash", nil, player, tos, self.name, true)
        end
      else
        room:useVirtualCard("slash", nil, to, player, self.name, true)
      end
    end
  end,
}
local kangyong = fk.CreateTriggerSkill{
  name = "kangyong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TurnStart then
        return player:isWounded()
      else
        return player.hp > 1 and player:getMark("kangyong-turn") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local n = player:getLostHp()
      room:setPlayerMark(player, "kangyong-turn", n)
      room:recover({
        who = player,
        num = n,
        recoverBy = player,
        skillName = self.name
      })
    else
      local n = math.min(player:getMark("kangyong-turn"), player.hp - 1)
      room:loseHp(player, n, self.name)
    end
  end,
}
dianwei:addSkill(kuangzhan)
dianwei:addSkill(kangyong)
Fk:loadTranslationTable{
  ["tymou__dianwei"] = "谋典韦",
  ["#tymou__dianwei"] = "狂战怒莽",
  ["illustrator:tymou__dianwei"] = "黯荧岛",

  ["kuangzhan"] = "狂战",
  [":kuangzhan"] = "出牌阶段限一次，你可以将手牌摸至体力上限并依次拼点X次（X为你以此法摸牌数），"..
  "每次拼点若你：赢，你视为对所有本回合拼点未赢的其他角色使用一张【杀】；没赢，其视为对你使用一张【杀】。",
  ["kangyong"] = "亢勇",
  [":kangyong"] = "锁定技，回合开始时，你回复体力至体力上限；回合结束时，你失去等量体力（至多失去至1点）。",
  ["#kuangzhan"] = "狂战：摸牌至体力上限，根据摸牌数拼点",
  ["#kuangzhan-choose"] = "狂战：拼点，若赢，你视为对所有拼点输的角色使用【杀】；若没赢，其视为对你使用【杀】（第%arg次，共%arg2次！）",

  ["$kuangzhan1"] = "平生不修礼乐，唯擅杀人放火！",
  ["$kuangzhan2"] = "宛城乃曹公掌中之物，谁敢染指？",
  ["$kangyong1"] = "此猛士之血，其与醇酒孰烈乎？",
  ["$kangyong2"] = "歃血为誓，城在则人在！",
  ["~tymou__dianwei"] = "主公无恙，韦虽死犹生……",
}

--周郎将计：程昱
local chengyu = General(extension, "tymou__chengyu", "wei", 3)
local shizha = fk.CreateTriggerSkill{
  name = "shizha",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local changehp_event_id = 1
      room.logic:getEventsByRule(GameEvent.ChangeHp, 1, function (e)
        if e.data[1] == target and e.data[2] ~= 0 then
          changehp_event_id = e.end_id
          return true
        end
      end, turn_event.id)
      if changehp_event_id == 1 then return false end
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local use_event_id = 1
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.data[1].from == target.id then
          use_event_id = e.id
        end
      end, changehp_event_id)
      return use_event_id == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#shizha-invoke::"..target.id..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    data.tos = {}
    room:sendLog{
      type = "#CardNullifiedBySkill",
      from = target.id,
      arg = self.name,
      arg2 = data.card:toLogString(),
    }
    if room:getCardArea(data.card) == Card.Processing then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
  end,
}
local gaojian = fk.CreateTriggerSkill{
  name = "gaojian",
  anim_type = "support",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:isCommonTrick() and player.phase == Player.Play and
      (not data.card:isVirtual() or data.card.subcards) and #player.room.alive_players > 1
  end,
  on_cost = function (self,event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#gaojian-choose", self.name, false)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = {}
    for i = 1, 5, 1 do
      local card = room:getNCards(1)
      table.insert(cards, card[1])
      room:moveCardTo(card, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, to.id)
      if Fk:getCardById(card[1]).type == Card.TypeTrick then
        break
      end
    end
    local yes = false
    if Fk:getCardById(cards[#cards]).type == Card.TypeTrick then
      local card = cards[#cards]
      if U.askForUseRealCard(room, to, {card}, ".", self.name, "#gaojian-use:::"..Fk:getCardById(card):toLogString(),
        {expand_pile = {card}, extraUse = true}) then
        yes = true
      end
    end
    if not yes then
      local results = room:askForArrangeCards(to, self.name, {cards, to:getCardIds("h"), "gaojian", "hand_card"},
        "#gaojian-exchange")
      if #results > 0 then
        U.swapCardsWithPile(to, results[1], results[2], self.name, "Top")
      end
    end
    U.clearRemainCards(room, cards, self.name)
  end,
}
chengyu:addSkill(shizha)
chengyu:addSkill(gaojian)
Fk:loadTranslationTable{
  ["tymou__chengyu"] = "谋程昱",
  ["#tymou__chengyu"] = "沐风知秋",
  ["illustrator:tymou__chengyu"] = "匠人绘",

  ["shizha"] = "识诈",
  [":shizha"] = "每回合限一次，其他角色使用牌时，若此牌是其本回合体力变化后使用的第一张牌，你可令此牌无效并获得此牌。",
  ["gaojian"] = "告谏",
  [":gaojian"] = "当你于出牌阶段使用锦囊牌结算完毕进入弃牌堆时，你可以选择一名其他角色，其依次展示牌堆顶的牌直到出现锦囊牌（至多五张），"..
  "然后其选择一项：1.使用此牌；2.将任意张手牌与等量展示牌交换。",
  ["#shizha-invoke"] = "识诈：是否令 %dest 使用的%arg无效并获得之？",
  ["#gaojian-choose"] = "告谏：选择一名角色，其展示牌堆顶牌，使用其中的锦囊牌或用手牌交换",
  ["#gaojian-use"] = "告谏：使用%arg，或点“取消”将任意张手牌与等量展示牌交换",
  ["#gaojian-exchange"] = "告谏：将任意张手牌与等量展示牌交换",

  ["$shizha1"] = "不好，江东鼠辈欲趁东风来袭！",
  ["$shizha2"] = "江上起东风，恐战局生变。",
  ["$gaojian1"] = "江东不乏能人，主公不可小觑。",
  ["$gaojian2"] = "狮子搏兔，亦需尽其全力。",
  ["~tymou__chengyu"] = "乌鹊南飞，何枝可依呀……",
}

--奇佐论胜：郭嘉、沮授

local jvshou = General(extension, "tymou__jvshou", "qun", 3)
local zuojun = fk.CreateActiveSkill{
  name = "zuojun",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#zuojun",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local cards = target:drawCards(3, self.name)
    local choice = room:askForChoice(target, {"zuojun1", "zuojun2"}, self.name)
    if choice == "zuojun1" then
      cards = table.filter(cards, function (id)
        return table.contains(target:getCardIds("h"), id)
      end)
      local mark = U.getMark(target, self.name)
      table.insertTableIfNeed(mark, cards)
      room:setPlayerMark(target, self.name, mark)
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zuojun-inhand", 1)
      end
    else
      room:loseHp(target, 1, self.name)
      if not target.dead then
        cards = table.filter(cards, function (id)
          return table.contains(target:getCardIds("h"), id)
        end)
        local card = target:drawCards(1, self.name)
        if table.contains(target:getCardIds("h"), card[1]) then
          table.insert(cards, card[1])
        end
        while not target.dead and #cards > 0 do
          local use = U.askForUseRealCard(room, target, cards, ".", self.name, "#zuojun-use",
            {extraUse = true}, true)
          if use then
            table.removeOne(cards, use.card:getEffectiveId())
            room:useCard(use)
          else
            break
          end
          cards = table.filter(cards, function (id)
            return table.contains(target:getCardIds("h"), id)
          end)
        end
      end
      cards = table.filter(cards, function (id)
        return table.contains(target:getCardIds("h"), id)
      end)
      if #cards > 0 then
        room:throwCard(cards, self.name, target, target)
      end
    end
  end,
}
local zuojun_prohibit = fk.CreateProhibitSkill{
  name = "#zuojun_prohibit",
  prohibit_use = function(self, player, card)
    return card and card:getMark("@@zuojun-inhand") > 0
  end,
}
local zuojun_maxcards = fk.CreateMaxCardsSkill{
  name = "#zuojun_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@zuojun-inhand") > 0
  end,
}
local zuojun_trigger = fk.CreateTriggerSkill{
  name = "#zuojun_trigger",

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("zuojun") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(U.getMark(player, "zuojun")) do
      room:setCardMark(Fk:getCardById(id), "@@zuojun-inhand", 0)
    end
    room:setPlayerMark(player, "zuojun", 0)
  end,
}
local muwang = fk.CreateTriggerSkill{
  name = "muwang",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if player:getMark("muwang-turn") == 0 then
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).type == Card.TypeBasic or Fk:getCardById(info.cardId):isCommonTrick() then
                local room = player.room
                local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
                if turn_event == nil then return false end
                if move.from == player.id then
                  if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                    self.cost_data = info.cardId
                    return true
                  end
                else
                  self.cost_data = -1
                  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
                    for _, m in ipairs(e.data) do
                      if m.from == player.id then
                        for _, i in ipairs(m.moveInfo) do
                          if i.cardId == info.cardId and (i.fromArea == Card.PlayerHand or i.fromArea == Card.PlayerEquip) then
                            --一个人不能两次踏进同一条河流~
                            self.cost_data = info.cardId
                            return true
                          end
                        end
                      end
                    end
                  end, Player.HistoryTurn)
                  return self.cost_data ~= -1
                end
              end
            end
          end
        end
      else
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                info.cardId == player:getMark("muwang-turn") then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if player:getMark("muwang-turn") == 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:setPlayerMark(player, "muwang-turn", self.cost_data)
      room:moveCardTo(self.cost_data, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id, "@@muwang-turn")
    else
      room:notifySkillInvoked(player, self.name, "negative")
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
zuojun:addRelatedSkill(zuojun_prohibit)
zuojun:addRelatedSkill(zuojun_maxcards)
zuojun:addRelatedSkill(zuojun_trigger)
jvshou:addSkill(zuojun)
jvshou:addSkill(muwang)
Fk:loadTranslationTable{
  ["tymou__jvshou"] = "谋沮授",
  --["#tymou__jvshou"] = "",
  --["illustrator:tymou__jvshou"] = "",

  ["zuojun"] = "佐军",
  [":zuojun"] = "出牌阶段限一次，你可选择一名角色，其摸三张牌并选择一项：1.这些牌无法使用且不计入手牌上限，直到其下回合结束；2.失去1点体力，"..
  "再摸一张牌，然后使用其中任意张牌，弃置剩余未使用的牌。",
  ["muwang"] = "暮往",
  [":muwang"] = "锁定技，当你每回合失去第一张基本牌或普通锦囊牌进入弃牌堆后，你获得之；当你本回合再次失去此牌后，弃置一张牌。",
  ["#zuojun"] = "佐军：令一名角色摸三张牌，然后其执行后续效果",
  ["@@zuojun-inhand"] = "佐军",
  ["zuojun1"] = "这些牌无法使用且不计入手牌上限直到你下回合结束",
  ["zuojun2"] = "失去1点体力再摸一张牌，然后使用其中任意张，弃置剩余牌",
  ["#zuojun-use"] = "佐军：请使用这些牌，未使用的将被弃置",
  ["@@muwang-turn"] = "暮往",
}

return extension
