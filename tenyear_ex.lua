local extension = Package("tenyear_ex")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_ex"] = "十周年界限突破",
   ["ty_ex"] = "十周年界",
}

local caozhi = General(extension, "ty_ex__caozhi", "wei", 3)
local ty_ex__jiushi = fk.CreateViewAsSkill{
  name = "ty_ex__jiushi",
  anim_type = "support",
  pattern = "analeptic",
  card_filter = function(self, to_select, selected)
    return false
  end,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self, cards)
    if not Self.faceup then return end
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
}
local ty_ex__jiushi_record = fk.CreateTriggerSkill{
  name = "#ty_ex__jiushi_record",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark(self.name) > 0
  end,
  on_cost = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, 1)
  end,
}
local ty_ex__jiushi_buff = fk.CreateTriggerSkill{
  name = "#ty_ex__jiushi_buff",
  anim_type = "control",
  events = {fk.AfterCardUseDeclared},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_ex__jiushi") and data.card.name == "analeptic"
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex_jiushi_buff",1)
  end,
  
  refresh_events ={fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_ex_jiushi_buff") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player.room:setPlayerMark(player, "@ty_ex_jiushi_buff", 0)
  end,
}
local jiushi_targetmod = fk.CreateTargetModSkill{
  name = "#jiushi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("ty_ex__jiushi") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@ty_ex_jiushi_buff")
    end
  end,
}
ty_ex__jiushi:addRelatedSkill(ty_ex__jiushi_record)
ty_ex__jiushi:addRelatedSkill(ty_ex__jiushi_buff)
ty_ex__jiushi:addRelatedSkill(jiushi_targetmod)
caozhi:addSkill("luoying")
caozhi:addSkill(ty_ex__jiushi)
Fk:loadTranslationTable{
  ["ty_ex__caozhi"] = "界曹植",
  ["ty_ex__jiushi"] = "酒诗",
  [":ty_ex__jiushi"] = "①若你的武将牌正面朝上，你可以（在合理的时机）将你的武将牌翻面来视为使用一张【酒】。"..
  "②当你的武将牌背面朝上时你受到伤害，你可在伤害结算后将之翻回正面。③当你使用酒时，你令你使用杀的次数上限+1，直到你的下个回合结束。",
  ["#ty_ex__jiushi_record"] = "酒诗",
  ["@ty_ex_jiushi_buff"] = "酒诗",
  ["$ty_ex__jiushi1"] = "暂无",
  ["$ty_ex__jiushi2"] = "暂无",
  ["~ty_ex__caozhi"] = "暂无",
}

local zhangchunhua = General(extension, "ty_ex__zhangchunhua", "wei", 3, 3, General.Female)
local ty_ex__jueqing_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__jueqing_trigger",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not data.chain
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jueqing-invoke::"..data.to.id..":"..data.damage..":"..data.damage)
  end,
  on_use = function(self, event, target, player, data)
     player.room:loseHp(player, data.damage, self.name)
    data.damage = data.damage * 2
  end,
}
local ty_ex__jueqing = fk.CreateTriggerSkill{
  name = "ty_ex__jueqing",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes("#ty_ex__jueqing_trigger", Player.HistoryGame) >0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, self.name)
    return true
  end,
}
local ty_ex__shangshi_discard = fk.CreateTriggerSkill{
  name = "#ty_ex__shangshi_discard",
  anim_type = "negative",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill("ty_ex__shangshi") and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".", "#shangshi-invoke")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
  end,
}
local ty_ex__shangshi = fk.CreateTriggerSkill{
  name = "ty_ex__shangshi",
  anim_type = "drawcard",
  events = {fk.HpChanged, fk.MaxHpChanged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getHandcardNum() < player:getLostHp() then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          return move.from == player.id
        end
      else
        return target == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getLostHp() - player:getHandcardNum(), self.name)
  end,
}
ty_ex__jueqing:addRelatedSkill(ty_ex__jueqing_trigger)
ty_ex__shangshi:addRelatedSkill(ty_ex__shangshi_discard)
zhangchunhua:addSkill(ty_ex__jueqing)
zhangchunhua:addSkill(ty_ex__shangshi)
Fk:loadTranslationTable{
  ["ty_ex__zhangchunhua"] = "界张春华",
  ["ty_ex__jueqing"] = "绝情",
  ["#ty_ex__jueqing_trigger"] = "绝情",
  [":ty_ex__jueqing"] = "①每局限一次，当你造成伤害时，你可以失去同于伤害值点体力令此伤害翻倍。②锁定技，若你已发动过绝情①，你造成的伤害均视为体力流失。",
  ["ty_ex__shangshi"] = "伤逝",
  ["#ty_ex__shangshi_discard"] = "伤逝",
  [":ty_ex__shangshi"] = "①当你受到伤害时，你可以弃置一张手牌；②每当你的手牌数小于你已损失的体力值时，可立即将手牌数补至等同于你已损失的体力值。",
  ["#shangshi-invoke"] = "伤逝:是否弃置一张手牌？",
  ["#jueqing-invoke"] = "绝情:是否令即将对%dest造成的%arg点伤害翻倍？然后你失去%arg2点体力",
  ["~ty_ex__zhangchunhua"] = "暂无",
}

