pcall(function()
    local g = game:GetService
    local Players, UIS, RunS = g("Players"), g("UserInputService"), g("RunService")
    local me = Players.LocalPlayer
    local cam = rawget(workspace, "CurrentCamera")
    local waitChild = waitForChild

    local gui = Instance.new("ScreenGui")
    gui.Name = "esp_gui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = math.random(700,900)
    gui.Parent = waitChild(me,"PlayerGui")

    local settings = {}

    local function WorldTo2D(pos)
        local ok, v2, depth = cam:WorldToViewportPoint(pos)
        return ok, Vector2.new(v2.X, v2.Y), depth
    end

    local Drawing = {}
    Drawing.__index = Drawing
    function Drawing.new(typ)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0,40,0,20)
        lbl.Position = UDim2.new(0,0,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = ""
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 12
        lbl.ZIndex = 10
        lbl.Parent = gui
        return lbl
    end

    local function drawText(props)
        local obj = Drawing.new("Text")
        for k,v in next, props do obj[k] = v end
        return obj
    end

    local cache = {}
    local menu, dragActive, dragStartPos, menuStartPos

    local function addLine(y, name, key, default)
        settings[key] = default
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,-6,0,22)
        frame.Position = UDim2.new(0,4,0,y)
        frame.BackgroundColor3 = Color3.new(0.10,0.09,0.16)
        frame.ZIndex = 9
        frame.Parent = menu

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,-30,0,20)
        label.Position = UDim2.new(0,2,0,0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.Font = Enum.Font.SourceSans
        label.TextSize = 11
        label.TextColor3 = Color3.new(0.9,0.9,0.9)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0,20,0,11)
        switch.Position = UDim2.new(1,-24,0,4)
        switch.Text = ""
        switch.ZIndex = 10

        local function updateSwitch()
            switch.BackgroundColor3 = settings[key] and Color3.fromRGB(34,145,72) or Color3.fromRGB(50,50,65)
        end
        updateSwitch()

        switch.InputBegan:Connect(function(input,gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                settings[key] = not settings[key]
                updateSwitch()
            end
        end)
        switch.Parent = frame
    end

    menu = Instance.new("Frame")
    menu.Name = "esp_menu"
    menu.Size = UDim2.new(0,270,0,210)
    menu.Position = UDim2.new(0,30,0,50)
    menu.BackgroundColor3 = Color3.new(0.07,0.07,0.12)
    menu.Visible = false
    menu.ZIndex = 8
    menu.Parent = gui

    local bar = Instance.new("TextLabel")
    bar.Size = UDim2.new(1,0,0,24)
    bar.BackgroundColor3 = Color3.new(0.13,0.08,0.17)
    bar.Text = "玩家ESP设置"
    bar.Font = Enum.Font.SourceSans
    bar.TextSize = 12
    bar.TextColor3 = Color3.fromRGB(230,100,150)
    bar.ZIndex = 9
    bar.Parent = menu

    addLine(28,"启用ESP","enable",true)
    addLine(54,"显示名字","name",true)
    addLine(80,"显示血量","hp",true)
    addLine(106,"显示距离","dist",true)

    bar.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragActive = true
            dragStartPos = input.Position
            menuStartPos = menu.Position
        end
    end)
    bar.InputChanged:Connect(function(input)
        if not dragActive then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartPos
            menu.Position = UDim2.new(0, menuStartPos.X.Offset + delta.X, 0, menuStartPos.Y.Offset + delta.Y)
        end
    end)
    bar.InputEnded:Connect(function() dragActive = false end)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0,11,0,38)
    toggleBtn.Position = UDim2.new(0,8,0,200)
    toggleBtn.BackgroundColor3 = Color3.new(0.25,0.25,0.25)
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 10
    toggleBtn.Parent = gui

    local function toggleMenu() menu.Visible = not menu.Visible end
    toggleBtn.TouchTap:Connect(toggleMenu)
    toggleBtn.MouseButton1Click:Connect(toggleMenu)

    task.spawn(function()
        while task.wait() do
            local nowActive = {}
            if not settings.enable then
                for _,v in next, cache do
                    pcall(function() v.name:Destroy() v.hp:Destroy() v.dist:Destroy() end)
                end
                table.clear(cache)
                continue
            end

            for _,player in next, Players:GetPlayers() do
                if player == me then continue end
                local char = player.Character
                if not char then continue end
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if not hum or not root or hum.Health <= 0 then continue end

                local ok, pos2d, dis = WorldTo2D(root.Position)
                if not ok then continue end
                local idStr = tostring(player.UserId)
                nowActive[idStr] = true

                if not cache[idStr] then
                    cache[idStr] = {
                        name = drawText({}),
                        hp = drawText({}),
                        dist = drawText({})
                    }
                end
                local t = cache[idStr]

                t.name.Visible = settings.name
                t.name.Position = pos2d + Vector2.new(0,-22)
                t.name.Text = player.Name
                t.name.TextColor3 = Color3.new(1,0.4,0.4)

                t.hp.Visible = settings.hp
                t.hp.Position = pos2d
                t.hp.Text = "HP:"..math.floor(hum.Health)
                t.hp.TextColor3 = Color3.new(0.4,0.85,1)

                t.dist.Visible = settings.dist
                t.dist.Position = pos2d + Vector2.new(0,20)
                t.dist.Text = math.floor(dis).."m"
                t.dist.TextColor3 = Color3.new(1,1,1)
            end

            for uid,item in next, cache do
                if not nowActive[uid] then
                    pcall(function() item.name:Destroy() item.hp:Destroy() item.dist:Destroy() end)
                    cache[uid] = nil
                end
            end
        end
    end)
end)
