local extension = Package("tenyear_huicui1")
extension.extensionName = "tenyear"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_huicui1"] = "十周年-群英荟萃1",
}

--无双上将：潘凤 邢道荣 曹性 淳于琼 夏侯杰 蔡阳 周善
local panfeng = General(extension, "ty__panfeng", "qun", 4)
local ty__kuangfu = fk.CreateActiveSkill{
  name = "ty__kuangfu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "e", self.name)
    room:throwCard({id}, self.name, target, player)
    if player.dead then return end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, Fk:cloneCard("slash")) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__kuangfu-slash", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    local use = {
      from = player.id,
      tos = {{to}},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    room:useCard(use)
    if not player.dead then
      if effect.from == effect.tos[1] and use.damageDealt then
        player:drawCards(2, self.name)
      end
      if effect.from ~= effect.tos[1] and not use.damageDealt then
        if #player.player_cards[Player.Hand] < 3 then
          player:throwAllCards("he")
        else
          player.room:askForDiscard(player, 2, 2, false, self.name, false)
        end
      end
    end
  end,
}
panfeng:addSkill(ty__kuangfu)
Fk:loadTranslationTable{
  ["ty__panfeng"] = "潘凤",
  ["ty__kuangfu"] = "狂斧",
  [":ty__kuangfu"] = "出牌阶段限一次，你可以弃置场上的一张装备牌，视为使用一张【杀】（此【杀】无距离限制且不计次数）。"..
  "若你弃置的不是你的牌且此【杀】未造成伤害，你弃置两张手牌；若弃置的是你的牌且此【杀】造成伤害，你摸两张牌。",
  ["#ty__kuangfu-slash"] = "狂斧：选择视为使用【杀】的目标",

  ["$ty__kuangfu1"] = "大斧到处，片甲不留！",
  ["$ty__kuangfu2"] = "你可接得住我一斧？",
  ["~ty__panfeng"] = "来者……可是魔将？",
}

local xingdaorong = General(extension, "xingdaorong", "qun", 4, 6)
local xuhe = fk.CreateTriggerSkill{
  name = "xuhe",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return true
      else
        return not table.every(player.room:getOtherPlayers(player), function(p) return p.maxHp <= player.maxHp end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xuhe-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:changeMaxHp(player, -1)
      if not player.dead then
        local choice = room:askForChoice(player, {"xuhe_discard", "xuhe_draw"}, self.name)
        if choice == "xuhe_discard" then
          for _, p in ipairs(room:getAlivePlayers()) do
            if player:distanceTo(p) < 2 and not p:isNude() then
              room:doIndicate(player.id, {p.id})
              local id = room:askForCardChosen(player, p, "he", self.name)
              room:throwCard({id}, self.name, p, player)
            end
          end
        else
          for _, p in ipairs(room:getAlivePlayers()) do
            if player:distanceTo(p) < 2  then
              p:drawCards(1, self.name)
            end
          end
        end
      end
    else
      room:changeMaxHp(player, 1)
      local choices = {"draw2"}
      if player:isWounded() then
        table.insert(choices, "recover")
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "draw2" then
        player:drawCards(2)
      else
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
xingdaorong:addSkill(xuhe)
Fk:loadTranslationTable{
  ["xingdaorong"] = "邢道荣",
  ["xuhe"] = "虚猲",
  [":xuhe"] = "出牌阶段开始时，你可以减1点体力上限，然后你弃置距离1以内的每名角色各一张牌或令这些角色各摸一张牌。出牌阶段结束时，"..
  "若你体力上限不为全场最高，你加1点体力上限，然后回复1点体力或摸两张牌。",
  ["#xuhe-invoke"] = "虚猲：你可以减1点体力上限，然后弃置距离1以内每名角色各一张牌或令这些角色各摸一张牌",
  ["xuhe_discard"] = "弃置距离1以内角色各一张牌",
  ["xuhe_draw"] = "距离1以内角色各摸一张牌",

  ["$xuhe1"] = "说出吾名，吓汝一跳！",
  ["$xuhe2"] = "我乃是零陵上将军！",
  ["~xingdaorong"] = "孔明之计，我难猜透啊。",
}

local caoxing = General(extension, "caoxing", "qun", 4)
local liushi = fk.CreateActiveSkill{
  name = "liushi",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), Fk:cloneCard("slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("slash"),
      skillName = self.name,
      extraUse = true,
    }
    room:useCard(use)
    if use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p.id] then
          room:addPlayerMark(target, "@@liushi", 1)
        end
      end
    end
  end,
}
local liushi_maxcards = fk.CreateMaxCardsSkill{
  name = "#liushi_maxcards",
  correct_func = function(self, player)
    if player:getMark("@@liushi") > 0 then
      return -player:getMark("@@liushi")
    end
    return 0
  end,
}
local zhanwan = fk.CreateTriggerSkill{
  name = "zhanwan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Discard and target:getMark("zhanwan-phase") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(target:getMark("zhanwan-phase"), self.name)
    player.room:setPlayerMark(target, "@@liushi", 0)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@liushi") > 0 and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        player.room:addPlayerMark(player, "zhanwan-phase", #move.moveInfo)
      end
    end
  end,
}
liushi:addRelatedSkill(liushi_maxcards)
caoxing:addSkill(liushi)
caoxing:addSkill(zhanwan)
Fk:loadTranslationTable{
  ["caoxing"] = "曹性",
  ["liushi"] = "流矢",
  [":liushi"] = "出牌阶段，你可以将一张<font color='red'>♥</font>牌置于牌堆顶，视为对一名角色使用一张【杀】（不计入次数且无距离限制）。"..
  "受到此【杀】伤害的角色手牌上限-1。",
  ["zhanwan"] = "斩腕",
  [":zhanwan"] = "锁定技，受到〖流矢〗效果影响的角色弃牌阶段结束时，若其于此阶段内弃置过牌，你摸等量的牌，然后移除其〖流矢〗的效果。",
  ["@@liushi"] = "流矢",

  ["$liushi1"] = "就你叫夏侯惇？",
  ["$liushi2"] = "兀那贼将，且吃我一箭！",
  ["$zhanwan1"] = "郝萌，尔敢造反不成？",
  ["$zhanwan2"] = "健儿护主，奸逆断腕！",
  ["~caoxing"] = "夏侯将军，有话好说……",
}

