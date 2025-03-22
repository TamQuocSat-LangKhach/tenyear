local qiaomeng = fk.CreateSkill {
  name = "ty_ex__qiaomeng",
}

Fk:loadTranslationTable{
  ["ty_ex__qiaomeng"] = "趫猛",
  [":ty_ex__qiaomeng"] = "当你使用黑色牌指定目标后，你可以弃置其中一名其他角色的一张牌，若此牌为：锦囊牌，此牌不能被响应；装备牌，改为你获得之。",

  ["#ty_ex__qiaomeng-choose"] = "趫猛：弃置一名角色的一张牌，若为锦囊则不可响应，若为装备你获得之",

  ["$ty_ex__qiaomeng1"] = "猛士骁锐，可慑百蛮失蹄！",
  ["$ty_ex__qiaomeng2"] = "锐士志猛，可凭白手夺马！",
}

qiaomeng:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiaomeng.name) and
      data.card.color == Card.Black and data.firstTarget and
      table.find(data.use.tos, function(p)
        return p ~= player and not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.use.tos, function(p)
      return p ~= player and not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ty_ex__qiaomeng-choose",
      skill_name = qiaomeng.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = qiaomeng.name,
    })
    local card = Fk:getCardById(id, true)
    if card.type == Card.TypeEquip then
      room:obtainCard(player, id, false, fk.ReasonPrey, player, qiaomeng.name)
    else
      room:throwCard(id, qiaomeng.name, to, player)
      if card.type == Card.TypeTrick then
        data.use.disresponsiveList = table.simpleClone(room.players)
      end
    end
  end,
})

return qiaomeng
