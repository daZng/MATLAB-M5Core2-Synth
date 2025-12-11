classdef Button < handle %handle makes the class a pass reference type
    %BUTTON GRAPHICS AND BOUND CHECK

    properties (Access = private)
        m5u;

        pressed;%One Time Event Trigger
        released;%One Time Event Trigger

        pressUpdatedOnCurrentPress; %need a way to check if pressed has already been triggered otherwise it keeps getting set to true
        releaseUpdatedOnCurrentRelease;

        onColor;
        offColor;
        outlineColor;

        xSize;
        ySize;

        disabled;
        disabledColor;

        holdTic;
        longPressed;%One Time Event Trigger
        ticUpdatedOnCurrentPress;
        minHoldTime;
    end
    properties (Access = public)
        beingPressed;

        xBounds;
        yBounds;

        checkForHold;
    end

    methods
        %Constructor
        function obj = Button(m5u, xBounds, yBounds, onColor, offColor, outlineColor)
            obj.m5u = m5u;
            obj.xBounds = xBounds;
            obj.yBounds = yBounds;

            obj.pressed = false;
            obj.released = false;

            obj.pressUpdatedOnCurrentPress = false;
            obj.releaseUpdatedOnCurrentRelease = true;
           
            obj.beingPressed = false;

            obj.onColor = onColor;
            obj.offColor = offColor;
            obj.outlineColor = outlineColor;

            obj.xSize = xBounds(2) - xBounds(1);
            obj.ySize = yBounds(2) - yBounds(1);

            obj.disabled = false;
            obj.disabledColor = "no";

            obj.longPressed = false;
            obj.checkForHold = false;
            obj.holdTic = 0;
            obj.ticUpdatedOnCurrentPress = false;
            obj.minHoldTime = 0.3;
        end

        %Update the Button's State
        function UpdateButtonState(obj, touchX, touchY)
            if (~obj.disabled)

                if (touchX > obj.xBounds(1) && ...
                    touchX <= obj.xBounds(2) && ...
                    touchY > obj.yBounds(1) && ...
                    touchY <= obj.yBounds(2))
       
                    obj.beingPressed = true;
                    
                    %One Time Event Trigger
                    if (~obj.pressUpdatedOnCurrentPress)    
                        obj.pressed = true;
                        obj.pressUpdatedOnCurrentPress = true;
                        obj.releaseUpdatedOnCurrentRelease = false;
                        if ~strcmp(obj.onColor, "no")
                            obj.DrawOnRec();
                        end
                    end

                    %Check for hold
                    if obj.checkForHold && ~obj.longPressed
                        if ~obj.ticUpdatedOnCurrentPress
                            obj.holdTic = tic;
                            obj.ticUpdatedOnCurrentPress = true;
                        end

                        if toc(obj.holdTic) >= obj.minHoldTime
                            obj.longPressed = true;
                        end

                    end

                else
                    obj.beingPressed = false;
    
                    %One Time Event Trigger
                    if (~obj.releaseUpdatedOnCurrentRelease)
                        obj.released = true;
                        obj.releaseUpdatedOnCurrentRelease = true;
                        obj.pressUpdatedOnCurrentPress = false;
                        if ~strcmp(obj.offColor, "no")
                            obj.DrawOffRec();
                        end
                    end

                    %need to reset hold timer every time button is released, not every time longpress is triggered
                    if obj.checkForHold
                        obj.ticUpdatedOnCurrentPress = false;
                    end
                   
                end
            end
        end
        
        %Checks if the button was pressed, returns true once then returns false
        %One Time Event Trigger
        function out = WasPressed(obj)
            out = obj.pressed;
            if obj.pressed
                obj.pressed = false;
            end
        end

        function out = WasReleased(obj)
            out = obj.released;
            if obj.released
                obj.released = false;
            end
        end

        function out = WasLongPressed(obj) %to be used with WasReleased
            out = obj.longPressed;
            if obj.longPressed
                obj.longPressed = false;
            end
        end

        function SetDisabledColor(obj, disabledColor)
            obj.disabledColor = disabledColor;
        end

        function DisableButton(obj)
            obj.disabled = true;
            if ~strcmp(obj.disabledColor, "no")
                obj.DrawDisabledRec(obj.disabledColor);
            end
        end

        function UndisableButton(obj)
            obj.disabled = false;
            if ~strcmp(obj.offColor, "no")
                obj.DrawOffRec;
            end
        end

        function out = GetDisabled(obj)
            out = obj.disabled;
        end

        function ForceRedraw(obj)
            obj.DrawOffRec();
        end

        function SetOnColor(obj, color)
            obj.onColor = color;
        end

        function SetOffColor(obj, color)
            obj.offColor = color;
        end

        function SetOutlineColor(obj, color)
            obj.outlineColor = color;
        end

        function out = GetOutlineColor(obj)
            out = obj.outlineColor;
        end

        function out = GetOffColor(obj)
            out = obj.offColor;
        end
        
    end

    methods (Hidden)
        function DrawOnRec(obj)
            obj.m5u.lcdDrawFillRect(obj.xBounds(1), obj.yBounds(1), obj.xSize, obj.ySize, obj.onColor);
            
            if ~strcmp(obj.outlineColor, "no")
                obj.m5u.lcdDrawRect(obj.xBounds(1), obj.yBounds(1), obj.xSize, obj.ySize, obj.outlineColor);
            end
        end
        function DrawOffRec(obj)
            obj.m5u.lcdDrawFillRect(obj.xBounds(1), obj.yBounds(1), obj.xSize, obj.ySize, obj.offColor);
            
            if ~strcmp(obj.outlineColor, "no")
                obj.m5u.lcdDrawRect(obj.xBounds(1), obj.yBounds(1), obj.xSize, obj.ySize, obj.outlineColor);
            end
        end
        function DrawDisabledRec(obj, color)
            obj.m5u.lcdDrawFillRect(obj.xBounds(1), obj.yBounds(1), obj.xSize, obj.ySize, color);
            
            if ~strcmp(obj.outlineColor, "no")
                obj.m5u.lcdDrawRect(obj.xBounds(1), obj.yBounds(1), obj.xSize, obj.ySize, obj.outlineColor);
            end
        end
    end
end