local chunyuqiong = General(extension, "chunyuqiong", "qun", 4)
local cangchu = fk.CreateTriggerSkill{
  name = "cangchu",
  events = {fk.GameStart , fk.AfterCardsMove},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self)
    elseif player:usedSkillTimes(self.name, Player.HistoryTurn) < 1 and player:getMark("@cangchu") < #player.room.alive_players then
      if player:hasSkill(self) and player.phase == Player.NotActive then
        for _, move in ipairs(data) do
          if move.toArea == Card.PlayerHand and move.to == player.id then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setPlayerMark(player, "@cangchu", math.min(#room.alive_players, player:getMark("@cangchu") + 3))
    else
      room:addPlayerMark(player, "@cangchu")
    end
    room:broadcastProperty(player, "MaxCards")
  end,

  refresh_events = {fk.Death},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self,true) and player:getMark("@cangchu") >#player.room.alive_players
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@cangchu", #room.alive_players)
    room:broadcastProperty(player, "MaxCards")
  end,
}
local cangchu_maxcards = fk.CreateMaxCardsSkill{
  name = "#cangchu_maxcards",
  correct_func = function(self, player)
    return player:getMark("@cangchu")
  end,
}
cangchu:addRelatedSkill(cangchu_maxcards)
chunyuqiong:addSkill(cangchu)
local liangying = fk.CreateTriggerSkill{
  name = "liangying",
  events = {fk.EventPhaseStart},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Discard and player:getMark("@cangchu") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@cangchu")
    local tos = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, n,"#liangying-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = self.cost_data
    room:sortPlayersByAction(tos)
    player:drawCards(#tos, self.name)
    for _, pid in ipairs(tos) do
      if player:isKongcheng() then break end
      local p = room:getPlayerById(pid)
      if not p.dead and p ~= player then
        local card = room:askForCard(player, 1, 1, false, self.name, false, ".", "#liangying-give::"..pid)
        if #card > 0 then
          room:obtainCard(p, card[1], false, fk.ReasonGive)
        end
      end
    end
  end,
}
chunyuqiong:addSkill(liangying)
local shishou = fk.CreateTriggerSkill{
  name = "shishou",
  events = {fk.EventPhaseStart, fk.CardUseFinished, fk.Damaged},
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start and player:getMark("@cangchu") == 0
      elseif event == fk.CardUseFinished then
        return player:getMark("@cangchu") > 0 and data.card.name == "analeptic"
      else
        return player:getMark("@cangchu") > 0 and data.damageType == fk.FireDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:loseHp(player, 1, self.name)
    else
      room:removePlayerMark(player, "@cangchu")
      room:broadcastProperty(player, "MaxCards")
    end
  end,
}
chunyuqiong:addSkill(shishou)
Fk:loadTranslationTable{
  ["chunyuqiong"] = "淳于琼",
  ["cangchu"] = "仓储",
  [":cangchu"] = "锁定技，游戏开始时，你获得3枚“粮”标记；每拥有1枚“粮”手牌上限+1；当你于回合外获得牌时，获得1枚“粮”"..
  "（每回合限一枚，且“粮”的总数不能大于存活角色数）。",
  ["liangying"] = "粮营",
  [":liangying"] = "弃牌阶段开始时，你可以摸选择至多X名角色并摸等量张牌，然后交给其中每名其他角色各一张手牌（X为“粮”的数量）。",
  ["shishou"] = "失守",
  [":shishou"] = "锁定技，当你使用【酒】或受到火焰伤害后，你失去1枚“粮”。准备阶段，若你没有“粮”，你失去1点体力。",
  ["@cangchu"] = "粮",
  ["#liangying-choose"] = "粮营：选择至多 %arg 名角色并摸等量张牌，然后交给这些角色各一张手牌",
  ["#liangying-give"] = "粮营：交给 %dest 一张手牌",
  
  ["$cangchu1"] = "广积粮草，有备无患。",
  ["$cangchu2"] = "吾奉命于此、建仓储粮。",
  ["$liangying1"] = "酒气上涌，精神倍长。",
  ["$liangying2"] = "仲简在此，谁敢来犯？",
  ["$shishou1"] = "腹痛骤发，痛不可当。",
  ["$shishou2"] = "火光冲天，悔不当初。",
  ["~chunyuqiong"] = "这酒，饮不得啊……",
}

local xiahoujie = General(extension, "xiahoujie", "wei", 5)
local liedan = fk.CreateTriggerSkill{
  name = "liedan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Start and player:getMark("@@zhuangdan") == 0 and
      (target ~= player or (target == player and player:getMark("@liedan")) > 4)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target ~= player then
      local n = 0
      if player:getHandcardNum() > target:getHandcardNum() then
        n = n + 1
      end
      if player.hp > target.hp then
        n = n + 1
      end
      if #player.player_cards[Player.Equip] > #target.player_cards[Player.Equip] then
        n = n + 1
      end
      if n > 0 then
        player:drawCards(n, self.name)
        if n == 3 and player.maxHp < 8 then
          room:changeMaxHp(player, 1)
        end
      else
        room:loseHp(player, 1, self.name)
        if not player.dead then
          room:addPlayerMark(player, "@liedan", 1)
        end
      end
    else
      room:killPlayer({who = player.id,})
    end
  end,
}
local zhuangdan = fk.CreateTriggerSkill{
  name = "zhuangdan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and player:getMark("@@zhuangdan") == 0 and
      table.every(player.room:getOtherPlayers(player), function(p) return player:getHandcardNum() > p:getHandcardNum() end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 1)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@zhuangdan") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 0)
  end,
}
xiahoujie:addSkill(liedan)
xiahoujie:addSkill(zhuangdan)
Fk:loadTranslationTable{
  ["xiahoujie"] = "夏侯杰",
  ["liedan"] = "裂胆",
  [":liedan"] = "锁定技，其他角色的准备阶段，你的手牌数、体力值和装备区里的牌数每有一项大于该角色，便摸一张牌。"..
  "若均大于其，你加1点体力上限（至多加至8）；若均不大于其，你失去1点体力并获得1枚“裂胆”标记。准备阶段，若“裂胆”标记不小于5，你死亡。",
  ["zhuangdan"] = "壮胆",
  [":zhuangdan"] = "锁定技，其他角色的回合结束时，若你的手牌数为全场唯一最大，〖裂胆〗失效直到你的回合结束。",
  ["@liedan"] = "裂胆",
  ["@@zhuangdan"] = "裂胆失效",

  ["$liedan1"] = "声若洪钟，震胆发聩！",
  ["$liedan2"] = "阴雷滚滚，肝胆俱颤！",
  ["$zhuangdan1"] = "假丞相虎威，壮豪将龙胆。",
  ["$zhuangdan2"] = "我家丞相在此，哪个有胆敢动我？",
  ["~xiahoujie"] = "你吼那么大声干嘛……",
}

local caiyang = General(extension, "caiyang", "wei", 4)
local xunji = fk.CreateActiveSkill{
  name = "xunji",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#xunji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = target:getMark("@@xunji")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(target, "@@xunji", mark)
  end,
}
local xunji_trigger = fk.CreateTriggerSkill{
  name = "#xunji_trigger",
  mute = true,
  events = {fk.EventPhaseStart, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:getMark("@@xunji") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@@xunji")
    room:setPlayerMark(player, "@@xunji", 0)
    local events = room.logic:getEventsOfScope(GameEvent.Damage, 999, function(e)
      local damage = e.data[1]
      return damage.from == player
    end, Player.HistoryTurn)
    if #events == 0 then return end
    for _, id in ipairs(mark) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead and not p:isProhibited(player, Fk:cloneCard("duel")) then
        p:broadcastSkillInvoke("xunji")
        room:notifySkillInvoked(p, "xunji", "offensive")
        room:doIndicate(p.id, {player.id})
        local use = {
          from = p.id,
          tos = {{player.id}},
          card = Fk:cloneCard("duel"),
          skillName = "xunji",
        }
        room:useCard(use)
        if not p.dead and use.damageDealt and use.damageDealt[player.id] then
          room:damage{
            from = player,
            to = p,
            damage = use.damageDealt[player.id],
            skillName = "xunji",
          }
        end
      end
    end
  end,
}
local jiaofeng = fk.CreateTriggerSkill{
  name = "jiaofeng",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    if player:getLostHp() > 0 then
      player:drawCards(1, self.name)
    end
    if player:getLostHp() > 1 then
      data.damage = data.damage + 1
    end
    if player:getLostHp() > 2 then
      player.room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
xunji:addRelatedSkill(xunji_trigger)
caiyang:addSkill(xunji)
caiyang:addSkill(jiaofeng)
Fk:loadTranslationTable{
  ["caiyang"] = "蔡阳",
  ["xunji"] = "寻嫉",
  [":xunji"] = "出牌阶段限一次，你可以选择一名其他角色。该角色下个回合结束阶段，若其本回合造成过伤害，则你视为对其使用一张【决斗】；"..
  "此【决斗】对其造成伤害后，其对你造成等量的伤害。",
  ["jiaofeng"] = "交锋",
  [":jiaofeng"] = "锁定技，当你每回合首次造成伤害时，若你已损失体力值：大于0，你摸一张牌；大于1，此伤害+1；大于2，你回复1点体力。",
  ["#xunji"] = "寻嫉：选择一名其他角色，若其下回合内造成过伤害，则你视为对其使用【决斗】",
  ["@@xunji"] = "寻嫉",

  ["$xunji1"] = "待拿下你，再找丞相谢罪。",
  ["$xunji2"] = "姓关的，我现在就来抓你！",
  ["$jiaofeng1"] = "此击透骨，亦解骨肉之痛。",
  ["$jiaofeng2"] = "关羽？哼，不过如此！",
  ["~caiyang"] = "何处来的鼓声？",
}

local zhoushan = General(extension, "zhoushan", "wu", 4)
local miyun_active = fk.CreateActiveSkill{
  name = "miyun_active",
  target_num = 1,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip then return false end
    local id = Self:getMark("miyun")
    return to_select == id or table.contains(selected, id)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return table.contains(selected_cards, Self:getMark("miyun")) and #selected == 0 and to_select ~= Self.id
  end,
}
local miyun = fk.CreateTriggerSkill{
  name = "miyun",
  frequency = Skill.Compulsory,
  events = {fk.RoundStart, fk.RoundEnd, fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.RoundStart then
      return not table.every(player.room.alive_players, function (p) return p == player or p:isNude() end)
    elseif event == fk.RoundEnd then
      return table.contains(player.player_cards[player.Hand], player:getMark(self.name))
    elseif event == fk.AfterCardsMove then
      local miyun_losehp = (data.extra_data or {}).miyun_losehp or {}
      return table.contains(miyun_losehp, player.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and not p:isNude()
      end)
      if #targets == 0 then return false end
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#miyun-choose", self.name, false, true)
      local cid = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
      local move = {
        from = tos[1],
        ids = {cid},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = "miyun_prey",
      }
      room:moveCards(move)
    elseif event == fk.RoundEnd then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)

      local cid = player:getMark(self.name)
      local card = Fk:getCardById(cid)

      local _, ret = room:askForUseActiveSkill(player, "miyun_active", "#miyun-give:::" .. card:toLogString(), false)
      local to_give = {cid}
      local target = room:getOtherPlayers(to_give)[1].id
      if ret and #ret.cards > 0 and #ret.targets == 1 then
        to_give = ret.cards
        target = ret.targets[1]
      end
      local move = {
        from = player.id,
        ids = to_give,
        to = target,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = "miyun_give",
      }
      room:moveCards(move)
      if not player.dead then
        local x = player.maxHp - player:getHandcardNum()
        if x > 0 then
          room:drawCards(player, x, self.name)
        end
      end
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = {}
    for _, move in ipairs(data) do
      if move.from == player.id and (move.to ~= player.id or move.toArea ~= Card.PlayerHand) then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if player:getMark(self.name) == info.cardId then
            room:setPlayerMark(player, self.name, 0)
            room:setPlayerMark(player, "@miyun_safe", 0)
            room:setCardMark(Fk:getCardById(info.cardId), "@@miyun_safe", 0)
            if move.skillName ~= "miyun_give" then
              data.extra_data = data.extra_data or {}
              local miyun_losehp = data.extra_data.miyun_losehp or {}
              table.insert(miyun_losehp, player.id)
              data.extra_data.miyun_losehp = miyun_losehp
            end
          end
        end
      elseif move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "miyun_prey" then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            table.insert(marked, id)
          end
        end
      end
    end
    if #marked > 0 then
      for _, id in ipairs(player.player_cards[player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@miyun_safe", 0)
      end
      local card = Fk:getCardById(marked[1])
      room:setPlayerMark(player, self.name, card.id)
      local num = card.number
      if num > 0 then
        if num == 1 then
          num = "A"
        elseif num == 11 then
          num = "J"
        elseif num == 12 then
          num = "Q"
        elseif num == 13 then
          num = "K"
        end
      end
      room:setPlayerMark(player, "@miyun_safe", {card.name, card:getSuitString(true), num})
      room:setCardMark(card, "@@miyun_safe", 1)
    end
  end,
}
local danying = fk.CreateViewAsSkill{
  name = "danying",
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    local slash = Fk:cloneCard("slash")
    if pat == nil and slash.skill:canUse(Self, slash)  then
      table.insert(names, "slash")
    else
      if Exppattern:Parse(pat):matchExp("slash") then
          table.insert(names, "slash")
      end
      if Exppattern:Parse(pat):matchExp("jink")  then
          table.insert(names, "jink")
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}  --FIXME: 体验很不好！
  end,
  view_as = function(self, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cid = player:getMark(miyun.name)
    if table.contains(player.player_cards[player.Hand], cid) then
      player:showCards({cid})
    end
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(self.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local slash = Fk:cloneCard("slash")
    return slash.skill:canUse(player, slash)
  end,
  enabled_at_response = function(self, player)
    if player:usedSkillTimes(self.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local pat = Fk.currentResponsePattern
    return pat and Exppattern:Parse(pat):matchExp(self.pattern)
  end,
}
local danying_delay = fk.CreateTriggerSkill{
  name = "#danying_delay",
  events = {fk.TargetConfirmed},
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(danying.name) > 0 and player:usedSkillTimes(self.name) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if not from.dead and not player.dead and not player:isNude() then
      local cid = room:askForCardChosen(from, player, "he", danying.name)
      room:throwCard({cid}, danying.name, player, from)
    end
  end,
}
Fk:addSkill(miyun_active)
zhoushan:addSkill(miyun)
danying:addRelatedSkill(danying_delay)
zhoushan:addSkill(danying)

Fk:loadTranslationTable{
  ["zhoushan"] = "周善",
  ["miyun"] = "密运",
  ["miyun_active"] = "密运",
  [":miyun"] = "锁定技，每轮开始时，你展示并获得一名其他角色的一张牌，称为『安』；"..
  "每轮结束时，你将包括『安』在内的任意张手牌交给一名其他角色，然后你将手牌摸至体力上限。你不以此法失去『安』时，你失去1点体力。",
  ["danying"] = "胆迎",
  ["#danying_delay"] = "胆迎",
  [":danying"] = "每回合限一次，你可展示手牌中的『安』，然后视为使用或打出一张【杀】或【闪】。"..
  "若如此做，本回合你下次成为牌的目标后，使用者弃置你一张牌。",

  ["#miyun-choose"] = "密运：选择一名角色，获得其一张牌作为『安』",
  ["#miyun-give"] = "密运：选择包含『安』（%arg）在内的任意张手牌，交给一名角色",
  ["@miyun_safe"] = "安",
  ["@@miyun_safe"] = "安",

  ["$miyun1"] = "不要大张旗鼓，要神不知鬼不觉。",
  ["$miyun2"] = "小阿斗，跟本将军走一趟吧。",
  ["$danying1"] = "早就想会会你常山赵子龙了。",
  ["$danying2"] = "赵子龙是吧？兜鍪给你打掉。",
  ["~zhoushan"] = "夫人救我！夫人救我！",
}

--才子佳人：董白 何晏 王桃 王悦 赵嫣 滕胤 张嫙 夏侯令女 孙茹 蒯祺 庞山民 张媱
local dongbai = General(extension, "ty__dongbai", "qun", 3, 3, General.Female)
local ty__lianzhu = fk.CreateActiveSkill{
  name = "ty__lianzhu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__lianzhu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
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
    player:showCards(effect.cards)
    if player.dead or not table.contains(player:getCardIds("h"), effect.cards[1]) then return end
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, target.id)
    if player.dead then return end
    if card.color == Card.Red then
      player:drawCards(1, self.name)
    elseif card.color == Card.Black then
      if #target:getCardIds("he") < 2 or
        #room:askForDiscard(target, 2, 2, true, self.name, true, ".", "#ty__lianzhu-discard:"..player.id) ~= 2 then
        player:drawCards(2, self.name)
      end
    end
  end,
}
local ty__xiahui = fk.CreateMaxCardsSkill{
  name = "ty__xiahui",
  frequency = Skill.Compulsory,
  exclude_from = function(self, player, card)
    return player:hasSkill(self) and card.color == Card.Black
  end,
}
local ty__xiahui_trigger = fk.CreateTriggerSkill{
  name = "#ty__xiahui_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.HpChanged, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    elseif event == fk.HpChanged then
      return target == player and data.num < 0 and
        table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
    elseif event == fk.TurnEnd then
      return target == player and target:getMark("ty__xiahui-turn") > 0 and
        not table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          local to = room:getPlayerById(move.to)
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and table.contains(to:getCardIds("h"), info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "@@ty__xiahui-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.HpChanged then
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@ty__xiahui-inhand", 0)
      end
    elseif event == fk.TurnEnd then
      room:loseHp(player, 1, "ty__xiahui")
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function (self, event, target, player, data)
    if player.phase ~= Player.NotActive and player:getMark("ty__xiahui-turn") == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@ty__xiahui-inhand") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "ty__xiahui-turn", 1)
  end,
}
local ty__xiahui_prohibit = fk.CreateProhibitSkill{
  name = "#ty__xiahui_prohibit",
  prohibit_use = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
  end,
  prohibit_response = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
  end,
  prohibit_discard = function(self, player, card)
    return card:getMark("@@ty__xiahui-inhand") > 0
  end,
}
ty__xiahui:addRelatedSkill(ty__xiahui_trigger)
ty__xiahui:addRelatedSkill(ty__xiahui_prohibit)
dongbai:addSkill(ty__lianzhu)
dongbai:addSkill(ty__xiahui)
Fk:loadTranslationTable{
  ["ty__dongbai"] = "董白",
  ["ty__lianzhu"] = "连诛",
  [":ty__lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若此牌为：红色，你摸一张牌；黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",
  ["ty__xiahui"] = "黠慧",
  [":ty__xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，这些牌标记为“黠慧”，其不能使用、打出、弃置“黠慧”牌直到其体力值减少。"..
  "其他角色回合结束时，若其本回合失去过“黠慧”牌且手牌中没有“黠慧”牌，其失去1点体力。",
  ["#ty__lianzhu"] = "连诛：展示并交给一名其他角色一张牌，根据颜色执行效果",
  ["#ty__lianzhu-discard"] = "连诛：你需弃置两张牌，否则 %src 摸两张牌",
  ["@@ty__xiahui-inhand"] = "黠慧",

  ["$ty__lianzhu1"] = "坐上这华盖车，可真威风啊。",
  ["$ty__lianzhu2"] = "跟着我爷爷，还有什么好怕的？",
  ["~ty__dongbai"] = "这次……轮到我们家了吗……",
}

local heyan = General(extension, "heyan", "wei", 3)
local yachai = fk.CreateTriggerSkill{
  name = "yachai",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yachai-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local choices = {"yachai2"}
    if not data.from:isKongcheng() then
      table.insert(choices, 1, "yachai1")
      table.insert(choices, 3, "yachai3")
    end
    local choice = room:askForChoice(data.from, choices, self.name, "#yachai-choice:"..player.id, false, {"yachai1", "yachai2", "yachai3"})
    if choice == "yachai1" then
      local n = (data.from:getHandcardNum() + 1) // 2
      room:askForDiscard(data.from, n, n, false, self.name, false)
    elseif choice == "yachai2" then
      room:setPlayerMark(data.from, "@@yachai-turn", 1)
      player:drawCards(2, self.name)
    elseif choice == "yachai3" then
      data.from:showCards(data.from:getCardIds("h"))
      if player.dead or data.from.dead then return end
      local ids = data.from:getCardIds("h")
      local suits = {}
      for _, id in ipairs(ids) do
        if Fk:getCardById(id).suit ~= Card.NoSuit then
          table.insertIfNeed(suits, Fk:getCardById(id):getSuitString(true))
        end
      end
      if #ids == 0 then return end
      choice = room:askForChoice(data.from, suits, self.name, "#yachai-give:"..player.id)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(table.filter(ids, function(id) return Fk:getCardById(id):getSuitString(true) == choice end))
      room:obtainCard(player.id, dummy, true, fk.ReasonGive)
    end
  end,
}
local yachai_prohibit = fk.CreateProhibitSkill{
  name = "#yachai_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@yachai-turn") > 0 and card and table.contains(player:getCardIds("h"), card:getEffectiveId())
  end,
}
local qingtan = fk.CreateActiveSkill{
  name = "qingtan",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#qingtan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:doIndicate(player.id, table.map(room.alive_players, Util.IdMapper))
    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
    local extraData = {
      num = 1,
      min_num = 1,
      include_equip = false,
      pattern = ".",
      reason = self.name,
    }
    for _, p in ipairs(targets) do
      p.request_data = json.encode({"choose_cards_skill", "#qingtan-card", true, extraData})
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", targets)
    for _, p in ipairs(targets) do
      local id
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        id = json.decode(replyCard).subcards[1]
      else
        id = table.random(p:getCardIds("h"))
      end
      room:setPlayerMark(p, "qingtan-tmp", id)
    end

    local cards = {}
    for _, p in ipairs(targets) do
      if not p.dead then
        local id = p:getMark("qingtan-tmp")
        p:showCards({id})
        if room:getCardOwner(id) == p and room:getCardArea(id) == Card.PlayerHand then
          table.insertIfNeed(cards, id)
        end
      end
    end
    if player.dead or #cards == 0 then return end
    local suits = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(suits, Fk:getCardById(id):getSuitString(true))
    end
    local _, choice = U.askforChooseCardsAndChoice(player, cards, suits, self.name, "#qingtan-get", {"Cancel"}, 0, 0, cards)
    if choice ~= "Cancel" then
      for _, p in ipairs(targets) do
        if not player.dead and not p.dead then
          local id = p:getMark("qingtan-tmp")
          if Fk:getCardById(id):getSuitString(true) == choice and room:getCardOwner(id) == p and room:getCardArea(id) == Card.PlayerHand then
            room:setPlayerMark(p, "qingtan-tmp", 0)
            room:obtainCard(player.id, id, true, fk.ReasonPrey)
            if not p.dead then
              p:drawCards(1, self.name)
            end
            table.removeOne(cards, id)
          end
        end
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead and p:getMark("qingtan-tmp") ~= 0 then
        local id = p:getMark("qingtan-tmp")
        if room:getCardOwner(id) == p and room:getCardArea(id) == Card.PlayerHand then
          room:setPlayerMark(p, "qingtan-tmp", 0)
          room:throwCard({id}, self.name, p, player)
        end
      end
    end
  end,
}
yachai:addRelatedSkill(yachai_prohibit)
heyan:addSkill(yachai)
heyan:addSkill(qingtan)
Fk:loadTranslationTable{
  ["heyan"] = "何晏",
  ["yachai"] = "崖柴",
  [":yachai"] = "当你受到伤害后，你可以令伤害来源选择一项：1.弃置一半手牌（向上取整）；2.其本回合不能再使用手牌，你摸两张牌；"..
  "3.展示所有手牌，然后交给你一种花色的所有手牌。",
  ["qingtan"] = "清谈",
  [":qingtan"] = "出牌阶段限一次，你可令所有角色同时选择一张手牌并展示。你可以获得其中一种花色的牌，然后展示此花色牌的角色各摸一张牌。弃置其余的牌。",
  ["#yachai-invoke"] = "崖柴：是否对 %dest 发动“崖柴”？",
  ["yachai1"] = "弃置一半手牌",
  ["yachai2"] = "你本回合不能使用手牌，其摸两张牌",
  ["yachai3"] = "展示所有手牌并交给其一种花色的所有手牌",
  ["#yachai-choice"] = "崖柴：选择 %src 令你执行的一项",
  ["@@yachai-turn"] = "崖柴",
  ["#yachai-give"] = "崖柴：选择交给 %src 的花色",
  ["#qingtan"] = "清谈：所有角色展示一张手牌，你获得其中一种花色的牌，弃置其余牌",
  ["#qingtan-card"] = "清谈：请展示一张手牌",
  ["#qingtan-get"] = "清谈：选择获得其中一种花色的牌",

  ["$yachai1"] = "才秀知名，无所顾惮。",
  ["$yachai2"] = "讲论经义，为万世法。",
  ["$qingtan1"] = "事而为事，由无以成。",
  ["$qingtan2"] = "转蓬去其根，流飘从风移。",
  ["~heyan"] = "恃无以生。",
}

local sunluyu = General(extension, "ty__sunluyu", "wu", 3, 3, General.Female)
local ty__meibu = fk.CreateTriggerSkill{
  name = "ty__meibu",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target.phase == Player.Play and target ~= player and target:inMyAttackRange(player) and not player:isNude()
      elseif event == fk.AfterCardsMove and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then
        for _, move in ipairs(data) do
          if move.skillName == "ty__zhixi" then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).suit == player:getMark("ty__meibu-turn") and
                player.room:getCardArea(info.cardId) == Card.DiscardPile then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__meibu-invoke::"..target.id, true)
      if #card > 0 then
        self.cost_data = card[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:doIndicate(player.id, {target.id})
      room:setPlayerMark(player, "ty__meibu-turn", Fk:getCardById(self.cost_data).suit)
      room:throwCard({self.cost_data}, self.name, player, player)
      if target.dead then return end
      room:setPlayerMark(target, "@ty__meibu-turn", Fk:getCardById(self.cost_data):getSuitString(true))
      local turn = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn ~= nil and not target:hasSkill("ty__zhixi", true) then
        room:handleAddLoseSkills(target, "ty__zhixi", nil, true, false)
        turn:addCleaner(function()
          room:handleAddLoseSkills(target, "-ty__zhixi", nil, true, false)
        end)
      end
    else
      local ids = {}
      for _, move in ipairs(data) do
        if move.skillName == "ty__zhixi" then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).suit == player:getMark("ty__meibu-turn") and
              room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(ids)
      room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
local ty__mumu = fk.CreateTriggerSkill{
  name = "ty__mumu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p) return #p:getCardIds("e") > 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel", "ty__mumu1", "ty__mumu2"}
    local choice = room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return #p:getCardIds("e") > 0 end), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#"..choice.."-choose", self.name, true)
      if #to > 0 then
        self.cost_data = {choice, to[1]}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[2])
    local id = room:askForCardChosen(player, to, "e", self.name)
    room:setPlayerMark(player, self.cost_data[1].."-turn", 1)
    if self.cost_data[1] == "ty__mumu1" then
      room:throwCard({id}, self.name, to, player)
    else
      room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
  end,
}
local ty__mumu_targetmod = fk.CreateTargetModSkill{
  name = "#ty__mumu_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      if player:getMark("ty__mumu1-turn") > 0 then
        return 1
      end
      if player:getMark("ty__mumu2-turn") > 0 then
        return -1
      end
    end
  end,
}
local ty__zhixi = fk.CreateTriggerSkill{
  name = "ty__zhixi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng() and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick)
  end,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, false, self.name, false)
  end,
}
ty__mumu:addRelatedSkill(ty__mumu_targetmod)
sunluyu:addSkill(ty__meibu)
sunluyu:addSkill(ty__mumu)
sunluyu:addRelatedSkill(ty__zhixi)
Fk:loadTranslationTable{
  ["ty__sunluyu"] = "孙鲁育",
  ["ty__meibu"] = "魅步",
  [":ty__meibu"] = "其他角色的出牌阶段开始时，若你在其攻击范围内，你可以弃置一张牌，令该角色于本回合内拥有〖止息〗。若其本回合因〖止息〗"..
  "弃置牌的花色与你本次发动〖魅步〗弃置牌的花色相同，你获得之。",
  ["ty__mumu"] = "穆穆",
  [":ty__mumu"] = "出牌阶段开始时，你可以选择一项：1.弃置一名其他角色装备区里的一张牌，你本回合出牌阶段使用【杀】次数上限+1；2.获得一名其他角色装备区"..
  "里的一张牌，你本回合出牌阶段使用【杀】次数上限-1。",
  ["ty__zhixi"] = "止息",
  [":ty__zhixi"] = "锁定技，出牌阶段，当你使用【杀】或锦囊牌时，需弃置一张手牌。",
  ["#ty__meibu-invoke"] = "魅步：你可以弃置一张牌，令 %dest 本回合获得〖止息〗",
  ["@ty__meibu-turn"] = "魅步",
  ["ty__mumu1"] = "弃置一名角色一张装备，你出牌阶段使用【杀】次数+1",
  ["ty__mumu2"] = "获得一名角色一张装备，你出牌阶段使用【杀】次数-1",
  ["#ty__mumu1-choose"] = "穆穆：弃置一名其他角色装备区里的一张牌",
  ["#ty__mumu2-choose"] = "穆穆：获得一名其他角色装备区里的一张牌",

  ["$ty__meibu1"] = "姐妹之情，当真今日了断？",
  ["$ty__meibu2"] = "上下和睦，姐妹同心。",
  ["$ty__mumu1"] = "素性贞淑，穆穆春山。",
  ["$ty__mumu2"] = "雍穆融治，吾之所愿。",
  ["~ty__sunluyu"] = "姐姐，我们回不到从前了。",
}

local wangtao = General(extension, "wangtao", "shu", 3, 3, General.Female)
local huguan = fk.CreateTriggerSkill{
  name = "huguan",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Play and data.card.color == Card.Red then
      local n = 0
      for _, v in pairs(target.cardUsedHistory) do
        if v[Player.HistoryPhase] > 0 then
          n = n + v[Player.HistoryPhase]
          if n > 1 then return end
        end
      end
      return n == 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, ".", "#huguan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
    local choices = table.map(suits, function(s) return Fk:translate(s) end)
    local choice = room:askForChoice(player, choices, self.name, "#huguan-choice::"..target.id)
    local mark = target:getMark("huguan-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, suits[table.indexOf(choices, choice)])
    room:setPlayerMark(target, "huguan-turn", mark)
    room:setPlayerMark(target, "@huguan-turn", table.concat(table.map(mark, function(s) return Fk:translate(s) end)))
  end,
}
local huguan_maxcards = fk.CreateMaxCardsSkill{
  name = "#huguan_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("huguan-turn") ~= 0 and table.contains(player:getMark("huguan-turn"), card:getSuitString(true))
  end,
}
local yaopei = fk.CreateTriggerSkill{
  name = "yaopei",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Discard and player:usedSkillTimes("huguan", Player.HistoryTurn) > 0 and
      target ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local pattern = "."
    if target:getMark("yaopei-phase") ~= 0 then
      local suits = {"spade", "heart", "club", "diamond"}
      pattern = ".|.|"
      for _, s in ipairs(suits) do
        if not table.contains(target:getMark("yaopei-phase"), s) then
          pattern = pattern..s..","
        end
      end
    end
    if pattern[#pattern] == "," then
      pattern = string.sub(pattern, 1, #pattern - 1)
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, pattern, "#yaopei-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead or target.dead then return end
    local to1 = room:askForChoosePlayers(player, {player.id, target.id}, 1, 1, "#yaopei-choose", self.name, false)
    if #to1 > 0 then
      to1 = room:getPlayerById(to1[1])
    else
      to1 = room:getPlayerById(player.id)
    end
    local to2 = player
    if to1 == player then
      to2 = target
    end
    if to1:isWounded() then
      room:recover{
        who = to1,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    end
    to2:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("yaopei-phase")
    if mark == 0 then mark = {} end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, Fk:getCardById(info.cardId):getSuitString())
        end
      end
    end
    if #mark == 0 then mark = 0 end
    player.room:setPlayerMark(player, "yaopei-phase", mark)
  end,
}
huguan:addRelatedSkill(huguan_maxcards)
wangtao:addSkill(yaopei)
wangtao:addSkill(huguan)
Fk:loadTranslationTable{
  ["wangtao"] = "王桃",
  ["huguan"] = "护关",
  [":huguan"] = "一名角色于其出牌阶段内使用第一张牌时，若为红色，你可以声明一个花色，本回合此花色的牌不计入其手牌上限。",
  ["yaopei"] = "摇佩",
  [":yaopei"] = "其他角色弃牌阶段结束时，若你本回合对其发动过〖护关〗，你可以弃置一张其此阶段没弃置过的花色的牌，然后令你与其中一名角色回复1点体力，"..
  "另一名角色摸两张牌。",
  ["#huguan-invoke"] = "护关：你可以声明一种花色，令 %dest 本回合此花色牌不计入手牌上限",
  ["#huguan-choice"] = "护关：选择令 %dest 本回合不计入手牌上限的花色",
  ["@huguan-turn"] = "护关",
  ["#yaopei-invoke"] = "摇佩：你可以弃置一张 %dest 此阶段未弃置过花色的牌，你与其一方回复1点体力，另一方摸两张牌",
  ["#yaopei-choose"] = "摇佩：选择回复体力的角色，另一方摸两张牌",
  
  ["$huguan_wangtao1"] = "共护边关，蜀汉可安。",
  ["$huguan_wangtao2"] = "护君周全，妾身无悔。",
  ["$yaopei1"] = "环佩春风，步摇桃粉。",
  ["$yaopei2"] = "赠君摇佩，佑君安好。",
  ["~wangtao"] = "落花有意，何人来摘……",
}

local wangyue = General(extension, "wangyues", "shu", 3, 3, General.Female)
local mingluan = fk.CreateTriggerSkill{
  name = "mingluan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and target.phase == Player.Finish then
      local events = player.room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e) return true end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 0, 999, true, self.name, true, ".", "#mingluan-invoke::"..target.id, true)
    if card then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead or target:isKongcheng() or player:getHandcardNum() > 4 then return end
    local n = math.min(5 - player:getHandcardNum(), target:getHandcardNum())
    player:drawCards(n, self.name)
  end,
}
wangyue:addSkill(mingluan)
wangyue:addSkill("huguan")
Fk:loadTranslationTable{
  ["wangyues"] = "王悦",
  ["mingluan"] = "鸣鸾",
  [":mingluan"] = "其他角色的结束阶段，若本回合有角色回复过体力，你可以弃置任意张牌，然后摸等同于当前回合角色手牌数的牌（最多摸至五张）。",
  ["#mingluan-invoke"] = "鸣鸾：你可以弃置任意张牌（可以不弃置），然后摸 %dest 手牌数的牌，最多摸至五张",

  ["$huguan_wangyues1"] = "此战虽险，悦亦可助之。",
  ["$huguan_wangyues2"] = "葭萌关外，同君携手。",
  ["$mingluan1"] = "鸾笺寄情，笙歌动心。",
  ["$mingluan2"] = "鸾鸣轻歌，声声悦耳。",
  ["~wangyues"] = "这次比试不算，再来。",
}

local zhaoyanw = General(extension, "zhaoyanw", "wu", 3, 3, General.Female)
local jinhui = fk.CreateActiveSkill{
  name = "jinhui",
  prompt = "#jinhui-active",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local names = {}
    --FIXME：选牌逻辑需要重做 @(=ﾟωﾟ)ﾉ
    local quick_cards = {"jink", "nullification"}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if not (card.is_damage_card or table.contains(quick_cards, card.trueName) or card.trueName:startsWith("wd_")) then
        local x = card.skill:getMinTargetNum()
        if (x == 0 and not card.multiple_targets) or x == 1 then
          table.insertIfNeed(names, card.trueName)
        end
      end
    end
    if #names < 3 then return end
    names = table.random(names, 3)
    local card_ids = {}
    for _, name in ipairs(names) do
      table.insertTable(card_ids, room:getCardsFromPileByRule(name))
    end
    if #card_ids == 0 then return end
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#jinhui-choose", self.name, false)
    local target = room:getPlayerById(tos[1])

    local JinHuiUse = function(playerA, playerB, cancelable)
      if playerA.dead or playerB.dead then return false end
      local to_use = table.filter(card_ids, function (id)
        if room:getCardArea(id) ~= Card.Processing then return false end
        local card = Fk:getCardById(id)
        if not playerA:canUse(card) or playerA:prohibitUse(card) then return false end
        local to = card.skill:getMinTargetNum() == 0 and playerA or playerB
        return not playerA:isProhibited(to, card) and card.skill:modTargetFilter(to.id, {}, playerA.id, card, false)
      end)
      if #to_use == 0 then return false end
        local ids = room:askForCardsChosen(playerA, playerB, cancelable and 0 or 1, 1, {
          card_data = {
            { self.name, to_use }
          }
        }, self.name)
      if #ids == 0 then return false end
      local card = Fk:getCardById(ids[1])
      room:useCard({
        from = playerA.id,
        tos = {{card.skill:getMinTargetNum() == 0 and playerA.id or playerB.id}},
        card = card,
        extraUse = true,
      })
      return true
    end
    JinHuiUse(target, player, false)
    while JinHuiUse(player, target, true) do
      
    end
    card_ids = table.filter(card_ids, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #card_ids > 0 then
      room:moveCards({
        ids = card_ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
    end
  end
}

local qingman = fk.CreateTriggerSkill{
  name = "qingman",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getHandcardNum() < 5 - #target:getCardIds("e")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(5 - #target:getCardIds("e") - player:getHandcardNum(), self.name)
  end,
}
zhaoyanw:addSkill(jinhui)
zhaoyanw:addSkill(qingman)
Fk:loadTranslationTable{
  ["zhaoyanw"] = "赵嫣",
  ["jinhui"] = "锦绘",
  [":jinhui"] = "出牌阶段限一次，你可以将牌堆中随机三张不同名且目标数为一的非伤害牌置于你的武将牌上，然后选择一名其他角色，该角色使用其中一张，"..
  "然后你可以依次使用其余两张（必须选择你或其为目标，无距离和次数限制）。",
  ["qingman"] = "轻幔",
  [":qingman"] = "锁定技，每个回合结束时，你将手牌摸至X张（X为当前回合角色装备区内的空位数）。",

  ["#jinhui-active"] = "发动 锦绘，亮出牌堆顶三张牌，令其他角色使用其中一张，你使用其余两张",
  ["#jinhui-choose"] = "锦绘：令一名其他角色使用其中一张牌，然后你可以使用其余两张",
  ["#jinhui-use"] = "锦绘：使用其中一张牌（必须指定你或 %src 为目标），然后其可以使用其余两张",
  ["#jinhui2-use"] = "锦绘：你可以使用剩余的牌（必须指定你或 %dest 为目标）",
  ["jinhui_viewas"] = "锦绘",

  ["$jinhui1"] = "大则盈尺，小则方寸。",
  ["$jinhui2"] = "十指纤纤，万分机巧。",
  ["$qingman1"] = "经纬分明，片片罗縠。",
  ["$qingman2"] = "罗帐轻幔，可消酷暑烦躁。",
  ["~zhaoyanw"] = "彩绘锦绣，二者不可缺其一。",
}

local tengyin = General(extension, "tengyin", "wu", 3)
local chenjian = fk.CreateTriggerSkill{
  name = "chenjian",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 + player:getMark(self.name))
    room:moveCards({
      ids = ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local choices = {"Cancel", "chenjian1", "chenjian2"}
    local n = 0
    while not player.dead and #ids > 0 do
      ids = table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end)
      if table.contains(choices, "chenjian1") then
        for _, id in ipairs(player:getCardIds("he")) do
          if table.find(ids, function(i) return Fk:getCardById(id).suit == Fk:getCardById(i).suit end) and
            not player:prohibitDiscard(Fk:getCardById(id)) then
            --continue
          else
            table.removeOne(choices, "chenjian1")
          end
        end
      end

      --TODO: 理应也判断chenjian2的，但现在All choices有bug

      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then
        break
      else
        table.removeOne(choices, choice)
        if choice == "chenjian1" then
          local suits = {}
          for _, id in ipairs(ids) do
            table.insertIfNeed(suits, Fk:getCardById(id):getSuitString())
          end
          local to, card =  room:askForChooseCardAndPlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, ".|.|"..table.concat(suits, ","), "#chenjian-choose", self.name, true)
          if #to > 0 and card then
            local suit = Fk:getCardById(card).suit
            room:throwCard({card}, self.name, player, player)
            local dummy = Fk:cloneCard("dilu")
            for i = #ids, 1, -1 do
              if Fk:getCardById(ids[i]).suit == suit then
                dummy:addSubcard(ids[i])
                table.removeOne(ids, ids[i])
              end
            end
            if not room:getPlayerById(to[1]).dead then
              room:obtainCard(to[1], dummy, true, fk.ReasonJustMove)
            end
            n = n + 1
          end
        elseif choice == "chenjian2" then
          local fakemove = {
            toArea = Card.PlayerHand,
            to = player.id,
            moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
            moveReason = fk.ReasonJustMove,
          }
          room:notifyMoveCards({player}, {fakemove})
          local availableCards = {}
          for _, id in ipairs(ids) do
            local card = Fk:getCardById(id)
            if not player:prohibitUse(card) and card.skill:canUse(player, card) then
              table.insertIfNeed(availableCards, id)
            end
          end
          room:setPlayerMark(player, "chenjian_cards", availableCards)
          local success, dat = room:askForUseActiveSkill(player, "chenjian_viewas", "#chenjian-use", true)
          room:setPlayerMark(player, "chenjian_cards", 0)
          fakemove = {
            from = player.id,
            toArea = Card.Void,
            moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
            moveReason = fk.ReasonJustMove,
          }
          room:notifyMoveCards({player}, {fakemove})
          if success then
            room:moveCards({
              from = player.id,
              ids = dat.cards,
              toArea = Card.Processing,
              moveReason = fk.ReasonUse,
              skillName = self.name,
            })
            local card = Fk.skills["chenjian_viewas"]:viewAs(dat.cards)
            room:useCard{
              from = player.id,
              tos = table.map(dat.targets, function(id) return {id} end),
              card = card,
              extraUse = true,
            }
            n = n + 1
          end
        end
      end
    end
    ids = table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end)
    if #ids > 0 then
      room:moveCards({
        ids = ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
    end
    if n == 2 and not player.dead then
      if player:getMark(self.name) < 2 then
        room:addPlayerMark(player, self.name, 1)
      end
      if not player:isKongcheng() then
        room:recastCard(player:getCardIds("h"), player, self.name)
      end
    end
  end
}
local chenjian_viewas = fk.CreateViewAsSkill{
  name = "chenjian_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("chenjian_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
local xixiu = fk.CreateTriggerSkill{
  name = "xixiu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed, fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TargetConfirmed then
        return target == player and data.from ~= player.id and
          table.find(player:getCardIds("e"), function(id) return Fk:getCardById(id).suit == data.card.suit end)
      else
        if #player:getCardIds("e") ~= 1 then return end
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard and (move.proposer ~= player and move.proposer ~= player.id) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      player:drawCards(1, self.name)
    else
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and (move.proposer ~= player and move.proposer ~= player.id) then
          for i = #move.moveInfo, 1, -1 do
            local info = move.moveInfo[i]
            if info.fromArea == Card.PlayerEquip then
              table.removeOne(move.moveInfo, info)
              break
            end
          end
        end
      end
    end
  end,
}
Fk:addSkill(chenjian_viewas)
tengyin:addSkill(chenjian)
tengyin:addSkill(xixiu)
Fk:loadTranslationTable{
  ["tengyin"] = "滕胤",
  ["chenjian"] = "陈见",
  [":chenjian"] = "准备阶段，你可以亮出牌堆顶的三张牌并可以执行：1.弃置一张牌，令一名角色获得其中此牌花色的牌；2.使用其中一张牌。"..
  "若两项均执行，则本局游戏你发动〖陈见〗亮出牌数+1（最多五张），然后你重铸所有手牌。",
  ["xixiu"] = "皙秀",
  [":xixiu"] = "锁定技，当你成为其他角色使用牌的目标后，若你装备区内有与此牌花色相同的牌，你摸一张牌；其他角色不能弃置你装备区内的最后一张牌。",
  ["chenjian1"] = "弃一张牌，令一名角色获得此花色的牌",
  ["chenjian2"] = "使用其中一张牌",
  ["#chenjian-choose"] = "陈见：弃置一张牌并选择一名角色，令其获得与之相同花色的牌",
  ["chenjian_viewas"] = "陈见",
  ["#chenjian-use"] = "陈见：使用其中一张牌",

  ["$chenjian1"] = "国有其弊，上书当陈。",
  ["$chenjian2"] = "食君之禄，怎可默言。",
  ["$xixiu1"] = "君子如玉，德形皓白。",
  ["$xixiu2"] = "木秀于身，芬芳自如。",
  ["~tengyin"] = "臣好洁，不堪与之合污！",
}

local zhangxuan = General(extension, "zhangxuan", "wu", 4, 4, General.Female)
local tongli = fk.CreateTriggerSkill{
  name = "tongli",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
      (not data.card:isVirtual() or #data.card.subcards > 0) and not table.contains(data.card.skillNames, self.name) and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not (table.contains({"peach", "analeptic"}, data.card.trueName) and table.find(player.room.alive_players, function(p) return p.dying end)) then
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        if Fk:getCardById(id).suit ~= Card.NoSuit then
          table.insertIfNeed(suits, Fk:getCardById(id).suit)
        end
      end
      return #suits == player:getMark("@tongli-turn")
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.tongli = player:getMark("@tongli-turn")
    player.room:setPlayerMark(player, "tongli_tos", AimGroup:getAllTargets(data.tos))
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.AfterCardUseDeclared then
        return player.phase == Player.Play and not table.contains(data.card.skillNames, self.name)
      else
        return data.extra_data and data.extra_data.tongli and player:getMark("tongli_tos") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:addPlayerMark(player, "@tongli-turn", 1)
    else
      local n = data.extra_data.tongli
      local targets = player:getMark("tongli_tos")
      room:setPlayerMark(player, "tongli_tos", 0)
      local tos = table.simpleClone(targets)
      for i = 1, n, 1 do
        if player.dead then return end
        for _, id in ipairs(targets) do
          if room:getPlayerById(id).dead then
            return
          end
        end
        if table.contains({"savage_assault", "archery_attack"}, data.card.name) then  --to modify tenyear's stupid processing
          for _, p in ipairs(room:getOtherPlayers(player)) do
            if not player:isProhibited(p, Fk:cloneCard(data.card.name)) then
              table.insertIfNeed(tos, p.id)
            end
          end
        elseif table.contains({"amazing_grace", "god_salvation"}, data.card.name) then
          for _, p in ipairs(room:getAlivePlayers()) do
            if not player:isProhibited(p, Fk:cloneCard(data.card.name)) then
              table.insertIfNeed(tos, p.id)
            end
          end
        end
        room:sortPlayersByAction(tos)
        room:useVirtualCard(data.card.name, nil, player, table.map(tos, function(id) return room:getPlayerById(id) end), self.name, true)
      end
    end
  end,
}
local shezang = fk.CreateTriggerSkill{
  name = "shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (target == player or player.phase ~= Player.NotActive) and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
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

  ["$tongli1"] = "胞妹殊礼，妾幸同之。",
  ["$tongli2"] = "夫妻之礼，举案齐眉。",
  ["$shezang1"] = "世间千百物，物物皆相思。",
  ["$shezang2"] = "伊人将逝，何物为葬？",
  ["~zhangxuan"] = "陛下，臣妾绝无异心！",
}

local sunru = General(extension, "ty__sunru", "wu", 3, 3, General.Female)
local xiecui = fk.CreateTriggerSkill{
  name = "xiecui",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.from and not data.from.dead and data.from.phase ~= Player.NotActive and data.card then
      if data.from:getMark("xiecui-turn") == 0 then
        player.room:addPlayerMark(data.from, "xiecui-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#xiecui-invoke:"..data.from.id..":"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if data.from.kingdom == "wu" and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(data.from, data.card, false)
      room:addPlayerMark(data.from, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,
}
local youxu = fk.CreateTriggerSkill{
  name = "youxu",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target:getHandcardNum() > target.hp and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#youxu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    local targets = table.map(room:getOtherPlayers(target), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#youxu-choose:::"..Fk:getCardById(id):toLogString(), self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:obtainCard(to, id, true, fk.ReasonGive)
    to = room:getPlayerById(to)
    if to:isWounded() and table.every(room:getOtherPlayers(to), function (p) return p.hp >= to.hp end) then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
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
  ["#xiecui-invoke"] = "撷翠：你可以令 %src 对 %dest造成的伤害+1",
  ["#youxu-invoke"] = "忧恤：你可以展示 %dest 的一张手牌，然后交给另一名角色",
  ["#youxu-choose"] = "忧恤：选择获得%arg的角色",

  ["$xiecui1"] = "东隅既得，亦收桑榆。",
  ["$xiecui2"] = "江东多娇，锦花相簇。",
  ["$youxu1"] = "积富之家，当恤众急。",
  ["$youxu2"] = "周忧济难，请君恤之。",
  ["~ty__sunru"] = "伯言，抗儿便托付于你了。",
}

local xiahoulingnv = General(extension, "xiahoulingnv", "wei", 4, 4, General.Female)
local fuping = fk.CreateViewAsSkill{
  name = "fuping",
  anim_type = "special",
  pattern = ".",
  prompt = "#fuping-viewas",
  interaction = function()
    if type(Self:getMark("@$fuping")) ~= "table" then return end
    local all_names, names = Self:getMark("@$fuping"), {}
    local used_names = type(Self:getMark("fuping-turn")) == "table" and Self:getMark("fuping-turn") or {}
    for _, name in ipairs(all_names) do
      if not table.contains(used_names, name) then
        local to_use = Fk:cloneCard(name)
        to_use.skillName = "fuping"
        if ((Fk.currentResponsePattern == nil and Self:canUse(to_use) and not Self:prohibitUse(to_use)) or
          (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("@$fuping")
    if type(names) ~= "table" then return false end
    local used_names = type(player:getMark("fuping-turn")) == "table" and player:getMark("fuping-turn") or {}
    for _, name in ipairs(names) do
      if not table.contains(used_names, name) then
        local to_use = Fk:cloneCard(name)
        to_use.skillName = self.name
        if player:canUse(to_use) and not player:prohibitUse(to_use) then
          return true
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    local names = player:getMark("@$fuping")
    if type(names) ~= "table" then return false end
    local used_names = type(player:getMark("fuping-turn")) == "table" and player:getMark("fuping-turn") or {}
    for _, name in ipairs(names) do
      if not table.contains(used_names, name) then
        local to_use = Fk:cloneCard(name)
        to_use.skillName = self.name
        if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
          return true
        end
      end
    end
  end,
  before_use = function(self, player, useData)
    local names = type(player:getMark("fuping-turn")) == "table" and player:getMark("fuping-turn") or {}
    table.insert(names, useData.card.trueName)
    player.room:setPlayerMark(player, "fuping-turn", names)
  end,
}
local fuping_trigger = fk.CreateTriggerSkill{
  name = "#fuping_trigger",
  events = {fk.CardUseFinished},
  main_skill = fuping,
  can_trigger = function(self, event, target, player, data)
    if target == player or not player:hasSkill(fuping.name) or #player:getAvailableEquipSlots() == 0 then return false end
    if data.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(data.tos), player.id) then
      local mark = player:getMark("@$fuping")
      return type(mark) ~= "table" or not table.contains(mark, data.card.trueName)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
    local subtypes = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    table.insert(all_choices, "Cancel")
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, fuping.name, "#fuping-choice:::" .. data.card.trueName, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(fuping.name)
    room:abortPlayerArea(player, {self.cost_data})
    local mark = type(player:getMark("@$fuping")) == "table" and player:getMark("@$fuping") or {}
    table.insertIfNeed(mark, data.card.trueName)
    room:setPlayerMark(player, "@$fuping", mark)
  end,
}
local fuping_targetmod = fk.CreateTargetModSkill{
  name = "#fuping_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(fuping.name) and #player:getAvailableEquipSlots() == 0
  end,
}
local weilie = fk.CreateActiveSkill{
  name = "weilie",
  anim_type = "support",
  prompt = function ()
    local max_times = type(Self:getMark("@$fuping")) == "table" and #Self:getMark("@$fuping") or 0
    return "#weilie-active:::" .. tostring(max_times - Self:usedSkillTimes("weilie", Player.HistoryGame) + 1)
  end,
  can_use = function(self, player)
    local max_times = type(player:getMark("@$fuping")) == "table" and #player:getMark("@$fuping") or 0
    return player:usedSkillTimes(self.name, Player.HistoryGame)  <= max_times
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  target_num = 1,
  card_num = 1,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, from, from)
    local target = room:getPlayerById(effect.tos[1])
    room:recover({
      who = target,
      num = 1,
      recoverBy = from,
      skillName = self.name
    })
    if not target.dead and target:isWounded() then
      room:drawCards(target, 1, self.name)
    end
  end,
}
fuping:addRelatedSkill(fuping_trigger)
fuping:addRelatedSkill(fuping_targetmod)
xiahoulingnv:addSkill(fuping)
xiahoulingnv:addSkill(weilie)
Fk:loadTranslationTable{
  ["xiahoulingnv"] = "夏侯令女",
  ["fuping"] = "浮萍",
  [":fuping"] = "当其他角色以你为目标的基本牌或锦囊牌牌结算后，若你未记录此牌，你可以废除一个装备栏并记录此牌。"..
  "你可以将一张非基本牌当记录的牌使用或打出（每种牌名每回合限一次）。若你的装备栏均已废除，你使用牌无距离限制。",
  ["weilie"] = "炜烈",
  [":weilie"] = "每局游戏限一次，出牌阶段，你可以弃置一张牌令一名角色回复1点体力，然后若其已受伤，则其摸一张牌。你每次发动〖浮萍〗记录牌名时，"..
  "此技能可发动次数+1。",

  ["#fuping_trigger"] = "浮萍",
  ["#fuping-choice"] = "是否发动 浮萍，废除一个装备栏，记录牌名【%arg】",
  ["@$fuping"] = "浮萍",
  ["#fuping-viewas"] = "发动 浮萍，将一张非基本牌当记录过的牌使用",
  ["#weilie-active"] = "发动 炜烈，弃置一张牌令一名已受伤的角色回复体力（剩余 %arg 次）",

  ["$fuping1"] = "有草生清池，无根碧波上。",
  ["$fuping2"] = "愿为浮萍草，托身寄清池。",
  ["$weilie1"] = "好学尚贞烈，义形必沾巾。",
  ["$weilie2"] = "贞烈过男子，何处弱须眉？",
  ["~xiahoulingnv"] = "心存死志，绝不肯从！",
}

local kuaiqi = General(extension, "kuaiqi", "wei", 3)
local liangxiu = fk.CreateActiveSkill{
  name = "liangxiu",
  anim_type = "drawcard",
  card_num = 2,
  target_num = 0,
  prompt = "#liangxiu",
  can_use = function(self, player)
    if #player:getCardIds("he") > 1 then
      for _, type in ipairs({"basic", "trick", "equip"}) do
        return player:getMark("liangxiu_"..type.."-phase") == 0
      end
    end
  end,
  card_filter = function(self, to_select, selected)
    if #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select)) then
      if #selected == 0 then
        return true
      else
        if Fk:getCardById(to_select).type ~= Fk:getCardById(selected[1]).type then
          local types = {"basic", "trick", "equip"}
          table.removeOne(types, Fk:getCardById(to_select):getTypeString())
          table.removeOne(types, Fk:getCardById(selected[1]):getTypeString())
          return Self:getMark("liangxiu_"..types[1].."-phase") == 0
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local types = {"basic", "trick", "equip"}
    for i = 1, 2, 1 do
      table.removeOne(types, Fk:getCardById(effect.cards[i]):getTypeString())
    end
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    room:setPlayerMark(player, "liangxiu_"..types[1].."-phase", 1)
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|"..types[1], 2)
    if #cards > 0 then
      local card = room:askForCardsChosen(player, player, 1, 1, {card_data = {{self.name, cards}}}, self.name, "#liangxiu-get")
      if #card > 0 then
        card = card[1]
      else
        card = cards[1]
      end
      room:obtainCard(player.id, card, true, fk.ReasonJustMove)
    end
  end
}
local xunjie = fk.CreateTriggerSkill{
  name = "xunjie",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark("xunjie_caninvoke-turn") > 0 and
      table.find(player.room.alive_players, function(p) return p:getHandcardNum() ~= p.hp end) and
      player:usedSkillTimes(self.name, Player.HistoryRound) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room.alive_players, function(p) return p:getHandcardNum() ~= p.hp end), Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#xunjie-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {}
    for i = 1, 2, 1 do
      if player:getMark("xunjie"..i.."-round") == 0 then
        table.insert(choices, "xunjie"..i)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#xunjie-choice::"..to.id, false, {"xunjie1", "xunjie2"})
    room:setPlayerMark(player, choice.."-round", 1)
    local n = to:getHandcardNum() - to.hp
    if choice == "xunjie1" then
      if n > 0 then
        room:askForDiscard(to, n, n, false, self.name, false)
      else
        to:drawCards(-n, self.name)
      end
    else
      if n > 0 then
        room:changeHp(to, math.min(n, to:getLostHp()), nil, self.name)
      else
        room:broadcastPlaySound("./audio/system/losehp")
        room:changeHp(to, n, nil, self.name)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},  --不能用记录器
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true) and player:getMark("xunjie_caninvoke-turn") == 0 and player.phase ~= Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        player.room:setPlayerMark(player, "xunjie_caninvoke-turn", 1)
        return
      end
    end
  end,
}
kuaiqi:addSkill(liangxiu)
kuaiqi:addSkill(xunjie)
Fk:loadTranslationTable{
  ["kuaiqi"] = "蒯祺",
  ["liangxiu"] = "良秀",
  [":liangxiu"] = "出牌阶段，你可以弃置两张不同类型的牌，然后从两张与你弃置牌类型均不同的牌中选择一张获得（每种类别限一次）。",
  ["xunjie"] = "殉节",
  [":xunjie"] = "每轮各限一次，每个回合结束时，若你本回合获得过手牌（摸牌阶段除外），你可以令一名角色将手牌/体力值调整至其体力值/手牌数。",
  ["#liangxiu"] = "良秀：你可以弃置两张类别不同的牌，获得一张另一类别的牌",
  ["#liangxiu-get"] = "良秀：选择获得一张牌",
  ["#xunjie-choose"] = "殉节：你可以令一名角色将手牌/体力值调整至其体力值/手牌数",
  ["#xunjie-choice"] = "殉节：选择令 %dest 执行的一项",
  ["xunjie1"] = "手牌数调整至体力值",
  ["xunjie2"] = "体力值调整至手牌数",

  ["$liangxiu1"] = "君子性谦，不夺人之爱。",
  ["$liangxiu2"] = "蒯门多隽秀，吾居其末。",
  ["$xunjie1"] = "君子有节，可杀而不可辱。",
  ["$xunjie2"] = "吾受国命，城破则身死。",
  ["~kuaiqi"] = "泉下万事休，人间雪满头……",
}

local zhangyao = General(extension, "zhangyao", "wu", 3, 3, General.Female)
local yuanyu = fk.CreateActiveSkill{
  name = "yuanyu",
  anim_type = "control",
  prompt = "#yuanyu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("yuanyu_extra_times-phase")
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:drawCards(player, 1, self.name)
    if player:isKongcheng() then return end
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, ".|.|.|hand", "#yuanyu-choose", self.name, false)
    if #tar > 0 and card then
      local targetRecorded = type(player:getMark("yuanyu_targets")) == "table" and player:getMark("yuanyu_targets") or {}
      if not table.contains(targetRecorded, tar[1]) then
        table.insert(targetRecorded, tar[1])
        room:addPlayerMark(room:getPlayerById(tar[1]), "@@yuanyu")
      end
      room:setPlayerMark(player, "yuanyu_targets", targetRecorded)
      player:addToPile("yuanyu_resent", card, true, self.name)
    end
  end
}
local yuanyu_trigger = fk.CreateTriggerSkill{
  name = "#yuanyu_trigger",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuanyu.name) then
      if event == fk.Damage then
        return target and not target:isKongcheng() and player:getMark("yuanyu_targets") ~= 0 and table.contains(player:getMark("yuanyu_targets"), target.id)
      elseif event == fk.EventPhaseStart and target.phase == Player.Discard then
        if target == player then
          return player:getMark("yuanyu_targets") ~= 0 and table.find(player:getMark("yuanyu_targets"), function (pid)
            local p = player.room:getPlayerById(pid)
            return not p:isKongcheng() and not p.dead end)
        else
          return not target:isKongcheng() and player:getMark("yuanyu_targets") ~= 0 and table.contains(player:getMark("yuanyu_targets"), target.id)
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local x = 1
    if event == fk.Damage then
      x = data.damage
    end
    for i = 1, x do
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    if event == fk.EventPhaseStart and target == player then
      local targetRecorded = player:getMark("yuanyu_targets")
      tos = table.filter(room:getAlivePlayers(), function (p) return table.contains(targetRecorded, p.id) end)
    else
      table.insert(tos, target)
    end
    room:doIndicate(player.id, table.map(tos, Util.IdMapper))
    for _, to in ipairs(tos) do
      if player.dead then break end
      local targetRecorded = player:getMark("yuanyu_targets")
      if targetRecorded == 0 then break end
      if not to.dead and not to:isKongcheng() and table.contains(targetRecorded, to.id) then
        local card = room:askForCard(to, 1, 1, false, self.name, false, ".|.|.|hand", "#yuanyu-push:" .. player.id)
        player:addToPile("yuanyu_resent", card, true, self.name) --原为false
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= yuanyu then return false end
    return player == target and type(player:getMark("yuanyu_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
  end,
}
local xiyan = fk.CreateTriggerSkill{
  name = "xiyan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerSpecial and move.specialName == "yuanyu_resent" then
          local suits = {}
          for _, id in ipairs(player:getPile("yuanyu_resent")) do
            table.insertIfNeed(suits, Fk:getCardById(id).suit)
          end
          table.removeOne(suits, Card.NoSuit)
          return #suits > 3
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("yuanyu_resent"))
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    if room.current and not room.current.dead and room.current.phase ~= Player.NotActive then
      if room.current == player then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 4)
        if player:usedSkillTimes(yuanyu.name, Player.HistoryPhase) > player:getMark("yuanyu_extra_times-phase") then
          room:addPlayerMark(player, "yuanyu_extra_times-phase")
        end
        room:addPlayerMark(player, "xiyan_targetmod-turn")
      elseif room:askForSkillInvoke(player, self.name, nil, "#xiyan-debuff::"..room.current.id) then
        room:addPlayerMark(room.current, MarkEnum.MinusMaxCardsInTurn, 4)
        room:addPlayerMark(room.current, "@@xiyan_prohibit-turn")
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if (move.from == player.id and table.find(move.moveInfo, function (info)
        return info.fromSpecialName == "yuanyu_resent" end)) or (move.to == player.id and move.specialName == "yuanyu_resent") then
          return true
        end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local suitsRecorded = {}
    if player:hasSkill(self.name, true) then
      for _, id in ipairs(player:getPile("yuanyu_resent")) do
        table.insertIfNeed(suitsRecorded, Fk:getCardById(id):getSuitString(true))
      end
    end
    player.room:setPlayerMark(player, "@xiyan", #suitsRecorded > 0 and suitsRecorded or 0)
  end,
}
local xiyan_targetmod = fk.CreateTargetModSkill{
  name = "#xiyan_targetmod",
  residue_func = function(self, player, skill, scope, card)
    return (card and player:getMark("xiyan_targetmod-turn") > 0) and 999 or 0
  end,
}
local xiyan_prohibit = fk.CreateProhibitSkill{
  name = "#xiyan_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@xiyan_prohibit-turn") > 0 and card.type == Card.TypeBasic
  end,
}
yuanyu:addRelatedSkill(yuanyu_trigger)
xiyan:addRelatedSkill(xiyan_targetmod)
xiyan:addRelatedSkill(xiyan_prohibit)
zhangyao:addSkill(yuanyu)
zhangyao:addSkill(xiyan)
Fk:loadTranslationTable{
  ["zhangyao"] = "张媱",
  ["yuanyu"] = "怨语",
  ["#yuanyu_trigger"] = "怨语",
  [":yuanyu"] = "出牌阶段限一次，你可以摸一张牌并将一张手牌置于武将牌上，称为“怨”。然后选择一名其他角色，你与其的弃牌阶段开始时，"..
  "该角色每次造成1点伤害后也须放置一张“怨”直到你触发〖夕颜〗。",
  ["xiyan"] = "夕颜",
  [":xiyan"] = "每次增加“怨”时，若“怨”的花色数达到4种，你可以获得所有“怨”。然后若此时是你的回合，你的〖怨语〗视为未发动过，"..
  "本回合手牌上限+4且使用牌无次数限制；若不是你的回合，你可令当前回合角色本回合手牌上限-4且本回合不能使用基本牌。",

  ["yuanyu_resent"] = "怨",
  ["@@yuanyu"] = "怨语",
  ["#yuanyu"] = "怨语：你可以摸一张牌，然后放置一张手牌作为“怨”",
  ["#yuanyu-choose"] = "怨语：选择作为“怨”的一张手牌以及作为目标的一名其他角色",
  ["#yuanyu-push"] = "怨语：选择一张手牌作为%src的“怨”",
  ["@xiyan"] = "夕颜",
  ["#xiyan-debuff"] = "夕颜：是否令%dest本回合不能使用基本牌且手牌上限-4",
  ["@@xiyan_prohibit-turn"] = "夕颜 不能出牌",

  ["$yuanyu1"] = "此生最恨者，吴垣孙氏人。",
  ["$yuanyu2"] = "愿为宫外柳，不做建章卿。",
  ["$xiyan1"] = "夕阳绝美，只叹黄昏。",
  ["$xiyan2"] = "朱颜将逝，知我何求。",
  ["~zhangyao"] = "花开人赏，花败谁怜……",
}

--芝兰玉树：张虎 吕玲绮 刘永 万年公主 滕公主 庞会 赵统赵广 袁谭袁尚袁熙 乐綝
local zhanghu = General(extension, "zhanghu", "wei", 4)
local cuijian = fk.CreateActiveSkill{
  name = "cuijian",
  anim_type = "control",
  prompt = "#cuijian-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = table.filter(target:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "jink" end)
    if #cards == 0 then
      if player:getMark("tongyuan1") ~= 0 then
        room:drawCards(player, 2, self.name)
      end
    else
      table.insertTable(cards, table.filter(target:getCardIds("he"), function(id) return Fk:getCardById(id).sub_type == Card.SubtypeArmor end))
      local x = #cards
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, true, fk.ReasonGive)
      if player.dead or player:isNude() or player:getMark("tongyuan2") ~= 0 or target.dead then return end
      local cards = player:getCardIds({Player.Hand, Player.Equip})
      if #cards > x then
        cards = room:askForCard(player, x, x, true, self.name, false, ".", "#cuijian-card::" .. target.id .. ":" .. tostring(x))
      end
      room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    end
  end,
}
local tongyuan = fk.CreateTriggerSkill{
  name = "tongyuan",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.color == Card.Red then
      if data.card.type == Card.TypeTrick then
        return event == fk.CardUseFinished and player:getMark("tongyuan1") == 0
      elseif data.card.type == Card.TypeBasic then
        return player:getMark("tongyuan2") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeTrick then
      room:setPlayerMark(player, "tongyuan1", 1)
      room:setPlayerMark(player, "@tongyuan", player:getMark("tongyuan2") > 0 and "tongyuan_all" or "tongyuan1")
    else
      room:setPlayerMark(player, "tongyuan2", 1)
      room:setPlayerMark(player, "@tongyuan", player:getMark("tongyuan1") > 0 and "tongyuan_all" or "tongyuan2")
    end
  end,
}
local tongyuan_delay = fk.CreateTriggerSkill{
  name = "#tongyuan_delay",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("tongyuan1") ~= 0 and player:getMark("tongyuan2") ~=0 and data.card.color == Card.Red then
      if event == fk.CardUsing then
        return data.card:isCommonTrick()
      else
        return data.card.type == Card.TypeBasic and #U.getUseExtraTargets(player.room, data) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(tongyuan.name)
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    else
      local targets = U.getUseExtraTargets(room, data)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#tongyuan-choose:::"..data.card:toLogString(), tongyuan.name, true)
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    end
  end,
}
tongyuan:addRelatedSkill(tongyuan_delay)
zhanghu:addSkill(cuijian)
zhanghu:addSkill(tongyuan)
Fk:loadTranslationTable{
  ["zhanghu"] = "张虎",
  ["cuijian"] = "摧坚",
  [":cuijian"] = "出牌阶段限一次，你可以选择一名有手牌的其他角色，若其手牌中有【闪】，其将所有【闪】和防具牌交给你，然后你交给其等量的牌。",
  ["tongyuan"] = "同援",
  [":tongyuan"] = "锁定技，你使用红色锦囊牌后，〖摧坚〗增加效果“若其没有【闪】，你摸两张牌”；<br>"..
  "你使用或打出红色基本牌后，〖摧坚〗将“交给”的效果删除；<br>"..
  "若以上两个效果均已触发，则你本局游戏接下来你使用红色普通锦囊牌无法被响应，使用红色基本牌可以额外指定一个目标。",

  ["#cuijian-active"] = "发动 摧坚，选择一名有手牌的其他角色",
  ["#cuijian-card"] = "摧坚：交给 %dest %arg张牌",
  ["@tongyuan"] = "同援",
  ["tongyuan1"] = "没闪摸牌",
  ["tongyuan2"] = "不用给牌",
  ["tongyuan_all"] = "全部生效",
  ["#tongyuan_delay"] = "同援",
  ["#tongyuan-choose"] = "同援：你可以为%arg额外指定一个目标",

  ["$cuijian1"] = "所当皆披靡，破坚若无人！",
  ["$cuijian2"] = "一枪定顽敌，一骑破坚城！",
  ["$tongyuan1"] = "乐将军何在？随我共援上方谷！",
  ["$tongyuan2"] = "袍泽有难，岂有坐视之理？",
  ["~zhanghu"] = "虎父威犹在，犬子叹奈何……",
}

local lvlingqi = General(extension, "lvlingqi", "qun", 4, 4, General.Female)
local guowu = fk.CreateTriggerSkill{
  name = "guowu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    local card = room:getCardsFromPileByRule("slash", 1, "discardPile")
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
    if #types > 1 then
      room:addPlayerMark(player, "guowu2-phase", 1)
    end
    if #types > 2 then
      room:addPlayerMark(player, "guowu3-phase", 1)
    end
  end,
}

local guowu_delay = fk.CreateTriggerSkill{
  name = "#guowu_delay",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("guowu3-phase") > 0 and not player.dead and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and #U.getUseExtraTargets(player.room, data) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = U.getUseExtraTargets(room, data)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, 2, "#guowu-choose:::"..data.card:toLogString(), guowu.name, true)
    if #tos > 0 then
      table.forEach(tos, function (id)
        table.insert(data.tos, {id})
      end)
    end
  end,
}
local guowu_targetmod = fk.CreateTargetModSkill{
  name = "#guowu_targetmod",
  bypass_distances =  function(self, player)
    return player:getMark("guowu2-phase") > 0
  end,
}
local zhuangrong = fk.CreateTriggerSkill{
  name = "zhuangrong",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player.player_cards[Player.Hand] == 1 or player.hp == 1
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
    room:handleAddLoseSkills(player, "shenwei|wushuang", nil, true, false)
  end,
}
guowu:addRelatedSkill(guowu_delay)
guowu:addRelatedSkill(guowu_targetmod)
lvlingqi:addSkill(guowu)
lvlingqi:addSkill(zhuangrong)
lvlingqi:addRelatedSkill("shenwei")
lvlingqi:addRelatedSkill("wushuang")
Fk:loadTranslationTable{
  ["lvlingqi"] = "吕玲绮",
  ["guowu"] = "帼武",
  ["#guowu_delay"] = "帼武",
  [":guowu"] = "出牌阶段开始时，你可以展示所有手牌，若包含的类别数：不小于1，你从弃牌堆中获得一张【杀】；不小于2，你本阶段使用牌无距离限制；"..
  "不小于3，你本阶段使用【杀】或普通锦囊牌可以多指定两个目标。",
  ["zhuangrong"] = "妆戎",
  [":zhuangrong"] = "觉醒技，一名角色的回合结束时，若你的手牌数或体力值为1，你减1点体力上限并将体力值回复至体力上限，然后将手牌摸至体力上限。"..
  "若如此做，你获得技能〖神威〗和〖无双〗。",
  ["#guowu-choose"] = "帼武：你可以为%arg增加至多两个目标",

  ["$guowu1"] = "方天映黛眉，赤兔牵红妆。",
  ["$guowu2"] = "武姬青丝利，巾帼女儿红。",
  ["$zhuangrong1"] = "锋镝鸣手中，锐戟映秋霜。",
  ["$zhuangrong2"] = "红妆非我愿，学武觅封侯。",
  ["$shenwei_lvlingqi1"] = "继父神威，无坚不摧！",
  ["$shenwei_lvlingqi2"] = "我乃温侯吕奉先之女！",
  ["$wushuang_lvlingqi1"] = "猛将策良骥，长戟破敌营。",
  ["$wushuang_lvlingqi2"] = "杀气腾剑戟，严风卷戎装。",
  ["~lvlingqi"] = "父亲，女儿好累……",
}

local liuyong = General(extension, "liuyong", "shu", 3)
local zhuning = fk.CreateActiveSkill{
  name = "zhuning",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("zhuning-phase") < 2 and not player:isNude()
  end,
  card_filter = Util.TrueFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(player, "zhuning-phase", 2)
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      proposer = player.id,
      skillName = self.name,
    })
    if not player.dead then
      local success, data = room:askForUseActiveSkill(player, "zhuning_viewas", "#zhuning-choice", true)
      if success then
        local card = Fk.skills["zhuning_viewas"]:viewAs(data.cards)
        local use = {
          from = player.id,
          tos = table.map(data.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
        room:useCard(use)
        if not player.dead and not use.damageDealt then
          room:removePlayerMark(player, "zhuning-phase", 1)
        end
      end
    end
  end,
}
local zhuning_viewas = fk.CreateViewAsSkill{
  name = "zhuning_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.is_damage_card and not card.is_derived then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "zhuning"
    return card
  end,
}
local zhuning_targetmod = fk.CreateTargetModSkill{
  name = "#zhuning_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "zhuning")
  end,
}
local function getFengxiangPlayer(room)
  local nums = table.map(room.alive_players, function(p)
    return #table.filter(p:getCardIds("h"), function(id)
      return Fk:getCardById(id, true):getMark("@@zhuning-inhand") > 0
    end)
  end)
  local n = math.max(table.unpack(nums))
  if #table.filter(room.alive_players, function(p)
      return #table.filter(p:getCardIds("h"), function(id)
        return Fk:getCardById(id, true):getMark("@@zhuning-inhand") > 0
      end) == n
    end) > 1 then
      return 0
  else
    return room.alive_players[table.indexOf(nums, n)].id
  end
end
local fengxiang = fk.CreateTriggerSkill{
  name = "fengxiang",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.Damaged then
        return target == player
      else
        local to = getFengxiangPlayer(player.room)
        for _, move in ipairs(data) do
          if move.extra_data and move.extra_data.fengxiang and move.extra_data.fengxiang ~= to then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      local to = getFengxiangPlayer(room)
      if to ~= 0 then
        room:doIndicate(player.id, {to})
        to = room:getPlayerById(to)
        if to:isWounded() then
          room:recover({
            who = to,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      else
        player:drawCards(1, self.name)
      end
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.BeforeCardsMove, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.BeforeCardsMove then
      if player:hasSkill(self.name, true) then
        for _, move in ipairs(data) do
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
          if move.toArea == Card.PlayerHand then
            return true
          end
        end
      end
    else
      for _, move in ipairs(data) do
        if move.skillName == "zhuning" then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.BeforeCardsMove then
      for _, move in ipairs(data) do
        move.extra_data = move.extra_data or {}
        move.extra_data.fengxiang = getFengxiangPlayer(player.room)
      end
    else
      for _, move in ipairs(data) do
        if move.skillName == "zhuning" then
          for _, info in ipairs(move.moveInfo) do
            player.room:setCardMark(Fk:getCardById(info.cardId, true), "@@zhuning-inhand", 1)
          end
        end
      end
    end
  end,
}
Fk:addSkill(zhuning_viewas)
zhuning:addRelatedSkill(zhuning_targetmod)
liuyong:addSkill(zhuning)
liuyong:addSkill(fengxiang)
Fk:loadTranslationTable{
  ["liuyong"] = "刘永",
  ["zhuning"] = "诛佞",
  [":zhuning"] = "出牌阶段限一次，你可以交给一名其他角色任意张牌，这些牌标记为“隙”，然后你可以视为使用一张不计次数的【杀】或伤害类锦囊牌，"..
  "然后若此牌没有造成伤害，此技能本阶段改为“出牌阶段限两次”。",
  ["fengxiang"] = "封乡",
  [":fengxiang"] = "锁定技，当你受到伤害后，手牌中“隙”唯一最多的角色回复1点体力（没有唯一最多的角色则改为你摸一张牌）；"..
  "当有角色因手牌数改变而使“隙”唯一最多的角色改变后，你摸一张牌。",
  ["@@zhuning-inhand"] = "隙",
  ["zhuning_viewas"] = "诛佞",
  ["#zhuning-choice"] = "诛佞：你可以视为使用一张不计次数的伤害牌",

  ["$zhuning1"] = "此剑半丈，当斩奸佞人头！",
  ["$zhuning2"] = "此身八尺，甘为柱国之石。",
  ["$fengxiang1"] = "北风摧蜀地，王爵换乡侯。",
  ["$fengxiang2"] = "汉皇可负我，我不负父兄。",
  ["~liuyong"] = "他日若是凛风起，你自长哭我自笑。",
}

local wanniangongzhu = General(extension, "wanniangongzhu", "qun", 3, 3, General.Female)
local zhenge = fk.CreateTriggerSkill{
  name = "zhenge",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local p = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, "#zhenge-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:getMark("@zhenge") < 5 then
      room:addPlayerMark(to, "@zhenge", 1)
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(to)) do
      if to:inMyAttackRange(p) and not to:isProhibited(p, Fk:cloneCard("slash")) then
        if p ~= player then
          table.insert(targets, p.id)
        end
      else
        return
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhenge-slash::"..to.id, self.name, true)
    if #tos > 0 then
      room:useVirtualCard("slash", nil, to, room:getPlayerById(tos[1]), self.name, true)
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
    return player:hasSkill(self) and target and target:getMark("@zhenge") > 0 and
      data.card and data.card.trueName == "slash" and data.card.extra_data and table.contains(data.card.extra_data, "xinghan")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not table.every(room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Hand] < player:getHandcardNum() end) then
        player:drawCards(math.min(target:getAttackRange(), 5), self.name)
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player.phase ~= Player.NotActive and data.card.trueName == "slash" and player:getMark("xinghan-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xinghan-turn", 1)
    if target:getMark("@zhenge") > 0 then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "xinghan")
    end
  end,
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
  ["#zhenge-slash"] = "枕戈：你可以选择另一名角色，视为 %dest 对此角色使用【杀】",

  ["$zhenge1"] = "常备不懈，严阵以待。",
  ["$zhenge2"] = "枕戈待旦，日夜警惕。",
  ["$xinghan1"] = "汉之兴旺，不敢松懈。",
  ["$xinghan2"] = "兴汉除贼，吾之所愿。",
  ["~wanniangongzhu"] = "兴汉的使命，还没有完成。",
}

local tenggongzhu = General(extension, "tenggongzhu", "wu", 3, 3, General.Female)
local xingchong = fk.CreateTriggerSkill{
  name = "xingchong",
  anim_type = "drawcard",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xingchong-invoke:::"..tostring(player.maxHp))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp
    local choices = {}
    local i1 = 0
    if player:isKongcheng() then
      i1 = 1
    end
    for i = i1, n, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askForChoice(player, choices, self.name, "#xingchong-draw")
    if choice ~= "0" then
      player:drawCards(tonumber(choice), self.name)
    end
    if player:isKongcheng() then return end
    n = n - tonumber(choice)
    local cards = room:askForCard(player, 1, n, false, self.name, true, ".", "#xingchong-card:::"..tostring(n))
    if #cards > 0 then
      player:showCards(cards)
      if not player.dead then
        local mark = {}
        for _, id in ipairs(cards) do
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            table.insert(mark, id)
            room:setCardMark(Fk:getCardById(id), "@@xingchong-inhand", 1)
          end
        end
        room:setPlayerMark(player, "xingchong-round", mark)
      end
    end
  end,

  refresh_events = {fk.RoundEnd},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@xingchong-inhand", 0)
    end
  end,
}
local xingchong_delay = fk.CreateTriggerSkill{
  name = "#xingchong_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.dead or type(player:getMark("xingchong-round")) ~= "table" then return false end
    local mark = player:getMark("xingchong-round")
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("xingchong-round")
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.removeOne(mark, info.cardId) then
            x = x + 2
          end
        end
      end
    end
    room:setPlayerMark(player, "xingchong-round", #mark > 0 and mark or 0)
    if x > 0 then
      room:drawCards(player, x, xingchong.name)
    end
  end,
}
local liunian = fk.CreateTriggerSkill{
  name = "liunian",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark("liunian-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) == 1 then
      room:changeMaxHp(player, 1)
    else
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 10)
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) < 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, 1)
    player.room:setPlayerMark(player, "liunian-turn", 1)
  end,
}
xingchong:addRelatedSkill(xingchong_delay)
tenggongzhu:addSkill(xingchong)
tenggongzhu:addSkill(liunian)
Fk:loadTranslationTable{
  ["tenggongzhu"] = "滕公主",
  ["xingchong"] = "幸宠",
  [":xingchong"] = "每轮游戏开始时，你可以摸任意张牌并展示任意张牌（摸牌和展示牌的总数不能超过你的体力上限）。"..
  "若如此做，本轮内当你失去一张以此法展示的手牌后，你摸两张牌。",
  ["liunian"] = "流年",
  [":liunian"] = "锁定技，牌堆第一次洗牌的回合结束时，你加1点体力上限。牌堆第二次洗牌的回合结束时，你回复1点体力，然后本局游戏手牌上限+10。",
  ["#xingchong-invoke"] = "幸宠：你可以摸牌、展示牌合计至多%arg张，本轮失去展示的牌后摸两张牌",
  ["#xingchong-draw"] = "幸宠：选择摸牌数",
  ["#xingchong-card"] = "幸宠：展示至多%arg张牌，本轮失去一张展示牌后摸两张牌",
  ["@@xingchong-inhand"] = "幸宠",
  ["#xingchong_delay"] = "幸宠",

  ["$xingchong1"] = "佳人有荣幸，好女天自怜。",
  ["$xingchong2"] = "世间万般宠爱，独聚我于一身。",
  ["$liunian1"] = "佳期若梦，似水流年。",
  ["$liunian2"] = "逝者如流水，昼夜不将息。",
  ["~tenggongzhu"] = "已过江北，再无江南……",
}

local panghui = General(extension, "panghui", "wei", 5)
local yiyong = fk.CreateTriggerSkill{
  name = "yiyong",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.to and data.to ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#yiyong-invoke::"..data.to.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local n1, n2 = 0, 0
    for _, id in ipairs(self.cost_data) do
      n1 = n1 + Fk:getCardById(id).number
    end
    local cards = player.room:askForDiscard(data.to, 1, 999, true, self.name, false, ".",
      "#yiyong-discard:"..player.id.."::"..tostring(n1))
    for _, id in ipairs(cards) do
      n2 = n2 + Fk:getCardById(id).number
    end
    if n1 <= n2 and #cards > 0 then
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
  [":yiyong"] = "当你对其他角色造成伤害时，你可以弃置任意张牌，令该角色弃置任意张牌。若你弃置的牌的点数之和：不大于其，你摸X张牌"..
  "（X为该角色弃置的牌数）；不小于其，此伤害+1。",
  --"当你对其他角色造成伤害时，你可以与其同时弃置任意张牌，若你弃置的牌点数之和：不大于其，你摸X张牌（X为该角色弃置的牌数）；不小于其，此伤害+1。",
  ["#yiyong-invoke"] = "异勇：你可以弃置任意张牌，令 %dest 弃置任意张牌，根据双方弃牌点数之和执行效果",
  ["#yiyong-discard"] = "异勇：弃置任意张牌，若点数之和大于等于%arg则 %src 摸牌，若小于则伤害+1",

  ["$yiyong1"] = "关氏鼠辈，庞令明之子来邪！",
  ["$yiyong2"] = "凭一腔勇力，父仇定可报还。",
  ["~panghui"] = "大仇虽报，奈何心有余创。",
}

local ty__zhaotongzhaoguang = General(extension, "ty__zhaotongzhaoguang", "shu", 4)
local ty__yizan = fk.CreateViewAsSkill{
  name = "ty__yizan",
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, selected, selected_cards)
    return (Self:usedSkillTimes("ty__longyuan", Player.HistoryGame) > 0) and "#ty__yizan2" or "#ty__yizan1"
  end,
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and
        ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return Fk:getCardById(to_select).type == Card.TypeBasic
    elseif Self:usedSkillTimes("ty__longyuan", Player.HistoryGame) == 0 then
      return #selected == 1
    end
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    if Self:usedSkillTimes("ty__longyuan", Player.HistoryGame) > 0 then
      if #cards ~= 1 then return end
    else
      if #cards ~= 2 then return end
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
}
local qingren = fk.CreateTriggerSkill{
  name = "qingren",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and
      player.phase == Player.Finish and player:usedSkillTimes("ty__yizan", Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(player:usedSkillTimes("ty__yizan", Player.HistoryTurn), self.name)
  end,
}
ty__zhaotongzhaoguang:addSkill(qingren)
local ty__longyuan = fk.CreateTriggerSkill{
  name = "ty__longyuan",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and
      target.phase == Player.Finish and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("ty__yizan", Player.HistoryGame) > 2
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, self.name)
    if not player.dead and player:isWounded() then
      player.room:recover { num = 1, skillName = self.name, who = player, recoverBy = player}
    end
  end,
}
ty__zhaotongzhaoguang:addSkill(ty__yizan)
ty__zhaotongzhaoguang:addSkill(ty__longyuan)
Fk:loadTranslationTable{
  ["ty__zhaotongzhaoguang"] = "赵统赵广",
  ["ty__yizan"] = "翊赞",
  [":ty__yizan"] = "你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出。",
  ["qingren"] = "青刃",
  [":qingren"] = "结束阶段，你可以摸X张牌（X为你本回合发动“翊赞”的次数）。",
  ["ty__longyuan"] = "龙渊",
  [":ty__longyuan"] = "觉醒技，一名角色的结束阶段，若你本局游戏内发动过至少三次“翊赞”，你摸两张牌并回复1点体力，将“翊赞”中的“两张牌”修改为“一张牌”。",
  ["#ty__yizan1"] = "翊赞：你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出",
  ["#ty__yizan2"] = "翊赞：你可以将一张基本牌当任意基本牌使用或打出",

  ["$ty__yizan1"] = "承吾父之勇，翊军立阵。",
  ["$ty__yizan2"] = "继先帝之志，季兴大汉。",
  ["$qingren1"] = "此身忠义，可鉴天涯明月。",
  ["$qingren2"] = "青釭并龙胆，试刃三千里。",
  ["$ty__longyuan1"] = "金鳞岂是池中物，一遇风云便化龙。",
  ["$ty__longyuan2"] = "忍时待机，今日终于可以建功立业。",
  ["~ty__zhaotongzhaoguang"] = "守业死战，不愧初心。",
}

local yuantanyuanshangyuanxi = General(extension, "yuantanyuanshangyuanxi", "qun", 4)
local ty__neifa = fk.CreateTriggerSkill{
  name = "ty__neifa",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, self.name)
    local card = room:askForDiscard(player, 1, 1, true, self.name, false)
    if Fk:getCardById(card[1]).type == Card.TypeBasic then
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == Card.TypeTrick end)
      room:setPlayerMark(player, "@ty__neifa-turn", "basic")
      room:setPlayerMark(player, "ty__neifa-turn", math.min(#cards, 5))
    elseif  Fk:getCardById(card[1]).type == Card.TypeTrick  then
      
      room:setPlayerMark(player, "@ty__neifa-turn", "trick")   
    end
  end,
}
local ty__neifa_trigger = fk.CreateTriggerSkill{
  name = "#ty__neifa_trigger",
  anim_type = "control",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__neifa-turn") == "trick" and data.card:isCommonTrick() and data.firstTarget
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForAddTarget(player, room:getAlivePlayers(), 1, true, false,
      "#ty__neifa_trigger-choose:::"..data.card:toLogString(), self.name, data)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if table.contains(AimGroup:getAllTargets(data.tos), self.cost_data) then
      TargetGroup:removeTarget(data.targetGroup, self.cost_data)
    else
      TargetGroup:pushTargets(data.targetGroup, self.cost_data)
    end
  end,
}
local ty__neifa_targetmod = fk.CreateTargetModSkill{
  name = "#ty__neifa_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@ty__neifa-turn") == "basic" and scope == Player.HistoryPhase then
      return player:getMark("ty__neifa-turn")
    end
  end,
  extra_target_func = function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@ty__neifa-turn") == "basic" then
      return 1
    end
  end,
}
local ty__neifa_prohibit = fk.CreateProhibitSkill{
  name = "#ty__neifa_prohibit",
  prohibit_use = function(self, player, card)
    return (player:getMark("@ty__neifa-turn") == "basic" and card.type == Card.TypeTrick) or
      (player:getMark("@ty__neifa-turn") == "trick" and card.type == Card.TypeBasic)
  end,
}
ty__neifa:addRelatedSkill(ty__neifa_targetmod)
ty__neifa:addRelatedSkill(ty__neifa_prohibit)
ty__neifa:addRelatedSkill(ty__neifa_trigger)
yuantanyuanshangyuanxi:addSkill(ty__neifa)
Fk:loadTranslationTable{
  ["yuantanyuanshangyuanxi"] = "袁谭袁尚袁熙",
  ["ty__neifa"] = "内伐",
  [":ty__neifa"] = "出牌阶段开始时，你可以摸三张牌，然后弃置一张牌。若弃置的牌：是基本牌，你本回合不能使用锦囊牌，"..
  "本阶段使用【杀】次数上限+X，目标上限+1；是锦囊牌，你本回合不能使用基本牌，使用普通锦囊牌的目标+1或-1。"..
  "（X为发动技能时手牌中因本技能不能使用的牌且至多为5）。",
  ["@ty__neifa-turn"] = "内伐",
  ["#ty__neifa_trigger-choose"] = "内伐：你可以为%arg增加/减少一个目标",
  ["#neifa_trigger"] = "内伐",

  ["$ty__neifa1"] = "同室操戈，胜者王、败者寇。",
  ["$ty__neifa2"] = "兄弟无能，吾当继袁氏大统。",
  ["~yuantanyuanshangyuanxi"] = "同室内伐，贻笑大方……",
}