local lingtong = General(extension, "ty_ex__lingtong", "wu", 4)
local ty_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "ty_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      else
        return target == player and player.phase == Player.Discard and player:getMark("ty_ex__xuanfeng-phase") > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if table.every(player.room:getOtherPlayers(player), function (p) return p:isNude() end) then return end
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targetsx = {}
    for i = 1, 2, 1 do
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude() end), function (p) return p.id end)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__xuanfeng-choose", self.name, true)
        if #tos == 0 then
          tos = {table.random(targets)}
        end
        room:doIndicate(player.id, tos)
         local card = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
        room:throwCard({card}, self.name, room:getPlayerById(tos[1]), player)
        if player.phase ~= Player.NotActive then
          table.insert(targetsx, tos[1])
        end
      end
    end
    if #targetsx > 0 then
      local tos = room:askForChoosePlayers(player, targetsx, 1, 1, "#ty_ex__xuanfeng-damage", self.name, true)
      if #tos == 0 then
        tos = {table.random(targetsx)}
      end
       room:damage{
         from = player,
         to = room:getPlayerById(tos[1]),
         damage = 1,
          skillName = self.name,
       }
    else return end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        player.room:addPlayerMark(player, "ty_ex__xuanfeng-phase", #move.moveInfo)
      end
    end
  end,
}
local ex__yongjin = fk.CreateActiveSkill{
  name = "ex__yongjin",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  card_filter = function()
    return false
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for i = 1, 3, 1 do
      if #room:canMoveCardInBoard() == 0 or player.dead then break end
      local to = room:askForChooseToMoveCardInBoard(player, "#ex__yongjin-choose", self.name, true, "e")
      if #to == 2 then
        room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name, "e")
      else
        break
      end
    end
  end,
}
lingtong:addSkill(ty_ex__xuanfeng)
lingtong:addSkill(ex__yongjin)
Fk:loadTranslationTable{
  ["ty_ex__lingtong"] = "界凌统",
  ["ty_ex__xuanfeng"] = "旋风",
  [":ty_ex__xuanfeng"] = "当你失去装备区里的牌，或于弃牌阶段弃掉两张或更多的牌时，你可以依次弃置一至两名角色的共计两张牌。"..
  "若此时是你的回合内，则你可以对其中一名角色造成1点伤害。",
  ["#ty_ex__xuanfeng-choose"] = "旋风：你可以依次弃置一至两名角色的共计两张牌",
  ["#ty_ex__xuanfeng-damage"] = "旋风：你可以对其中一名角色造成一点伤害。",
  ["ex__yongjin"] = "勇进",
  [":ex__yongjin"] = "限定技，出牌阶段，你可以依次移动场上至多三张装备牌。",
  ["#ex__yongjin-choose"] = "勇进：你可以移动场上的一张装备牌",
  ["$ty_ex__xuanfeng1"] = "风动扬帆起，枪出敌军溃！",
  ["$ty_ex__xuanfeng2"] = "御风而动，敌军四散！",
  ["$ex__yongjin1"] = "鏖兵卫主，勇足以却敌！",
  ["$ex__yongjin2"] = "勇不可挡，进则无退！",
  ["~ty_ex__lingtong"] = "泉下弟兄，统来也！",
}

