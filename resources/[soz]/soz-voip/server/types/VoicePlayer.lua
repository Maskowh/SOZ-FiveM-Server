---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Pablo1610.
--- DateTime: 23/01/2022 20:20
---

---@class VoicePlayer
---@field public _src number
---@field public callChannel number
---@field public radioAlphaChannel number
---@field public radioBetaChannel number
VoicePlayer = {}

---new
---@return VoicePlayer
---@public
function VoicePlayer:new(_src)
    local object = {}
    setmetatable(object, self)
    self.__index = self
    self._src = _src
    self.callChannel = nil
    self.radioAlphaChannel = nil
    self.radioBetaChannel = nil
    return self
end