local yuechen = General(extension, "yuechen", "wei", 4)
local porui = fk.CreateTriggerSkill{
  name = "porui",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not player:isNude() and target ~= player and target.phase == Player.Finish and
    player:usedSkillTimes(self.name, Player.HistoryRound) < (player:getMark("gonghu1") == 0 and 1 or 2) then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      local end_id = turn_event.id
      return #U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from ~= nil and move.from ~= player.id and move.from ~= target.id and not room:getPlayerById(move.from).dead and
          (move.to ~= move.from or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
        return false
      end, end_id) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    local end_id = turn_event.id
    U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from ~= nil and move.from ~= player.id and move.from ~= target.id and
        (move.to ~= move.from or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          local p = room:getPlayerById(move.from)
          if not p.dead then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                if p:getMark("@porui_record") < 5 then
                  room:addPlayerMark(p, "@porui_record")
                end
              end
            end
          end
        end
      end
      return false
    end, end_id)
    local targets = table.filter(room.alive_players, function (p)
      return p:getMark("@porui_record") > 0
    end)
    if #targets == 0 then return false end
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(targets, Util.IdMapper), 1, 1, ".", "#porui-choose", self.name, true)
    if #tar > 0 and card then
      local to = room:getPlayerById(tar[1])
      self.cost_data = {tar[1], card, to:getMark("@porui_record")}
    end
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "@porui_record", 0)
    end
    return #tar > 0 and card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local cid = self.cost_data[2]
    local x = self.cost_data[3]
    room:throwCard(cid, self.name, player, player)
    for _ = 1, x+1, 1 do
      if player.dead or to.dead or not room:useVirtualCard("slash", nil, player, to, self.name, true) then break end
    end
    if not (player.dead or player:getMark("gonghu2") ~= 0 or player:isKongcheng() or to.dead) then
      local cards = player:getCardIds(Player.Hand)
      if #cards > x then
        cards = room:askForCard(player, x, x, false, self.name, false, ".", "#porui-give::" .. to.id .. ":" .. tostring(x))
      end
      room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
    end
  end,
}
local gonghu = fk.CreateTriggerSkill{
  name = "gonghu",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player.phase ~= Player.NotActive then return false end
    if event == fk.AfterCardsMove then
      if player:getMark("gonghu1") > 0 then return false end
      local x = 0
      for _, move in ipairs(data) do
        if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).type == Card.TypeBasic then
              x = x + 1
            end
          end
        end
      end
      if x == 1 then
        x = 0
        player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
              for _, info in ipairs(move.moveInfo) do
                if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                Fk:getCardById(info.cardId).type == Card.TypeBasic then
                  x = x + 1
                end
              end
            end
          end
        end, Player.HistoryTurn)
      end
      return x > 1
    else
      if player ~= target or player:getMark("gonghu2") > 0 then return false end
      if data.damage > 1 then return true end
      local x = 0
      player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local damage = e.data[5]
        if damage and (event == fk.Damage and damage.from or damage.to) == player then
          x = x + damage.damage
        end
      end, Player.HistoryTurn)
      return x > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:setPlayerMark(player, "gonghu1", 1)
      room:setPlayerMark(player, "@gonghu", player:getMark("gonghu2") > 0 and "gonghu_all" or "gonghu1")
    else
      room:setPlayerMark(player, "gonghu2", 1)
      room:setPlayerMark(player, "@gonghu", player:getMark("gonghu1") > 0 and "gonghu_all" or "gonghu2")
    end
  end,
}
local gonghu_delay = fk.CreateTriggerSkill{
  name = "#gonghu_delay",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("gonghu1") ~= 0 and player:getMark("gonghu2") ~=0 and data.card.color == Card.Red then
      if event == fk.CardUsing then
        return data.card.type == Card.TypeBasic
      else
        return data.card:isCommonTrick() and #U.getUseExtraTargets(player.room, data) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(gonghu.name)
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    else
      local targets = U.getUseExtraTargets(room, data)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#gonghu-choose:::"..data.card:toLogString(), gonghu.name, true)
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    end
  end,
}
gonghu:addRelatedSkill(gonghu_delay)
yuechen:addSkill(porui)
yuechen:addSkill(gonghu)
Fk:loadTranslationTable{
  ["yuechen"] = "乐綝",
  ["porui"] = "破锐",
  [":porui"] = "每轮限一次，其他角色的结束阶段，你可以弃置一张牌并选择本回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】，然后你"..
  "交给其X张手牌（X为其本回合失去的牌数且最多为5，不足则全交给）。",
  ["gonghu"] = "共护",
  [":gonghu"] = "锁定技，当你于回合外一回合失去超过一张基本牌后，〖破锐〗改为“每轮限两次”；当你于回合外一回合造成或受到伤害超过1点伤害后，"..
  "你删除〖破锐〗中交给牌的效果。若以上两个效果均已触发，则你本局游戏使用红色基本牌无法响应，使用红色普通锦囊牌可以额外指定一个目标。",

  ["#porui-choose"] = "发动 破锐，弃置一张牌并选择本回合失去过牌的角色",
  ["@porui_record"] = "失去牌数",
  ["#porui-give"] = "破锐：选择%arg张手牌，交给%dest",
  ["@gonghu"] = "共护",
  ["gonghu1"] = "限两次",
  ["gonghu2"] = "不用给牌",
  ["gonghu_all"] = "全部生效",
  ["#gonghu_delay"] = "共护",
  ["#gonghu-choose"] = "共护：可为此【%arg】额外指定一个目标",

  ["$porui1"] = "承父勇烈，问此间谁堪敌手。",
  ["$porui2"] = "敌锋虽锐，吾亦击之如破卵。",
  ["$gonghu1"] = "大都督中伏，吾等当舍命救之。",
  ["$gonghu2"] = "袍泽临难，但有共死而无坐视。",
  ["~yuechen"] = "天下犹魏，公休何故如此？",
}