local wuguotai = General(extension, "ty_ex__wuguotai", "wu", 3, 3, General.Female)
local ty_ex__ganlu = fk.CreateActiveSkill{
  name = "ty_ex__ganlu",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      if #target1.player_cards[Player.Equip] == 0 and #target2.player_cards[Player.Equip] == 0 then
        return false
      end
      return true
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
       local target1 = Fk:currentRoom():getPlayerById(effect.tos[1])
    local target2 = Fk:currentRoom():getPlayerById(effect.tos[2])
    local cards1 = table.clone(target1.player_cards[Player.Equip])
    local cards2 = table.clone(target2.player_cards[Player.Equip])
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[1],
        ids = cards1,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[2],
        ids = cards2,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    moveInfos = {}

    if not target2.dead then
      local to_ex_cards1 = table.filter(cards1, function (id)
        return room:getCardArea(id) == Card.Processing and target2:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards1 > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards1,
          fromArea = Card.Processing,
          to = effect.tos[2],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if not target1.dead then
      local to_ex_cards = table.filter(cards2, function (id)
        return room:getCardArea(id) == Card.Processing and target1:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = effect.tos[1],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    table.insertTable(cards1, cards2)

    local dis_cards = table.filter(cards1, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #dis_cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(dis_cards)
      room:moveCardTo(dummy, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    end
     local player =room:getPlayerById(effect.from)
    if math.abs(#room:getPlayerById(effect.tos[1]).player_cards[Player.Equip] - #room:getPlayerById(effect.tos[2]).player_cards[Player.Equip]) > player:getLostHp() then
      if player:getHandcardNum() >1 then
        room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#ganlu-discard")
      else
        player:throwAllCards("h")
      end
    end
  end,
}
local ty_ex__buyi = fk.CreateTriggerSkill{
  name = "ty_ex__buyi",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__buyi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #target.player_cards[Player.Hand] == 1 then
      self.cost_numer = true
    end
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    if Fk:getCardById(id).type ~= Card.TypeBasic then
      room:throwCard({id}, self.name, target, target)
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
      if self.cost_numer ~= nil then
        target:drawCards(1, self.name)
      end
    end
  end,
}
wuguotai:addSkill(ty_ex__ganlu)
wuguotai:addSkill(ty_ex__buyi)
Fk:loadTranslationTable{
  ["ty_ex__wuguotai"] = "界吴国太",
  ["ty_ex__ganlu"] = "甘露",
  [":ty_ex__ganlu"] = "出牌阶段限一次，你可以选择两名角色，交换他们装备区里的所有牌，然后若他们装备区的差大于X，你需弃置两张手牌（X为你已损失体力值）。",
  ["ty_ex__buyi"] = "补益",
  [":ty_ex__buyi"] = "当有角色进入濒死状态时，你可以展示该角色的一张手牌：若此牌不为基本牌，则该角色弃掉这张牌并回复1点体力，然后若此牌移动前是其唯一的手牌，其摸一张牌。",
  ["#ty_ex__buyi-invoke"] = "补益：你可以展示%dest的一张手牌，若为非基本牌则其弃掉并回复1点体力，然后若此牌移动前是其唯一的手牌，其摸一张牌。",
  ["#ganlu-discard"] ="甘露: 请弃置两张手牌",
  ["$ty_ex__ganlu1"] = "男婚女嫁，须当交换文定之物。",
  ["$ty_ex__ganlu2"] = "此真乃吾之佳婿也。",
  ["$ty_ex__buyi1"] = "吾乃吴国之母，何人敢放肆？",
  ["$ty_ex__buyi2"] = "有老身在，汝等尽可放心。",
  ["~ty_ex__wuguotai"] = "卿等，务必用心辅佐仲谋……",
}

local chengong = General(extension, "ty_ex__chengong", "qun", 3)
local ty_ex__mingce = fk.CreateActiveSkill{
  name = "ty_ex__mingce",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and (Fk:getCardById(to_select).trueName == "slash" or Fk:getCardById(to_select).type == Card.TypeEquip)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__mingce-choose::"..target.id, self.name, false)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(target.id, {to})
      local choice = room:askForChoice(target, {"ty_ex__mingce_slash", "draw1"}, self.name)
      if choice == "ty_ex__mingce_slash" then
        local use = {
          from = target.id,
          tos = {{to}},
          card = Fk:cloneCard("slash"),
          skillName = self.name,
          extraUse = true,
        }
        room:useCard(use)
        if use.damageDealt then
          if not player.dead then
            player:drawCards(1, self.name)
          end
          if not target.dead then
            target:drawCards(1, self.name)
          end
        end
      else
        player:drawCards(1, self.name)
        target:drawCards(1, self.name)
      end
    end
  end,
}

chengong:addSkill(ty_ex__mingce)
chengong:addSkill("zhichi")
Fk:loadTranslationTable{
  ["ty_ex__chengong"] = "界陈宫",
  ["ty_ex__mingce"] = "明策",
  [":ty_ex__mingce"] = "出牌阶段限一次，你可以交给一名其他角色一张装备牌或【杀】，其选择一项：1.视为对其攻击范围内的另一名由你指定的角色使用一张【杀】，"..
  "若此杀造成伤害则执行选项2；2.你与其各摸一张牌。",
  ["#ty_ex__mingce-choose"] = "明策：选择 %dest 视为使用【杀】的目标",
  ["ty_ex__mingce_slash"] = "视为使用【杀】",
  ["$mingce1"] = "暂无",
  ["$mingce2"] = "暂无",
  ["~ty_ex__chengong"] = "暂无",
}

local guanping = General(extension, "ty_ex__guanping", "shu", 4)
local ty_ex__longyin = fk.CreateTriggerSkill{
  name = "ty_ex__longyin",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Play and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty_ex__longyin-invoke::"..target.id) 
     if #cards > 0 then
        self.cost_data = cards
        return true
     end
  end,
  on_use = function(self, event, target, player, data)
    target:addCardUseHistory(data.card.trueName, -1)
    if data.card.color == Card.Red then
      player:drawCards(1, self.name)
    end
     if data.card.number == Fk:getCardById(self.cost_data[1]).number and player:usedSkillTimes("ty_ex__jiezhong", Player.HistoryGame) > 0 then
       player:setSkillUseHistory("ty_ex__jiezhong", 0, Player.HistoryGame)
     end
  end,
}
local ty_ex__jiezhong = fk.CreateTriggerSkill{
  name = "ty_ex__jiezhong",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      math.min(player.maxHp, 5) > player:getHandcardNum() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
     local draw = math.min(player.maxHp, 5) - player:getHandcardNum()
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiezhong-invoke:::"..draw)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player.maxHp, 5) - player:getHandcardNum()
    player:drawCards(n, self.name)
  end,
}
guanping:addSkill(ty_ex__longyin)
guanping:addSkill(ty_ex__jiezhong)
Fk:loadTranslationTable{
  ["ty_ex__guanping"] = "界关平",
  ["ty_ex__longyin"] = "龙吟",
  [":ty_ex__longyin"] = "每当一名角色在其出牌阶段使用【杀】时，你可以弃置一张牌令此【杀】不计入出牌阶段使用次数，若此【杀】为红色，你摸一张牌。"..
  "若你以此法弃置的牌点数与此【杀】相同，你重置〖竭忠〗。",
  ["#ty_ex__longyin-invoke"] = "龙吟：你可以弃置一张牌令 %dest 的【杀】不计入次数限制",
  ["ty_ex__jiezhong"] = "竭忠",
  [":ty_ex__jiezhong"] = "限定技，出牌阶段开始时，若你的手牌数小于体力上限，你可以将手牌补至体力上限(至多为5)。",
  ["#ty_ex__jiezhong-invoke"] = "竭忠：是否发动“竭忠”摸%arg张牌？ ",
}
local zhonghui = General(extension, "ty_ex__zhonghui", "wei", 4)
local ty_ex__quanji = fk.CreateTriggerSkill{
  name = "ty_ex__quanji",
  anim_type = "masochism",
  events = {fk.AfterCardsMove, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
              self:doCost(event, target, player, data)
            end
          end
        end
      end
    elseif event == fk.Damaged and player:hasSkill(self.name) and target == player then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost then break end
       self:doCost(event, target, player, data)
      end
    else
      return false
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if not player:isKongcheng() then
      local card = room:askForCard(player, 1, 1, false, self.name, false)
      player:addToPile("zhonghui_quan", card, false, self.name)
    end
  end,
}
local ex__quanji_maxcards = fk.CreateMaxCardsSkill{
  name = "#ex__quanji_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return #player:getPile("zhonghui_quan")
    else
      return 0
    end
  end,
}
local ty_ex__zili = fk.CreateTriggerSkill{
  name = "ty_ex__zili",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("zhonghui_quan") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    player:drawCards(2, self.name)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "ty_ex__paiyi", nil, true, false)
  end,
}

local ty_ex__paiyi = fk.CreateActiveSkill{
  name = "ty_ex__paiyi",
  anim_type = "control",
  expand_pile = "zhonghui_quan",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function(self)
    return self.interaction.data == "cesipaiyi_draw" and 1 or #Self:getPile("zhonghui_quan") - 1
  end,
  interaction = function(self)
    local choiceList = {}
    if Self:getMark("cesipaiyi_draw-phase") == 0 then
      table.insert(choiceList, "cesipaiyi_draw")
    end
    if Self:getMark("cesipaiyi_damage-phase") == 0 then 
      table.insert(choiceList, "cesipaiyi_damage")
    end
    return UI.ComboBox { choices = choiceList }
  end,
  target_filter = function(self, to_select, selected)
    return self.interaction.data == "cesipaiyi_draw" and #selected == 0 or #selected < #Self:getPile("zhonghui_quan")-1
  end,
  can_use = function(self, player)
    return #player:getPile("zhonghui_quan") > 0 and (player:getMark("cesipaiyi_draw-phase") == 0 or player:getMark("cesipaiyi_damage-phase") == 0)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "zhonghui_quan"
  end,
  on_use = function(self, room, effect)
      local player = room:getPlayerById(effect.from)
      local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
    })
    player:removeCards(Player.Special, effect.cards, self.name)
    if self.interaction.data == "cesipaiyi_draw" then
     target:drawCards(math.max(#player:getPile("zhonghui_quan"),1), self.name)
      room:setPlayerMark(player, "cesipaiyi_draw-phase", 1)
    else
      table.forEach(effect.tos, function(p)
        room:damage{ from = player, to = room:getPlayerById(p), damage = 1, skillName = self.name }
      end)
      room:setPlayerMark(player, "cesipaiyi_damage-phase", 1)
    end
  end,
}

ty_ex__quanji:addRelatedSkill(ex__quanji_maxcards)
zhonghui:addSkill(ty_ex__quanji)
zhonghui:addSkill(ty_ex__zili)
zhonghui:addRelatedSkill(ty_ex__paiyi)
Fk:loadTranslationTable{
  ["ty_ex__zhonghui"] = "界钟会",
  ["ty_ex__quanji"] = "权计",
  [":ty_ex__quanji"] = "每当你的牌被其他角色获得或受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”；每有一张“权”，你的手牌上限便+1。",
  ["ty_ex__zili"] = "自立",
  [":ty_ex__zili"] = "觉醒技，回合开始阶段开始时，若“权”的数量达到3或更多，你须减1点体力上限，然后回复1点体力并摸两张牌，并获得技能〖排异〗。",
  ["ty_ex__paiyi"] = "排异",
  [":ty_ex__paiyi"] = "出牌阶段每项各限一次，你可移去一张“权”并选择一项：①令一名角色摸X张牌。②对至多X名角色各造成1点伤害。（X为“权”数且至少为1）",
  ["cesipaiyi_draw"] = "摸牌",
  ["cesipaiyi_damage"] = "伤害",
}
local wangyi = General(extension, "ty_ex__wangyi", "wei", 4, 4, General.Female)
wangyi:addSkill("zhenlie")
wangyi:addSkill("miji")
Fk:loadTranslationTable{
  ["ty_ex__wangyi"] = "界王异",
}
local ty_ex__tongxin = fk.CreateAttackRangeSkill{
  name = "ty_ex__tongxin",
  correct_func = function (self, from, to)
    return 2
  end,
}
local guanzhang = General(extension, "ty_ex__guanzhang", "shu", 4)
guanzhang:addSkill("fuhun")
guanzhang:addSkill(ty_ex__tongxin)
Fk:loadTranslationTable{
  ["ty_ex__guanzhang"] = "界关兴张苞",
  ["ty_ex__tongxin"] = "同心",
  [":ty_ex__tongxin"] = "锁定技，你的攻击范围+2。",
}
local chengpu = General(extension, "ty_ex__chengpu", "wu", 4)
local ty_ex__chunlao = fk.CreateTriggerSkill{
  name = "ty_ex__chunlao",
  anim_type = "support",
  expand_pile = "ty_ex__chengpu_chun",
  events = {fk.EventPhaseStart, fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and #player:getPile("ty_ex__chengpu_chun") == 0 and not player:isKongcheng()
      else
        return target.dying and #player:getPile("ty_ex__chengpu_chun") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    if event == fk.EventPhaseStart then
      cards = room:askForCard(player, 1, #player.player_cards[Player.Hand], false, self.name, true, "slash", "#ty_ex__chunlao-cost")
    else
      cards = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|ty_ex__chengpu_chun|.|.", "#ty_ex__chunlao-invoke::"..target.id, "ty_ex__chengpu_chun")
    end
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:addToPile("ty_ex__chengpu_chun", self.cost_data, false, self.name)
    else
      room:moveCards({
        from = player.id,
        ids = self.cost_data,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      player:removeCards(Player.Special, self.cost_data, "ty_ex__chengpu_chun")
      local analeptic = Fk:cloneCard("analeptic")
      room:useCard({
        card = analeptic,
        from = target.id,
        tos = {{target.id}},
        extra_data = {analepticRecover = true},
        skillName = self.name,
      })
      if self.cost_data.name == "fire__slash" then
        if player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      elseif self.cost_data.name == "thunder__slash" then
         player:drawCards(2, self.name)
      end
    end
  end,
}
chengpu:addSkill("lihuo")
chengpu:addSkill(ty_ex__chunlao)
Fk:loadTranslationTable{
  ["ty_ex__chengpu"] = "界程普",
  ["ty_ex__chunlao"] = "醇醪",
  [":ty_ex__chunlao"] = "回合结束阶段开始时，若你的武将牌上没有牌，你可以将任意数量的【杀】置于你的武将牌上，称为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，视为该角色使用一张【酒】。若你此法置入弃牌堆的是【火杀】，你恢复一点体力，若是【雷杀】，你摸两张牌。",
  ["ty_ex__chengpu_chun"] = "醇",
  ["#ty_ex__chunlao-cost"] = "醇醪：你可以将任意张【杀】置为“醇”",
  ["#ty_ex__chunlao-invoke"] = "醇醪：你可以将一张“醇”置入弃牌堆，视为 %dest 使用一张【酒】",
}
return extension
