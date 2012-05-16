local table = require("hp/lang/table")
local class = require("hp/lang/class")
local NinePatch = require("hp/display/NinePatch")
local TextLabel = require("hp/display/TextLabel")
local Event = require("hp/event/Event")
local Widget = require("hp/widget/Widget")
local WidgetManager = require("hp/manager/WidgetManager")

----------------------------------------------------------------
-- ボタンウィジットクラスです.<br>
-- @class table
-- @name Button
----------------------------------------------------------------
local M = class(Widget)

local super = Widget

----------------------------------------------------------------
-- インスタンスを生成して返します.
----------------------------------------------------------------
function M:init(params)
    super.init(self, params)
    
    params = params or self:getDefaultTheme()
    assert(params.upSkin)
    assert(params.downSkin)
    
    self.upSkin = params.upSkin
    self.upColor = params.upColor or {red = 1, green = 1, blue = 1, alpha = 1}
    self.downSkin = params.downSkin
    self.downColor = params.downColor or {red = 1, green = 1, blue = 1, alpha = 1}
    
    self.background = NinePatch:new({texture = self.upSkin, width = params.width, height = params.height})
    self.background:setLeft(0)
    self.background:setTop(0)
    
    self.textLabel = TextLabel:new({text = params.text, textSize = params.fontSize})
    self.textLabel:setSize(self.background:getWidth(), self.textLabel:getTextSize())
    self.textLabel:setLeft(0)
    self.textLabel:setTop(self.background:getHeight() - self.textLabel:getHeight() - self.textLabel:getHeight() / 2 - 2)
    self.textLabel:setAlignment(MOAITextBox.CENTER_JUSTIFY)
    
    self:addChild(self.background)
    self:addChild(self.textLabel)
    
    self:setSize(self.background:getWidth(), self.background:getHeight())

    self.buttonDownEvent = Event:new(Event.BUTTON_DOWN)
    self.buttonUpEvent = Event:new(Event.BUTTON_UP)
    self.clickEvent = Event:new(Event.CLICK)
    self.cancelEvent = Event:new(Event.CANCEL)
    self.buttonDownFlag = false
    self.buttonTouching = false
    self:setToggle(params.toggle or false)
    
    self:addEventListener("resize", self.onResizeButton, self)
    
    self:setButtonUpState()
end

--------------------------------------------------------------------------------
-- サイズ変更時に子の大きさも変更します.
--------------------------------------------------------------------------------
function M:getDefaultTheme()
    return WidgetManager:getDefaultTheme()["Button"]
end

--------------------------------------------------------------------------------
-- ボタンの押下前の状態を設定します.
--------------------------------------------------------------------------------
function M:setButtonUpState()
    if not self.buttonDownFlag then
        return
    end
    
    local color = self.upColor
    self.buttonDownFlag = false
    self.background:setTexture(self.upSkin)
    self:setColor(color.red, color.green, color.blue, color.alpha)
    self:dispatchEvent(self.buttonUpEvent)
end

--------------------------------------------------------------------------------
-- ボタンの押下後の状態を設定します.
--------------------------------------------------------------------------------
function M:setButtonDownState()
    if self.buttonDownFlag then
        return
    end
    
    local color = self.downColor
    self.buttonDownFlag = true
    self.background:setTexture(self.downSkin)
    self:setColor(color.red, color.green, color.blue, color.alpha)

    self:dispatchEvent(self.buttonDownEvent)
end

--------------------------------------------------------------------------------
-- テキストを設定します.
--------------------------------------------------------------------------------
function M:setText(text)
    self.textLabel:setString(text)
end

--------------------------------------------------------------------------------
-- テキストの色を設定します.
--------------------------------------------------------------------------------
function M:setTextColor(r, g, b, a)
    self.textLabel:setColor(r, g, b, a)
end

--------------------------------------------------------------------------------
-- テキストサイズを設定します.
--------------------------------------------------------------------------------
function M:setTextSize(points, dpi)
    self.textLabel:setTextSize(points, dpi)
end

--------------------------------------------------------------------------------
-- トグルボタンかどうか設定します.
--------------------------------------------------------------------------------
function M:setToggle(value)
    self:setPrivate("toggle", value)
end

--------------------------------------------------------------------------------
-- トグルボタンかどうか返します.
--------------------------------------------------------------------------------
function M:isToggle()
    return self:getPrivate("toggle")
end

--------------------------------------------------------------------------------
-- サイズ変更時に子の大きさも変更します.
--------------------------------------------------------------------------------
function M:onResizeButton(e)
    self.background:setSize(e.newWidth, e.newHeight)
    self.textLabel:setSize(e.newWidth, e.newHeight)
end

--------------------------------------------------------------------------------
-- タッチした時のイベントリスナです.
--------------------------------------------------------------------------------
function M:onTouchDown(e)
    if not self:isEnabled() then
        return
    end
    
    local wx, wy = self.layer:wndToWorld(e.x, e.y, 0)
    if self:isHit(wx, wy, 0, self.background) then
        self.buttonTouching = true
        if self:isToggle() and self.buttonDownFlag then
            self:setButtonUpState()
        else
            self:setButtonDownState()
        end
    end
    
end

--------------------------------------------------------------------------------
-- タッチした時のイベントリスナです.
--------------------------------------------------------------------------------
function M:onTouchUp(e)
    if not self:isEnabled() then
        return
    end

    if self.buttonTouching and not self:isToggle() then
        self.buttonTouching = false
        self:setButtonUpState()
        self:dispatchEvent(self.clickEvent)
    end
end

--------------------------------------------------------------------------------
-- タッチした時のイベントリスナです.
--------------------------------------------------------------------------------
function M:onTouchMove(e)
    if not self:isEnabled() then
        return
    end

    local wx, wy = self.layer:wndToWorld(e.x, e.y, 0)
    if self.buttonTouching and not self:isHit(wx, wy, 0, self.background) then
        self.buttonTouching = false
        if not self:isToggle() then
            self:setButtonUpState()
            self:dispatchEvent(self.cancelEvent)
        end
    end
end

--------------------------------------------------------------------------------
-- タッチした時のイベントリスナです.
--------------------------------------------------------------------------------
function M:onTouchCancel(e)
    if not self:isEnabled() then
        return
    end

    if not self:isToggle() then
        self.buttonTouching = false
        self:setButtonUpState()
        self:dispatchEvent(self.cancelEvent)
    end
end

return M