--天下归心：阚泽 魏贾诩 陈登 蔡瑁张允 高览 尹夫人 吕旷吕翔 陈珪 陈矫 秦朗 董昭 唐咨
local jiaxu = General(extension, "ty__jiaxu", "wei", 3)
local ty__jianshu = fk.CreateActiveSkill{
  name = "ty__jianshu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target.id, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if not p:isKongcheng() and p ~= player then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__jianshu-choose::"..target.id, self.name, false)
    if #to == 0 then
      to = room:getPlayerById(table.random(targets))
    else
      to = room:getPlayerById(to[1])
    end
    local pindian = target:pindian({to}, self.name)
    if pindian.results[to.id].winner then
      local winner, loser
      if pindian.results[to.id].winner == target then
        winner = target
        loser = to
      else
        winner = to
        loser = target
      end
      if not winner:isNude() and not winner.dead then
        local id = table.random(winner:getCardIds{Player.Hand, Player.Equip})
        room:throwCard({id}, self.name, winner, winner)
      end
      if not loser.dead then
        room:loseHp(loser, 1, self.name)
      end
    else
      if not target.dead then
        room:loseHp(target, 1, self.name)
      end
      if not to.dead then
        room:loseHp(to, 1, self.name)
      end
    end
  end
}
local ty__jianshu_record = fk.CreateTriggerSkill{
  name = "#ty__jianshu_record",

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if player:usedSkillTimes("ty__jianshu", Player.HistoryPhase) > 0 then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.LoseHp)
      if e then
        return e.data[3] == "ty__jianshu"
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory("ty__jianshu", 0, Player.HistoryPhase)
  end,
}
local ty__yongdi = fk.CreateActiveSkill{
  name = "ty__yongdi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select).gender == General.Male
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if table.every(room.alive_players, function(p) return p.hp >= target.hp end) and target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if table.every(room.alive_players, function(p) return p.maxHp >= target.maxHp end) then
      room:changeMaxHp(target, 1)
    end
    if table.every(room.alive_players, function(p) return p:getHandcardNum() >= target:getHandcardNum() end) then
      target:drawCards(math.min(target.maxHp, 5), self.name)
    end
   end
}
ty__jianshu:addRelatedSkill(ty__jianshu_record)
jiaxu:addSkill("zhenlve")
jiaxu:addSkill(ty__jianshu)
jiaxu:addSkill(ty__yongdi)
Fk:loadTranslationTable{
  ["ty__jiaxu"] = "贾诩",
  ["ty__jianshu"] = "间书",
  [":ty__jianshu"] = "出牌阶段限一次，你可以将一张黑色手牌交给一名其他角色，然后选择另一名其他角色，令这两名角色拼点：赢的角色随机弃置一张牌，"..
  "没赢的角色失去1点体力。若有角色因此死亡，此技能视为未发动过。",
  ["ty__yongdi"] = "拥嫡",
  [":ty__yongdi"] = "限定技，出牌阶段，你可选择一名男性角色：若其体力值全场最少，其回复1点体力；体力上限全场最少，其加1点体力上限；"..
  "手牌数全场最少，其摸体力上限张牌（最多摸五张）。",
  ["#ty__jianshu-choose"] = "间书：选择另一名其他角色，令其和 %dest 拼点",

  ["$ty__jianshu1"] = "令其相疑，则一鼓可破也。",
  ["$ty__jianshu2"] = "貌合神离，正合用反间之计。",
  ["$ty__yongdi1"] = "废长立幼，实乃取祸之道也。",
  ["$ty__yongdi2"] = "长幼有序，不可紊乱。",
  ["~ty__jiaxu"] = "算无遗策，然终有疏漏……",
}

local chendeng = General(extension, "ty__chendeng", "qun", 3)
local wangzu = fk.CreateTriggerSkill{
  name = "wangzu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= player and not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local nums = {0, 0, 0}
    for _, p in ipairs(room.alive_players) do
      if p.role == "lord" or p.role == "loyalist" then
        nums[1] = nums[1] + 1
      elseif p.role == "rebel" then
        nums[2] = nums[2] + 1
      else
        nums[3] = nums[3] + 1
      end
    end
    local n = math.max(table.unpack(nums))
    if ((player.role == "lord" or player.role == "loyalist") and n == nums[1]) or
      (player.role == "rebel" and n == nums[2]) or (player.role == "renegade" and n == nums[3]) then
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#wangzu1-invoke", true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      local cards = table.filter(player:getCardIds("h"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
      if #cards == 0 then return end
      if room:askForSkillInvoke(player, self.name, nil, "#wangzu2-invoke") then
        self.cost_data = {table.random(cards)}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    data.damage = data.damage - 1
  end,
}
local yingshui = fk.CreateActiveSkill{
  name = "yingshui",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#yingshui",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))  --飞刀
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(Fk:getCardById(effect.cards[1]), Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if target.dead then return end
    if player.dead or #target:getCardIds("he") < 2 then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    else
      local cards = room:askForCard(target, 2, 999, true, self.name, true, ".|.|.|.|.|equip", "#yingshui-give:"..player.id)
      if #cards > 1 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, target.id)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
local fuyuan = fk.CreateTriggerSkill{
  name = "fuyuan",
  anim_type = "support",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.trueName == "slash" and not target.dead then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      return #U.getEventsByRule(room, GameEvent.UseCard, 1, function(e)
        if e.id <= room.logic:getCurrentEvent().id then
          local use = e.data[1]
          if use.card.color == Card.Red and use.tos and table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
            return true
          end
        end
      end, turn_event.id) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fuyuan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    target:drawCards(1, self.name)
  end,
}
chendeng:addSkill(wangzu)
chendeng:addSkill(yingshui)
chendeng:addSkill(fuyuan)
Fk:loadTranslationTable{
  ["ty__chendeng"] = "陈登",
  ["wangzu"] = "望族",
  [":wangzu"] = "每回合限一次，当你受到其他角色造成的伤害时，你可以随机弃置一张手牌令此伤害-1，若你所在的阵营存活人数全场最多，则改为选择一张手牌弃置。",
  ["yingshui"] = "营说",
  [":yingshui"] = "出牌阶段限一次，你可以交给你攻击范围内的一名其他角色一张牌，然后令其选择一项：1.你对其造成1点伤害；2.交给你至少两张装备牌。",
  ["fuyuan"] = "扶援",
  [":fuyuan"] = "当一名角色成为【杀】的目标后，若其本回合没有成为过红色牌的目标，你可令其摸一张牌。",
  ["#wangzu1-invoke"] = "望族：你可以弃置一张手牌，令此伤害-1",
  ["#wangzu2-invoke"] = "望族：你可以随机弃置一张手牌，令此伤害-1",
  ["#yingshui"] = "营说：交给一名角色一张牌，其选择交给你两张装备牌或你对其造成伤害",
  ["#yingshui-give"] = "营说：你需交给 %src 至少两张装备牌，否则其对你造成1点伤害",
  ["#fuyuan-invoke"] = "扶援：你可以令 %dest 摸一张牌",

  ["$wangzu1"] = "名门望族，显贵荣达。",
  ["$wangzu2"] = "能人辈出，仕宦显达。",
  ["$yingshui1"] = "道之以德，齐之以礼。",
  ["$yingshui2"] = "施恩行惠，赡之以义。",
  ["$fuyuan1"] = "今君困顿，扶援相助。",
  ["$fuyuan2"] = "恤君之患，以相扶援。",
  ["~ty__chendeng"] = "吾疾无人可治。",	
}

local caimaozhangyun = General(extension, "caimaozhangyun", "wei", 4)
local lianzhou = fk.CreateTriggerSkill{
  name = "lianzhou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.chained then
      player:setChainState(true)
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp == player.hp and not p.chained end), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 999, "#lianzhou-choose", self.name, true)
    if #tos > 0 then
      table.forEach(tos, function(p) room:getPlayerById(p):setChainState(true) end)
    end
  end,
}
local jinglan = fk.CreateTriggerSkill{
  name = "jinglan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > player.hp then
      room:askForDiscard(player, 4, 4, false, self.name, false)
    elseif player:getHandcardNum() == player.hp then
      room:askForDiscard(player, 1, 1, true, self.name, false)
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif player:getHandcardNum() < player.hp then
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      }
      if not player.dead then
        player:drawCards(5, self.name)
      end
    end
  end,
}
caimaozhangyun:addSkill(lianzhou)
caimaozhangyun:addSkill(jinglan)
Fk:loadTranslationTable{
  ["caimaozhangyun"] = "蔡瑁张允",
  ["lianzhou"] = "连舟",
  [":lianzhou"] = "锁定技，准备阶段，将你的武将牌横置，然后横置任意名体力值等于你的角色。",
  ["jinglan"] = "惊澜",
  [":jinglan"] = "锁定技，当你造成伤害后，若你的手牌数：大于体力值，你弃四张手牌；等于体力值，你弃一张牌并回复1点体力；"..
  "小于体力值，你受到1点火焰伤害并摸五张牌。",
  ["#lianzhou-choose"] = "连舟：你可以横置任意名体力值等于你的角色",

  ["$lianzhou1"] = "操练水军，以应东吴。",
  ["$lianzhou2"] = "连锁环舟，方能共济。",
  ["$jinglan1"] = "潮生潮落，风浪不息。",
  ["$jinglan2"] = "狂风舟起，巨浪滔天。",
  ["~caimaozhangyun"] = "丞相，冤枉，冤枉啊！",
}

local gaolan = General(extension, "ty__gaolan", "qun", 4)
local xizhen = fk.CreateTriggerSkill{
  name = "xizhen",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not (player:isProhibited(p, Fk:cloneCard("slash")) and player:isProhibited(p, Fk:cloneCard("duel"))) then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xizhen-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:setPlayerMark(player, "xizhen-phase", to.id)
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if not player:isProhibited(to, Fk:cloneCard(name)) then
        table.insert(choices, name)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#xizhen-choice::"..to.id)
    room:useVirtualCard(choice, nil, player, to, self.name, true)
  end,
}
local xizhen_trigger = fk.CreateTriggerSkill{
  name = "#xizhen_trigger",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("xizhen-phase") ~= 0 and data.responseToEvent and data.responseToEvent.from and
      data.responseToEvent.from == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("xizhen-phase"))
    if not to.dead then
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = "xizhen",
        }
        player:drawCards(1, "xizhen")
      else
        player:drawCards(2, "xizhen")
      end
    end
  end,
}
xizhen:addRelatedSkill(xizhen_trigger)
gaolan:addSkill(xizhen)
Fk:loadTranslationTable{
  ["ty__gaolan"] = "高览",
  ["xizhen"] = "袭阵",
  [":xizhen"] = "出牌阶段开始时，你可选择一名其他角色，视为对其使用【杀】或【决斗】，然后本阶段你的牌每次被使用或打出牌响应时，"..
  "该角色回复1点体力，你摸一张牌（若其未受伤，改为两张）。",
  ["#xizhen-choose"] = "袭阵：你可视为对一名角色使用【杀】或【决斗】；<br>本阶段你的牌被响应时其回复1点体力，你摸一张牌（若其未受伤则改为摸两张）",
  ["#xizhen-choice"] = "袭阵：选择视为对 %dest 使用的牌",

  ["$xizhen1"] = "今我为刀俎，尔等皆为鱼肉。",
  ["$xizhen2"] = "先发可制人，后发制于人。",
  ["~ty__gaolan"] = "郭公则害我！",
}

local yinfuren = General(extension, "yinfuren", "wei", 3, 3, General.Female)
local yingyu = fk.CreateTriggerSkill{
  name = "yingyu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (player.phase == Player.Play or (player.phase == Player.Finish and player:usedSkillTimes("yongbi", Player.HistoryGame) > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    if #targets < 2 then return end
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#yingyu-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target1 = room:getPlayerById(self.cost_data[1])
    local target2 = room:getPlayerById(self.cost_data[2])
    room:doIndicate(player.id, {self.cost_data[1]})
    local id1 = room:askForCardChosen(player, target1, "h", self.name)
    room:doIndicate(player.id, {self.cost_data[2]})
    local id2 = room:askForCardChosen(player, target2, "h", self.name)
    target1:showCards(id1)
    target2:showCards(id2)
    if Fk:getCardById(id1).suit ~= Fk:getCardById(id2).suit and
      Fk:getCardById(id1).suit ~= Card.NoSuit and Fk:getCardById(id1).suit ~= Card.NoSuit then
      local to = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#yingyu2-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(self.cost_data)
      end
      if to == target1.id then
        room:obtainCard(self.cost_data[1], id2, true, fk.ReasonPrey)
      else
        room:obtainCard(self.cost_data[2], id1, true, fk.ReasonPrey)
      end
    end
  end,
}
local yongbi = fk.CreateActiveSkill{
  name = "yongbi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).gender == General.Male
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    local suits = {}
    for _, id in ipairs(dummy.subcards) do
      if Fk:getCardById(id, true).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id, true).suit)
      end
    end
    if #suits > 1 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
      room:addPlayerMark(target, MarkEnum.AddMaxCards, 2)
    end
    if #suits > 2 then
      room:setPlayerMark(player, "@@yongbi", 1)
      room:setPlayerMark(target, "@@yongbi", 1)
    end
  end,
}
local yingyu_trigger = fk.CreateTriggerSkill{
  name = "#yingyu_trigger",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yongbi") > 0 and data.damage > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage - 1
  end,
}
yongbi:addRelatedSkill(yingyu_trigger)
yinfuren:addSkill(yingyu)
yinfuren:addSkill(yongbi)
Fk:loadTranslationTable{
  ["yinfuren"] = "尹夫人",
  ["yingyu"] = "媵予",
  [":yingyu"] = "准备阶段，你可以展示两名角色的各一张手牌，若花色不同，则你选择其中的一名角色获得另一名角色的展示牌。",
  ["yongbi"] = "拥嬖",
  [":yongbi"] = "限定技，出牌阶段，你可将所有手牌交给一名男性角色，然后〖媵予〗改为结束阶段也可以发动。根据其中牌的花色数量，"..
  "你与其永久获得以下效果：至少两种，手牌上限+2；至少三种，受到大于1点的伤害时伤害-1。",
  ["#yingyu-choose"] = "媵予：你可以展示两名角色各一张手牌，若花色不同，选择其中一名角色获得另一名角色的展示牌",
  ["#yingyu2-choose"] = "媵予：选择一名角色，其获得另一名角色的展示牌",
  ["@@yongbi"] = "拥嬖",
  ["#yingyu_trigger"] = "拥嬖",

  ["$yingyu1"] = "妾身蒲柳，幸蒙将军不弃。",
  ["$yingyu2"] = "妾之所有，愿尽予君。",
  ["$yongbi1"] = "海誓山盟，此生不渝。",
  ["$yongbi2"] = "万千宠爱，幸君怜之。",
  ["~yinfuren"] = "奈何遇君何其晚乎？",
}

local lvkuanglvxiang = General(extension, "ty__lvkuanglvxiang", "wei", 4)
local shuhe = fk.CreateActiveSkill{
  name = "shuhe",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(effect.cards)
    local card = Fk:getCardById(effect.cards[1])
    local yes = false
    for _, p in ipairs(room:getAlivePlayers()) do
      for _, id in ipairs(p:getCardIds{Player.Equip, Player.Judge}) do
        if Fk:getCardById(id).number == card.number then
          room:obtainCard(player, id, true, fk.ReasonPrey)
          yes = true
        end
      end
    end
    if not yes then
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#shuhe-choose:::"..card:toLogString(), self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:obtainCard(to, card, true, fk.ReasonGive)
      if player:getMark("@ty__liehou") < 5 then
        room:addPlayerMark(player, "@ty__liehou", 1)
      end
    end
  end,
}
local ty__liehou = fk.CreateTriggerSkill{
  name = "ty__liehou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards, fk.AfterDrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + 1 + player:getMark("@ty__liehou")
    else
      local room = player.room
      local n = 1 + player:getMark("@ty__liehou")
      if #room:askForDiscard(player, n, n, true, self.name, true, ".", "#ty__liehou-discard:::"..n) < n then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
lvkuanglvxiang:addSkill(shuhe)
lvkuanglvxiang:addSkill(ty__liehou)
Fk:loadTranslationTable{
  ["ty__lvkuanglvxiang"] = "吕旷吕翔",
  ["shuhe"] = "数合",
  [":shuhe"] = "出牌阶段限一次，你可以展示一张手牌，并获得场上与展示牌相同点数的牌。如果你没有因此获得牌，你需将展示牌交给一名其他角色，"..
  "然后〖列侯〗的额外摸牌数+1（至多为5）。",
  ["ty__liehou"] = "列侯",
  [":ty__liehou"] = "锁定技，摸牌阶段，你额外摸一张牌，然后选择一项：1.弃置等量的牌；2.失去1点体力。",
  ["#shuhe-choose"] = "数合：选择一名其他角色，将%arg交给其",
  ["@ty__liehou"] = "列侯",
  ["#ty__liehou-discard"] = "列侯：你需弃置%arg张牌，否则失去1点体力",

  ["$shuhe1"] = "齐心共举，万事俱成。",
  ["$shuhe2"] = "手足协力，天下可往。",
  ["$ty__liehou1"] = "论功行赏，加官进侯。",
  ["$ty__liehou2"] = "增班列侯，赏赐无量！",
  ["~ty__lvkuanglvxiang"] = "不避其死，以成其忠……",
}

local chengui = General(extension, "chengui", "qun", 3)
local yingtu = fk.CreateTriggerSkill{
  name = "yingtu",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 then
      for _, move in ipairs(data) do
        if move.to ~= nil and move.toArea == Card.PlayerHand then
          local p = player.room:getPlayerById(move.to)
          if p.phase ~= Player.Draw and (p:getNextAlive() == player or player:getNextAlive() == p) and not p:isNude() then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if move.to ~= nil and move.toArea == Card.PlayerHand then
        local p = player.room:getPlayerById(move.to)
        if p.phase ~= Player.Draw and (p:getNextAlive() == player or player:getNextAlive() == p) and not p:isNude() then
          table.insertIfNeed(targets, move.to)
        end
      end
    end
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#yingtu-invoke::"..targets[1]) then
        self.cost_data = targets[1]
        return true
      end
    elseif #targets > 1 then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#yingtu-invoke-multi", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(self.cost_data)
    local lastplayer = (player:getNextAlive() == from)
    local card = room:askForCardChosen(player, from, "he", self.name)
    room:obtainCard(player.id, card, false, fk.ReasonPrey)
    local to = player:getNextAlive()
    if lastplayer then
      to = table.find(room.alive_players, function (p)
        return p:getNextAlive() == player
      end)
    end
    if to == nil or to == player then return false end
    local id = room:askForCard(player, 1, 1, true, self.name, false, ".", "#yingtu-choose::"..to.id)[1]
    room:obtainCard(to, id, false, fk.ReasonGive)
    local to_use = Fk:getCardById(id)
    if to_use.type == Card.TypeEquip and not to.dead and room:getCardOwner(id) == to and room:getCardArea(id) == Card.PlayerHand and
      U.canUseCardTo(room, to, to, to_use) then
      room:useCard({
        from = to.id,
        tos = {{to.id}},
        card = to_use,
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
    return not target.dead and player:hasSkill(self) and data.card.type == Card.TypeEquip and table.every(player.room.alive_players, function(p)
      return #target.player_cards[Player.Equip] >= #p.player_cards[Player.Equip]
    end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
chengui:addSkill(yingtu)
chengui:addSkill(congshi)
Fk:loadTranslationTable{
  ["chengui"] = "陈珪",
  ["yingtu"] = "营图",
  [":yingtu"] = "每回合限一次，当一名角色于其摸牌阶段外获得牌后，若其是你的上家或下家，你可以获得该角色的一张牌，然后交给你的下家或上家一张牌。若以此法给出的牌为装备牌，获得牌的角色使用之。",
  ["congshi"] = "从势",
  [":congshi"] = "锁定技，当一名角色使用一张装备牌结算结束后，若其装备区里的牌数为全场最多的，你摸一张牌。",
  ["#yingtu-invoke"] = "营图：你可以获得 %dest 的一张牌",
  ["#yingtu-invoke-multi"] = "营图：你可以获得上家或下家的一张牌",
  ["#yingtu-choose"] = "营图：选择一张牌交给 %dest，若为装备牌则其使用之",

  ["$yingtu1"] = "不过略施小计，聊戏莽夫耳。",
  ["$yingtu2"] = "栖虎狼之侧，安能不图存身？",
  ["$congshi1"] = "阁下奉天子以令诸侯，珪自当相从。",
  ["$congshi2"] = "将军率六师以伐不臣，珪何敢相抗？",
  ["~chengui"] = "终日戏虎，竟为虎所噬。",
}

local chenjiao = General(extension, "chenjiao", "wei", 3)
local xieshou = fk.CreateTriggerSkill{
  name = "xieshou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:distanceTo(target) <= 2 and player:getMaxCards() > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xieshou-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    local choices = {"xieshou_draw"}
    if target:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askForChoice(target, choices, self.name, "#xieshou-choice:"..player.id)
    if choice == "recover" then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      if not target.faceup then
        target:turnOver()
      end
      if target.chained then
        target:setChainState(false)
      end
      target:drawCards(2, self.name)
    end
  end,
}
local qingyan = fk.CreateTriggerSkill{
  name = "qingyan",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and data.card.color == Card.Black and data.from ~= player.id and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    if player:getHandcardNum() < math.min(player.hp, player.maxHp) then
      if player.room:askForSkillInvoke(player, self.name, nil, "#qingyan-invoke") then
        self.cost_data = {"draw"}
        return true
      end
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#qingyan-card", true)
      if #card > 0 then
        self.cost_data = {"discard", card}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] == "discard" then
      room:throwCard(self.cost_data[2], self.name, player, player)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    end
  end,
}
local qizi = fk.CreateTriggerSkill{
  name = "qizi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:distanceTo(target) > 2
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local qizi_prohibit = fk.CreateProhibitSkill{
  name = "#qizi_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    if player:hasSkill("qizi") and card.name == "peach" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and player:distanceTo(p) > 2 end)
    end
  end,
}
qizi:addRelatedSkill(qizi_prohibit)
chenjiao:addSkill(xieshou)
chenjiao:addSkill(qingyan)
chenjiao:addSkill(qizi)
Fk:loadTranslationTable{
  ["chenjiao"] = "陈矫",
  ["xieshou"] = "协守",
  [":xieshou"] = "每回合限一次，一名角色受到伤害后，若你与其距离不大于2，你可以令你的手牌上限-1，然后其选择一项：1.回复1点体力；2.复原武将牌并摸两张牌。",
  ["qingyan"] = "清严",
  [":qingyan"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后，若你的手牌数：小于体力值，你可将手牌摸至体力上限；"..
  "不小于体力值，你可以弃置一张手牌令手牌上限+1。",
  ["qizi"] = "弃子",
  [":qizi"] = "锁定技，其他角色处于濒死状态时，若你与其距离大于2，你不能对其使用【桃】。",
  ["#xieshou-invoke"] = "协守：你可以手牌上限-1，令 %dest 选择回复体力，或复原武将牌并摸牌",
  ["xieshou_draw"] = "复原武将牌并摸两张牌",
  ["#xieshou-choice"] = "协守：选择 %src 令你执行的一项",
  ["#qingyan-invoke"] = "清严：你可以将手牌摸至体力上限",
  ["#qingyan-card"] = "清严：你可以弃置一张手牌令手牌上限+1",

  ["$xieshou1"] = "此城所能守者，在你我之协力。",
  ["$xieshou2"] = "据地利而拥人和，其天时在我。",
  ["$qingyan1"] = "清风盈大袖，严韵久长存。",
  ["$qingyan2"] = "至清之人无徒，唯余雁阵惊寒。",
  ["~chenjiao"] = "矫既死，则魏再无直臣哉……",
}

local qinlang = General(extension, "qinlang", "wei", 4)
local haochong = fk.CreateTriggerSkill{
  name = "haochong",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getHandcardNum() ~= player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player:getMaxCards()
    if n > 0 then
      local cards = player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#haochong-discard:::"..tostring(n), true)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      if player.room:askForSkillInvoke(player, self.name, nil, "#haochong-draw:::"..player:getMaxCards()) then
        self.cost_data = {}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:throwCard(self.cost_data, self.name, player, player)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      room:broadcastProperty(player, "MaxCards")
    else
      local n = player:getMaxCards() - player:getHandcardNum()
      player:drawCards(math.min(n, 5), self.name)
      if player:getMaxCards() > 0 then  --不允许减为负数
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
        room:broadcastProperty(player, "MaxCards")
      end
    end
  end,
}
local jinjin = fk.CreateTriggerSkill{
  name = "jinjin",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMaxCards() ~= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jinjin-invoke::"..data.from.id..":"..player:getMaxCards())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(player:getMaxCards() - player.hp)
    room:setPlayerMark(player, MarkEnum.AddMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 0)
    room:broadcastProperty(player, "MaxCards")
    if data.from and not data.from.dead then
      local x = #room:askForDiscard(data.from, 1, n, true, self.name, false, ".", "#jinjin-discard:"..player.id.."::"..n)
      if x < n then
        player:drawCards(n - x, self.name)
      end
    end
  end,
}
qinlang:addSkill(haochong)
qinlang:addSkill(jinjin)
Fk:loadTranslationTable{
  ["qinlang"] = "秦朗",
  ["haochong"] = "昊宠",
  [":haochong"] = "当你使用一张牌后，你可以将手牌调整至手牌上限（最多摸五张），然后若你以此法：获得牌，你的手牌上限-1；失去牌，你的手牌上限+1。",
  ["jinjin"] = "矜谨",
  [":jinjin"] = "每回合限一次，当你造成或受到伤害后，你可以将你的手牌上限重置为当前体力值。"..
  "若如此做，伤害来源可以弃置至多X张牌（X为你因此变化的手牌上限数且至少为1），然后其每少弃置一张，你便摸一张牌。",
  ["#haochong-discard"] = "昊宠：你可以将手牌弃至手牌上限（弃置%arg张），然后手牌上限+1",
  ["#haochong-draw"] = "昊宠：你可以将手牌摸至手牌上限（当前手牌上限%arg，最多摸五张），然后手牌上限-1",
  ["#jinjin-invoke"] = "矜谨：你可将手牌上限（当前为%arg）重置为体力值，令 %dest 弃至多等量的牌",
  ["#jinjin-discard"] = "矜谨：弃置1~%arg张牌，每少弃置一张 %src 便摸一张牌",

  ["$haochong1"] = "朗螟蛉之子，幸隆曹氏厚恩。",
  ["$haochong2"] = "幸得义父所重，必效死奉曹。",
  ["$jinjin1"] = "螟蛉终非麒麟，不可气盛自矜。",
  ["$jinjin2"] = "我姓非曹，可敬人，不可欺人。",
  ["~qinlang"] = "二姓之人，死无其所……",
}

local dongzhao = General(extension, "ty__dongzhao", "wei", 3)
local yijia = fk.CreateTriggerSkill{
  name = "yijia",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:distanceTo(target) <= 1 and
      table.find(player.room:getOtherPlayers(target), function(p)
        return table.find(p:getCardIds("e"), function(id)
          return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
        end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(target), function(p)
      return table.find(p:getCardIds("e"), function(id)
        return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
      end)
    end), Util.IdMapper)
    while room:askForSkillInvoke(player, self.name, nil, "#yijia-invoke::"..target.id) do
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#yijia-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = table.filter(to:getCardIds("e"), function(id)
      return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
    end)
    local id = room:askForCardsChosen(player, target, 1, 1, {card_data = {{to.general, cards}}}, self.name, "#yijia-move::"..target.id)[1]
    local orig = table.filter(room.alive_players, function(p) return p:inMyAttackRange(target) end)
    U.moveCardIntoEquip(room, target, id, self.name, true, player)
    if player.dead or #orig == 0 then return end
    if table.find(orig, function(p) return not p:inMyAttackRange(target) end) then
      player:drawCards(1, self.name)
    end
  end,
}
local dingji = fk.CreateTriggerSkill{
  name = "dingji",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(player.room.alive_players, Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#dingji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = to:getHandcardNum() - 5
    if n <= 0 then
      to:drawCards(-n, self.name)
    else
      room:askForDiscard(to, n, n, false, self.name, false, ".", "#dingji-discard:::"..n)
    end
    if to.dead then return end
    to:showCards(to:getCardIds("h"))
    if to.dead or to:isKongcheng() then return end
    if table.every(player:getCardIds("h"), function(id)
      return not table.find(player:getCardIds("h"), function(id2)
        return id ~= id2 and Fk:getCardById(id).trueName == Fk:getCardById(id2).trueName
      end)
    end) then
      if not table.find(player:getCardIds("h"), function(id)
        local card = Fk:getCardById(id)
        return (card.type == Card.TypeBasic or card:isCommonTrick()) and to:canUse(card)
      end) then return end
      local success, dat = room:askForUseActiveSkill(to, "dingji_viewas", "#dingji-use", true)
      if success then
        local card = Fk.skills["dingji_viewas"]:viewAs(dat.cards)
        card.skillName = self.name
        room:useCard{
          from = target.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      end
    end
  end,
}
local dingji_viewas = fk.CreateViewAsSkill{
  name = "dingji_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Self:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) and Self:canUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "dingji"
    return card
  end,
}
Fk:addSkill(dingji_viewas)
dongzhao:addSkill(yijia)
dongzhao:addSkill(dingji)
Fk:loadTranslationTable{
  ["ty__dongzhao"] = "董昭",
  ["yijia"] = "移驾",
  [":yijia"] = "你距离1以内的角色受到伤害后，你可以将场上一张装备牌移动至其装备区（替换原装备），若其因此脱离了一名角色的攻击范围，你摸一张牌。",
  ["dingji"] = "定基",
  [":dingji"] = "准备阶段，你可以令一名角色将手牌数调整至五，然后其展示所有手牌，若牌名均不同，其可以视为使用其中一张基本牌或普通锦囊牌。",
  ["#yijia-invoke"] = "移驾：你可以将场上一张装备移至 %dest 的装备区（替换原装备）",
  ["#yijia-choose"] = "移驾：选择被移动装备的角色",
  ["#yijia-move"] = "移驾：选择移动给 %dest 的装备",
  ["#dingji-choose"] = "定基：你可以令一名角色将手牌数调整至五",
  ["#dingji-discard"] = "定基：请弃置%arg张手牌，若剩余牌牌名均不同，你可视为使用其中一张",
  ["dingji_viewas"] = "定基",
  ["#dingji-use"] = "定基：你可以视为使用手牌中一张基本牌或普通锦囊牌",

  ["$yijia1"] = "曹侯忠心可鉴，可暂居其檐下。",
  ["$yijia2"] = "今东都糜败，陛下当移驾许昌。",
  ["$dingji1"] = "丞相宜进爵国公，以彰殊勋。",
  ["$dingji2"] = "今公与诸将并侯，岂天下所望哉！",
  ["~ty__dongzhao"] = "凡有天下者，无虚伪不真之人……",
}

local tangzi = General(extension, "ty__tangzi", "wei", 4)
tangzi.subkingdom = "wu"
local ty__xingzhao = fk.CreateTriggerSkill{
  name = "ty__xingzhao",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.HpChanged, fk.MaxHpChanged, fk.CardUsing, fk.EventPhaseChanging, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local n = #table.filter(player.room.alive_players, function(p) return p:isWounded() end)
      if event == fk.HpChanged or event == fk.MaxHpChanged then
        return (player:hasSkill("xunxun", true) and n == 0) or (not player:hasSkill("xunxun", true) and n > 0)
      elseif event == fk.CardUsing then
        return target == player and data.card.type == Card.TypeEquip and n > 1
      elseif event == fk.EventPhaseChanging then
        return target == player and (data.to == Player.Judge or data.to == Player.Discard) and n > 2
      elseif event == fk.DamageCaused then
        return target == player and data.card and not data.chain and (n == 0 or n > 3)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.HpChanged or event == fk.MaxHpChanged then
      if player:hasSkill("xunxun", true) then
        room:handleAddLoseSkills(player, "-xunxun", self.name, true, false)
      else
        room:handleAddLoseSkills(player, "xunxun", self.name, true, false)
      end
    elseif event == fk.CardUsing then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    elseif event == fk.EventPhaseChanging then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    elseif event == fk.DamageCaused then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    end
  end,
}
tangzi:addSkill(ty__xingzhao)
tangzi:addRelatedSkill("xunxun")
Fk:loadTranslationTable{
  ["ty__tangzi"] = "唐咨",
  ["ty__xingzhao"] = "兴棹",
  [":ty__xingzhao"] = "锁定技，场上受伤的角色为1个或以上，你拥有技能〖恂恂〗；2个或以上，你使用装备牌时摸一张牌；"..
  "3个或以上，你跳过判定和弃牌阶段；0个、4个或以上，你使用牌对目标角色造成的伤害+1。",

  ["$ty__xingzhao1"] = "野棹出浅滩，借风当显威。",
  ["$ty__xingzhao2"] = "御棹水中行，前路皆助力。",
  ["$xunxun_ty__tangzi1"] = "兵者凶器也，将者儒夫也，文可掌兵。",
  ["$xunxun_ty__tangzi2"] = "良禽择木而栖，亦如君子不居于危墙。",
  ["~ty__tangzi"] = "水载船，亦可覆……",
}

--绕庭之鸦：黄皓 孙资刘放 岑昏 孙綝 贾充
local huanghao = General(extension, "ty__huanghao", "shu", 3)
local ty__qinqing = fk.CreateTriggerSkill{
  name = "ty__qinqing",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Finish and player:hasSkill(self) then
      local lord = table.filter(player.room.players, function(p) return p.seat == 1 end)[1]
      return lord and not lord.dead and table.find(player.room.alive_players, function(p) return p:inMyAttackRange(lord) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local lord = table.filter(player.room.players, function(p) return p.seat == 1 end)[1]
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:inMyAttackRange(lord) and not p:isNude() end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__qinqing-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cid = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({cid}, self.name, to, player)
    local lord = table.filter(player.room.players, function(p) return p.seat == 1 end)[1]
    if player.dead or to.dead or lord.dead then return end
    if to:getHandcardNum() > lord:getHandcardNum() then
      player:drawCards(1, self.name)
    end
  end,
}
local cunwei = fk.CreateTriggerSkill{
  name = "cunwei",
  mute =true,
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.type == Card.TypeTrick then
      return U.isOnlyTarget(player, data, fk.TargetConfirmed) or not player:isNude()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if U.isOnlyTarget(player, data, fk.TargetConfirmed) then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    else
      room:notifySkillInvoked(player, self.name, "negative")
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
huanghao:addSkill(ty__qinqing)
huanghao:addSkill("huisheng")
huanghao:addSkill(cunwei)
Fk:loadTranslationTable{
  ["ty__huanghao"] = "黄皓",
  ["ty__qinqing"] = "寝情",
  [":ty__qinqing"] = "结束阶段，你可以弃置攻击范围内含有一号位的一名其他角色的一张牌，然后若其手牌数比一号位多，你摸一张牌。",
  ["cunwei"] = "存畏",
  [":cunwei"] = "锁定技，当你成为锦囊牌的目标后，若你：是此牌唯一目标，你摸一张牌；不是此牌唯一目标，你弃置一张牌。",
  ["#ty__qinqing-choose"] = "寝情：弃置一名角色一张牌，然后若其手牌数多于一号位，你摸一张牌",

  ["$ty__qinqing1"] = "陛下今日不理朝政，退下吧！",
  ["$ty__qinqing2"] = "此事咱家自会传达陛下。",
  ["$huisheng_ty__huanghao1"] = "不就是想要好处嘛？",
  ["$huisheng_ty__huanghao2"] = "这些都拿去。",
  ["$cunwei1"] = "陛下专宠，诸侯畏惧。",
  ["$cunwei2"] = "君侧之人，众所畏惧。",
  ["~ty__huanghao"] = "难道都是我一个人的错吗！",
}

local sunziliufang = General(extension, "ty__sunziliufang", "wei", 3)
local qinshen = fk.CreateTriggerSkill{
  name = "qinshen",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("qinshen_"..suit.."-turn") == 0 then
        self.cost_data = self.cost_data + 1
      end
    end
    return self.cost_data > 0 and player.room:askForSkillInvoke(player, self.name, nil, "#qinshen-invoke:::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase < Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          player.room:addPlayerMark(player, "qinshen_"..Fk:getCardById(info.cardId):getSuitString().."-turn", 1)
        end
      end
    end
  end,
}
local weidang_active = fk.CreateActiveSkill{
  name = "#weidang_active",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      local n = 0
      for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
        if Self:getMark("weidang_"..suit.."-turn") == 0 then
          n = n + 1
        end
      end
      return #Fk:translate(Fk:getCardById(to_select).trueName) / 3 == n
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      drawPilePosition = -1,
    })
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if #Fk:translate(card.trueName) == #Fk:translate(Fk:getCardById(effect.cards[1]).trueName) then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    local id = table.random(cards)
    local card = Fk:getCardById(id)
    room:moveCards({
      ids = {id},
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
    if player:canUse(card) then
      local use = room:askForUseCard(player, "weidang", ".|.|.|.|.|.|"..id, "#weidang-use:::"..card:toLogString(), false)
      if use then
        room:useCard(use)
      end
    end
  end,
}
local weidang = fk.CreateTriggerSkill{
  name = "weidang",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("weidang_"..suit.."-turn") == 0 then
        n = n + 1
      end
    end
    if n > 0 then
      player.room:askForUseActiveSkill(player, "#weidang_active", "#weidang-invoke:::"..n, true)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and player.room.current
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          player.room:addPlayerMark(player, "weidang_"..Fk:getCardById(info.cardId):getSuitString().."-turn", 1)
        end
      end
    end
  end,
}
sunziliufang:addSkill(qinshen)
sunziliufang:addSkill(weidang)
Fk:addSkill(weidang_active)
Fk:loadTranslationTable{
  ["ty__sunziliufang"] = "孙资刘放",
  ["qinshen"] = "勤慎",
  [":qinshen"] = "弃牌阶段结束时，你可摸X张牌（X为本回合没有进入过弃牌堆的花色数量）。",
  ["weidang"] = "伪谠",
  [":weidang"] = "其他角色的结束阶段，你可以将一张字数为X的牌置于牌堆底，然后获得牌堆中一张字数为X的牌（X为本回合没有进入过弃牌堆的花色数量），能使用则使用之。",
  ["#qinshen-invoke"] = "勤慎：你可以摸%arg张牌",
  ["#weidang_active"] = "伪谠",
  ["#weidang-invoke"] = "伪谠：你可以将一张牌名字数为%arg的牌置于牌堆底，然后从牌堆获得一张字数相同的牌并使用之",
  ["#weidang-use"] = "伪谠：请使用%arg",

  ["$qinshen1"] = "怀藏拙之心，赚不名之利。",
  ["$qinshen2"] = "勤可补拙，慎可避祸。",
  ["$weidang1"] = "臣等忠耿之言，绝无藏私之意。",
  ["$weidang2"] = "假谠言之术，行利己之实。",
  ["~ty__sunziliufang"] = "臣一心为国朝，冤枉呀……",
}

local cenhun = General(extension, "ty__cenhun", "wu", 4)
cenhun:addSkill("jishe")
cenhun:addSkill("lianhuo")
Fk:loadTranslationTable{
  ["ty__cenhun"] = "岑昏",
}

local sunchen = General(extension, "sunchen", "wu", 4)
local zigu = fk.CreateActiveSkill{
  name = "zigu",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  prompt = "#zigu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local targets = table.map(table.filter(room.alive_players, function(p)
      return #p:getCardIds("e") > 0 end), function (p) return p.id end)
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zigu-choose", self.name, false)
      to = room:getPlayerById(to[1])
      local id = room:askForCardChosen(player, to, "e", self.name, "#zigu-prey::"..to.id)
      room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      if not player.dead and to == player then
        player:drawCards(1, self.name)
      end
    else
      player:drawCards(1, self.name)
    end
  end,
}
local zuowei = fk.CreateTriggerSkill{
  name = "zuowei",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase ~= Player.NotActive then
      local n = player:getHandcardNum() - math.max(#player:getCardIds("e"), 1)
      if n > 0 then
        return data.card.trueName == "slash" or data.card:isCommonTrick()
      elseif n == 0 then
        return true
      elseif n < 0 then
        return player:getMark("zuowei-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getHandcardNum() - math.max(#player:getCardIds("e"), 1)
    if n > 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#zuowei-invoke:::"..data.card:toLogString())
    elseif n == 0 then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1,
        "#zuowei-damage", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    elseif n < 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#zuowei-draw")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local n = player:getHandcardNum() - math.max(#player:getCardIds("e"), 1)
    if n > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      data.disresponsive = true
    elseif n == 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:damage{
        from = player,
        to = room:getPlayerById(self.cost_data),
        damage = 1,
        skillName = self.name,
      }
    elseif n < 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:setPlayerMark(player, "zuowei-turn", 1)
      player:drawCards(2, self.name)
    end
  end,
}
sunchen:addSkill(zigu)
sunchen:addSkill(zuowei)
Fk:loadTranslationTable{
  ["sunchen"] = "孙綝",
  ["zigu"] = "自固",
  [":zigu"] = "出牌阶段限一次，你可以弃置一张牌，然后获得场上一张装备牌。若你没有因此获得其他角色的牌，你摸一张牌。",
  ["zuowei"] = "作威",
  [":zuowei"] = "当你于回合内使用牌时，若你当前手牌数：大于X，你可以令此牌不可响应；等于X，你可以对一名其他角色造成1点伤害；小于X，"..
  "你可以摸两张牌并令本回合此选项失效（X为你装备区内的牌数且至少为1）。",
  ["#zigu"] = "自固：你可以弃置一张牌，然后获得场上一张装备牌",
  ["#zigu-choose"] = "自固：选择一名角色，获得其场上一张装备牌",
  ["#zigu-prey"] = "自固：获得 %dest 场上一张装备牌",
  ["#zuowei-invoke"] = "作威：你可以令此%arg不可响应",
  ["#zuowei-damage"] = "作威：你可以对一名其他角色造成1点伤害",
  ["#zuowei-draw"] = "作威：你可以摸两张牌，然后本回合此项无效",

  ["$zigu1"] = "卿有成材良木，可妆吾家江山。",
  ["$zigu2"] = "吾好锦衣玉食，卿家可愿割爱否？",
  ["$zuowei1"] = "不顺我意者，当填在野之壑。",
  ["$zuowei2"] = "吾令不从者，当膏霜锋之锷。",
  ["~sunchen"] = "臣家火起，请离席救之……",
}

local jiachong = General(extension, "ty__jiachong", "wei", 3)
jiachong.subkingdom = "jin"
local ty__beini = fk.CreateActiveSkill{
  name = "ty__beini",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#ty__beini",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player:getHandcardNum() - player.maxHp
    if n > 0 then
      room:askForDiscard(player, n, n, false, self.name, false)
    else
      player:drawCards(-n, self.name)
    end
    if player.dead then return end
    local success, dat = room:askForUseActiveSkill(player, "ty__beini_active", "#ty__beini-choose", false)
    if success then
      local target1 = room:getPlayerById(dat.targets[1])
      local target2 = room:getPlayerById(dat.targets[2])
      room:doIndicate(player.id, {target1.id})
      room:setPlayerMark(target1, "@@ty__beini-turn", 1)
      room:setPlayerMark(target2, "@@ty__beini-turn", 1)
      room:addPlayerMark(target1, MarkEnum.UncompulsoryInvalidity .. "-turn")
      room:addPlayerMark(target2, MarkEnum.UncompulsoryInvalidity .. "-turn")
      room:useVirtualCard("slash", nil, target1, target2, self.name, true)
    end
  end,
}
local ty__beini_active = fk.CreateActiveSkill{
  name = "ty__beini_active",
  mute = true,
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return not target:prohibitUse(Fk:cloneCard("slash"))
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(selected[1])
      return target1:inMyAttackRange(target) and not target1:isProhibited(target, Fk:cloneCard("slash"))
    else
      return false
    end
  end,
}
local shizong = fk.CreateViewAsSkill{
  name = "shizong",
  pattern = ".|.|.|.|.|basic",
  prompt = "#shizong",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and
        ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@shizong_fail-turn") == 0 and
      #player:getCardIds("he") > player:usedSkillTimes(self.name, Player.HistoryTurn)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("@@shizong_fail-turn") == 0 and
      #player:getCardIds("he") > player:usedSkillTimes(self.name, Player.HistoryTurn)
  end,
}
local shizong_trigger = fk.CreateTriggerSkill{
  name = "#shizong_trigger",
  events = {fk.PreCardUse},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "shizong")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, TargetGroup:getRealTargets(data.tos))
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "shizong_active",
      "#shizong-give:::"..player:usedSkillTimes("shizong", Player.HistoryTurn), false)
    if success then
      local to = room:getPlayerById(dat.targets[1])
      if to.phase == Player.NotActive then
        room:setPlayerMark(player, "@@shizong_fail-turn", 1)
      end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(dat.cards)
      room:obtainCard(to.id, dummy, false, fk.ReasonGive)
      if to.dead or to:isNude() then return true end
      local card = room:askForCard(to, 1, 1, true, "shizong", true, ".", "#shizong-put:"..player.id.."::"..data.card.name)
      if #card > 0 then
        room:moveCards({
          ids = card,
          from = to.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = "shizong",
          drawPilePosition = -1,
        })
        return false
      end
    end
    return true
  end,
}
local shizong_active = fk.CreateActiveSkill{
  name = "shizong_active",
  mute = true,
  card_num = function()
    return Self:usedSkillTimes("shizong", Player.HistoryTurn)
  end,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected < Self:usedSkillTimes("shizong", Player.HistoryTurn)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
}
Fk:addSkill(ty__beini_active)
Fk:addSkill(shizong_active)
shizong:addRelatedSkill(shizong_trigger)
jiachong:addSkill(ty__beini)
jiachong:addSkill(shizong)
Fk:loadTranslationTable{
  ["ty__jiachong"] = "贾充",
  ["ty__beini"] = "悖逆",
  [":ty__beini"] = "出牌阶段限一次，你可以将手牌数调整至体力上限，然后令一名角色视为对另一名角色使用一张【杀】；这两名角色的非锁定技本回合失效。",
  ["shizong"] = "恃纵",
  [":shizong"] = "当你需要使用一张基本牌时，你可交给一名其他角色X张牌（X为此技能本回合发动次数），然后其可将一张牌置于牌堆底，视为你使用之。"..
  "若其不为当前回合角色，此技能本回合失效。",
  ["#ty__beini"] = "悖逆：你可以将手牌调整至体力上限，然后视为一名角色对另一名角色使用【杀】",
  ["ty__beini_active"] = "悖逆",
  ["#ty__beini-choose"] = "悖逆：选择两名角色，视为前者对后者使用【杀】，这些角色本回合非锁定技失效",
  ["@@ty__beini-turn"] = "悖逆",
  ["#shizong"] = "恃纵：你可以视为使用一张基本牌",
  ["#shizong-give"] = "恃纵：交给一名其他角色%arg张牌",
  ["shizong_active"] = "恃纵",
  ["#shizong-put"] = "恃纵：你可以将一张牌置于牌堆底，视为 %src 使用【%arg】",
  ["@@shizong_fail-turn"] = "恃纵失效",

  ["$ty__beini1"] = "臣等忠心耿耿，陛下何故谋反？",
  ["$ty__beini2"] = "公等养汝，正拟今日，复何疑？",
  ["$shizong1"] = "成济、王经已死，独我安享富贵。",
  ["$shizong2"] = "吾乃司马公心腹，顺我者生！",
  ["~ty__jiachong"] = "诸公勿怪，充乃奉命行事……",
}

--代汉涂高：马日磾 张勋 纪灵 雷薄 桥蕤 董绾
local ty__mamidi = General(extension, "ty__mamidi", "qun", 4, 6)
local bingjie = fk.CreateTriggerSkill{
  name = "bingjie",
  events = { fk.EventPhaseStart , fk.TargetSpecified},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and target == player) then return false end
    if event == fk.EventPhaseStart then
      return player.phase == Player.Play
    else
      return player:getMark("@@bingjie-turn") > 0 and (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.firstTarget and data.tos and table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(player, "@@bingjie-turn")
      room:changeMaxHp(player, -1)
    elseif event == fk.TargetSpecified then
      for _, pid in ipairs(AimGroup:getAllTargets(data.tos)) do
        local to = room:getPlayerById(pid)
        if not to.dead and not to:isNude() and to ~= player then
          local throw = room:askForDiscard(to, 1, 1, true, self.name, false, ".", "#bingjie-discard:::"..data.card:getColorString()..":"..data.card:toLogString())
          if #throw > 0 and Fk:getCardById(throw[1]).color == data.card.color then
            data.disresponsiveList = data.disresponsiveList or {}
            table.insertIfNeed(data.disresponsiveList, to.id)
          end
        end
      end
    end
  end,
}
ty__mamidi:addSkill(bingjie)
local zhengding = fk.CreateTriggerSkill{
  name = "zhengding",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player and player.phase == Player.NotActive and data.responseToEvent then
      if (event == fk.CardUsing and data.toCard and data.toCard.color == data.card.color) or
        (event == fk.CardResponding and data.responseToEvent.card and data.responseToEvent.card.color == data.card.color) then
        return data.responseToEvent.from ~= player.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead then
      room:recover({ who = player,  num = 1, skillName = self.name })
    end
  end,
}
ty__mamidi:addSkill(zhengding)
Fk:loadTranslationTable{
  ["ty__mamidi"] = "马日磾",
  ["bingjie"] = "秉节",
  [":bingjie"] = "出牌阶段开始时，你可以减1点体力上限，然后当你本回合使用【杀】或普通锦囊牌指定目标后，除你以外的目标角色各弃置一张牌，"..
  "若弃置的牌与你使用的牌颜色相同，其无法响应此牌。",
  ["@@bingjie-turn"] = "秉节",
  ["#bingjie-discard"] = "秉节：请弃置一张牌，若你弃置了%arg牌，无法响应%arg2",
  ["zhengding"] = "正订",
  [":zhengding"] = "锁定技，你的回合外，当你使用或打出牌响应其他角色使用的牌时，若你使用或打出的牌与其使用的牌颜色相同，你增加1点体力上限，回复1点体力。",
  ["$bingjie1"] = "秉节传旌，心存丹衷。",
  ["$bingjie2"] = "秉节刚劲，奸佞务尽。",
  ["$zhengding1"] = "行义修正，改故用新。",
  ["$zhengding2"] = "义约谬误，有所正订。",
  ["~ty__mamidi"] = "失节屈辱忧恚！",
}

local zhangxun = General(extension, "zhangxun", "qun", 4)
local suizheng = fk.CreateTriggerSkill{
  name = "suizheng",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return target:getMark("@@suizheng-turn") > 0 and target.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt
    if player.phase == Player.Finish then
      targets = table.map(room:getAlivePlayers(), Util.IdMapper)
      prompt = "#suizheng-choose"
    else
      room:setPlayerMark(player, "@@suizheng-turn", 1)
      targets = table.filter(player.tag[self.name], function(id) return not room:getPlayerById(id).dead end)
      player.tag[self.name] = {}
      if #targets == 0 then return end
      prompt = "#suizheng-slash"
    end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if player.phase == Player.Finish then
      room:setPlayerMark(to, "@@suizheng", 1)
    else
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:getMark("@@suizheng") > 0 and player.phase == Player.Play
    else
      return player:hasSkill(self.name, true) and data.from and target:getMark("@@suizheng-turn") > 0 and data.to ~= player and not data.to.dead
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:setPlayerMark(player, "@@suizheng", 0)
      room:setPlayerMark(player, "@@suizheng-turn", 1)
    else
      player.tag[self.name] = player.tag[self.name] or {}
      table.insert(player.tag[self.name], data.to.id)
    end
  end,
}
local suizheng_targetmod = fk.CreateTargetModSkill{
  name = "#suizheng_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 then
      return 999
    end
  end,
}
suizheng:addRelatedSkill(suizheng_targetmod)
zhangxun:addSkill(suizheng)
Fk:loadTranslationTable{
  ["zhangxun"] = "张勋",
  ["suizheng"] = "随征",
  [":suizheng"] = "结束阶段，你可以选择一名角色，该角色下个回合的出牌阶段使用【杀】无距离限制且可以多使用一张【杀】。"..
  "然后其出牌阶段结束时，你可以视为对其本阶段造成过伤害的一名其他角色使用一张【杀】。",
  ["@@suizheng"] = "随征",
  ["@@suizheng-turn"] = "随征",
  ["#suizheng-choose"] = "随征：令一名角色下回合出牌阶段使用【杀】无距离限制且次数+1",
  ["#suizheng-slash"] = "随征：你可以视为对其中一名角色使用【杀】",

  ["$suizheng1"] = "屡屡随征，战皆告捷。",
  ["$suizheng2"] = "将勇兵强，大举出征！",
  ["~zhangxun"] = "此役，死伤甚重……",
}

local ty__jiling = General(extension, "ty__jiling", "qun", 4)
local ty__shuangren = fk.CreateTriggerSkill{
  name = "ty__shuangren",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng() and table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty__shuangren-ask", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({to}, self.name)
    if pindian.results[to.id].winner == player then
      local slash = Fk:cloneCard("slash")
      if player.dead or player:prohibitUse(slash) then return false end
      local targets = table.filter(room:getOtherPlayers(player), function(p) return p.kingdom == to.kingdom and not player:isProhibited(p, slash) end)
      if #targets == 0 then return false end
      room:setPlayerMark(player, "ty__shuangren_kingdom", to.kingdom)
      room:setPlayerMark(player, "ty__shuangren_target", to.id)
      local success, dat = room:askForUseActiveSkill(player, "#ty__shuangren_active", "#ty__shuangren_slash-ask:" .. to.id, false)
      local tos = success and table.map(dat.targets, Util.Id2PlayerMapper) or table.random(targets, 1)
      room:useVirtualCard("slash", nil, player, tos, self.name, true)
    else
      room:addPlayerMark(player, "@@ty__shuangren_prohibit-phase")
    end
  end,
}
local ty__shuangren_active = fk.CreateActiveSkill{
  name = "#ty__shuangren_active",
  card_num = 0,
  card_filter = Util.FalseFunc,
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected < 2 then
      local to = Fk:currentRoom():getPlayerById(to_select)
      return to.kingdom == Self:getMark("ty__shuangren_kingdom")
    end
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards == 0 and #selected > 0 and #selected <= 2 then
      return #selected == 1 or table.contains(selected, Self:getMark("ty__shuangren_target"))
    end
  end,
}
local ty__shuangren_prohibit = fk.CreateProhibitSkill{
  name = "#ty__shuangren_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty__shuangren_prohibit-phase") > 0 and card.trueName == "slash"
  end,
}
ty__shuangren:addRelatedSkill(ty__shuangren_prohibit)
ty__shuangren:addRelatedSkill(ty__shuangren_active)
ty__jiling:addSkill(ty__shuangren)
Fk:loadTranslationTable{
  ["ty__jiling"] = "纪灵",
  ["ty__shuangren"] = "双刃",
  [":ty__shuangren"] = "出牌阶段开始时，你可以与一名角色拼点。若你赢，你选择与其势力相同的一至两名角色（若选择两名，其中一名须为该角色），然后你视为对选择的角色使用一张不计入次数的【杀】；若你没赢，你本阶段不能使用【杀】。",
  ["#ty__shuangren_active"] = "双刃",
  ["#ty__shuangren_prohibit"] = "双刃",
  ["@@ty__shuangren_prohibit-phase"] = "双刃禁杀",

  ["#ty__shuangren-ask"] = "双刃：你可与一名角色拼点",
  ["#ty__shuangren_slash-ask"] = "双刃：视为对与 %src 势力相同的一至两名角色使用【杀】(若选两名，其中一名须为%src)",

  ["$ty__shuangren1"] = "这淮阴城下，正是葬汝尸骨的好地界。",
  ["$ty__shuangren2"] = "吾众下大军已至，匹夫，以何敌我？",
  ["~ty__jiling"] = "穷寇兵枪势猛，伏义实在不敌啊。",
}

local leibo = General(extension, "leibo", "qun", 4)
local silve = fk.CreateTriggerSkill{
  name = "silve",
  mute = true,
  events = {fk.GameStart, fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif target and player:getMark(self.name) == target.id and not player.dead then
        if event == fk.Damage then
          return not data.to.dead and not data.to:isNude() and player:getMark("silve_preyed"..data.to.id.."-turn") == 0
        else
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      local room = player.room
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#silve-choose", self.name)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    elseif event == fk.Damage then
      return player.room:askForSkillInvoke(player, self.name, nil, "#silve-prey::"..data.to.id)
    elseif event == fk.Damaged then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "special")
      room:setPlayerMark(player, self.name, self.cost_data)
      room:setPlayerMark(player, "@silve", room:getPlayerById(self.cost_data).general)
    elseif event == fk.Damage then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:doIndicate(player.id, {data.to.id})
      room:setPlayerMark(player, "silve_preyed"..data.to.id.."-turn", 1)
      local id = room:askForCardChosen(player, data.to, "he", self.name, "#silve-card::"..data.to.id)
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    elseif event == fk.Damaged then
      if (not data.from or data.from.dead) and not player:isKongcheng() then
        room:notifySkillInvoked(player, self.name, "negative")
        room:askForDiscard(player, 1, 1, false, self.name, false)
      else
        local use = room:askForUseCard(player, self.name, "slash", "#silve-slash::"..data.from.id, true,
          {must_targets = {data.from.id}, bypass_distances = true, bypass_times = true})
        if use then
          room:notifySkillInvoked(player, self.name, "offensive")
          room:useCard(use)
        elseif not player:isKongcheng() then
          room:notifySkillInvoked(player, self.name, "negative")
          room:askForDiscard(player, 1, 1, false, self.name, false)
        end
      end
    end
  end,
}
local shuaijie = fk.CreateActiveSkill{
  name = "shuaijie",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = "#shuaijie",
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:getMark("silve") ~= 0 then
      local to = Fk:currentRoom():getPlayerById(player:getMark("silve"))
      return to.dead or (player.hp > to.hp and #player:getCardIds("e") > #to:getCardIds("e"))
    end
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local to = room:getPlayerById(player:getMark("silve"))
    local choices = {"shuaijie2"}
    if not to.dead and not to:isNude() then
      table.insert(choices, 1, "shuaijie1::"..to.id)
    end
    local choice = room:askForChoice(player, choices, self.name)
    local dummy = Fk:cloneCard("dilu")
    if choice[9] == "1" then
      room:doIndicate(player.id, {to.id})
      local cards = room:askForCardsChosen(player, to, 1, 3, "he", self.name)
      dummy:addSubcards(cards)
    else
      local types = {"basic", "trick", "equip"}
      while #types > 0 do
        local pattern = table.random(types)
        table.removeOne(types, pattern)
        dummy:addSubcards(room:getCardsFromPileByRule(".|.|.|.|.|"..pattern))
      end
    end
    if #dummy.subcards > 0 then
      room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    end
    if not player.dead then
      room:setPlayerMark(player, "silve", player.id)
      room:setPlayerMark(player, "@silve", player.general)
    end
  end,
}
leibo:addSkill(silve)
leibo:addSkill(shuaijie)
Fk:loadTranslationTable{
  ["leibo"] = "雷薄",
  ["silve"] = "私掠",
  [":silve"] = "游戏开始时，你选择一名其他角色为“私掠”角色。<br>“私掠”角色造成伤害后，你可以获得受伤角色一张牌（每回合每名角色限一次）。<br>"..
  "“私掠”角色受到伤害后，你需对伤害来源使用一张【杀】（无距离限制），否则你弃置一张手牌。",
  ["shuaijie"] = "衰劫",
  [":shuaijie"] = "限定技，出牌阶段，若你体力值与装备区里的牌均大于“私掠”角色或“私掠”角色已死亡，你可以减1点体力上限，然后选择一项：<br>"..
  "1.获得“私掠”角色至多3张牌；2.从牌堆获得三张类型不同的牌。然后“私掠”角色改为你。",
  ["#silve-choose"] = "私掠：选择一名其他角色，作为“私掠”角色",
  ["@silve"] = "私掠",
  ["#silve-prey"] = "私掠：是否获得 %dest 的一张牌？",
  ["#silve-card"] = "私掠：获得 %dest 的一张牌",
  ["#silve-slash"] = "私掠：你需对 %dest 使用一张【杀】，否则弃置一张手牌",
  ["#shuaijie"] = "衰劫：你可以减1点体力上限，“私掠”角色改为你！",
  ["shuaijie1"] = "获得%dest至多三张牌",
  ["shuaijie2"] = "从牌堆获得三张类型不同的牌",

  ["$silve1"] = "劫尔之富，济我之贫！",
  ["$silve2"] = "徇私而动，劫财掠货。",
  ["$shuaijie1"] = "弱肉强食，实乃天地至理。",
  ["$shuaijie2"] = "恃强凌弱，方为我辈本色！",
  ["~leibo"] = "此人不可力敌，速退！",
}

local qiaorui = General(extension, "ty__qiaorui", "qun", 4)
local aishou = fk.CreateTriggerSkill{
  name = "aishou",
  mute = true,
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart and target == player then
        if player.phase == Player.Finish then
          return true
        elseif player.phase == Player.Start then
          return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end)
        end
      elseif event == fk.AfterCardsMove and player.phase == Player.NotActive and
        not table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end) then
        for _, move in ipairs(data) do
          if move.from == player.id then
            if move.extra_data and move.extra_data.aishou then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      return player.room:askForSkillInvoke(player, self.name)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseStart then
      if player.phase == Player.Finish then
        room:notifySkillInvoked(player, self.name, "drawcard")
        local cards = player:drawCards(player.maxHp, self.name)
        for _, id in ipairs(cards) do
          if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
            room:setCardMark(Fk:getCardById(id), "@@aishou-inhand", 1)
          end
        end
      else
        room:notifySkillInvoked(player, self.name, "special")
        local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end)
        room:throwCard(cards, self.name, player, player)
        if not player.dead and #cards > player.hp then
          room:changeMaxHp(player, 1)
        end
      end
    else
      room:notifySkillInvoked(player, self.name, "negative")
      room:changeMaxHp(player, -1)
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.NotActive
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@aishou-inhand") > 0 then
            move.extra_data = move.extra_data or {}
            move.extra_data.aishou = true
            break
          end
        end
      end
    end
  end,
}
local saowei = fk.CreateTriggerSkill{
  name = "saowei",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and data.card.trueName == "slash" and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end) and
      table.find(TargetGroup:getRealTargets(data.tos), function(id)
        local p = player.room:getPlayerById(id)
        return id ~= player.id and not p.dead and player:inMyAttackRange(p) and not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id)
      local p = room:getPlayerById(id)
      return id ~= player.id and not p.dead and player:inMyAttackRange(p) and not player:isProhibited(p, Fk:cloneCard("slash"))
    end)
    local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end)
    local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, 1,
      ".|.|.|.|.|.|"..table.concat(ids, ","), "#saowei-use", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos, id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("slash")
    card:addSubcard(self.cost_data[2])
    card.skillName = self.name
    local use = {
      from = player.id,
      tos = {self.cost_data[1]},
      card = card,
      extraUse = true,
    }
    use.card.skillName = self.name
    room:useCard(use)
    if use.damageDealt and not player.dead and room:getCardArea(use.card) == Card.DiscardPile then
      room:obtainCard(player.id, use.card, true, fk.ReasonJustMove)
    end
  end,
}
qiaorui:addSkill(aishou)
qiaorui:addSkill(saowei)
Fk:loadTranslationTable{
  ["ty__qiaorui"] = "桥蕤",
  ["aishou"] = "隘守",
  [":aishou"] = "结束阶段，你可以摸X张牌（X为你的体力上限），这些牌标记为“隘”。当你于回合外失去最后一张“隘”后，你减1点体力上限。<br>"..
  "准备阶段，弃置你手牌中的所有“隘”，若弃置的“隘”数大于你的体力值，你加1点体力上限。",
  ["saowei"] = "扫围",
  [":saowei"] = "当其他角色使用【杀】结算后，若目标角色不为你且目标角色在你的攻击范围内，你可以将一张“隘”当【杀】对该目标角色使用。"..
  "若此【杀】造成伤害，你获得之。",
  ["@@aishou-inhand"] = "隘",
  ["#saowei-use"] = "扫围：你可以将一张“隘”当【杀】对目标角色使用",

  ["$aishou1"] = "某家未闻有一合而破关之将。",
  ["$aishou2"] = "凭关而守，敌强又奈何？",
  ["$saowei1"] = "今从王师猎虎，必擒吕布。",
  ["$saowei2"] = "七军围猎，虓虎插翅难逃。",
  ["~ty__qiaorui"] = "今兵败城破，唯死而已。",
}

local dongwan = General(extension, "dongwan", "qun", 3, 3, General.Female)
local shengdu = fk.CreateTriggerSkill{
  name = "shengdu",
  anim_type = "drawcard",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local p = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p ~= player and p:getMark("@@shengdu") == 0
    end), Util.IdMapper), 1, 1, "#shengdu-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player.room:getPlayerById(self.cost_data), "@@shengdu", player.id)
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@shengdu") == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shengdu", 0)
  end,
}
local shengdu_delay = fk.CreateTriggerSkill{
  name = "#shengdu_delay",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local to = player.room.current
    if to == nil or to.phase ~= Player.Draw or to:getMark("@@shengdu") ~= player.id then return false end
    for _, move in ipairs(data) do
      if move.to == to.id and move.moveReason == fk.ReasonDraw then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("shengdu")
    local room = player.room
    local x = 0
    local to = room.current
    room:setPlayerMark(to, "@@shengdu", 0)
    for _, move in ipairs(data) do
      if move.to == to.id and move.moveReason == fk.ReasonDraw then
        x = x + #move.moveInfo
      end
    end
    if x > 0 then
      player:drawCards(x, "shengdu")
    end
  end,
}
local jieling = fk.CreateActiveSkill{
  name = "jieling",
  anim_type = "offensive",
  prompt = "#jieling-active",
  card_num = 2,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        if Fk:getCardById(to_select).color ~= Fk:getCardById(selected[1]).color then
          local slash = Fk:cloneCard("slash")
          slash.skillName = self.name
          slash:addSubcard(selected[1])
          slash:addSubcard(to_select)
          return not Self:prohibitUse(slash)
        end
      else
        return false
      end
    end
  end,
  target_filter = function(self, to_select, selected, cards)
    if to_select == Self.id then return false end
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    slash:addSubcards(cards)
    return #selected < slash.skill:getMaxTargetNum(Self, slash) and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), slash)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local use = {
      from = player.id,
      tos = table.map(effect.tos, function (id)
        return {id}
      end),
      card = Fk:cloneCard("slash"),
      extra_data = {jielingUser = player.id},
    }
    use.card:addSubcards(effect.cards)
    use.card.skillName = self.name
    room:useCard(use)
  end,
}
local jieling_delay = fk.CreateTriggerSkill{
  name = "#jieling_delay",
  events = {fk.CardUseFinished},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.extra_data and data.extra_data.jielingUser == player.id then
      local room = player.room
      local targets = TargetGroup:getRealTargets(data.tos)
      for _, pid in ipairs(targets) do
        if not room:getPlayerById(pid).dead then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("jieling")
    local targets = TargetGroup:getRealTargets(data.tos)
    targets = table.filter(targets, function (pid)
      return not room:getPlayerById(pid).dead
    end)
    room:doIndicate(player.id, targets)
    for _, id in ipairs(targets) do
      local to = room:getPlayerById(id)
      if not to.dead then
        if data.damageDealt and data.damageDealt[id] then
          room:loseHp(to, 1, "jieling")
        elseif not player.dead and to:getMark("@@shengdu") == 0 then
          room:setPlayerMark(to, "@@shengdu", player.id)
        end
      end
    end
  end,
}
shengdu:addRelatedSkill(shengdu_delay)
jieling:addRelatedSkill(jieling_delay)
dongwan:addSkill(shengdu)
dongwan:addSkill(jieling)
Fk:loadTranslationTable{
  ["dongwan"] = "董绾",
  ["shengdu"] = "生妒",
  [":shengdu"] = "回合开始时，你可以选择一名其他角色，该角色下个摸牌阶段摸牌后，你摸等量的牌。",
  ["jieling"] = "介绫",
  [":jieling"] = "出牌阶段限一次，你可以将两张颜色不同的手牌当无距离和次数限制的【杀】使用。"..
  "若此【杀】：造成伤害，则目标角色失去1点体力；没造成伤害，则你对目标角色发动一次〖生妒〗。",
  ["#shengdu-choose"] = "生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌",
  ["@@shengdu"] = "生妒",
  ["#shengdu_delay"] = "生妒",
  ["#jieling-active"] = "发动 介绫，将两张颜色不同的手牌当【杀】使用（无距离和次数限制）",
  ["#jieling_delay"] = "介绫",

  ["$shengdu1"] = "姐姐有的，妹妹也要有。",
  ["$shengdu2"] = "你我同为佳丽，凭甚汝得独宠？",
  ["$jieling1"] = "来人，送冯氏上路！",
  ["$jieling2"] = "我有一求，请姐姐赴之。",
  ["~dongwan"] = "陛下饶命，妾并无歹意……",
}

return extension
