-- Ghost Soares Hub V2 • By Soares And Ghost Hub
-- Menu local para Murder Mystery 2 (Nikilis).

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    return
end
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
    return
end

local previous = playerGui:FindFirstChild("SoaresHub")
if previous then
    local closePrevious = previous:FindFirstChild("Encerrar")
    if closePrevious and closePrevious:IsA("BindableFunction") then
        pcall(function()
            closePrevious:Invoke()
        end)
    end
    if previous.Parent then
        previous:Destroy()
    end
end

local isMM2 = game.GameId == 66654135 or game.PlaceId == 142823291
local renderName = "SoaresHubCamera_" .. player.UserId
local state = {
    running = true,
    loading = true,
    unlocked = false,
    aim = false,
    smoothAim = false,
    torsoAim = false,
    checkWalls = false,
    aimRange = math.huge,
    aimSmoothRate = 25,
    aimWeapon = false,
    aimLead = false,
    touchShift = false,
    esp = {Murderer = false, Sheriff = false, Innocent = false},
    espName = true,
    espDistance = false,
    espFill = true,
    espThrough = true,
    espHealth = false,
    espTracers = false,
    espTraceCenter = false,
    espRange = math.huge,
    espOpacity = 0.76,
    profile = "Original",
    graphics = {},
    showFps = false,
    performanceHud = false,
    animateMenu = true,
    lockMenu = false,
    uiSize = "Padrão",
    rgbTheme = "Aurora",
}
local connections = {}
local animations = {}
local ui = {}
local farm = {active = false, controlsCharacter = false}
local roundTools = {}
local dashboard = {}
local playerTools = {}
local skinTools = {}
local optionRefresh = {}
local espRefresh = {}

local colors = {
    white = Color3.fromRGB(242, 247, 255),
    paper = Color3.fromRGB(224, 235, 253),
    ink = Color3.fromRGB(8, 12, 23),
    panel = Color3.fromRGB(13, 19, 33),
    surface = Color3.fromRGB(22, 30, 50),
    raised = Color3.fromRGB(33, 43, 67),
    selected = Color3.fromRGB(40, 57, 84),
    line = Color3.fromRGB(64, 80, 117),
    muted = Color3.fromRGB(177, 192, 220),
    darkMuted = Color3.fromRGB(151, 170, 201),
    accent = Color3.fromRGB(112, 241, 255),
    violet = Color3.fromRGB(165, 119, 255),
    pink = Color3.fromRGB(255, 118, 202),
}
local roleInfo = {
    Murderer = {name = "Murder", color = Color3.fromRGB(255, 67, 80)},
    Sheriff = {name = "Sheriff", color = Color3.fromRGB(68, 150, 255)},
    Hero = {name = "Herói", color = Color3.fromRGB(98, 205, 255)},
    Innocent = {name = "Innocent", color = Color3.fromRGB(84, 231, 146)},
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function make(className, parent, properties)
    local object = Instance.new(className)
    for name, value in pairs(properties) do
        object[name] = value
    end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    make("UICorner", parent, {CornerRadius = UDim.new(0, radius)})
end

local function stroke(parent, color, transparency)
    make("UIStroke", parent, {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        Transparency = transparency or 0,
        Thickness = 1,
    })
end

local function label(parent, value, size, font, color)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Font = font or Enum.Font.GothamMedium,
        Text = value,
        TextColor3 = color or colors.white,
        TextSize = size,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function button(parent, value, size)
    local object = make("TextButton", parent, {
        AutoButtonColor = true,
        BackgroundColor3 = colors.accent,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = value,
        TextColor3 = colors.ink,
        TextSize = size or 12,
    })
    round(object, 8)
    return object
end

local function paintChoice(object, selected)
    object.BackgroundColor3 = selected and colors.accent or colors.raised
    object.TextColor3 = selected and colors.ink or colors.muted
end

local function animate(object, tweenInfo, goal)
    local tween = TweenService:Create(object, tweenInfo, goal)
    table.insert(animations, tween)
    tween:Play()
    return tween
end

local rgbPalettes = {
    Aurora = {colors.accent, colors.violet, colors.pink, colors.accent},
    Glacial = {Color3.fromRGB(142, 250, 231), Color3.fromRGB(70, 165, 255), colors.white, Color3.fromRGB(142, 250, 231)},
    Neon = {Color3.fromRGB(217, 100, 255), Color3.fromRGB(255, 98, 153), Color3.fromRGB(111, 131, 255), Color3.fromRGB(217, 100, 255)},
}

local function spectrumColors(theme)
    local palette = rgbPalettes[theme]
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, palette[1]),
        ColorSequenceKeypoint.new(0.34, palette[2]),
        ColorSequenceKeypoint.new(0.66, palette[3]),
        ColorSequenceKeypoint.new(1, palette[4]),
    })
end

local function spectrum(parent, duration, rotation)
    local gradient = make("UIGradient", parent, {
        Rotation = rotation,
        Color = spectrumColors(state.rgbTheme),
    })
    local motion = animate(gradient, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        Rotation = rotation + 360,
    })
    return motion, gradient
end

local function glyph(parent, name, position, size, color)
    local tile = make("Frame", parent, {
        Name = "GhostIcon",
        BackgroundTransparency = 1,
        Position = position,
        Size = UDim2.fromOffset(size, size),
    })
    local function bar(x, y, w, h, rotation)
        local piece = make("Frame", tile, {
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Position = UDim2.fromScale(x, y),
            Size = UDim2.fromScale(w, h),
            Rotation = rotation or 0,
        })
        make("UICorner", piece, {CornerRadius = UDim.new(0.45, 0)})
    end
    local function ring(x, y, diameter, square)
        local piece = make("Frame", tile, {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(x, y),
            Size = UDim2.fromScale(diameter, diameter),
        })
        make("UICorner", piece, {CornerRadius = UDim.new(square and 0.18 or 0.5, 0)})
        stroke(piece, color)
    end
    if name == "radar" then
        ring(0.12, 0.12, 0.76)
        ring(0.32, 0.32, 0.36)
        bar(0.43, 0.37, 0.43, 0.10, -42)
    elseif name == "aim" then
        ring(0.24, 0.24, 0.52)
        bar(0.46, 0.04, 0.08, 0.30)
        bar(0.46, 0.66, 0.08, 0.30)
        bar(0.04, 0.46, 0.30, 0.08)
        bar(0.66, 0.46, 0.30, 0.08)
    elseif name == "esp" then
        ring(0.09, 0.09, 0.82, true)
        ring(0.30, 0.30, 0.40)
        bar(0.44, 0.44, 0.12, 0.12)
    elseif name == "troll" then
        bar(0.34, 0.07, 0.15, 0.48, 32)
        bar(0.31, 0.43, 0.42, 0.14)
        bar(0.52, 0.44, 0.15, 0.49, 32)
    elseif name == "coin" then
        ring(0.11, 0.11, 0.78)
        bar(0.44, 0.26, 0.12, 0.48)
        bar(0.34, 0.29, 0.32, 0.09)
        bar(0.34, 0.62, 0.32, 0.09)
    elseif name == "player" then
        ring(0.34, 0.10, 0.32)
        bar(0.18, 0.57, 0.64, 0.26)
    elseif name == "visual" then
        bar(0.15, 0.61, 0.17, 0.26)
        bar(0.41, 0.42, 0.17, 0.45)
        bar(0.67, 0.16, 0.17, 0.71)
    elseif name == "skins" then
        bar(0.20, 0.40, 0.63, 0.17, -43)
        bar(0.26, 0.50, 0.15, 0.33, -43)
        bar(0.21, 0.62, 0.26, 0.11, -43)
    elseif name == "hub" then
        for index = 0, 2 do
            local y = 0.17 + index * 0.29
            bar(0.12, y, 0.76, 0.10)
            bar(index == 1 and 0.61 or 0.32, y - 0.08, 0.13, 0.25)
        end
    elseif name == "info" then
        ring(0.11, 0.11, 0.78)
        bar(0.45, 0.28, 0.10, 0.10)
        bar(0.45, 0.45, 0.10, 0.26)
    elseif name == "jump" then
        bar(0.21, 0.30, 0.38, 0.12, -44)
        bar(0.43, 0.30, 0.38, 0.12, 44)
        bar(0.44, 0.40, 0.12, 0.38)
    elseif name == "close" then
        bar(0.18, 0.44, 0.64, 0.12, 45)
        bar(0.18, 0.44, 0.64, 0.12, -45)
    elseif name == "minus" then
        bar(0.19, 0.45, 0.62, 0.10)
    else
        ring(0.10, 0.10, 0.80, true)
        bar(0.30, 0.28, 0.40, 0.15)
        bar(0.29, 0.41, 0.16, 0.28)
        bar(0.44, 0.55, 0.30, 0.15)
    end
    return tile
end

ui.gui = make("ScreenGui", playerGui, {
    Name = "SoaresHub",
    DisplayOrder = 50,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function()
    ui.gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)
local closeSignal = make("BindableFunction", ui.gui, {Name = "Encerrar"})
local visuals = make("Folder", Workspace, {Name = "SoaresHubVisuals"})

local screen = make("Frame", ui.gui, {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
})
local window = make("Frame", screen, {
    Name = "Menu",
    BackgroundColor3 = colors.white,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 5,
})
round(window, 16)
local menuMotion, menuGradient = spectrum(window, 8.4, -33)
menuMotion:Pause()
local shell = make("Frame", window, {
    BackgroundColor3 = colors.panel,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(2, 2),
    Size = UDim2.new(1, -4, 1, -4),
})
round(shell, 14)
make("UIGradient", shell, {
    Color = ColorSequence.new(Color3.fromRGB(244, 250, 255), Color3.fromRGB(183, 167, 255)),
    Rotation = 32,
})

local header = make("Frame", window, {
    BackgroundColor3 = colors.surface,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(10, 10),
    Size = UDim2.new(1, -20, 0, 75),
})
round(header, 11)
stroke(header, colors.line, 0.36)
local rail = make("Frame", header, {
    BackgroundColor3 = colors.white,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 1, -4),
    Size = UDim2.new(1, -24, 0, 2),
})
round(rail, 3)
local railMotion, railGradient = spectrum(rail, 5.3, 12)
railMotion:Pause()

local logo = make("Frame", header, {
    BackgroundColor3 = colors.raised,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(11, 13),
    Size = UDim2.fromOffset(42, 42),
})
round(logo, 10)
stroke(logo, colors.accent, 0.28)
glyph(logo, "logo", UDim2.fromOffset(9, 9), 24, colors.accent)

local title = label(header, "Ghost Soares Hub", 24, Enum.Font.GothamBlack)
title.Position = UDim2.fromOffset(63, 7)
title.Size = UDim2.new(1, -158, 0, 30)
title.TextScaled = true
make("UITextSizeConstraint", title, {MinTextSize = 12, MaxTextSize = 24})
local author = label(header, "By Soares And Ghost Hub", 11, Enum.Font.GothamBold, colors.muted)
author.Position = UDim2.fromOffset(64, 38)
author.Size = UDim2.new(1, -110, 0, 14)
local tagline = label(header, "GHOST V2  /  MM2 SUITE", 9, Enum.Font.GothamBold, colors.accent)
tagline.Position = UDim2.fromOffset(64, 52)
tagline.Size = UDim2.new(1, -112, 0, 13)
local badge = label(header, "V2", 10, Enum.Font.GothamBold, colors.accent)
badge.BackgroundColor3 = colors.raised
badge.BackgroundTransparency = 0
badge.Position = UDim2.new(1, -44, 0, 45)
badge.Size = UDim2.fromOffset(34, 17)
badge.TextXAlignment = Enum.TextXAlignment.Center
round(badge, 5)
stroke(badge, colors.accent, 0.52)

local dragZone = make("Frame", header, {
    Active = true,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -91, 1, 0),
    ZIndex = 3,
})
local function headerButton(text, icon, offset)
    local action = button(header, text, 12)
    action.BackgroundColor3 = colors.raised
    action.TextTransparency = 1
    action.Position = UDim2.new(1, offset, 0, 10)
    action.Size = UDim2.fromOffset(24, 26)
    action.ZIndex = 4
    glyph(action, icon, UDim2.fromOffset(5, 6), 14, colors.accent)
    return action
end
local infoShortcut = headerButton("ABRIR INFORMAÇÕES", "info", -87)
local minimize = headerButton("–", "minus", -60)
local exit = headerButton("×", "close", -33)

local launcher = button(screen, "GHOST SOARES", 11)
launcher.BackgroundColor3 = colors.surface
launcher.TextColor3 = colors.white
launcher.Position = UDim2.fromOffset(12, 64)
launcher.Size = UDim2.fromOffset(139, 37)
launcher.Visible = false
launcher.TextTransparency = 1
stroke(launcher, colors.accent, 0.32)
glyph(launcher, "logo", UDim2.fromOffset(7, 10), 17, colors.accent)
local launcherCaption = label(launcher, launcher.Text, 11, Enum.Font.GothamBold, colors.white)
launcherCaption.Position = UDim2.fromOffset(30, 0)
launcherCaption.Size = UDim2.new(1, -36, 1, 0)

local shiftButton = button(screen, "SHIFT LOCK", 11)
shiftButton.Position = UDim2.fromOffset(12, 108)
shiftButton.Size = UDim2.fromOffset(108, 38)
shiftButton.Visible = false
stroke(shiftButton, colors.accent, 0.28)

local nav = make("ScrollingFrame", window, {
    Name = "GhostNav",
    Active = true,
    BackgroundColor3 = colors.ink,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0),
    ScrollBarImageColor3 = colors.accent,
    ScrollBarThickness = 2,
})
round(nav, 9)
stroke(nav, colors.line, 0.32)

local pages = {}
local tabs = {}
local tabMarks = {}
local tabLabels = {}
local pageNames = {
    {"Rodada", "RODADA", "radar"},
    {"Combate", "COMBATE", "aim"},
    {"ESP", "ESP", "esp"},
    {"Troll", "TROLL", "troll"},
    {"Farm", "FARM", "coin"},
    {"Player", "PLAYER", "player"},
    {"Visual", "VISUAL", "skins"},
    {"Gráficos", "GRÁFICOS", "visual"},
    {"Hub", "HUB", "hub"},
    {"Informações", "INFO", "info"},
}
local function revealTab(key)
    local tab = tabs[key]
    local viewport = nav.AbsoluteWindowSize
    local canvas = nav.CanvasPosition
    local horizontal = nav.ScrollingDirection == Enum.ScrollingDirection.X
    local start = horizontal and tab.Position.X.Offset or tab.Position.Y.Offset
    local length = horizontal and tab.Size.X.Offset or tab.Size.Y.Offset
    local span = horizontal and viewport.X or viewport.Y
    local offset = horizontal and canvas.X or canvas.Y
    if span > 0 then
        local maximum = math.max(start - 4, 0)
        local minimum = math.min(math.max(0, start + length - span + 4), maximum)
        local nextOffset = math.clamp(offset, minimum, maximum)
        nav.CanvasPosition = horizontal and Vector2.new(nextOffset, 0) or Vector2.new(0, nextOffset)
    end
end

local function selectPage(key)
    ui.pageName = key
    if key == "Farm" and roundTools.cancelForFarm then
        roundTools.cancelForFarm()
    end
    tagline.Text = "GHOST V2  /  " .. tabs[key].Text
    for pageKey, page in pairs(pages) do
        local selected = pageKey == key
        page.Visible = selected
        tabs[pageKey].BackgroundColor3 = selected and colors.selected or colors.surface
        tabLabels[pageKey].TextColor3 = selected and colors.white or colors.muted
        tabMarks[pageKey].Visible = selected
    end
    revealTab(key)
    if dashboard.updateVisibility then dashboard.updateVisibility() end
    if key == "Visual" and skinTools.open then skinTools.open() end
end

for _, item in ipairs(pageNames) do
    local key = item[1]
    local tab = button(nav, item[2], 11)
    tab.BackgroundColor3 = colors.surface
    tab.TextTransparency = 1
    local caption = label(tab, item[2], 11, Enum.Font.GothamBold, colors.muted)
    caption.Position = UDim2.fromOffset(28, 0)
    caption.Size = UDim2.new(1, -34, 1, 0)
    caption.TextScaled = true
    make("UITextSizeConstraint", caption, {MinTextSize = 8, MaxTextSize = 11})
    tabLabels[key] = caption
    glyph(tab, item[3], UDim2.fromOffset(8, 7), 15, colors.accent)
    tabMarks[key] = make("Frame", tab, {
        BackgroundColor3 = colors.accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 5),
        Size = UDim2.fromOffset(2, 18),
        Visible = false,
    })
    tabs[key] = tab

    local page = make("ScrollingFrame", window, {
        Name = key,
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = colors.accent,
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    })
    make("UIListLayout", page, {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    make("UIPadding", page, {
        PaddingTop = UDim.new(0, 1),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 6),
    })
    pages[key] = page
    connect(tab.Activated, function() selectPage(key) end)
end
connect(infoShortcut.Activated, function() selectPage("Informações") end)

local footer = make("Frame", window, {
    BackgroundColor3 = colors.surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 1, -36),
    Size = UDim2.new(1, -20, 0, 26),
})
round(footer, 8)
stroke(footer, colors.line)
ui.status = label(footer, "", 11, Enum.Font.GothamMedium, colors.muted)
ui.status.Position = UDim2.fromOffset(8, 0)
ui.status.Size = UDim2.new(1, -16, 1, 0)
ui.fps = label(footer, "", 10, Enum.Font.GothamBold)
ui.fps.Position = UDim2.new(1, -66, 0, 0)
ui.fps.Size = UDim2.fromOffset(58, 26)
ui.fps.TextXAlignment = Enum.TextXAlignment.Right

local function status(message)
    if state.running then
        ui.status.Text = message
    end
end

local function card(page, height)
    local row = make("Frame", page, {
        BackgroundColor3 = colors.surface,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        LayoutOrder = #page:GetChildren(),
        Size = UDim2.new(1, 0, 0, height),
    })
    round(row, 10)
    stroke(row, colors.line, 0.43)
    return row
end

local function cardCopy(row, titleText, description, reserved)
    local heading = label(row, titleText, 13, Enum.Font.GothamBold)
    heading.Position = UDim2.fromOffset(10, 7)
    heading.Size = UDim2.new(1, -reserved, 0, 17)
    local detail = label(row, description, 11, nil, colors.muted)
    detail.Position = UDim2.fromOffset(10, 26)
    detail.Size = UDim2.new(1, -reserved, 0, 24)
    detail.TextTruncate = Enum.TextTruncate.None
    detail.TextWrapped = true
    detail.TextYAlignment = Enum.TextYAlignment.Top
    return detail
end

local function toggle(page, titleText, detail, read, write)
    local row = card(page, 55)
    local descriptionLabel = cardCopy(row, titleText, detail, 72)
    local action = button(row, "", 10)
    action.Position = UDim2.new(1, -57, 0, 14)
    action.Size = UDim2.fromOffset(47, 27)
    local function refresh()
        local enabled = read()
        action.Text = enabled and "ON" or "OFF"
        paintChoice(action, enabled)
    end
    connect(action.Activated, function()
        write(not read())
        refresh()
    end)
    refresh()
    return refresh, descriptionLabel
end

local function option(page, key, titleText, detail, onChange)
    local refresh, description = toggle(page, titleText, detail, function()
        return state[key]
    end, function(value)
        state[key] = value
        if onChange then
            onChange(value)
        end
    end)
    optionRefresh[key] = refresh
    return refresh, description
end

local function refreshMenuMotion()
    if window.Visible and state.animateMenu then
        menuMotion:Play()
        railMotion:Play()
    else
        menuMotion:Pause()
        railMotion:Pause()
    end
end

local function refreshSpectrum()
    local sequence = spectrumColors(state.rgbTheme)
    menuGradient.Color = sequence
    railGradient.Color = sequence
end

local function setMenu(visible)
    if state.loading or not state.unlocked or not state.running then
        return
    end
    if visible and ui.pageName == "Farm" and roundTools.cancelForFarm then
        roundTools.cancelForFarm()
    end
    window.Visible = visible
    launcher.Visible = not visible
    shiftButton.Visible = isMM2 and UserInputService.TouchEnabled and not visible
    refreshMenuMotion()
    if dashboard.updateVisibility then dashboard.updateVisibility() end
    if playerTools.updateVisibility then playerTools.updateVisibility() end
end

connect(minimize.Activated, function()
    setMenu(false)
end)
connect(launcher.Activated, function()
    setMenu(true)
end)

local position
local windowSizes = {
    Compacto = {394, 430},
    ["Padrão"] = {592, 514},
    Amplo = {688, 565},
}

local function layoutNavigation(width, height)
    local sidebar = width >= 505
    local headerHeight = height < 355 and 68 or 75
    local navTop = 17 + headerHeight
    local contentTop = sidebar and navTop or navTop + 44
    local contentLeft = sidebar and 142 or 10
    header.Size = UDim2.new(1, -20, 0, headerHeight)
    badge.Visible = width >= 310
    author.Size = UDim2.new(1, badge.Visible and -110 or -76, 0, 14)
    nav.Position = UDim2.fromOffset(10, navTop)
    nav.Size = sidebar and UDim2.new(0, 122, 1, -(navTop + 43)) or UDim2.new(1, -20, 0, 37)
    nav.ScrollingDirection = sidebar and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.X
    nav.CanvasSize = sidebar and UDim2.fromOffset(0, #pageNames * 34 + 5) or UDim2.fromOffset(#pageNames * 100 + 6, 0)
    for index, item in ipairs(pageNames) do
        local key = item[1]
        local tab = tabs[key]
        tab.Position = sidebar and UDim2.fromOffset(5, (index - 1) * 34 + 4) or UDim2.fromOffset((index - 1) * 100 + 4, 4)
        tab.Size = UDim2.fromOffset(sidebar and 110 or 95, 28)
        pages[key].Position = UDim2.fromOffset(contentLeft, contentTop)
        pages[key].Size = UDim2.new(1, -(contentLeft + 10), 1, -(contentTop + 44))
    end
    if ui.pageName then revealTab(ui.pageName) end
end

local function resizeMenu()
    local bounds = screen.AbsoluteSize
    if bounds.X < 1 or bounds.Y < 1 then
        return
    end
    local limit = windowSizes[state.uiSize]
    local width = math.min(limit[1], math.max(1, bounds.X - 16))
    local height = math.min(limit[2], math.max(1, bounds.Y - 16))
    local xLimit = math.max(0, bounds.X - width)
    local yLimit = math.max(0, bounds.Y - height)
    window.Size = UDim2.fromOffset(width, height)
    layoutNavigation(width, height)
    local target = position or Vector2.new(xLimit / 2, yLimit / 2)
    local clamped = Vector2.new(math.clamp(target.X, 0, xLimit), math.clamp(target.Y, 0, yLimit))
    if position then
        position = clamped
    end
    window.Position = UDim2.fromOffset(clamped.X, clamped.Y)
end
connect(screen:GetPropertyChangedSignal("AbsoluteSize"), resizeMenu)
resizeMenu()

local dragInput
local dragOrigin
local startPosition
connect(dragZone.InputBegan, function(input)
    if state.lockMenu then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
        dragOrigin = input.Position
        startPosition = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not dragInput or state.lockMenu then
        return
    end
    local mouseDrag = dragInput.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement
    if input == dragInput or mouseDrag then
        local delta = input.Position - dragOrigin
        position = startPosition + Vector2.new(delta.X, delta.Y)
        resizeMenu()
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input == dragInput then
        dragInput = nil
    end
end)
connect(UserInputService.WindowFocusReleased, function()
    dragInput = nil
end)
connect(UserInputService.InputBegan, function(input, handled)
    if not handled and input.KeyCode == Enum.KeyCode.RightControl and not UserInputService:GetFocusedTextBox() then
        setMenu(not window.Visible)
    end
end)

-- Estado da rodada e detecção auxiliar por equipamento.
local roundData = {}
local lastSnapshot = -math.huge
local roleRemote
local lastRemoteSearch = -math.huge
local queryBusy = false
local murderer
local espObjects = {}
local activeKill

local function aliveCharacter(other)
    local character = other.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if character and character.Parent and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        return character, humanoid, root
    end
end

local function playerTool(other, name)
    local character = other.Character
    local backpack = other:FindFirstChildOfClass("Backpack")
    local equipped = character and character:FindFirstChild(name)
    if equipped and equipped:IsA("Tool") then
        return equipped
    end
    local stored = backpack and backpack:FindFirstChild(name)
    if stored and stored:IsA("Tool") then
        return stored
    end
end

local function rowFor(other)
    if os.clock() - lastSnapshot <= 3.5 then
        local entry = roundData[other.Name]
        if type(entry) == "table" then
            return entry
        end
    end
end

local function hasRoundData()
    return os.clock() - lastSnapshot <= 3.5 and next(roundData) ~= nil
end

local function isEliminated(entry)
    return entry and (entry.Killed == true or entry.Dead == true or entry.Alive == false)
end

local function roundRole(other, entry)
    if isEliminated(entry) then
        return nil
    end
    local role = entry and entry.Role
    if role == "Murder" then
        return "Murderer"
    end
    if type(role) == "string" and roleInfo[role] then
        return role
    end
    if playerTool(other, "Knife") then
        return "Murderer"
    end
    if playerTool(other, "Gun") then
        return "Sheriff"
    end
end

local function requestRoles()
    if not isMM2 or queryBusy then
        return
    end
    if not roleRemote or not roleRemote:IsDescendantOf(ReplicatedStorage) then
        local now = os.clock()
        if now - lastRemoteSearch < 5 then
            return
        end
        lastRemoteSearch = now
        local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        roleRemote = remote and remote:IsA("RemoteFunction") and remote or nil
    end
    if not roleRemote then
        return
    end

    queryBusy = true
    local remote = roleRemote
    task.spawn(function()
        local ok, result = pcall(function()
            return remote:InvokeServer()
        end)
        queryBusy = false
        if state.running and ok and type(result) == "table" then
            roundData = result
            lastSnapshot = os.clock()
        end
    end)
end

local function removeEsp(other)
    local visual = espObjects[other]
    if visual then
        visual.highlight:Destroy()
        visual.billboard:Destroy()
        if visual.line then visual.line:Destroy() end
        espObjects[other] = nil
    end
end

local function updateEsp(other, character, humanoid, root, role, distance)
    local visual = espObjects[other]
    if not visual then
        local highlight = make("Highlight", visuals, {
            Name = "SoaresOutline",
        })
        local billboard = make("BillboardGui", visuals, {
            Name = "SoaresRole",
            MaxDistance = 500,
            Size = UDim2.fromOffset(180, 34),
            StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0),
        })
        local caption = label(billboard, "", 12, Enum.Font.GothamBold)
        caption.Size = UDim2.new(1, 0, 0, 23)
        caption.TextXAlignment = Enum.TextXAlignment.Center
        caption.TextStrokeColor3 = colors.ink
        caption.TextStrokeTransparency = 0.15
        local healthTrack = make("Frame", billboard, {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = colors.ink,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0, 24),
            Size = UDim2.fromOffset(66, 4),
            Visible = false,
        })
        round(healthTrack, 3)
        local healthBar = make("Frame", healthTrack, {
            BackgroundColor3 = Color3.fromRGB(91, 223, 140),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
        })
        round(healthBar, 3)
        visual = {highlight = highlight, billboard = billboard, caption = caption, healthTrack = healthTrack, healthBar = healthBar}
        espObjects[other] = visual
    end

    local info = roleInfo[role]
    local highlight = visual.highlight
    highlight.Adornee = character
    highlight.DepthMode = state.espThrough and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.FillColor = info.color
    highlight.FillTransparency = state.espFill and state.espOpacity or 1
    highlight.OutlineColor = info.color
    highlight.OutlineTransparency = 0.1

    local billboard = visual.billboard
    billboard.Adornee = character:FindFirstChild("Head") or root
    billboard.MaxDistance = math.min(state.espRange, 500)
    billboard.AlwaysOnTop = state.espThrough
    visual.caption.Visible = state.espName or state.espDistance
    billboard.Enabled = visual.caption.Visible or state.espHealth
    local caption = state.espName and (other.DisplayName .. "  ·  " .. info.name) or info.name
    if state.espDistance and distance then
        caption = caption .. string.format("  [%d]", math.floor(distance + 0.5))
    end
    visual.caption.TextColor3 = info.color
    visual.caption.Text = caption
    visual.healthTrack.Visible = state.espHealth
    if state.espHealth then
        local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
        visual.healthBar.Size = UDim2.fromScale(ratio, 1)
        visual.healthBar.BackgroundColor3 = ratio > 0.4 and Color3.fromRGB(91, 223, 140) or roleInfo.Murderer.color
    end
    if state.espTracers and not visual.line then
        visual.line = make("Frame", screen, {
            Name = "SoaresTracer",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            BackgroundTransparency = 0.22,
            Visible = false,
            ZIndex = 3,
        })
    end
    if visual.line then
        visual.line.BackgroundColor3 = info.color
        if not state.espTracers then visual.line.Visible = false end
    end
    visual.root = root
    visual.character = character
end

local function syncPlayers()
    murderer = nil
    if not isMM2 then
        return
    end
    local camera = Workspace.CurrentCamera
    local origin = camera and camera.CFrame.Position
    for _, other in ipairs(Players:GetPlayers()) do
        local character, humanoid, root = aliveCharacter(other)
        local role = character and roundRole(other, rowFor(other))
        if role == "Murderer" then
            murderer = other
        end
        local espRole = role == "Hero" and "Sheriff" or role
        local distance = origin and root and (root.Position - origin).Magnitude
        if other ~= player and role and state.esp[espRole] and (not distance or distance <= state.espRange) then
            updateEsp(other, character, humanoid, root, role, distance)
        else
            removeEsp(other)
        end
    end
end
connect(Players.PlayerRemoving, removeEsp)

-- Mira de câmera após o controlador original do Roblox.
local cameraModule
task.defer(function()
    local scripts = player:FindFirstChild("PlayerScripts")
    local playerModule = scripts and scripts:FindFirstChild("PlayerModule")
    if playerModule and playerModule:IsA("ModuleScript") then
        local ok, module = pcall(require, playerModule)
        if ok and type(module) == "table" and type(module.GetCameras) == "function" then
            local camerasOk, cameras = pcall(module.GetCameras, module)
            if camerasOk and type(cameras) == "table" then
                cameraModule = cameras
            end
        end
    end
end)

local function nativeShift(camera)
    local controller = cameraModule and cameraModule.activeMouseLockController
    if type(controller) == "table" and type(controller.GetIsMouseLocked) == "function"
        and controller:GetIsMouseLocked() then
        return true
    end
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        and (camera.CFrame.Position - camera.Focus.Position).Magnitude > 1
end

local touchHumanoid
local touchOffset
local touchAutoRotate

local function releaseTouchShift()
    if touchHumanoid and touchHumanoid.Parent then
        touchHumanoid.CameraOffset = touchOffset
        touchHumanoid.AutoRotate = touchAutoRotate
    end
    touchHumanoid = nil
end

local function setTouchShift(enabled)
    state.touchShift = enabled
    shiftButton.Text = enabled and "SHIFT LOCK ON" or "SHIFT LOCK"
    paintChoice(shiftButton, enabled)
    if not enabled then
        releaseTouchShift()
    end
end

connect(shiftButton.Activated, function()
    setTouchShift(not state.touchShift)
end)
connect(player.CharacterRemoving, function()
    setTouchShift(false)
end)

local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.IgnoreWater = true
local lastAimState
local frameCount, elapsed = 0, 0

local function render(dt)
    if state.showFps or state.performanceHud then
        frameCount = frameCount + 1
        elapsed = elapsed + dt
        if elapsed >= 0.55 then
            ui.latestFps = math.floor(frameCount / elapsed + 0.5)
            if state.showFps then ui.fps.Text = string.format("%d FPS", ui.latestFps) end
            frameCount, elapsed = 0, 0
        end
    end
    if farm.controlsCharacter or roundTools.fling or roundTools.pickup or roundTools.view
        or (not state.aim and not state.touchShift) then
        return
    end
    local camera = Workspace.CurrentCamera
    local character, humanoid, root = aliveCharacter(player)
    if not camera or camera.CameraType == Enum.CameraType.Scriptable or not character then
        releaseTouchShift()
        return
    end
    local subject = camera.CameraSubject
    if subject ~= humanoid and (not subject or not subject:IsDescendantOf(character)) then
        releaseTouchShift()
        return
    end

    if state.touchShift and touchHumanoid ~= humanoid then
        releaseTouchShift()
        touchHumanoid = humanoid
        touchOffset = humanoid.CameraOffset
        touchAutoRotate = humanoid.AutoRotate
        humanoid.CameraOffset = touchOffset + Vector3.new(1.65, 0.15, 0)
        humanoid.AutoRotate = false
    end

    local notice
    if state.aim and isMM2 and not activeKill then
        local gun = state.aimWeapon and character:FindFirstChild("Gun")
        if not (state.touchShift or nativeShift(camera)) then
            notice = "Mira armada. Ative o Shift Lock."
        elseif state.aimWeapon and (not gun or not gun:IsA("Tool")) then
            notice = "Equipe a arma para usar a mira."
        elseif not murderer or murderer == player then
            notice = "Aguardando um Murder na rodada."
        else
            local target, _, targetRoot = aliveCharacter(murderer)
            if target then
                local aimPart
                if state.torsoAim then
                    aimPart = target:FindFirstChild("UpperTorso") or target:FindFirstChild("Torso")
                else
                    aimPart = target:FindFirstChild("Head")
                end
                aimPart = aimPart or targetRoot
                local origin = camera.CFrame.Position
                local point = aimPart.Position
                if state.aimLead then
                    local velocity = targetRoot.AssemblyLinearVelocity
                    if velocity.Magnitude < 120 then point = point + velocity * 0.065 end
                end
                local direction = point - origin
                local distance = direction.Magnitude
                local inRange = distance <= state.aimRange
                local clear = inRange and distance > 0.01
                if clear and state.checkWalls then
                    ray.FilterDescendantsInstances = {character}
                    local hit = Workspace:Raycast(origin, direction, ray)
                    clear = not hit or hit.Instance:IsDescendantOf(target)
                end
                if clear then
                    local locked = CFrame.lookAt(origin, point)
                    local blend = 1 - math.exp(-dt * state.aimSmoothRate)
                    camera.CFrame = state.smoothAim and camera.CFrame:Lerp(locked, blend) or locked
                    notice = "Mira travada em " .. murderer.DisplayName
                elseif not inRange then
                    notice = "Murder fora do alcance da mira."
                else
                    notice = "Murder fora da linha de visão."
                end
            else
                notice = "Aguardando um Murder na rodada."
            end
        end
    end
    if notice and notice ~= lastAimState then
        lastAimState = notice
        status(notice)
    end

    if state.touchShift then
        local view = camera.CFrame.LookVector
        local horizontal = Vector3.new(view.X, 0, view.Z)
        if horizontal.Magnitude > 0.01 then
            root.CFrame = CFrame.lookAt(root.Position, root.Position + horizontal)
        end
    end
end

local traceElapsed = 0
local function drawTracers(dt)
    if not state.espTracers then return end
    traceElapsed = traceElapsed + dt
    if traceElapsed < 1 / 30 then return end
    traceElapsed = 0
    local camera = Workspace.CurrentCamera
    local bounds = screen.AbsoluteSize
    local inset = screen.AbsolutePosition
    local originX = bounds.X / 2
    local originY = state.espTraceCenter and bounds.Y / 2 or bounds.Y - 24
    for _, visual in pairs(espObjects) do
        local line = visual.line
        if line then
            local visible = false
            if camera and visual.root.Parent then
                local target = visual.root.Position
                local projection, inView = camera:WorldToViewportPoint(target)
                local x = projection.X - inset.X
                local y = projection.Y - inset.Y
                visible = inView and projection.Z > 0 and x >= 0 and x <= bounds.X and y >= 0 and y <= bounds.Y
                if visible and not state.espThrough then
                    local cameraPosition = camera.CFrame.Position
                    ray.FilterDescendantsInstances = {player.Character}
                    local hit = Workspace:Raycast(cameraPosition, target - cameraPosition, ray)
                    visible = not hit or hit.Instance:IsDescendantOf(visual.character)
                end
                if visible then
                    local dx, dy = x - originX, y - originY
                    line.Position = UDim2.fromOffset(originX + dx / 2, originY + dy / 2)
                    line.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 1.5)
                    line.Rotation = math.deg(math.atan2(dy, dx))
                end
            end
            line.Visible = visible
        end
    end
end
RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, function(dt)
    render(dt)
    drawTracers(dt)
end)

-- Ações do menu e Kill All com alvo virtual.
local function actionRow(page, titleText, description, caption, callback)
    local row = card(page, 55)
    local detail = cardCopy(row, titleText, description, 109)
    local action = button(row, caption, 10)
    action.Position = UDim2.new(1, -95, 0, 13)
    action.Size = UDim2.fromOffset(84, 29)
    connect(action.Activated, callback)
    return action, detail
end

local function choiceRow(page, titleText, description, choices, get, set)
    local row = card(page, 95)
    cardCopy(row, titleText, description, 20)
    local buttons = {}
    local function refresh()
        local chosen = get()
        for index, choice in ipairs(choices) do
            local selected = choice[2] == chosen
            paintChoice(buttons[index], selected)
        end
    end
    local share = 1 / #choices
    for index, choice in ipairs(choices) do
        local action = button(row, choice[1], 11)
        action.Position = UDim2.new((index - 1) * share, 7, 0, 55)
        action.Size = UDim2.new(share, -14, 0, 29)
        buttons[index] = action
        connect(action.Activated, function()
            set(choice[2])
            refresh()
        end)
    end
    refresh()
    return refresh
end

local simulateTouch = type(firetouchinterest) == "function" and firetouchinterest or nil

local function touchPair(first, second)
    if simulateTouch and pcall(simulateTouch, first, second, 0) then
        task.delay(0.045, function()
            if first.Parent and second.Parent then
                pcall(simulateTouch, first, second, 1)
            end
        end)
    end
end

local function roundCharacter(other)
    local entry = rowFor(other)
    if other.Parent ~= Players or isEliminated(entry) or (hasRoundData() and not entry) then
        return nil
    end
    return aliveCharacter(other)
end

local combat = pages.Combate
local kill = {
    auto = false,
    equip = true,
    virtual = true,
    sheriffFirst = true,
    interval = 0.58,
    nextAuto = 0,
}
local killButton
local killHint
local refreshAutoKill

local function currentKnife()
    if not isMM2 then
        return nil
    end
    local character, humanoid, root = roundCharacter(player)
    local knife = character and playerTool(player, "Knife")
    if knife and roundRole(player, rowFor(player)) == "Murderer" then
        return knife, character, humanoid, root
    end
end

local function refreshKillButton()
    local available = currentKnife() ~= nil
    local engaged = activeKill or kill.auto
    killButton.Text = engaged and "PARAR" or "KILL ALL"
    paintChoice(killButton, available or engaged)
    if activeKill then
        killHint.Text = activeKill.detail
    elseif kill.auto then
        killHint.Text = available and "Auto armado. Procurando alvos." or "Auto armado. Aguardando a faca."
    else
        killHint.Text = available and "Fixa um alvo por vez na fila." or "Disponível quando você estiver de Murder."
    end
end

local function returnFromKill(job)
    if not job.equipped or player.Character ~= job.character or job.knife.Parent ~= job.character then
        return
    end
    local humanoid = job.humanoid
    if humanoid.Health <= 0 then
        return
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    if job.originalTool and backpack and job.originalTool.Parent == backpack then
        humanoid:EquipTool(job.originalTool)
    else
        humanoid:UnequipTools()
    end
end

local function stopKill(disarm, message)
    local previousJob = activeKill
    activeKill = nil
    if disarm then
        kill.auto = false
    end
    if previousJob then
        pcall(returnFromKill, previousJob)
    end
    if state.running then
        refreshKillButton()
        if refreshAutoKill then refreshAutoKill() end
        if message then status(message) end
    end
end

local function startKill(automatic)
    if farm.active or roundTools.fling or roundTools.pickup then
        if not automatic then
            status("Finalize o Farm ou a ação em andamento para usar o Kill All.")
        end
        return
    end
    local knife, character, humanoid = currentKnife()
    if not knife then
        if not automatic then
            status(isMM2 and "Kill All requer a faca da rodada." or "Abra o Murder Mystery 2.")
        end
        return
    end
    activeKill = {
        knife = knife,
        character = character,
        humanoid = humanoid,
        originalTool = character:FindFirstChildOfClass("Tool"),
        nextAction = 0,
        confirmed = 0,
        detail = "Procurando um alvo vivo.",
    }
    refreshKillButton()
    status(automatic and "Auto Kill All em andamento." or "Kill All em andamento.")
end

local function nearestKillTarget(origin)
    local chosen
    local best = math.huge
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local character, humanoid, root = roundCharacter(other)
            if character then
                local distance = (root.Position - origin).Magnitude
                local role = roundRole(other, rowFor(other))
                local priority = kill.sheriffFirst and (role == "Sheriff" or role == "Hero")
                local score = priority and (distance - 100000) or distance
                if score < best then
                    best = score
                    chosen = {player = other, character = character, humanoid = humanoid, root = root, attempts = 0}
                end
            end
        end
    end
    return chosen
end

local function attackLockedTarget(job, target, root, now)
    local handle = job.knife:FindFirstChild("Handle")
    local hasTouch = simulateTouch and handle and handle:IsA("BasePart")
    local inReach = (root.Position - target.root.Position).Magnitude <= 6
    if not inReach and (not hasTouch or not kill.virtual) then
        job.detail = "Alvo fixo: " .. target.player.DisplayName .. " · aguardando alcance."
        job.nextAction = now + 0.4
        return
    end
    local stab = job.knife:FindFirstChild("Stab")
    if stab and stab:IsA("RemoteEvent") then
        stab:FireServer("Slash")
    else
        job.knife:Activate()
    end
    if hasTouch then
        task.delay(0.035, function()
            if activeKill == job and job.target == target and job.knife.Parent == job.character
                and job.humanoid.Health > 0 and root.Parent == job.character
                and target.root.Parent == target.character and target.humanoid.Health > 0
                and (kill.virtual or (root.Position - target.root.Position).Magnitude <= 6) then
                touchPair(handle, target.root)
            end
        end)
    end
    target.attempts = target.attempts + 1
    local coolingDown = target.attempts % 3 == 0
    job.nextAction = now + (coolingDown and math.max(kill.interval, 1.8) or kill.interval)
    job.detail = string.format("Alvo fixo: %s · %d confirmados", target.player.DisplayName, job.confirmed)
end

local function stepKill(now)
    if not activeKill then
        if kill.auto and now >= kill.nextAuto then
            kill.nextAuto = now + 0.8
            startKill(true)
        end
        return
    end
    local job = activeKill
    local knife, character, humanoid, root = currentKnife()
    if knife ~= job.knife or character ~= job.character then
        stopKill(false, "Kill All encerrou com a rodada.")
        return
    end
    if now < job.nextAction then
        return
    end
    local target = job.target
    if target then
        local currentCharacter, _, currentRoot = roundCharacter(target.player)
        if currentCharacter ~= target.character or currentRoot ~= target.root then
            if target.humanoid.Health <= 0 or isEliminated(rowFor(target.player)) then
                job.confirmed = job.confirmed + 1
            end
            job.target = nil
            target = nil
        end
    end
    if not target then
        target = nearestKillTarget(root.Position)
        job.target = target
    end
    if not target then
        kill.nextAuto = now + 1.6
        stopKill(false, string.format("Kill All • %d eliminações confirmadas", job.confirmed))
        return
    end
    if knife.Parent ~= character then
        if kill.equip then
            humanoid:EquipTool(knife)
            job.equipped = true
        end
        job.detail = kill.equip and "Equipando a faca da rodada." or "Equipe a faca para continuar."
        job.nextAction = now + 0.2
        return
    end
    attackLockedTarget(job, target, root, now)
end

killButton, killHint = actionRow(combat, "Kill All invisível", "Fixa um alvo por vez na fila.", "KILL ALL", function()
    if activeKill or kill.auto then
        stopKill(true, "Kill All parado.")
    else
        startKill(false)
    end
end)
killButton.Parent.LayoutOrder = -30
local autoKillHint
refreshAutoKill, autoKillHint = toggle(combat, "Auto Kill All", "Arma a sequência quando você virar Murder.", function()
    return kill.auto
end, function(value)
    if not isMM2 then
        status("Abra o Murder Mystery 2 para usar o Auto Kill All.")
        return
    end
    if value then
        kill.auto = true
        kill.nextAuto = 0
        requestRoles()
        refreshKillButton()
        status("Auto Kill All armado.")
    else
        stopKill(true, "Auto Kill All desligado.")
    end
end)
autoKillHint.Parent.LayoutOrder = -29

for _, data in ipairs({
    {"virtual", "Toque virtual da faca", "Tenta contato com o alvo fixo à distância."},
    {"equip", "Auto equipar faca", "Equipa a faca antes da sequência de ataques."},
    {"sheriffFirst", "Priorizar Sheriff", "Começa pelo jogador armado quando disponível."},
}) do
    local key = data[1]
    toggle(combat, data[2], data[3], function()
        return kill[key]
    end, function(value)
        kill[key] = value
    end)
end
choiceRow(combat, "Ritmo do Kill All", "Ajusta o intervalo entre tentativas da faca.", {
    {"Calmo", 0.95}, {"Normal", 0.58}, {"Rápido", 0.44},
}, function()
    return kill.interval
end, function(value)
    kill.interval = value
end)

-- Opções de combate e marcadores.
local _, aimHint = option(combat, "aim", "Mira no Murder", "Acompanha o alvo com Shift Lock ligado.", function(enabled)
    if not isMM2 then
        state.aim = false
        status("Abra o Murder Mystery 2 para usar a mira.")
        return
    end
    lastAimState = nil
    if enabled then
        requestRoles()
        syncPlayers()
        status("Mira armada. Ative o Shift Lock.")
    else
        status("Mira desligada.")
    end
end)
aimHint.Parent.LayoutOrder = -35
option(combat, "smoothAim", "Movimento suave", "ON suaviza a mira. OFF gruda de uma vez.")
option(combat, "torsoAim", "Mirar no peito", "ON mira no peito. OFF mira na cabeça.")
option(combat, "checkWalls", "Checar paredes", "Trava a mira quando o Murder estiver visível.")
option(combat, "aimWeapon", "Mira com arma equipada", "Restringe a trava de câmera à arma em mãos.")
option(combat, "aimLead", "Antecipar movimento", "Adianta a mira conforme a velocidade do alvo.")
optionRefresh.aimRange = choiceRow(combat, "Alcance da mira", "Distância máxima para travar no Murder.", {
    {"80 studs", 80}, {"160 studs", 160}, {"Livre", math.huge},
}, function() return state.aimRange end, function(value) state.aimRange = value end)
optionRefresh.aimSmoothRate = choiceRow(combat, "Resposta da mira suave", "Ajusta a velocidade de acompanhamento.", {
    {"Suave", 12}, {"Normal", 25}, {"Ágil", 42},
}, function() return state.aimSmoothRate end, function(value) state.aimSmoothRate = value end)

local espPage = pages.ESP
for _, role in ipairs({"Murderer", "Sheriff", "Innocent"}) do
    local info = roleInfo[role]
    local description = {
        Murderer = "Marca o Murder em vermelho.",
        Sheriff = "Marca o Sheriff e o Herói em azul.",
        Innocent = "Marca os Innocents vivos em verde.",
    }
    espRefresh[role] = toggle(espPage, "ESP " .. info.name, description[role], function()
        return state.esp[role]
    end, function(value)
        if not isMM2 then
            status("Abra o Murder Mystery 2 para usar o ESP.")
            return
        end
        state.esp[role] = value
        if value then
            requestRoles()
        end
        syncPlayers()
        status("ESP " .. info.name .. (value and " ligado." or " desligado."))
    end)
end
option(espPage, "espName", "Nome e papel", "Mostra o nome do jogador acima do personagem.", syncPlayers)
option(espPage, "espDistance", "Distância", "Mostra a distância em studs.", syncPlayers)
option(espPage, "espFill", "Preenchimento", "Liga a cor no interior da silhueta.", syncPlayers)
option(espPage, "espThrough", "Através de paredes", "Exibe os contornos quando há obstáculos.", syncPlayers)
option(espPage, "espHealth", "Barra de vida", "Mostra a vida dos personagens marcados.", syncPlayers)
option(espPage, "espTracers", "Traçadores", "Traça linhas até os papéis com ESP ativo.", syncPlayers)
option(espPage, "espTraceCenter", "Traços a partir do centro", "Move a origem das linhas para o centro da tela.")
optionRefresh.espRange = choiceRow(espPage, "Alcance do ESP", "Filtra os marcadores pela distância da câmera.", {
    {"140 studs", 140}, {"300 studs", 300}, {"Livre", math.huge},
}, function() return state.espRange end, function(value)
    state.espRange = value
    syncPlayers()
end)
optionRefresh.espOpacity = choiceRow(espPage, "Intensidade da cor", "Regula o preenchimento dos contornos.", {
    {"Leve", 0.86}, {"Normal", 0.76}, {"Forte", 0.58},
}, function() return state.espOpacity end, function(value)
    state.espOpacity = value
    syncPlayers()
end)

-- Arma caída, alertas de rodada e ações da aba Troll.
do
    local troll = pages.Troll
    local options = {
        autoGun = false,
        moveForGun = true,
        equipGun = false,
        gunMarker = false,
        gunAlert = false,
        murderAlert = false,
        force = 310,
        duration = 1.15,
        returnAfterFling = true,
        includeHero = true,
    }
    local zero = Vector3.new(0, 0, 0)
    local up = Vector3.new(0, 1, 0)
    local droppedNames = {GunDrop = true, DroppedGun = true}
    local cachedDrop
    local nextDropScan, nextPickup = 0, 0
    local lastAlertedDrop
    local murderNear = false
    local gunMarker
    local grabButton, grabHint
    local refreshAutoGun
    local alertUntil = 0
    local alert = label(screen, "", 13, Enum.Font.GothamBold, colors.white)
    alert.AnchorPoint = Vector2.new(0.5, 0)
    alert.Position = UDim2.new(0.5, 0, 0, 16)
    alert.Size = UDim2.new(1, -36, 0, 32)
    alert.BackgroundColor3 = colors.ink
    alert.BackgroundTransparency = 0.1
    alert.TextXAlignment = Enum.TextXAlignment.Center
    alert.Visible = false
    alert.ZIndex = 4
    make("UISizeConstraint", alert, {MaxSize = Vector2.new(306, 32)})
    round(alert, 9)

    local function notify(message)
        alert.Text = message
        alert.Visible = true
        alertUntil = os.clock() + 2.8
    end
    roundTools.notify = notify

    local function findRole(wanted, position)
        local selected, selectedHumanoid, selectedRoot
        local best = math.huge
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player then
                local character, humanoid, root = roundCharacter(other)
                local role = character and roundRole(other, rowFor(other))
                local hero = wanted == "Sheriff" and options.includeHero and role == "Hero"
                if role == wanted or hero then
                    local score = (root.Position - position).Magnitude + (hero and 10000 or 0)
                    if score < best then
                        selected, selectedHumanoid, selectedRoot = other, humanoid, root
                        best = score
                    end
                end
            end
        end
        return selected, selectedHumanoid, selectedRoot
    end

    local function findDrop(now)
        if cachedDrop and cachedDrop:IsDescendantOf(Workspace) then
            return cachedDrop
        end
        cachedDrop = Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("DroppedGun")
        if not cachedDrop and now >= nextDropScan then
            nextDropScan = now + 1.25
            cachedDrop = Workspace:FindFirstChild("GunDrop", true) or Workspace:FindFirstChild("DroppedGun", true)
        end
        return cachedDrop
    end

    connect(Workspace.DescendantAdded, function(item)
        if isMM2 and droppedNames[item.Name] then
            cachedDrop = item
            nextPickup = 0
        end
    end)

    local function dropPart(drop)
        if not drop then
            return nil
        end
        if drop:IsA("BasePart") and drop.CanTouch then
            return drop
        end
        local fallback
        for _, item in ipairs(drop:GetDescendants()) do
            if item:IsA("BasePart") and item.CanTouch then
                if item:FindFirstChildOfClass("TouchTransmitter") then
                    return item
                end
                fallback = fallback or item
            end
        end
        return fallback
    end
    function roundTools.getDroppedPart(now)
        return dropPart(findDrop(now))
    end

    local function updateGunMarker(drop, part)
        if options.gunMarker and part and not gunMarker then
            gunMarker = make("Highlight", visuals, {
                Name = "SoaresDroppedGun",
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                FillColor = Color3.fromRGB(97, 181, 255),
                OutlineColor = colors.white,
                FillTransparency = 0.48,
                OutlineTransparency = 0,
            })
        end
        if gunMarker then
            gunMarker.Enabled = options.gunMarker and part ~= nil
            gunMarker.Adornee = gunMarker.Enabled and (drop:IsA("Model") and drop or part) or nil
        end
    end

    local function farmHasPriority()
        return farm.active or (ui.pageName == "Farm" and window.Visible)
    end

    local function stopPickup(restorePosition, message)
        local job = roundTools.pickup
        roundTools.pickup = nil
        if job and job.moved and job.root.Parent == job.character and job.humanoid.Health > 0
            and player.Character == job.character and not farm.controlsCharacter then
            if restorePosition then
                job.root.CFrame = job.origin
                job.root.AssemblyLinearVelocity = job.velocity
            end
        end
        if message then status(message) end
    end

    local function pickupCanContinue(job)
        return state.running and roundTools.pickup == job and player.Character == job.character
            and job.humanoid.Health > 0 and not farmHasPriority()
            and not isEliminated(rowFor(player))
    end

    local function grabGun(automatic, drop, part)
        if roundTools.pickup then
            if not automatic then stopPickup(true, "Busca de arma cancelada.") end
            return
        end
        if not isMM2 or activeKill or roundTools.fling or farmHasPriority() then
            if not automatic then status("Coleta disponível no MM2 quando o avatar está livre.") end
            return
        end
        local character, humanoid, root = roundCharacter(player)
        if not character or root.Anchored or playerTool(player, "Knife") or playerTool(player, "Gun") then
            if not automatic then status("Busca de arma disponível para quem pode pegar a arma caída.") end
            return
        end
        if not drop then
            drop = findDrop(os.clock())
            part = dropPart(drop)
        end
        if not part then
            if not automatic then status("Aguardando a arma do Sheriff cair.") end
            return
        end
        local job = {
            automatic = automatic,
            character = character,
            humanoid = humanoid,
            root = root,
            origin = root.CFrame,
            velocity = root.AssemblyLinearVelocity,
        }
        roundTools.pickup = job
        task.spawn(function()
            local ok = pcall(function()
                if not pickupCanContinue(job) then return end
                if simulateTouch and part:IsDescendantOf(Workspace) then
                    touchPair(part, root)
                    task.wait(0.19)
                end
                if not pickupCanContinue(job) or playerTool(player, "Gun") then return end
                if options.moveForGun and part:IsDescendantOf(Workspace) then
                    local delta = part.Position - root.Position
                    local flat = Vector3.new(delta.X, 0, delta.Z)
                    local heading = flat.Magnitude > 0.03 and flat.Unit or Vector3.new(0, 0, -1)
                    local contact = part.Position - heading * 1.25
                    job.moved = true
                    root.CFrame = job.origin + (contact - job.origin.Position)
                    root.AssemblyLinearVelocity = heading * 16 + up * 3
                    task.wait(0.095)
                    if pickupCanContinue(job) and part:IsDescendantOf(Workspace) then
                        touchPair(part, root)
                    end
                    task.wait(0.24)
                end
            end)
            if roundTools.pickup ~= job then return end
            local gun = pickupCanContinue(job) and playerTool(player, "Gun")
            stopPickup(true)
            if not state.running then return end
            if gun then
                if options.equipGun and gun.Parent ~= character then
                    pcall(function()
                        humanoid:EquipTool(gun)
                    end)
                end
                status("Arma do Sheriff coletada.")
            elseif not automatic then
                status(ok and "Coleta aguardando confirmação do MM2." or "Busca da arma interrompida.")
            end
        end)
    end

    local function stopView()
        local view = roundTools.view
        roundTools.view = nil
        if view and view.camera.CameraSubject == view.subject then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                view.camera.CameraSubject = humanoid
            elseif view.previous and view.previous.Parent then
                view.camera.CameraSubject = view.previous
            end
        end
    end

    function roundTools.observe(target)
        if not isMM2 or farmHasPriority() then
            status("Observação disponível durante uma rodada do MM2.")
            return
        end
        local camera = Workspace.CurrentCamera
        if not camera or camera.CameraType == Enum.CameraType.Scriptable then return end
        local _, subject = roundCharacter(target)
        if not subject or target == player then
            status("Aguardando um jogador ativo para observar.")
            return
        end
        stopView()
        releaseTouchShift()
        roundTools.view = {camera = camera, target = target, subject = subject, previous = camera.CameraSubject}
        camera.CameraSubject = subject
        status("Observando " .. target.DisplayName .. ".")
    end
    local function startView(role)
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local target = findRole(role, camera.CFrame.Position)
        if target then
            roundTools.observe(target)
        else
            requestRoles()
            status("Aguardando " .. roleInfo[role].name .. " na rodada.")
        end
    end

    local function stopFling(restorePosition, message)
        local job = roundTools.fling
        roundTools.fling = nil
        if job and job.root.Parent == job.character then
            local root = job.root
            if not farm.controlsCharacter then
                root.CanCollide = job.collided
                if player.Character == job.character and job.humanoid.Health > 0 then
                    if restorePosition and options.returnAfterFling then
                        root.CFrame = job.origin
                    end
                    root.AssemblyLinearVelocity = zero
                    root.AssemblyAngularVelocity = zero
                end
            end
        end
        if job and job.humanoid.Parent and not farm.controlsCharacter then
            job.humanoid.PlatformStand = job.platformStand
            job.humanoid.AutoRotate = job.autoRotate
        end
        if message then status(message) end
    end

    local function startFling(role)
        if not isMM2 or farmHasPriority() or activeKill or roundTools.pickup then
            status("Fling disponível no MM2 quando o avatar está livre.")
            return
        end
        if roundTools.fling then
            stopFling(true, "Fling parado.")
            return
        end
        local character, humanoid, root = roundCharacter(player)
        if not character or root.Anchored then
            status("Aguardando seu personagem na rodada.")
            return
        end
        local target, _, targetRoot = findRole(role, root.Position)
        if not target or targetRoot.Anchored then
            requestRoles()
            status("Aguardando " .. roleInfo[role].name .. " disponível.")
            return
        end
        stopView()
        releaseTouchShift()
        local now = os.clock()
        roundTools.fling = {
            character = character,
            humanoid = humanoid,
            root = root,
            target = target,
            targetRoot = targetRoot,
            origin = root.CFrame,
            collided = root.CanCollide,
            platformStand = humanoid.PlatformStand,
            autoRotate = humanoid.AutoRotate,
            endsAt = now + options.duration,
            nextRush = now,
        }
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        status("Fling mirando " .. target.DisplayName .. ".")
    end

    local function stepFling(job)
        local now = os.clock()
        local _, _, targetRoot = roundCharacter(job.target)
        if now >= job.endsAt or targetRoot ~= job.targetRoot or targetRoot.Anchored then
            stopFling(true, "Fling finalizado.")
            return
        end
        if farmHasPriority() or player.Character ~= job.character or job.humanoid.Health <= 0 then
            stopFling(false)
            return
        end
        local root = job.root
        root.CanCollide = true
        if now < job.nextRush then
            return
        end
        job.nextRush = now + 0.18
        local offset = targetRoot.Position - root.Position
        local flat = Vector3.new(offset.X, 0, offset.Z)
        local direction = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, -1)
        local approach = targetRoot.Position - direction * 2.35 + up * 0.3
        local strength = options.force
        root.CFrame = CFrame.lookAt(approach, targetRoot.Position)
        root.AssemblyLinearVelocity = direction * strength + up * (strength * 0.12)
        root.AssemblyAngularVelocity = Vector3.new(strength * 0.36, strength * 0.72, strength * 0.28)
    end

    connect(RunService.PreSimulation, function()
        local job = roundTools.fling
        if job then
            local ok = pcall(stepFling, job)
            if not ok then stopFling(true, "Fling interrompido.") end
        end
    end)

    function roundTools.cancelForFarm()
        stopPickup(true)
        stopFling(true)
        stopView()
    end

    function roundTools.pauseCombat()
        stopKill(true)
        options.autoGun = false
        if refreshAutoGun then refreshAutoGun() end
        roundTools.cancelForFarm()
        state.aim = false
        optionRefresh.aim()
        lastAimState = nil
        status("Ações de combate pausadas.")
    end

    function roundTools.grab()
        grabGun(false)
    end

    function roundTools.restoreCamera()
        stopView()
        status("Câmera de volta ao seu personagem.")
    end

    function roundTools.shutdown()
        roundTools.cancelForFarm()
        alert.Visible = false
    end

    connect(player.CharacterRemoving, function()
        stopPickup(false)
        stopFling(false)
        stopView()
    end)

    function roundTools.wantsRoles()
        return options.autoGun or options.murderAlert or roundTools.fling or roundTools.view
            or (window.Visible and ui.pageName == "Troll")
    end

    function roundTools.tick(now)
        if alert.Visible and now >= alertUntil then
            alert.Visible = false
        end
        local view = roundTools.view
        if view then
            local _, humanoid = roundCharacter(view.target)
            if humanoid ~= view.subject or Workspace.CurrentCamera ~= view.camera
                or view.camera.CameraSubject ~= view.subject then
                stopView()
            end
        end
        if options.murderAlert then
            local _, _, root = roundCharacter(player)
            local target, _, targetRoot
            if root then
                target, _, targetRoot = findRole("Murderer", root.Position)
            end
            local nearby = target and (targetRoot.Position - root.Position).Magnitude <= 28
            if nearby and not murderNear then notify("Murder a menos de 28 studs") end
            murderNear = nearby == true
        end
        local drop, part
        if options.autoGun or options.gunMarker or options.gunAlert or (window.Visible and ui.pageName == "Combate") then
            drop = findDrop(now)
            part = dropPart(drop)
        end
        updateGunMarker(drop, part)
        if options.gunAlert and part and drop ~= lastAlertedDrop then
            lastAlertedDrop = drop
            notify("Arma do Sheriff no chão")
        elseif not part then
            lastAlertedDrop = nil
        end
        grabButton.Text = roundTools.pickup and "CANCELAR" or "BUSCAR"
        if roundTools.pickup then
            grabHint.Text = "Buscando arma do Sheriff."
        elseif part then
            local _, _, root = aliveCharacter(player)
            local distance = root and math.floor((part.Position - root.Position).Magnitude + 0.5)
            grabHint.Text = distance and ("Arma no chão · " .. distance .. " studs.") or "Arma no chão."
        else
            grabHint.Text = "Aguardando a arma do Sheriff cair."
        end
        if options.autoGun and part and now >= nextPickup and not roundTools.pickup and not farmHasPriority() then
            nextPickup = now + 1.2
            grabGun(true, drop, part)
        end
    end

    grabButton, grabHint = actionRow(combat, "Pegar arma agora", "Aguardando a arma do Sheriff cair.", "BUSCAR", function()
        grabGun(false)
    end)
    grabButton.Parent.LayoutOrder = -26
    for _, data in ipairs({
        {"autoGun", "Auto pegar arma", "Busca a arma caída assim que estiver livre."},
        {"moveForGun", "Encostar e voltar", "Aproxima o avatar e volta ao ponto de partida."},
        {"equipGun", "Equipar arma coletada", "Equipa a arma assim que entrar na mochila."},
        {"gunMarker", "Marcar arma caída", "Mostra o contorno azul e a distância no menu."},
        {"gunAlert", "Aviso de arma caída", "Mostra um aviso assim que a arma cair."},
        {"murderAlert", "Aviso de Murder perto", "Mostra um aviso quando o Murder estiver próximo."},
    }) do
        local key = data[1]
        local refresh, hint = toggle(combat, data[2], data[3], function()
            return options[key]
        end, function(value)
            if key == "autoGun" and not isMM2 then
                status("Abra o Murder Mystery 2 para usar a busca automática.")
                return
            end
            options[key] = value
            if key == "autoGun" then
                nextPickup = 0
                local job = roundTools.pickup
                if not value and job and job.automatic then stopPickup(true, "Busca automática desligada.") end
            elseif key == "murderAlert" then
                murderNear = false
            end
        end)
        if key == "autoGun" then
            hint.Parent.LayoutOrder = -27
            refreshAutoGun = refresh
        end
    end

    actionRow(troll, "Fling Murder", "Tenta empurrar o Murder por contato físico.", "FLING", function()
        startFling("Murderer")
    end)
    actionRow(troll, "Fling Sheriff", "Tenta empurrar o jogador armado por contato.", "FLING", function()
        startFling("Sheriff")
    end)
    actionRow(troll, "Parar Fling", "Cancela o próximo impulso do avatar.", "PARAR", function()
        if roundTools.fling then stopFling(true, "Fling parado.") end
    end)
    choiceRow(troll, "Força do Fling", "Define a força da aproximação e do giro.", {
        {"Leve", 170}, {"Forte", 310}, {"Turbo", 460},
    }, function() return options.force end, function(value) options.force = value end)
    choiceRow(troll, "Duração do Fling", "Define por quanto tempo tenta o contato.", {
        {"Curta", 0.65}, {"Normal", 1.15}, {"Longa", 1.7},
    }, function() return options.duration end, function(value) options.duration = value end)
    toggle(troll, "Voltar após Fling", "Retorna ao ponto inicial quando o efeito parar.", function()
        return options.returnAfterFling
    end, function(value) options.returnAfterFling = value end)
    toggle(troll, "Incluir Herói", "Aceita o Herói como alvo do Sheriff.", function()
        return options.includeHero
    end, function(value) options.includeHero = value end)
    actionRow(troll, "Observar Murder", "Segue o personagem do Murder pela câmera.", "OBSERVAR", function()
        startView("Murderer")
    end)
    actionRow(troll, "Observar Sheriff", "Segue o jogador armado pela câmera.", "OBSERVAR", function()
        startView("Sheriff")
    end)
    actionRow(troll, "Voltar à sua câmera", "Encerra a observação do outro jogador.", "VOLTAR", function()
        roundTools.restoreCamera()
    end)
end

-- Farm de moedas. O avatar voa por física e tenta a coleta pelo contato real.
do
    local page = pages.Farm
    local settings = {
        mode = "Subsolo",
        speed = 42,
        depth = 4.5,
        radius = 2.5,
        prone = true,
        sameFloor = false,
        marker = false,
        resume = true,
        returnToStart = true,
        hideOnStart = false,
    }
    local zero = Vector3.new(0, 0, 0)
    local up = Vector3.new(0, 1, 0)
    local proneRotation = CFrame.Angles(-math.pi / 2, 0, 0)
    local containers = {}
    local retryAfter = {}
    local flight
    local target
    local marker
    local lastContainer
    local contacts = 0
    local nextScan, nextDiscovery, nextDetail = 0, 0, 0
    local refreshSwitch
    local detail

    local function describe(message)
        if state.running and detail.Text ~= message then
            detail.Text = message
        end
    end

    local function updateMarker()
        if settings.marker and target and not marker then
            marker = make("Highlight", visuals, {
                Name = "SoaresCoinTarget",
                FillColor = Color3.fromRGB(255, 207, 76),
                FillTransparency = 0.4,
                OutlineColor = colors.white,
                OutlineTransparency = 0,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            })
        end
        if marker then
            marker.Enabled = settings.marker and target ~= nil
            marker.Adornee = marker.Enabled and (target.visual or target.part) or nil
        end
    end

    local function clearTarget()
        target = nil
        nextScan = 0
        updateMarker()
    end

    local function discoverContainers()
        for _, item in ipairs(Workspace:GetDescendants()) do
            if item.Name == "CoinContainer" then
                containers[item] = true
            end
        end
    end

    connect(Workspace.DescendantAdded, function(item)
        if farm.active and item.Name == "CoinContainer" then
            containers[item] = true
        end
    end)
    connect(Workspace.DescendantRemoving, function(item)
        containers[item] = nil
        retryAfter[item] = nil
    end)

    local function available(coin)
        return coin.object.Parent == coin.container and coin.part.Parent ~= nil
            and (coin.part == coin.object or coin.part:IsDescendantOf(coin.object))
            and coin.part.CanTouch and coin.container:IsDescendantOf(Workspace)
            and (not coin.visual or coin.visual:IsDescendantOf(coin.object))
            and (not coin.watchOpacity or coin.visual.Transparency < 0.99)
    end

    local function coinFrom(container, item)
        if item.Name ~= "Coin_Server" and item.Name ~= "CoinServer" and item.Name ~= "Coin" then
            return nil
        end
        local visual = item:FindFirstChild("CoinVisual", true)
        local hitbox = item
        if not hitbox:IsA("BasePart") then
            hitbox = item:FindFirstChild("Hitbox", true) or item:FindFirstChild("TouchPart", true)
                or (item:IsA("Model") and item.PrimaryPart)
                or item:FindFirstChildWhichIsA("BasePart", true)
        end
        if not hitbox or not hitbox:IsA("BasePart") or not hitbox.CanTouch then
            if not visual or not visual:IsA("BasePart") or not visual.CanTouch then
                return nil
            end
            hitbox = visual
        end
        if item.Name == "Coin_Server" and not visual then
            return nil
        end
        if visual and visual:IsA("BasePart") and visual.Transparency >= 0.99 then
            return nil
        end
        return {
            object = item,
            container = container,
            part = hitbox,
            visual = visual,
            watchOpacity = visual and visual:IsA("BasePart"),
        }
    end

    local function findCoin(position, now)
        local best
        local bestScore = math.huge
        for container in pairs(containers) do
            if not container:IsDescendantOf(Workspace) then
                containers[container] = nil
            elseif not flight or flight.container == container then
                for _, item in ipairs(container:GetChildren()) do
                    if (retryAfter[item] or 0) <= now then
                        local coin = coinFrom(container, item)
                        if coin then
                            local delta = coin.part.Position - position
                            local score = delta.Magnitude
                            if settings.sameFloor then
                                score = score + math.max(0, math.abs(delta.Y) - 4) * 2.5
                            end
                            if score < bestScore then
                                best = coin
                                bestScore = score
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function rememberPart(actor, part)
        if part:IsA("BasePart") and actor.collisions[part] == nil then
            actor.collisions[part] = part.CanCollide
            part.CanCollide = false
        end
    end

    local function floorHeight(actor, position)
        local hit = Workspace:Raycast(position + up * 0.25, up * -16, actor.floorRay)
        return hit and hit.Position.Y or position.Y - 1.8
    end

    local function takeFlight(character, humanoid, root, container)
        releaseTouchShift()
        local look = root.CFrame.LookVector
        local heading = Vector3.new(look.X, 0, look.Z)
        local actor = {
            character = character,
            humanoid = humanoid,
            root = root,
            container = container,
            origin = root.CFrame,
            heading = heading.Magnitude > 0.01 and heading.Unit or Vector3.new(0, 0, -1),
            autoRotate = humanoid.AutoRotate,
            platformStand = humanoid.PlatformStand,
            canTouch = root.CanTouch,
            collisions = {},
            floorRay = RaycastParams.new(),
            overlap = OverlapParams.new(),
        }
        flight = actor
        farm.controlsCharacter = true
        lastAimState = nil
        lastContainer = container
        actor.floorRay.FilterType = Enum.RaycastFilterType.Exclude
        actor.floorRay.FilterDescendantsInstances = {character, container}
        actor.floorRay.IgnoreWater = true
        actor.floorRay.RespectCanCollide = true
        actor.overlap.FilterType = Enum.RaycastFilterType.Include
        actor.overlap.FilterDescendantsInstances = {character}
        actor.standHeight = math.clamp(root.Position.Y - floorHeight(actor, root.Position), 2.5, 4.5)

        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
        root.CanTouch = true
        for _, part in ipairs(character:GetDescendants()) do
            rememberPart(actor, part)
        end
        actor.added = character.DescendantAdded:Connect(function(part)
            rememberPart(actor, part)
        end)
        actor.removing = character.DescendantRemoving:Connect(function(part)
            local original = actor.collisions[part]
            if original ~= nil then
                actor.collisions[part] = nil
                part.CanCollide = original
            end
        end)

        actor.attachment = make("Attachment", root, {Name = "SoaresFarmAttachment"})
        actor.velocity = make("LinearVelocity", root, {
            Name = "SoaresFarmVelocity",
            Attachment0 = actor.attachment,
            RelativeTo = Enum.ActuatorRelativeTo.World,
            VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
            ForceLimitsEnabled = false,
            VectorVelocity = zero,
        })
        actor.orientation = make("AlignOrientation", root, {
            Name = "SoaresFarmPose",
            Attachment0 = actor.attachment,
            Mode = Enum.OrientationAlignmentMode.OneAttachment,
            RigidityEnabled = true,
            CFrame = CFrame.lookAt(zero, actor.heading),
        })
    end

    local function releaseFlight(returnPosition)
        local actor = flight
        if not actor then
            return
        end
        flight = nil
        farm.controlsCharacter = false
        if actor.added then actor.added:Disconnect() end
        if actor.removing then actor.removing:Disconnect() end
        if actor.velocity then actor.velocity:Destroy() end
        if actor.orientation then actor.orientation:Destroy() end
        if actor.attachment then actor.attachment:Destroy() end
        local root, humanoid = actor.root, actor.humanoid
        if root.Parent then
            root.CanTouch = actor.canTouch
            root.AssemblyLinearVelocity = zero
            root.AssemblyAngularVelocity = zero
            if humanoid.Health > 0 and player.Character == actor.character then
                if returnPosition and actor.container:IsDescendantOf(Workspace) then
                    root.CFrame = settings.returnToStart and actor.origin or actor.safeExit or actor.origin
                else
                    root.CFrame = CFrame.lookAt(root.Position, root.Position + actor.heading)
                end
            end
        end
        if humanoid.Parent then
            humanoid.PlatformStand = actor.platformStand
            humanoid.AutoRotate = actor.autoRotate
        end
        for part, original in pairs(actor.collisions) do
            if part.Parent then
                part.CanCollide = original
            end
        end
    end

    function farm.stop(message)
        farm.active = false
        clearTarget()
        releaseFlight(true)
        table.clear(containers)
        table.clear(retryAfter)
        lastContainer = nil
        if state.running then
            refreshSwitch()
            describe(message or string.format("Desligado. %d contatos nesta sessão.", contacts))
            if message then
                status(message)
            end
        end
    end

    local function beginPhase(coin, phase, now)
        coin.phase = phase
        coin.bestDistance = math.huge
        coin.lastProgress = now
    end

    local function plan(coin, now)
        local rootPosition = flight.root.Position
        local coinPosition = coin.part.Position
        local targetFloor = floorHeight(flight, coinPosition)
        local minY = Workspace.FallenPartsDestroyHeight + 7
        local entryY = math.max(minY, floorHeight(flight, rootPosition) - settings.depth)
        local tunnelY = math.max(minY, targetFloor - settings.depth)
        coin.entry = Vector3.new(rootPosition.X, entryY, rootPosition.Z)
        coin.tunnel = Vector3.new(coinPosition.X, tunnelY, coinPosition.Z)
        coin.exitPosition = Vector3.new(coinPosition.X, targetFloor + flight.standHeight, coinPosition.Z)
        beginPhase(coin, settings.mode == "Subsolo" and "Descendo" or "Coleta", now)
    end

    local function flyTo(position, speed)
        local delta = position - flight.root.Position
        local distance = delta.Magnitude
        local forward = Vector3.new(delta.X, 0, delta.Z)
        if forward.Magnitude > 0.12 then
            flight.heading = forward.Unit
        end
        local orientation = CFrame.lookAt(zero, flight.heading)
        flight.orientation.CFrame = settings.prone and orientation * proneRotation or orientation
        flight.velocity.VectorVelocity = distance > 0.035
            and delta * math.min(speed / distance, 12) or zero
        return distance
    end

    local function touchPart(coin, distance)
        if distance > settings.radius then
            return nil
        end
        for _, part in ipairs(Workspace:GetPartsInPart(coin.part, flight.overlap)) do
            if part.CanTouch then
                return part
            end
        end
    end

    local function noteContact(coin, part, now)
        coin.contactAt = now
        contacts = contacts + 1
        local position = coin.exitPosition
        flight.safeExit = CFrame.lookAt(position, position + flight.heading)
        if simulateTouch then
            local hitbox = coin.part
            pcall(simulateTouch, hitbox, part, 0)
            task.delay(0.04, function()
                if hitbox.Parent and part.Parent then
                    pcall(simulateTouch, hitbox, part, 1)
                end
            end)
        end
    end

    local function moveToCoin(now)
        if not target.phase then
            plan(target, now)
        end
        local distance
        if target.phase == "Descendo" then
            distance = flyTo(target.entry, settings.speed)
            if distance <= 0.42 then
                beginPhase(target, "Subsolo", now)
                return
            end
        elseif target.phase == "Subsolo" then
            distance = flyTo(target.tunnel, settings.speed)
            if distance <= 0.42 then
                beginPhase(target, "Coleta", now)
                return
            end
        else
            local position = target.part.Position
            local remaining = (position - flight.root.Position).Magnitude
            local speed = remaining <= settings.radius and math.min(settings.speed, 10) or settings.speed
            distance = flyTo(position, speed)
            if not target.contactAt then
                local part = touchPart(target, distance)
                if part then
                    noteContact(target, part, now)
                end
            end
        end

        if distance < target.bestDistance - 0.1 then
            target.bestDistance = distance
            target.lastProgress = now
        end
        local contactTimeout = target.contactAt and now - target.contactAt >= 0.65
        if contactTimeout or now - target.lastProgress > 2.4 then
            retryAfter[target.object] = now + 3.5
            clearTarget()
            return
        end
        if now >= nextDetail then
            nextDetail = now + 0.18
            local remaining = (target.part.Position - flight.root.Position).Magnitude
            describe(string.format("%s · %.0f studs · %d contatos", target.phase, remaining, contacts))
        end
    end

    local function step()
        local now = os.clock()
        local character, humanoid, root = aliveCharacter(player)
        local entry = rowFor(player)
        local unavailable = not root or root.Anchored or isEliminated(entry) or (hasRoundData() and not entry)
        local roundEnded = lastContainer and not lastContainer:IsDescendantOf(Workspace)
        if unavailable or roundEnded then
            clearTarget()
            releaseFlight(false)
            if lastContainer and not settings.resume then
                farm.stop("Auto Farm parado no fim da rodada.")
            else
                if roundEnded then lastContainer = nil end
                describe("Aguardando entrar em uma rodada.")
            end
            return
        end
        if flight and (flight.character ~= character or flight.root ~= root) then
            clearTarget()
            releaseFlight(false)
        end
        if target and not available(target) then
            clearTarget()
        end
        if not target then
            if now < nextScan then
                return
            end
            if not next(containers) and now >= nextDiscovery then
                nextDiscovery = now + 2
                discoverContainers()
            end
            target = findCoin(root.Position, now)
            if not target then
                nextScan = now + 0.35
                releaseFlight(true)
                describe("Aguardando moedas disponíveis.")
                return
            end
            if not flight then
                takeFlight(character, humanoid, root, target.container)
            end
            updateMarker()
        end

        for part in pairs(flight.collisions) do
            if part.Parent and part.CanCollide then
                part.CanCollide = false
            end
        end
        moveToCoin(now)
    end

    refreshSwitch, detail = toggle(page, "Auto Farm de moedas", "Desligado. Escolha o trajeto abaixo.", function()
        return farm.active
    end, function(enabled)
        if not enabled then
            farm.stop()
            return
        end
        if not isMM2 then
            status("Abra o Murder Mystery 2 para usar o Auto Farm.")
            return
        end
        if activeKill then
            status("Pare o Kill All antes de ligar o Auto Farm.")
            return
        end
        farm.active = true
        contacts = 0
        nextScan, nextDetail = 0, 0
        nextDiscovery = os.clock() + 2
        discoverContainers()
        requestRoles()
        describe("Procurando moedas da rodada.")
        status("Auto Farm ligado.")
        if settings.hideOnStart then
            setMenu(false)
        end
    end)

    local function choices(titleText, description, key, values, onChange)
        local row = card(page, 95)
        cardCopy(row, titleText, description, 20)
        local actions = {}
        local width = 1 / #values
        local function refresh()
            for _, item in ipairs(values) do
                local selected = settings[key] == item[2]
                actions[item[2]].BackgroundColor3 = selected and colors.ink or colors.paper
                actions[item[2]].TextColor3 = selected and colors.white or colors.ink
            end
        end
        for index, item in ipairs(values) do
            local action = button(row, item[1], 11)
            action.Position = UDim2.new((index - 1) * width, 7, 0, 55)
            action.Size = UDim2.new(width, -14, 0, 29)
            actions[item[2]] = action
            connect(action.Activated, function()
                settings[key] = item[2]
                if onChange then onChange() end
                refresh()
            end)
        end
        refresh()
    end

    local function replan()
        if target and not target.contactAt then
            target.phase = nil
        end
    end
    choices("Trajeto", "Subsolo passa sob o piso de cada andar.", "mode", {
        {"Subsolo", "Subsolo"}, {"Voo direto", "Voo direto"},
    }, replan)
    choices("Velocidade de voo", "Escolha a velocidade de viagem entre moedas.", "speed", {
        {"Lento", 28}, {"Rápido", 42},
    })
    choices("Profundidade", "Distância abaixo do piso no modo Subsolo.", "depth", {
        {"Raso", 2.5}, {"Médio", 4.5}, {"Fundo", 7},
    }, replan)
    choices("Raio de aproximação", "Faixa em que o voo desacelera para o contato.", "radius", {
        {"1,5 studs", 1.5}, {"2,5 studs", 2.5}, {"4 studs", 4},
    })

    for _, optionData in ipairs({
        {"prone", "De bruço", "Voa de barriga para baixo."},
        {"sameFloor", "Priorizar mesmo andar", "Prefere o mesmo nível e ainda sobe se precisar."},
        {"marker", "Marcar moeda atual", "Destaca o próximo alvo em dourado."},
        {"resume", "Retomar próxima rodada", "Espera novas moedas depois que a rodada termina."},
        {"returnToStart", "Voltar ao início", "OFF sai de pé perto do último alvo tocado."},
        {"hideOnStart", "Minimizar ao ligar", "Reabra pelo botão SOARES para desligar."},
    }) do
        local key = optionData[1]
        toggle(page, optionData[2], optionData[3], function()
            return settings[key]
        end, function(enabled)
            settings[key] = enabled
            if key == "marker" then
                updateMarker()
            end
        end)
    end

    connect(RunService.PreSimulation, function()
        if farm.active then
            local ok = pcall(step)
            if not ok then
                farm.stop("Auto Farm interrompido. Ligue de novo para tentar.")
            end
        end
    end)
    connect(player.CharacterRemoving, function()
        if farm.active then
            clearTarget()
            releaseFlight(false)
            if not settings.resume then
                farm.stop("Auto Farm parado na troca de personagem.")
            end
        end
    end)
end

-- Perfis gráficos locais. Cada propriedade alterada é registrada para restauração.
local graphicsTools = {}
do
    local profiles = {
        Original = {},
        Alto = {shadows = true, specular = 1, diffuse = 1, quality = "Level21"},
        Baixo = {noShadows = true, noParticles = true, noPost = true, specular = 0, quality = "Level04"},
        Massinha = {
            noShadows = true,
            noParticles = true,
            noPost = true,
            noLights = true,
            noTextures = true,
            noFog = true,
            plastic = true,
            specular = 0,
            quality = "Level01",
        },
    }
    local originals = {}
    local graphicsGeneration = 0
    local graphicsRendering
    pcall(function()
        graphicsRendering = settings().Rendering
    end)

    local function change(instance, key, value)
        if value == nil then
            return
        end
        local ok, before = pcall(function()
            return instance[key]
        end)
        if not ok or before == value then
            return
        end
        local applied = pcall(function()
            instance[key] = value
        end)
        if not applied then
            return
        end
        local fields = originals[instance]
        if not fields then
            fields = {}
            originals[instance] = fields
        end
        fields[key] = {before = before, set = value}
    end

    local function restore(instance)
        local fields = originals[instance]
        if not fields then
            return
        end
        originals[instance] = nil
        for key, record in pairs(fields) do
            pcall(function()
                if instance[key] == record.set then
                    instance[key] = record.before
                end
            end)
        end
    end

    local function restoreAll()
        for instance in pairs(originals) do
            restore(instance)
        end
    end

    local function belongsToCharacter(instance)
        local model = instance:FindFirstAncestorOfClass("Model")
        while model do
            if model:FindFirstChildOfClass("Humanoid") then
                return true
            end
            model = model:FindFirstAncestorOfClass("Model")
        end
        return false
    end

    local function paint(instance)
        local graphics = state.graphics
        if graphics.noPost and instance:IsA("PostEffect") then
            change(instance, "Enabled", false)
        elseif graphics.noLights and instance:IsA("Light") then
            change(instance, "Enabled", false)
        elseif graphics.noParticles and (
            instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")
            or instance:IsA("Smoke") or instance:IsA("Sparkles") or instance:IsA("Fire")
        ) then
            change(instance, "Enabled", false)
        elseif graphics.noFog and instance:IsA("Atmosphere") then
            change(instance, "Density", 0)
            change(instance, "Haze", 0)
            change(instance, "Glare", 0)
        end

        if (graphics.plastic or graphics.noReflections) and instance:IsA("BasePart") and not belongsToCharacter(instance) then
            if graphics.plastic then
                change(instance, "MaterialVariant", "")
                change(instance, "Material", Enum.Material.SmoothPlastic)
            end
            change(instance, "Reflectance", 0)
        end
        if graphics.noTextures then
            if (instance:IsA("Decal") or instance:IsA("Texture")) and not belongsToCharacter(instance) then
                change(instance, "Transparency", 1)
            elseif instance:IsA("MeshPart") and not belongsToCharacter(instance) then
                change(instance, "TextureID", "")
            elseif instance:IsA("SpecialMesh") and not belongsToCharacter(instance) then
                change(instance, "TextureId", "")
            end
        end
    end

    local function graphicsNeedScan()
        local g = state.graphics
        return g.noPost or g.noLights or g.noParticles or g.noFog or g.plastic or g.noTextures or g.noReflections
    end

    local function applyGraphics()
        graphicsGeneration = graphicsGeneration + 1
        local generation = graphicsGeneration
        restoreAll()

        local graphics = state.graphics
        if graphics.noShadows then
            change(Lighting, "GlobalShadows", false)
        elseif graphics.shadows then
            change(Lighting, "GlobalShadows", true)
        end
        change(Lighting, "EnvironmentDiffuseScale", graphics.diffuse)
        change(Lighting, "EnvironmentSpecularScale", graphics.noReflections and 0 or graphics.specular)
        if graphics.fov and Workspace.CurrentCamera then
            change(Workspace.CurrentCamera, "FieldOfView", graphics.fov)
        end
        if graphics.noFog then
            change(Lighting, "FogEnd", 100000)
        end
        if graphics.quality and graphicsRendering then
            change(graphicsRendering, "QualityLevel", Enum.QualityLevel[graphics.quality])
        end
        if not graphicsNeedScan() then
            return
        end

        task.spawn(function()
            for _, scope in ipairs({Lighting, Workspace}) do
                for index, instance in ipairs(scope:GetDescendants()) do
                    if generation ~= graphicsGeneration or not state.running then
                        return
                    end
                    if instance:IsDescendantOf(scope) then
                        paint(instance)
                    end
                    if index % 200 == 0 then
                        task.wait()
                    end
                end
            end
        end)
    end

    connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        if state.graphics.fov then applyGraphics() end
    end)

    for _, scope in ipairs({Lighting, Workspace}) do
        connect(scope.DescendantAdded, function(instance)
            if graphicsNeedScan() then
                task.defer(function()
                    if state.running and instance:IsDescendantOf(scope) then
                        paint(instance)
                    end
                end)
            end
        end)
        connect(scope.DescendantRemoving, restore)
    end

    local graphicsPage = pages["Gráficos"]
    local presetRow = card(graphicsPage, 77)
    local presetTitle = label(presetRow, "Perfil gráfico", 13, Enum.Font.GothamBold)
    presetTitle.Position = UDim2.fromOffset(10, 7)
    presetTitle.Size = UDim2.new(1, -20, 0, 17)
    local presetButtons = {}
    local graphicsToggles = {}

    local function refreshGraphicsControls()
        for key, action in pairs(presetButtons) do
            local selected = key == state.profile
            paintChoice(action, selected)
        end
        for _, refresh in ipairs(graphicsToggles) do
            refresh()
        end
    end

    for index, name in ipairs({"Original", "Alto", "Baixo", "Massinha"}) do
        local action = button(presetRow, name, 11)
        action.Position = UDim2.new((index - 1) / 4, 7, 0, 35)
        action.Size = UDim2.new(1 / 4, -14, 0, 31)
        presetButtons[name] = action
        connect(action.Activated, function()
            state.profile = name
            state.graphics = {}
            for property, value in pairs(profiles[name]) do
                state.graphics[property] = value
            end
            applyGraphics()
            refreshGraphicsControls()
            status(name == "Original" and "Gráficos originais restaurados." or "Perfil " .. name .. " aplicado.")
        end)
    end

    for _, setting in ipairs({
        {"noShadows", "Reduzir sombras", "Desliga as sombras globais."},
        {"noParticles", "Ocultar partículas", "Esconde partículas, feixes e rastros."},
        {"noPost", "Ocultar pós-efeitos", "Desliga bloom, desfoque e filtros de cor."},
        {"noLights", "Ocultar luzes", "Desliga luzes dinâmicas do mapa."},
        {"noTextures", "Ocultar texturas", "Oculta texturas comuns do cenário."},
        {"noFog", "Reduzir névoa", "Reduz névoa e brilho da atmosfera."},
        {"plastic", "Material liso", "Troca os materiais do cenário por plástico."},
        {"noReflections", "Reduzir reflexos", "Remove o reflexo das superfícies do cenário."},
    }) do
        local key = setting[1]
        local refresh = toggle(graphicsPage, setting[2], setting[3], function()
            return state.graphics[key] == true
        end, function(value)
            state.graphics[key] = value
            applyGraphics()
        end)
        table.insert(graphicsToggles, refresh)
    end

    local refreshFov = choiceRow(graphicsPage, "Campo de visão", "Ajusta o ângulo da câmera local.", {
        {"Original", 0}, {"80°", 80}, {"92°", 92},
    }, function()
        return state.graphics.fov or 0
    end, function(value)
        state.graphics.fov = value > 0 and value or nil
        applyGraphics()
    end)
    table.insert(graphicsToggles, refreshFov)

    option(graphicsPage, "showFps", "Contador de FPS", "Mostra os FPS no rodapé do menu.", function(enabled)
        frameCount, elapsed = 0, 0
        ui.fps.Text = ""
        ui.status.Size = UDim2.new(1, enabled and -72 or -16, 1, 0)
    end)
    refreshGraphicsControls()

    graphicsTools.apply = applyGraphics
    graphicsTools.refresh = refreshGraphicsControls
    graphicsTools.profiles = profiles
    function graphicsTools.shutdown()
        graphicsGeneration = graphicsGeneration + 1
        restoreAll()
    end
end

-- Catálogo e equipamento cosmético da aba Visual.
local function setupVisualPage()
    local page = pages.Visual
    local kinds = {"Knife", "Gun"}
    local kindName = {Knife = "Faca", Gun = "Arma"}
    local rarityColors = {
        Common = colors.muted,
        Uncommon = Color3.fromRGB(116, 221, 153),
        Rare = Color3.fromRGB(104, 178, 255),
        Legendary = Color3.fromRGB(255, 124, 137),
        Godly = colors.pink,
        Ancient = colors.violet,
        Unique = Color3.fromRGB(255, 210, 117),
        Chroma = colors.accent,
    }
    local controls, cards = {}, {}
    local catalog, equipped, body = {}, {}, {}
    local savedTools, savedImages, savedHolsters = {}, {}, {}
    local settings = {hotbar = true, body = true, equipScreen = true, result = true, tradePreview = true}
    local opened, loading = false, false
    local filter, pageNumber, rowsPerPage = "Tudo", 1, 7
    local preview, previewWorld
    local nextNativeCheck = 0

    local function asset(value)
        if type(value) == "number" then
            if value > 0 and value < math.huge then return "rbxassetid://" .. string.format("%.0f", value) end
        elseif type(value) == "string" then
            local digits = value:match("^rbxassetid://(%d+)$") or value:match("^%s*(%d+)%s*$")
            if digits and tonumber(digits) > 0 then return "rbxassetid://" .. digits end
            if value:match("^rbxthumb://type=Asset&id=%d+&w=%d+&h=%d+$") or value:match("^rbxasset://textures/") then
                return value
            end
            local host = value:match("^https?://([^/]+)/")
            if host == "www.roblox.com" or host == "roblox.com" or host == "assetdelivery.roblox.com" then
                local id = value:match("[?&]id=(%d+)")
                if id then return "rbxassetid://" .. id end
            end
        end
    end

    local function firstAsset(data, keys)
        for _, key in ipairs(keys) do
            local value = asset(data[key])
            if value then return value end
        end
    end

    local function category(value)
        if type(value) ~= "string" then return nil end
        local key = value:lower()
        if key == "knife" or key == "knives" then return "Knife" end
        if key == "gun" or key == "guns" then return "Gun" end
    end

    local function readCatalog()
        local rows, byKey, modules = {}, {}, {}
        local function addModule(instance)
            if instance and instance:IsA("ModuleScript") then table.insert(modules, instance) end
        end
        local database = ReplicatedStorage:FindFirstChild("Database")
        local sync = database and database:FindFirstChild("Sync")
        addModule(sync)
        if sync then
            addModule(sync:FindFirstChild("Item"))
            addModule(sync:FindFirstChild("Items"))
            addModule(sync:FindFirstChild("Weapons"))
        end
        if database then addModule(database:FindFirstChild("Item")) end
        addModule(ReplicatedStorage:FindFirstChild("ItemDatabase"))

        local function collect(source, defaultKind, grouped)
            if type(source) ~= "table" then return end
            for key, data in pairs(source) do
                if type(data) == "table" then
                    local kind = category(data.ItemType) or category(data.WeaponType) or category(data.Type) or defaultKind
                    if kind then
                        local display = type(data.ItemName) == "string" and data.ItemName or data.Name
                        if type(display) ~= "string" or display == "" then display = tostring(key) end
                        local id = type(key) == "string" and key or tostring(data.ItemId or data.Id or display)
                        local identity = kind .. "/" .. id
                        if not byKey[identity] then
                            local rarity = data.Chroma == true and "Chroma" or data.Rarity
                            local entry = {
                                id = id, identity = identity, name = display, kind = kind,
                                rarity = type(rarity) == "string" and rarity or "Comum",
                                icon = firstAsset(data, {"Image", "ImageId", "ImageID", "ItemImage", "Icon", "IconId", "Thumbnail", "Thumb"}),
                                mesh = firstAsset(data, {"MeshId", "MeshID", "MeshAssetId", "Mesh"}),
                                texture = firstAsset(data, {"TextureId", "TextureID", "Texture", "SkinTexture"}),
                                model = data.Model or data.ModelName or data.WeaponModel,
                            }
                            byKey[identity] = entry
                            table.insert(rows, entry)
                        end
                    elseif grouped then
                        local kindGroup = category(key)
                        if kindGroup then collect(data, kindGroup, false) end
                    end
                end
            end
        end

        for _, module in ipairs(modules) do
            local ok, data = pcall(require, module)
            if ok and type(data) == "table" then
                collect(data.Weapons, nil, true)
                collect(data.Item, nil, true)
                collect(data.Items, nil, true)
                if type(data.Item) == "table" then collect(data.Item.Weapons, nil, true) end
                if #rows == 0 then collect(data, nil, true) end
            end
            if #rows > 0 then break end
        end
        table.sort(rows, function(a, b)
            if a.name == b.name then return a.identity < b.identity end
            return a.name:lower() < b.name:lower()
        end)
        return rows, byKey
    end

    local function findModel(entry)
        if entry.source and entry.source.Parent then return entry.source end
        if typeof(entry.model) == "Instance" and entry.model:IsDescendantOf(ReplicatedStorage) then
            entry.source = entry.model
            return entry.source
        end
        local keys = {entry.id, entry.name}
        if type(entry.model) == "string" and not asset(entry.model) then table.insert(keys, entry.model) end
        local roots = {}
        local function addRoots(parent)
            if not parent then return end
            for _, name in ipairs({"Weapons", "WeaponModels", "ItemModels", "WeaponAssets"}) do
                local root = parent:FindFirstChild(name)
                if root then table.insert(roots, root) end
            end
        end
        addRoots(ReplicatedStorage)
        addRoots(ReplicatedStorage:FindFirstChild("Assets"))
        addRoots(ReplicatedStorage:FindFirstChild("Models"))
        addRoots(ReplicatedStorage:FindFirstChild("Database"))
        for _, root in ipairs(roots) do
            local group = root:FindFirstChild(entry.kind == "Knife" and "Knives" or "Guns") or root
            for _, name in ipairs(keys) do
                local item = group:FindFirstChild(name, true)
                if item and (item:IsA("Model") or item:IsA("BasePart") or item:IsA("Tool") or item:IsA("Folder")) then
                    if name ~= entry.kind or entry.texture or entry.id == entry.kind then
                        entry.source = item
                        if not entry.icon and item:IsA("Tool") then entry.icon = asset(item.TextureId) end
                        return item
                    end
                end
            end
        end
    end

    local function cleanPart(part, texture)
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("SpecialMesh") or child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                if texture and child:IsA("SpecialMesh") then child.TextureId = texture end
                for _, nested in ipairs(child:GetChildren()) do nested:Destroy() end
            else
                child:Destroy()
            end
        end
        if texture and part:IsA("MeshPart") then
            pcall(function() part.TextureID = texture end)
        end
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Massless = true
    end

    local function buildModel(entry)
        local source = findModel(entry)
        if not source and not entry.mesh then return nil end
        local model = make("Model", nil, {Name = "GhostLocal" .. entry.kind .. "Skin"})
        local count = 0
        if source then
            local pieces = source:IsA("BasePart") and {source} or source:GetDescendants()
            for _, piece in ipairs(pieces) do
                if piece:IsA("BasePart") and count < 24 then
                    local ok, copy = pcall(function() return piece:Clone() end)
                    if ok and copy then
                        cleanPart(copy, entry.texture)
                        copy.Parent = model
                        count = count + 1
                    end
                end
            end
        end
        if count == 0 and entry.mesh then
            local part = make("Part", model, {
                Size = entry.kind == "Knife" and Vector3.new(0.6, 2.4, 0.35) or Vector3.new(1.65, 0.95, 0.4),
                CFrame = CFrame.new(),
            })
            make("SpecialMesh", part, {MeshType = Enum.MeshType.FileMesh, MeshId = entry.mesh, TextureId = entry.texture or ""})
            cleanPart(part, entry.texture)
            count = 1
        end
        if count == 0 then
            model:Destroy()
            return nil
        end
        return model
    end

    local function syncOverrides(saved, desired, property)
        for object, old in pairs(saved) do
            if not object.Parent or not desired[object] then
                if object.Parent then
                    pcall(function()
                        if object[property] == old.applied then object[property] = old.original end
                    end)
                end
                saved[object] = nil
            end
        end
        for object, value in pairs(desired) do
            if object.Parent then
                pcall(function()
                    local previous = object[property]
                    if previous ~= value then
                        local old = saved[object]
                        if not old or previous ~= old.applied then
                            old = {original = previous}
                            saved[object] = old
                        end
                        object[property] = value
                        old.applied = value
                    end
                end)
            end
        end
    end

    local function syncTools()
        local desired = {}
        if settings.hotbar then
            for _, kind in ipairs(kinds) do
                local entry = equipped[kind]
                local tool = entry and entry.icon and playerTool(player, kind)
                if tool then desired[tool] = entry.icon end
            end
        end
        syncOverrides(savedTools, desired, "TextureId")
    end

    local function destroyBody(kind)
        local current = body[kind]
        if current then
            if current.object then current.object:Destroy() end
            body[kind] = nil
        end
    end

    local function image(parent, size, position)
        return make("ImageLabel", parent, {
            Size = size, Position = position,
            BackgroundTransparency = 1,
            Image = "",
            ScaleType = Enum.ScaleType.Fit,
        })
    end

    local function mount(entry, anchor)
        local offset
        if entry.kind == "Knife" then
            offset = CFrame.new(0.05, 0.04, anchor.Size.Z / 2 + 0.19) * CFrame.Angles(0, 0, math.rad(30))
        else
            offset = CFrame.new(anchor.Size.X / 2 + 0.24, -anchor.Size.Y * 0.42, 0.03)
                * CFrame.Angles(0, math.pi / 2, math.rad(-14))
        end
        local model = buildModel(entry)
        if model then
            local bounds, size = model:GetBoundingBox()
            local maximum = math.max(size.X, size.Y, size.Z)
            if maximum > 4.8 then
                model:ScaleTo(4.8 / maximum)
                bounds = model:GetBoundingBox()
            end
            model:PivotTo(anchor.CFrame * offset * bounds:ToObjectSpace(model:GetPivot()))
            for _, part in ipairs(model:GetChildren()) do
                make("WeldConstraint", part, {Part0 = anchor, Part1 = part})
                part.Anchored = false
            end
            model.Parent = anchor.Parent
            return model, true
        elseif entry.icon then
            local holder = make("Attachment", anchor, {Name = "GhostSkinIcon", CFrame = offset})
            local badge = make("BillboardGui", holder, {
                Name = "GhostSkinBadge", Adornee = holder,
                AlwaysOnTop = false, MaxDistance = 24, Size = UDim2.fromOffset(36, 36),
            })
            image(badge, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0)).Image = entry.icon
            return holder, false
        end
    end

    local function syncBody()
        local character = settings.body and not farm.active and aliveCharacter(player)
        local hide = {}
        for _, kind in ipairs(kinds) do
            local entry = equipped[kind]
            local held = character and character:FindFirstChild(kind)
            held = held and held:IsA("Tool")
            local torso = character and (character:FindFirstChild(kind == "Knife" and "UpperTorso" or "LowerTorso")
                or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
            local current = body[kind]
            if current and (current.character ~= character or current.entry ~= entry or current.anchor ~= torso
                or held or (current.object and not current.object.Parent)) then
                destroyBody(kind)
                current = nil
            end
            if entry and torso and torso:IsA("BasePart") and not held and not current then
                local object, isModel = mount(entry, torso)
                current = {entry = entry, character = character, anchor = torso, object = object, isModel = isModel}
                body[kind] = current
            end
            if current and current.isModel then
                local display = character:FindFirstChild(kind .. "Display")
                if display then
                    if display:IsA("BasePart") then hide[display] = 1 end
                    for _, part in ipairs(display:GetDescendants()) do
                        if part:IsA("BasePart") then hide[part] = 1 end
                    end
                end
            end
        end
        syncOverrides(savedHolsters, hide, "LocalTransparencyModifier")
    end

    local function normalize(name)
        return (name:lower():gsub("[^%w]", ""))
    end

    local equipNames = {equip = true, equipped = true, equippeditems = true, equippedweapons = true, loadout = true}
    local resultNames = {
        roundend = true, endround = true, roundover = true, roundending = true, roundendingframe = true,
        roundendingscreen = true, roundresults = true, endofround = true,
        victory = true, victoryframe = true, victoryscreen = true,
    }
    local tradeNames = {
        trade = true, tradeframe = true, tradegui = true, tradepanel = true,
        tradewindow = true, trademenu = true, tradescreen = true, tradeui = true,
    }
    local roleCards = {
        murderer = "Knife", murder = "Knife", murdererframe = "Knife", murdererinfo = "Knife",
        sheriff = "Gun", sheriffframe = "Gun", sheriffinfo = "Gun", hero = "Gun", heroframe = "Gun",
        winner = true, winnercard = true, winnerframe = true, playercard = true,
    }

    local function withinUi(node, checkVisible)
        while node and node ~= playerGui do
            local name = normalize(node.Name)
            if node == ui.gui or name:find("trade", 1, true) or name:find("shop", 1, true)
                or name:find("purchase", 1, true) then
                return false
            end
            if checkVisible then
                if node:IsA("GuiObject") and not node.Visible then return false end
                if node:IsA("ScreenGui") and not node.Enabled then return false end
            end
            node = node.Parent
        end
        return node == playerGui
    end

    local function isImage(object)
        return object and (object:IsA("ImageLabel") or object:IsA("ImageButton"))
    end

    local function iconIn(slot)
        if isImage(slot) then return slot end
        if slot then
            for _, name in ipairs({"WeaponIcon", "ItemIcon", "Icon", "ItemImage", "Image"}) do
                local candidate = slot:FindFirstChild(name, true)
                if isImage(candidate) then return candidate end
            end
        end
    end

    local function weaponIcon(panel, kind, useGeneric)
        for _, name in ipairs({kind .. "Icon", kind .. "Image", kind .. "Slot", kind}) do
            local slot = panel:FindFirstChild(name, true)
            local icon = iconIn(slot)
            if icon and withinUi(icon, true) then return icon end
        end
        local generic = useGeneric and iconIn(panel)
        if generic and withinUi(generic, true) then return generic end
    end

    local function ownsResultCard(card)
        local owner = tonumber(card:GetAttribute("UserId"))
        if owner and owner > 0 then return owner == player.UserId end
        for _, name in ipairs({"PlayerName", "Username", "DisplayName", "Name"}) do
            local title = card:FindFirstChild(name, true)
            if title and title:IsA("TextLabel") then
                local text = title.Text:gsub("^@", "")
                if text == player.Name or text == player.DisplayName then return true end
            end
        end
        return false
    end

    local function updateResultsOverlay(show)
        controls.resultOverlay.Visible = show and not window.Visible
        for _, kind in ipairs(kinds) do
            local entry = equipped[kind]
            controls.resultSlots[kind].Image = entry and entry.icon or ""
        end
    end

    local function visibleInPlayerGui(node)
        while node and node ~= playerGui do
            if node:IsA("GuiObject") and not node.Visible then return false end
            if node:IsA("ScreenGui") and not node.Enabled then return false end
            node = node.Parent
        end
        return node == playerGui
    end

    local function tradePanel(node)
        if not tradeNames[normalize(node.Name)] or not visibleInPlayerGui(node) then return nil end
        if node:IsA("GuiObject") then return node end
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then return child end
        end
    end

    local function findOpenTrade(main)
        if main then
            for _, node in ipairs(main:GetDescendants()) do
                local panel = tradePanel(node)
                if panel then return panel end
            end
        end
        for _, child in ipairs(playerGui:GetChildren()) do
            local panel = tradePanel(child)
            if panel then return panel end
        end
    end

    local function updateTradePreview(trade)
        local overlay = controls.tradeOverlay
        overlay.Visible = trade ~= nil and settings.tradePreview
        if not overlay.Visible then return end
        local bounds = screen.AbsoluteSize
        local width, height = math.min(244, math.max(1, bounds.X - 16)), 54
        local position = trade.AbsolutePosition - screen.AbsolutePosition
        local size = trade.AbsoluteSize
        local x, y = (bounds.X - width) / 2, 8
        if bounds.X - position.X - size.X >= width + 16 then
            x, y = position.X + size.X + 8, position.Y
        elseif position.X >= width + 16 then
            x, y = position.X - width - 8, position.Y
        elseif position.Y >= height + 16 then
            y = position.Y - height - 8
        elseif bounds.Y - position.Y - size.Y >= height + 16 then
            y = position.Y + size.Y + 8
        end
        overlay.Position = UDim2.fromOffset(x, math.clamp(y, 0, math.max(0, bounds.Y - height)))
        overlay.Size = UDim2.fromOffset(width, height)
        for _, kind in ipairs(kinds) do
            local entry, slot = equipped[kind], controls.tradeSlots[kind]
            slot.icon.Image = entry and entry.icon or ""
            slot.name.Text = entry and entry.name or "—"
        end
    end

    local function syncNative()
        local desired = {}
        local showResult = false
        local hasSelection = equipped.Knife or equipped.Gun
        local main = playerGui:FindFirstChild("MainGUI")
        local trade = hasSelection and findOpenTrade(main) or nil
        updateTradePreview(trade)
        if trade then
            syncOverrides(savedImages, desired, "Image")
            updateResultsOverlay(false)
            return
        end
        if hasSelection and (settings.equipScreen or settings.result) then
            local surfaces = {}
            if main then table.insert(surfaces, main) end
            for _, child in ipairs(playerGui:GetChildren()) do
                if child ~= main and resultNames[normalize(child.Name)] then table.insert(surfaces, child) end
            end
            local function inspect(panel)
                local name = normalize(panel.Name)
                if settings.equipScreen and equipNames[name] and withinUi(panel, true) then
                    for _, kind in ipairs(kinds) do
                        local entry = equipped[kind]
                        local icon = entry and entry.icon and weaponIcon(panel, kind, false)
                        if icon then desired[icon] = entry.icon end
                    end
                end
                if settings.result and resultNames[name] and withinUi(panel, true) then
                    showResult = true
                    for _, card in ipairs(panel:GetDescendants()) do
                        local role = roleCards[normalize(card.Name)]
                        if role and card:IsA("GuiObject") and withinUi(card, true) and ownsResultCard(card) then
                            for _, kind in ipairs(kinds) do
                                if role == true or role == kind then
                                    local entry = equipped[kind]
                                    local icon = entry and entry.icon and weaponIcon(card, kind, role == kind)
                                    if icon then desired[icon] = entry.icon end
                                end
                            end
                        end
                    end
                end
            end
            for _, surface in ipairs(surfaces) do
                inspect(surface)
                for _, descendant in ipairs(surface:GetDescendants()) do
                    if descendant:IsA("GuiObject") then inspect(descendant) end
                end
            end
        end
        syncOverrides(savedImages, desired, "Image")
        updateResultsOverlay(showResult)
    end

    local function refreshEquipped()
        for _, kind in ipairs(kinds) do
            local slot = controls.slots[kind]
            local entry = equipped[kind]
            slot.icon.Image = entry and entry.icon or ""
            slot.title.Text = entry and entry.name or "Visual padrão"
            paintChoice(slot.remove, entry ~= nil)
        end
        syncTools()
        syncBody()
        nextNativeCheck = 0
    end

    local function showPreview(entry)
        preview = entry
        if previewWorld then previewWorld:Destroy(); previewWorld = nil end
        controls.previewViewport.Visible = false
        controls.previewIcon.Visible = false
        controls.previewGlyph.Visible = true
        controls.previewTitle.Text = entry and entry.name or "Selecione um item"
        controls.previewText.Text = entry and (kindName[entry.kind] .. "  ·  " .. entry.rarity) or "Prévia local"
        controls.previewText.TextColor3 = entry and (rarityColors[entry.rarity] or colors.muted) or colors.muted
        paintChoice(controls.use, entry ~= nil)
        if not entry then
            controls.previewSupport.Text = "Escolha uma faca ou arma no catálogo."
            return
        end
        local model = buildModel(entry)
        if model then
            previewWorld = make("WorldModel", controls.previewViewport, {Name = "GhostPreviewWorld"})
            model.Parent = previewWorld
            local bounds, size = model:GetBoundingBox()
            local distance = math.max(size.Magnitude * 1.3, 2.5)
            controls.previewCamera.CFrame = CFrame.lookAt(bounds.Position + Vector3.new(distance * 0.65, distance * 0.35, distance), bounds.Position)
            controls.previewViewport.Visible = true
            controls.previewGlyph.Visible = false
            controls.previewSupport.Text = "Prévia 3D do modelo disponível."
        elseif entry.icon then
            controls.previewIcon.Image = entry.icon
            controls.previewIcon.Visible = true
            controls.previewGlyph.Visible = false
            controls.previewSupport.Text = "Prévia pelo ícone disponível."
        else
            controls.previewSupport.Text = "Este item tem apenas o nome no catálogo local."
        end
    end

    local function refreshList()
        local matched = {}
        local query = controls.search.Text:lower()
        for _, entry in ipairs(catalog) do
            if (filter == "Tudo" or filter == entry.kind) and (query == "" or entry.name:lower():find(query, 1, true)
                or entry.id:lower():find(query, 1, true) or entry.rarity:lower():find(query, 1, true)) then
                table.insert(matched, entry)
            end
        end
        local totalPages = math.max(1, math.ceil(#matched / rowsPerPage))
        pageNumber = math.clamp(pageNumber, 1, totalPages)
        controls.pagination.Text = string.format("%d / %d  ·  %d %s", pageNumber, totalPages, #matched, #matched == 1 and "item" or "itens")
        paintChoice(controls.back, pageNumber > 1)
        paintChoice(controls.next, pageNumber < totalPages)
        for index, slot in ipairs(cards) do
            local entry = matched[(pageNumber - 1) * rowsPerPage + index]
            slot.entry = entry
            slot.row.Visible = entry ~= nil
            if entry then
                slot.icon.Image = entry.icon or ""
                slot.glyph.Visible = not entry.icon
                slot.name.Text = entry.name
                slot.detail.Text = kindName[entry.kind] .. "  ·  " .. entry.rarity
                slot.detail.TextColor3 = rarityColors[entry.rarity] or colors.muted
            end
        end
    end

    local function updateCatalog()
        if loading then return end
        if not isMM2 then
            controls.source.Text = "Abra o MM2 para ler o catálogo disponível."
            return
        end
        loading = true
        controls.source.Text = "Lendo o catálogo do MM2…"
        task.spawn(function()
            local ok, rows, byKey = pcall(readCatalog)
            loading = false
            if not state.running then return end
            if ok and #rows > 0 then
                catalog = rows
                for _, kind in ipairs(kinds) do
                    local active = equipped[kind]
                    if active then equipped[kind] = byKey[active.identity] or active end
                end
                controls.source.Text = string.format("%d facas e armas disponíveis no catálogo local.", #catalog)
                showPreview(preview and byKey[preview.identity] or nil)
                refreshEquipped()
            else
                controls.source.Text = #catalog > 0 and "O catálogo anterior está carregado." or "Catálogo indisponível. Toque em atualizar."
            end
            refreshList()
        end)
    end

    local _, sourceText = actionRow(page, "Inventário visual do MM2", "Leia as skins que o jogo carrega no cliente.", "ATUALIZAR", updateCatalog)
    controls.source = sourceText

    local loadout = card(page, 103)
    cardCopy(loadout, "Equipamento visual", "Ícones das escolhas da sua coleção pessoal.", 20)
    controls.slots = {}
    for index, kind in ipairs(kinds) do
        local tile = make("Frame", loadout, {
            Position = UDim2.new((index - 1) / 2, 7, 0, 49),
            Size = UDim2.new(0.5, -14, 0, 44),
            BackgroundColor3 = colors.raised, BorderSizePixel = 0,
        })
        round(tile, 7)
        local icon = image(tile, UDim2.fromOffset(28, 30), UDim2.fromOffset(5, 7))
        local tag = label(tile, kindName[kind], 9, Enum.Font.GothamBold, colors.accent)
        tag.Position, tag.Size = UDim2.fromOffset(36, 4), UDim2.new(1, -60, 0, 14)
        local name = label(tile, "Visual padrão", 11, Enum.Font.GothamBold)
        name.Position, name.Size = UDim2.fromOffset(36, 19), UDim2.new(1, -60, 0, 18)
        local remove = button(tile, "×", 13)
        remove.Position, remove.Size = UDim2.new(1, -23, 0, 13), UDim2.fromOffset(18, 18)
        controls.slots[kind] = {icon = icon, title = name, remove = remove}
        connect(remove.Activated, function()
            equipped[kind] = nil
            refreshEquipped()
            syncNative()
        end)
    end

    local showcase = card(page, 142)
    showcase.Name = "GhostSkinPreview"
    local canvas = make("Frame", showcase, {
        Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(112, 122),
        BackgroundColor3 = colors.ink, BorderSizePixel = 0,
    })
    round(canvas, 9)
    controls.previewGlyph = glyph(canvas, "skins", UDim2.fromOffset(39, 43), 34, colors.violet)
    controls.previewIcon = image(canvas, UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6))
    controls.previewViewport = make("ViewportFrame", canvas, {
        Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
    })
    controls.previewCamera = make("Camera", controls.previewViewport, {FieldOfView = 38})
    controls.previewViewport.CurrentCamera = controls.previewCamera
    local function previewLabel(text, y, height, size)
        local caption = label(showcase, text, size, Enum.Font.GothamBold)
        caption.Position, caption.Size = UDim2.fromOffset(131, y), UDim2.new(1, -141, 0, height)
        return caption
    end
    controls.previewTitle = previewLabel("Selecione um item", 10, 22, 14)
    controls.previewText = previewLabel("Prévia local", 35, 15, 10)
    controls.previewSupport = previewLabel("", 55, 33, 10)
    controls.previewSupport.TextWrapped = true
    controls.previewSupport.TextTruncate = Enum.TextTruncate.None
    controls.use = button(showcase, "USAR VISUAL", 10)
    controls.use.Position, controls.use.Size = UDim2.fromOffset(131, 96), UDim2.new(1, -141, 0, 31)
    connect(controls.use.Activated, function()
        if not preview then return end
        equipped[preview.kind] = preview
        refreshEquipped()
        syncNative()
        status("Visual equipado · " .. preview.name)
    end)

    local searchRow = card(page, 45)
    controls.search = make("TextBox", searchRow, {
        Name = "GhostSkinSearch",
        Position = UDim2.fromOffset(8, 7), Size = UDim2.new(1, -16, 0, 31),
        BackgroundColor3 = colors.raised, BorderSizePixel = 0,
        TextColor3 = colors.white, TextSize = 12, Font = Enum.Font.GothamMedium,
        PlaceholderText = "Pesquisar nome, ID ou raridade", PlaceholderColor3 = colors.muted,
        Text = "", ClearTextOnFocus = false,
    })
    round(controls.search, 7)
    choiceRow(page, "Tipo de item", "Filtre a coleção por faca ou arma.", {
        {"Tudo", "Tudo"}, {"Facas", "Knife"}, {"Armas", "Gun"},
    }, function() return filter end, function(value)
        filter, pageNumber = value, 1
        refreshList()
    end)
    local pager = card(page, 42)
    controls.back = button(pager, "‹", 16)
    controls.back.Position, controls.back.Size = UDim2.fromOffset(7, 7), UDim2.fromOffset(35, 28)
    controls.next = button(pager, "›", 16)
    controls.next.Position, controls.next.Size = UDim2.new(1, -42, 0, 7), UDim2.fromOffset(35, 28)
    controls.pagination = label(pager, "", 11, Enum.Font.GothamBold, colors.muted)
    controls.pagination.Position, controls.pagination.Size = UDim2.fromOffset(47, 0), UDim2.new(1, -94, 1, 0)
    controls.pagination.TextXAlignment = Enum.TextXAlignment.Center
    connect(controls.back.Activated, function() pageNumber = pageNumber - 1; refreshList() end)
    connect(controls.next.Activated, function() pageNumber = pageNumber + 1; refreshList() end)
    connect(controls.search:GetPropertyChangedSignal("Text"), function()
        pageNumber = 1
        refreshList()
    end)

    for index = 1, rowsPerPage do
        local row = card(page, 54)
        row.Name = "GhostCatalogRow"
        local icon = image(row, UDim2.fromOffset(34, 36), UDim2.fromOffset(7, 9))
        local fallback = glyph(row, "skins", UDim2.fromOffset(14, 15), 20, colors.accent)
        local name = label(row, "", 12, Enum.Font.GothamBold)
        name.Position, name.Size = UDim2.fromOffset(48, 5), UDim2.new(1, -115, 0, 20)
        local detail = label(row, "", 10, nil, colors.muted)
        detail.Position, detail.Size = UDim2.fromOffset(48, 26), UDim2.new(1, -115, 0, 18)
        local view = button(row, "VER", 10)
        view.Position, view.Size = UDim2.new(1, -58, 0, 13), UDim2.fromOffset(48, 28)
        local slot = {row = row, icon = icon, glyph = fallback, name = name, detail = detail}
        cards[index] = slot
        connect(view.Activated, function()
            if slot.entry then
                showPreview(slot.entry)
                local top = showcase.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
                page.CanvasPosition = Vector2.new(0, math.max(0, top - 4))
            end
        end)
    end
    for _, item in ipairs({
        {"hotbar", "Ícone na Tool", "Aplica o ícone à faca ou arma da sua barra."},
        {"body", "Visual no personagem", "Coloca a faca nas costas e a arma na lateral."},
        {"equipScreen", "Ícone no equipamento", "Aplica em espaços de equipamento reconhecidos."},
        {"result", "Visual no fim da rodada", "Mostra a escolha nas telas de resultado reconhecidas."},
        {"tradePreview", "Prévia local na troca", "Mostra suas skins em um cartão pessoal durante a troca."},
    }) do
        local key = item[1]
        toggle(page, item[2], item[3], function() return settings[key] end, function(value)
            settings[key] = value
            refreshEquipped()
            syncNative()
        end)
    end

    controls.resultOverlay = make("Frame", screen, {
        Name = "GhostRoundSkinOverlay", AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -63), Size = UDim2.fromOffset(174, 62),
        BackgroundColor3 = colors.surface, BorderSizePixel = 0, Visible = false, ZIndex = 6,
    })
    round(controls.resultOverlay, 10)
    stroke(controls.resultOverlay, colors.accent, 0.31)
    local resultLabel = label(controls.resultOverlay, "VISUAL DA RODADA", 10, Enum.Font.GothamBold, colors.accent)
    resultLabel.Position, resultLabel.Size = UDim2.fromOffset(9, 3), UDim2.new(1, -18, 0, 18)
    resultLabel.TextXAlignment = Enum.TextXAlignment.Center
    controls.resultSlots = {}
    for index, kind in ipairs(kinds) do
        controls.resultSlots[kind] = image(controls.resultOverlay, UDim2.fromOffset(41, 34), UDim2.fromOffset(35 + (index - 1) * 62, 23))
    end

    controls.tradeOverlay = make("Frame", screen, {
        Name = "GhostTradeSkinPreview", Size = UDim2.fromOffset(244, 54),
        BackgroundColor3 = colors.surface, BorderSizePixel = 0, Visible = false, Active = false, ZIndex = 4,
    })
    round(controls.tradeOverlay, 9)
    stroke(controls.tradeOverlay, colors.accent, 0.35)
    local tradeLabel = label(controls.tradeOverlay, "PRÉVIA LOCAL  /  VISUAL", 9, Enum.Font.GothamBold, colors.accent)
    tradeLabel.Position, tradeLabel.Size = UDim2.fromOffset(8, 3), UDim2.new(1, -16, 0, 14)
    controls.tradeSlots = {}
    for index, kind in ipairs(kinds) do
        local tile = make("Frame", controls.tradeOverlay, {
            Position = UDim2.new((index - 1) / 2, 5, 0, 19), Size = UDim2.new(0.5, -10, 0, 29),
            BackgroundColor3 = colors.raised, BorderSizePixel = 0, Active = false,
        })
        round(tile, 6)
        local icon = image(tile, UDim2.fromOffset(22, 22), UDim2.fromOffset(3, 3))
        local kindLabel = label(tile, kindName[kind], 8, Enum.Font.GothamBold, colors.muted)
        kindLabel.Position, kindLabel.Size = UDim2.fromOffset(28, 2), UDim2.new(1, -31, 0, 11)
        local name = label(tile, "—", 9, Enum.Font.GothamBold)
        name.Position, name.Size = UDim2.fromOffset(28, 13), UDim2.new(1, -31, 0, 13)
        controls.tradeSlots[kind] = {icon = icon, name = name}
    end

    function skinTools.open()
        if not opened then
            opened = true
            updateCatalog()
        end
    end

    function skinTools.tick(now)
        if not opened then return end
        if not equipped.Knife and not equipped.Gun and not next(savedTools) and not next(savedImages) and not next(body) then return end
        syncTools()
        syncBody()
        if now >= nextNativeCheck then
            nextNativeCheck = now + 0.65
            syncNative()
        end
    end

    function skinTools.shutdown()
        for _, kind in ipairs(kinds) do destroyBody(kind) end
        syncOverrides(savedTools, {}, "TextureId")
        syncOverrides(savedImages, {}, "Image")
        syncOverrides(savedHolsters, {}, "LocalTransparencyModifier")
    end

    connect(player.CharacterRemoving, function()
        for _, kind in ipairs(kinds) do destroyBody(kind) end
        syncOverrides(savedHolsters, {}, "LocalTransparencyModifier")
    end)
    showPreview(nil)
    refreshList()
    refreshEquipped()
end
setupVisualPage()

-- Player V2. Cada acionamento de pulo aplica um único impulso.
do
    local page = pages.Player
    state.infiniteJump = false
    state.playerHud = false
    local actionName = "GhostSoaresJump_" .. player.UserId
    local held = {}
    local jumpStrength = 1
    local buttonSize = 64
    local buttonSide = "Direita"
    local jumps = 0
    local walkBoost = 0
    local walkOverride
    local zoomValue = 0
    local zoomOverride
    local nativeButton
    local nativeVisible
    local nativeWatcher
    local actionBound = false
    local jumpDetail

    local mobileJump = button(screen, "", 10)
    mobileJump.Name = "GhostJumpButton"
    mobileJump.BackgroundColor3 = colors.surface
    mobileJump.Selectable = false
    mobileJump.Visible = false
    mobileJump.ZIndex = 4
    mobileJump:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
    stroke(mobileJump, colors.accent, 0.16)
    local jumpIcon = glyph(mobileJump, "jump", UDim2.new(0.5, -11, 0.5, -16), 22, colors.accent)
    jumpIcon.Name = "GhostJumpIcon"
    local jumpText = label(mobileJump, "PULO", 9, Enum.Font.GothamBold, colors.white)
    jumpText.Position = UDim2.new(0, 0, 1, -20)
    jumpText.Size = UDim2.new(1, 0, 0, 13)
    jumpText.TextXAlignment = Enum.TextXAlignment.Center

    local hud = make("Frame", screen, {
        Name = "GhostPlayerHud",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -68),
        Size = UDim2.fromOffset(160, 56),
        BackgroundColor3 = colors.surface,
        BackgroundTransparency = 0.07,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 4,
    })
    round(hud, 9)
    stroke(hud, colors.accent, 0.54)
    local hudLabel = label(hud, "PLAYER  /  GHOST V2", 9, Enum.Font.GothamBold, colors.accent)
    hudLabel.Position = UDim2.fromOffset(9, 5)
    hudLabel.Size = UDim2.new(1, -18, 0, 14)
    local hudValue = label(hud, "", 11, Enum.Font.GothamBold)
    hudValue.Position = UDim2.fromOffset(9, 23)
    hudValue.Size = UDim2.new(1, -18, 0, 22)

    local function movable()
        if not state.running or not state.unlocked or farm.active or farm.controlsCharacter
            or roundTools.fling or roundTools.pickup or roundTools.view then
            return nil
        end
        local character, humanoid, root = aliveCharacter(player)
        if character and not root.Anchored and not humanoid.PlatformStand and not humanoid.Sit then
            return character, humanoid, root
        end
    end

    local function layoutJump()
        local onLeft = buttonSide == "Esquerda"
        mobileJump.AnchorPoint = Vector2.new(onLeft and 0 or 1, 1)
        mobileJump.Position = UDim2.new(onLeft and 0 or 1, onLeft and 24 or -24, 1, -70)
        mobileJump.Size = UDim2.fromOffset(buttonSize, buttonSize)
        hud.Position = UDim2.new(0, 12, 1, onLeft and mobileJump.Visible and -147 or -68)
    end

    local function restoreNative()
        if nativeWatcher then
            nativeWatcher:Disconnect()
            nativeWatcher = nil
        end
        if nativeButton and nativeButton.Parent then
            nativeButton.Visible = nativeVisible
        end
        nativeButton = nil
        nativeVisible = nil
    end

    local function hideNative()
        local touchGui = playerGui:FindFirstChild("TouchGui")
        local native = touchGui and touchGui:FindFirstChild("JumpButton", true)
        if native == nativeButton then return end
        restoreNative()
        if native and native:IsA("GuiButton") then
            nativeButton = native
            nativeVisible = native.Visible
            nativeWatcher = native:GetPropertyChangedSignal("Visible"):Connect(function()
                if nativeButton == native and native.Visible then
                    nativeVisible = true
                    native.Visible = false
                end
            end)
            native.Visible = false
        end
    end

    function playerTools.updateVisibility()
        local useMobile = state.infiniteJump and UserInputService.TouchEnabled and movable() ~= nil
        mobileJump.Visible = useMobile and not window.Visible
        if useMobile then
            hideNative()
        else
            restoreNative()
        end
        hud.Visible = state.running and state.unlocked and not window.Visible and state.playerHud
        layoutJump()
    end

    local function describeJump()
        if not state.infiniteJump then
            jumpDetail.Text = "Desligado. Ative para pular com novos toques."
        elseif movable() then
            jumpDetail.Text = string.format("%d %s nesta vida. Um por toque.", jumps, jumps == 1 and "impulso" or "impulsos")
        else
            jumpDetail.Text = "Armado. Aguardando seu avatar ficar livre."
        end
    end

    local function pulseJump()
        if not state.infiniteJump then return false end
        local _, humanoid, root = movable()
        if not humanoid then return false end
        local velocity = root.AssemblyLinearVelocity
        local jumpSpeed = humanoid.JumpPower
        if not humanoid.UseJumpPower then
            jumpSpeed = math.sqrt(2 * Workspace.Gravity * math.max(0, humanoid.JumpHeight))
        end
        if jumpSpeed <= 0 then return false end
        humanoid.Jump = false
        local inAir = humanoid.FloorMaterial == Enum.Material.Air
        if not inAir then
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
        local lift = jumpSpeed * jumpStrength
        local risingBoost = inAir and math.clamp(velocity.Y, 0, lift) * 0.32 or 0
        root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.clamp(lift + risingBoost, 15, 95), velocity.Z)
        jumps = jumps + 1
        describeJump()
        return true
    end

    local function jumpAction(_, inputState, input)
        if inputState == Enum.UserInputState.Cancel then
            table.clear(held)
            return Enum.ContextActionResult.Pass
        end
        local key = input and input.KeyCode
        if not key then return Enum.ContextActionResult.Pass end
        if inputState == Enum.UserInputState.End then
            local consumed = held[key]
            held[key] = nil
            return consumed and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
        end
        if held[key] then return Enum.ContextActionResult.Sink end
        if inputState ~= Enum.UserInputState.Begin or UserInputService:GetFocusedTextBox() then
            return Enum.ContextActionResult.Pass
        end
        if pulseJump() then
            held[key] = true
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end

    local function syncJumpBinding()
        if state.infiniteJump and not actionBound then
            ContextActionService:BindActionAtPriority(
                actionName, jumpAction, false, Enum.ContextActionPriority.High.Value + 1,
                Enum.KeyCode.Space, Enum.KeyCode.ButtonA
            )
            actionBound = true
        elseif not state.infiniteJump and actionBound then
            ContextActionService:UnbindAction(actionName)
            table.clear(held)
            actionBound = false
        end
    end

    local function restoreWalk()
        local saved = walkOverride
        walkOverride = nil
        if saved and saved.humanoid.Parent and saved.humanoid.WalkSpeed == saved.applied then
            saved.humanoid.WalkSpeed = saved.before
        end
    end

    local function updateWalk()
        local _, humanoid = movable()
        if walkBoost == 0 or not humanoid then
            restoreWalk()
            return
        end
        if walkOverride and walkOverride.humanoid == humanoid and walkOverride.boost == walkBoost then return end
        restoreWalk()
        local before = humanoid.WalkSpeed
        if before > 0 then
            local applied = before + walkBoost
            walkOverride = {humanoid = humanoid, before = before, applied = applied, boost = walkBoost}
            humanoid.WalkSpeed = applied
        end
    end

    local function setZoom(value)
        if zoomOverride and player.CameraMaxZoomDistance == zoomOverride.applied then
            player.CameraMaxZoomDistance = zoomOverride.before
        end
        zoomOverride = nil
        zoomValue = value
        if value > 0 then
            local before = player.CameraMaxZoomDistance
            local applied = math.max(player.CameraMinZoomDistance, value)
            player.CameraMaxZoomDistance = applied
            zoomOverride = {before = before, applied = applied}
        end
    end

    function playerTools.tick()
        playerTools.updateVisibility()
        updateWalk()
        if state.infiniteJump or (window.Visible and ui.pageName == "Player") then describeJump() end
        if hud.Visible then
            local _, humanoid, root = aliveCharacter(player)
            if humanoid then
                local velocity = root.AssemblyLinearVelocity
                local horizontal = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
                hudValue.Text = string.format("%d HP  ·  %.0f vel.  ·  %d pulos", math.ceil(humanoid.Health), horizontal, jumps)
            else
                hudValue.Text = "Aguardando avatar"
            end
        end
    end

    function playerTools.shutdown()
        state.infiniteJump = false
        syncJumpBinding()
        restoreNative()
        restoreWalk()
        setZoom(0)
    end

    local _, detail = option(page, "infiniteJump", "Infinite Jump", "Um impulso por toque, inclusive no ar.", function()
        syncJumpBinding()
        playerTools.updateVisibility()
        describeJump()
        status(state.infiniteJump and "Infinite Jump ligado. Use novos toques." or "Infinite Jump desligado.")
    end)
    jumpDetail = detail
    choiceRow(page, "Força do impulso", "Ajusta a altura de cada pulo.", {
        {"Leve", 0.8}, {"Normal", 1}, {"Forte", 1.25},
    }, function() return jumpStrength end, function(value) jumpStrength = value end)
    choiceRow(page, "Botão de pulo", "Escolha o tamanho do controle no celular.", {
        {"Pequeno", 52}, {"Padrão", 64}, {"Grande", 74},
    }, function() return buttonSize end, function(value)
        buttonSize = value
        layoutJump()
    end)
    choiceRow(page, "Lado do botão", "Reposiciona o controle para a outra mão.", {
        {"Esquerda", "Esquerda"}, {"Direita", "Direita"},
    }, function() return buttonSide end, function(value)
        buttonSide = value
        layoutJump()
    end)
    option(page, "playerHud", "HUD do Player", "Mostra vida, velocidade e número de impulsos.", playerTools.updateVisibility)
    actionRow(page, "Zerar contador", "Reinicia a contagem dos pulos nesta vida.", "ZERAR", function()
        jumps = 0
        describeJump()
    end)
    choiceRow(page, "Caminhada", "Ajuste local sobre a velocidade do avatar.", {
        {"Padrão", 0}, {"Leve +3", 3}, {"Ágil +6", 6},
    }, function() return walkBoost end, function(value)
        walkBoost = value
        updateWalk()
    end)
    choiceRow(page, "Zoom máximo", "Escolha o limite do zoom da câmera.", {
        {"Padrão", 0}, {"45 studs", 45}, {"85 studs", 85},
    }, function() return zoomValue end, setZoom)
    actionRow(page, "Retomar sua câmera", "Fecha a observação e segue seu personagem.", "VOLTAR", roundTools.restoreCamera)
    local guide = card(page, 64)
    cardCopy(guide, "Como pular no ar", "Toque em PULO no celular ou use Espaço / A. Solte e pressione de novo para cada impulso.", 20)

    connect(mobileJump.Activated, function()
        if mobileJump.Visible then pulseJump() end
    end)
    connect(UserInputService.WindowFocusReleased, function() table.clear(held) end)
    connect(player.CharacterRemoving, function()
        table.clear(held)
        restoreNative()
        restoreWalk()
        jumps = 0
        mobileJump.Visible = false
    end)
    connect(RunService.PreSimulation, function()
        if state.infiniteJump then
            local _, humanoid = movable()
            if humanoid and humanoid.Jump then humanoid.Jump = false end
        end
    end)
end

-- Informações do Ghost Soares Hub e contato.
do
    local page = pages["Informações"]
    local introCard = card(page, 104)
    introCard.BackgroundColor3 = colors.ink
    glyph(introCard, "logo", UDim2.fromOffset(12, 15), 31, colors.accent)
    local heading = label(introCard, "Ghost Soares Hub", 19, Enum.Font.GothamBlack)
    heading.Position = UDim2.fromOffset(53, 12)
    heading.Size = UDim2.new(1, -65, 0, 25)
    local signature = label(introCard, "By Soares And Ghost Hub", 11, Enum.Font.GothamBold, colors.muted)
    signature.Position = UDim2.fromOffset(54, 39)
    signature.Size = UDim2.new(1, -65, 0, 17)
    local version = label(introCard, "V2  /  EDIÇÃO GHOST", 10, Enum.Font.GothamBold, colors.accent)
    version.Position = UDim2.fromOffset(13, 71)
    version.Size = UDim2.new(1, -26, 0, 18)

    local contact = card(page, 91)
    cardCopy(contact, "Discord", "Contato para menus e informações do hub.", 20)
    local handle = make("TextBox", contact, {
        BackgroundColor3 = colors.raised,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamBold,
        Position = UDim2.fromOffset(10, 50),
        Size = UDim2.new(1, -103, 0, 30),
        Text = "loyalfriendp",
        TextColor3 = colors.accent,
        TextEditable = false,
        TextSize = 13,
    })
    round(handle, 7)
    local copy = button(contact, "COPIAR", 10)
    copy.Position = UDim2.new(1, -84, 0, 50)
    copy.Size = UDim2.fromOffset(73, 30)
    connect(copy.Activated, function()
        if type(setclipboard) == "function" and pcall(setclipboard, handle.Text) then
            status("Discord copiado.")
        else
            handle:CaptureFocus()
            status("Selecione loyalfriendp para copiar.")
        end
    end)

    local offer = card(page, 83)
    local text = cardCopy(offer, "Menus personalizados  /  R$ 35",
        "Faço seu próprio menu por 35 reais. Chamem no privado do Discord.", 20)
    text.Size = UDim2.new(1, -20, 0, 46)
    local community = card(page, 51)
    glyph(community, "info", UDim2.fromOffset(12, 16), 17, colors.violet)
    local coming = label(community, "Comunidade em breve", 13, Enum.Font.GothamBold, colors.accent)
    coming.Position = UDim2.fromOffset(38, 0)
    coming.Size = UDim2.new(1, -50, 1, 0)
end

-- Painel de rodada, radar, atalhos e perfis de sessão.
do
    local board, hub = pages.Rodada, pages.Hub
    state.roundHud = false
    state.radar = false
    state.radarRange = 100
    state.quickActions = true
    state.keyboardShortcuts = false
    state.roundAlert = false
    local boardSort = "Distância"
    local onlyActive = false
    local startedAt = os.clock()
    local latest
    local feed = {}
    local previousRole, previousMurder, previousDrop
    local slots = {}
    local dots = {}
    local storedProfile

    local banner = card(board, 88)
    banner.BackgroundColor3 = colors.ink
    banner.BackgroundTransparency = 0.02
    local function bannerLine(text, y, size, color)
        local line = label(banner, text, size, Enum.Font.GothamBold, color)
        line.Position = UDim2.fromOffset(12, y)
        line.Size = UDim2.new(1, -24, 0, size + 8)
        return line
    end
    bannerLine("GHOST SOARES  /  PAINEL DE RODADA", 8, 10, colors.accent)
    local roleText = bannerLine("Aguardando dados da rodada", 28, 17, colors.white)
    local countsText = bannerLine("Aguardando jogadores", 56, 11, colors.darkMuted)

    local _, weaponText = actionRow(board, "Arma do Sheriff", "Aguardando a arma caída.", "BUSCAR", roundTools.grab)
    actionRow(board, "Voltar à sua câmera", "Encerra a observação pelo quadro.", "VOLTAR", roundTools.restoreCamera)

    local eventRow = card(board, 126)
    local eventTitle = label(eventRow, "Eventos da sessão", 13, Enum.Font.GothamBold)
    eventTitle.Position = UDim2.fromOffset(10, 8)
    eventTitle.Size = UDim2.new(1, -20, 0, 17)
    local eventText = label(eventRow, "Aguardando eventos observados pelo painel.", 11, nil, colors.muted)
    eventText.Position = UDim2.fromOffset(10, 30)
    eventText.Size = UDim2.new(1, -20, 0, 86)
    eventText.TextWrapped = true
    eventText.TextTruncate = Enum.TextTruncate.None
    eventText.TextYAlignment = Enum.TextYAlignment.Top

    local searchRow = card(board, 80)
    local searchLabel = label(searchRow, "Jogadores da sala", 13, Enum.Font.GothamBold)
    searchLabel.Position = UDim2.fromOffset(10, 7)
    searchLabel.Size = UDim2.new(1, -20, 0, 18)
    local search = make("TextBox", searchRow, {
        Name = "SoaresPlayerSearch",
        BackgroundColor3 = colors.raised,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = "Pesquisar nome ou @usuário",
        PlaceholderColor3 = colors.muted,
        Position = UDim2.fromOffset(10, 34),
        Size = UDim2.new(1, -20, 0, 34),
        Text = "",
        TextColor3 = colors.white,
        TextSize = 12,
    })
    round(search, 8)
    stroke(search, colors.line)

    local function clockText(seconds)
        local total = math.floor(math.max(0, seconds))
        return string.format("%02d:%02d", math.floor(total / 60), total % 60)
    end

    local function logEvent(message, now)
        table.insert(feed, 1, clockText(now - startedAt) .. "  ·  " .. message)
        if #feed > 5 then table.remove(feed) end
        eventText.Text = table.concat(feed, "\n")
    end

    local roleOrder = {Murderer = 1, Sheriff = 2, Hero = 3, Innocent = 4}
    local function displayRole(entry)
        if entry.role then return roleInfo[entry.role].name end
        if entry.eliminated then return "Eliminado" end
        return entry.active and "Papel pendente" or "Fora da rodada"
    end

    local function refreshBoard()
        if not latest then return end
        local summary = latest
        if summary.ownRole then
            roleText.Text = "Seu papel · " .. roleInfo[summary.ownRole].name
        elseif summary.eliminated then
            roleText.Text = "Você foi eliminado"
        else
            roleText.Text = isMM2 and "Aguardando papel da rodada" or "Entre no Murder Mystery 2"
        end
        countsText.Text = string.format("%d ativos   ·   %d armados   ·   %d na sala", summary.active, summary.armed, summary.total)
        weaponText.Text = summary.dropDistance and ("Arma caída · " .. summary.dropDistance .. " studs")
            or (summary.drop and "Arma caída na rodada." or "Aguardando a arma caída.")

        local matched = {}
        local query = search.Text:lower():match("^%s*(.-)%s*$")
        query = query:gsub("^@", "")
        for _, entry in ipairs(summary.players) do
            if (not onlyActive or entry.active) and (query == ""
                or entry.other.DisplayName:lower():find(query, 1, true)
                or entry.other.Name:lower():find(query, 1, true)) then
                table.insert(matched, entry)
            end
        end
        table.sort(matched, function(a, b)
            if boardSort == "Papel" then
                local rankA, rankB = roleOrder[a.role] or 5, roleOrder[b.role] or 5
                if rankA ~= rankB then return rankA < rankB end
            elseif boardSort == "Distância" and a.distance ~= b.distance then
                return (a.distance or math.huge) < (b.distance or math.huge)
            end
            return a.other.Name < b.other.Name
        end)
        for index, slot in ipairs(slots) do
            local entry = matched[index]
            slot.entry = entry
            slot.row.Visible = entry ~= nil
            if entry then
                local info = roleInfo[entry.role]
                slot.name.Text = entry.other.DisplayName .. "  ·  @" .. entry.other.Name
                slot.caption.Text = displayRole(entry) .. (entry.distance and ("  ·  " .. entry.distance .. " studs") or "")
                slot.dot.BackgroundColor3 = info and info.color or colors.line
                slot.button.Text = entry.active and "VER" or "—"
                paintChoice(slot.button, entry.active)
            end
        end
    end

    choiceRow(board, "Ordenar jogadores", "Escolha a ordem do quadro.", {
        {"Distância", "Distância"}, {"Papel", "Papel"}, {"Nome", "Nome"},
    }, function() return boardSort end, function(value)
        boardSort = value
        refreshBoard()
    end)
    toggle(board, "Somente jogadores ativos", "Filtra a lista pelos avatares ativos.", function()
        return onlyActive
    end, function(value)
        onlyActive = value
        refreshBoard()
    end)
    for index = 1, 12 do
        local row = card(board, 53)
        row.Name = "SoaresPlayerRow"
        row.Visible = false
        local dot = make("Frame", row, {
            BackgroundColor3 = colors.line, BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(7, 7),
        })
        round(dot, 6)
        local name = label(row, "", 12, Enum.Font.GothamBold)
        name.Position = UDim2.fromOffset(24, 5)
        name.Size = UDim2.new(1, -96, 0, 21)
        local caption = label(row, "", 11, nil, colors.muted)
        caption.Position = UDim2.fromOffset(24, 25)
        caption.Size = UDim2.new(1, -96, 0, 19)
        local see = button(row, "VER", 10)
        see.Position = UDim2.new(1, -63, 0, 12)
        see.Size = UDim2.fromOffset(52, 27)
        local slot = {row = row, dot = dot, name = name, caption = caption, button = see}
        slots[index] = slot
        connect(see.Activated, function()
            if slot.entry and slot.entry.active then roundTools.observe(slot.entry.other) end
        end)
    end
    connect(search:GetPropertyChangedSignal("Text"), refreshBoard)

    local hud = make("Frame", screen, {
        Name = "SoaresRoundHud",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = colors.ink,
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -12, 0, 48),
        Size = UDim2.fromOffset(186, 68),
        Visible = false,
        ZIndex = 4,
    })
    round(hud, 12)
    stroke(hud, colors.white, 0.63)
    local function hudLine(y, size, color)
        local text = label(hud, "", size, Enum.Font.GothamBold, color)
        text.Position = UDim2.fromOffset(10, y)
        text.Size = UDim2.new(1, -20, 0, size + 7)
        return text
    end
    local hudTitle = hudLine(6, 10, colors.darkMuted)
    local hudMain = hudLine(23, 13, colors.white)
    local hudSub = hudLine(44, 10, colors.darkMuted)
    local ping
    local nextPing = 0

    local radar = make("Frame", screen, {
        Name = "SoaresRadar",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = colors.ink,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 4,
    })
    round(radar, 12)
    stroke(radar, colors.white, 0.65)
    local dial = make("Frame", radar, {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 6),
        Size = UDim2.new(1, -20, 1, -23),
    })
    for _, size in ipairs({0.5, 1}) do
        local ring = make("Frame", dial, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(size, size),
        })
        make("UICorner", ring, {CornerRadius = UDim.new(0.5, 0)})
        stroke(ring, colors.white, 0.72)
    end
    local selfDot = make("Frame", dial, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = colors.white,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(5, 5),
    })
    round(selfDot, 6)
    local radarText = label(radar, "", 9, Enum.Font.GothamBold, colors.darkMuted)
    radarText.TextXAlignment = Enum.TextXAlignment.Center
    radarText.Position = UDim2.new(0, 0, 1, -16)
    radarText.Size = UDim2.new(1, 0, 0, 14)
    for index = 1, 12 do
        local dot = make("Frame", dial, {
            Name = "RadarDot",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = colors.white,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(6, 6),
            Visible = false,
        })
        round(dot, 6)
        dots[index] = dot
    end

    local dock = make("Frame", screen, {
        Name = "SoaresQuickActions",
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, -15),
        Size = UDim2.fromOffset(202, 32),
        Visible = false,
        ZIndex = 4,
    })

    function dashboard.updateVisibility()
        local playing = state.unlocked and not window.Visible
        hud.Visible = playing and (state.roundHud or state.performanceHud)
        radar.Visible = playing and isMM2 and state.radar
        dock.Visible = playing and state.quickActions
        local hudTop = 48
        local radarTop = hud.Visible and 123 or hudTop
        local available = screen.AbsoluteSize.Y - radarTop - 50
        local size = math.clamp(available, 66, 122)
        radar.Position = UDim2.new(1, -12, 0, radarTop)
        radar.Size = UDim2.fromOffset(size, size)
    end

    local function flipHud()
        state.roundHud = not state.roundHud
        if optionRefresh.roundHud then optionRefresh.roundHud() end
        dashboard.updateVisibility()
    end

    for index, item in ipairs({
        {"HUD", flipHud, "radar"}, {"ARMA", roundTools.grab, "aim"}, {"PAUSAR", roundTools.pauseCombat, "minus"},
    }) do
        local action = button(dock, item[1], 10)
        action.Position = UDim2.fromOffset((index - 1) * 68, 0)
        action.Size = UDim2.fromOffset(65, 32)
        action.TextTransparency = 1
        stroke(action, colors.white, 0.52)
        glyph(action, item[3], UDim2.fromOffset(4, 10), 11, colors.ink)
        local caption = label(action, item[1], 10, Enum.Font.GothamBold, colors.ink)
        caption.Position = UDim2.fromOffset(17, 0)
        caption.Size = UDim2.new(1, -20, 1, 0)
        caption.TextXAlignment = Enum.TextXAlignment.Center
        connect(action.Activated, item[2])
    end
    connect(screen:GetPropertyChangedSignal("AbsoluteSize"), dashboard.updateVisibility)

    local function drawRadar(summary)
        local filled = 0
        local camera = Workspace.CurrentCamera
        if radar.Visible and summary.root and camera then
            local look = camera.CFrame.LookVector
            local forward = Vector3.new(look.X, 0, look.Z)
            forward = forward.Magnitude > 0.01 and forward.Unit or Vector3.new(0, 0, -1)
            local right = Vector3.new(-forward.Z, 0, forward.X)
            local origin = summary.root.Position
            for _, entry in ipairs(summary.players) do
                if entry.root and filled < #dots then
                    local delta = entry.root.Position - origin
                    local x = delta:Dot(right) / state.radarRange
                    local y = -delta:Dot(forward) / state.radarRange
                    if x * x + y * y <= 1 then
                        filled = filled + 1
                        local dot = dots[filled]
                        local info = roleInfo[entry.role]
                        dot.BackgroundColor3 = info and info.color or colors.darkMuted
                        dot.Position = UDim2.fromScale(0.5 + x * 0.44, 0.5 + y * 0.44)
                        dot.Visible = true
                    end
                end
            end
        end
        for index = filled + 1, #dots do dots[index].Visible = false end
        radarText.Text = "RADAR  ·  " .. state.radarRange .. " STUDS"
    end

    local function buildSummary(now)
        local _, _, ownRoot = aliveCharacter(player)
        local camera = Workspace.CurrentCamera
        local origin = ownRoot and ownRoot.Position or (camera and camera.CFrame.Position)
        local summary = {players = {}, root = ownRoot, total = 0, active = 0, armed = 0}
        if not isMM2 then return summary end
        for _, other in ipairs(Players:GetPlayers()) do
            local entry = rowFor(other)
            local character, _, root = roundCharacter(other)
            local role = character and roundRole(other, entry)
            summary.total = summary.total + 1
            if character then summary.active = summary.active + 1 end
            if role == "Sheriff" or role == "Hero" then summary.armed = summary.armed + 1 end
            if role == "Murderer" then summary.murder = other end
            if other == player then
                summary.ownRole = role
                summary.eliminated = isEliminated(entry) == true
            else
                table.insert(summary.players, {
                    other = other,
                    role = role,
                    active = character ~= nil,
                    eliminated = isEliminated(entry) == true,
                    root = root,
                    distance = root and origin and math.floor((root.Position - origin).Magnitude + 0.5),
                })
            end
        end
        summary.drop = roundTools.getDroppedPart(now)
        if summary.drop and origin then
            summary.dropDistance = math.floor((summary.drop.Position - origin).Magnitude + 0.5)
        end
        return summary
    end

    function dashboard.wantsRoles()
        return state.roundHud or state.radar or state.roundAlert or (window.Visible and ui.pageName == "Rodada")
    end

    local function updateHud(summary, now)
        if not hud.Visible then return end
        hudTitle.Text = "GHOST V2  /  " .. clockText(now - startedAt)
        local fps = ui.latestFps and (ui.latestFps .. " FPS") or "FPS —"
        local latency = ping and (ping .. " ms") or "PING —"
        if state.roundHud then
            local role = summary.ownRole and roleInfo[summary.ownRole].name or "Aguardando rodada"
            hudMain.Text = role .. "  ·  " .. summary.active .. " ativos"
            hudSub.Text = state.performanceHud and (fps .. "   ·   " .. latency)
                or (summary.dropDistance and ("Arma a " .. summary.dropDistance .. " studs") or "Murder Mystery 2")
        else
            hudMain.Text = fps .. "   ·   " .. latency
            hudSub.Text = "DESEMPENHO DO CLIENTE"
        end
    end

    function dashboard.tick(now)
        local needsRound = dashboard.wantsRoles()
        if not needsRound and not state.performanceHud then return end
        if state.performanceHud and now >= nextPing then
            nextPing = now + 1
            local ok, seconds = pcall(function() return player:GetNetworkPing() end)
            ping = ok and type(seconds) == "number" and math.floor(seconds * 1000 + 0.5) or nil
        end
        if needsRound then
            latest = buildSummary(now)
            local role, murder, drop = latest.ownRole, latest.murder, latest.drop
            if role and role ~= previousRole then
                local message = "Seu papel · " .. roleInfo[role].name
                logEvent(message, now)
                if state.roundAlert then roundTools.notify(message) end
            end
            if murder and murder ~= previousMurder and murder ~= player then
                logEvent("Murder identificado · " .. murder.DisplayName, now)
            end
            if drop ~= previousDrop then
                if drop then
                    logEvent("Arma do Sheriff no chão", now)
                elseif previousDrop then
                    logEvent("Arma saiu do chão", now)
                end
            end
            previousRole, previousMurder, previousDrop = role, murder, drop
            if window.Visible and ui.pageName == "Rodada" then refreshBoard() end
            if radar.Visible then drawRadar(latest) end
        end
        updateHud(latest or {active = 0}, now)
    end

    option(hub, "roundHud", "HUD da rodada", "Mostra seu papel, ativos e arma caída ao minimizar.", dashboard.updateVisibility)
    option(hub, "radar", "Radar da rodada", "Mostra posições próximas em relação à câmera.", dashboard.updateVisibility)
    optionRefresh.radarRange = choiceRow(hub, "Alcance do radar", "Define o raio em studs ao redor do avatar.", {
        {"50 studs", 50}, {"100 studs", 100}, {"160 studs", 160},
    }, function() return state.radarRange end, function(value) state.radarRange = value end)
    option(hub, "performanceHud", "HUD de FPS e ping", "Exibe desempenho e latência da sessão.", dashboard.updateVisibility)
    option(hub, "roundAlert", "Aviso de papel", "Exibe um aviso quando seu papel for identificado.")
    option(hub, "quickActions", "Atalhos no celular", "Mostra HUD, arma e pausa ao minimizar.", dashboard.updateVisibility)
    option(hub, "keyboardShortcuts", "Atalhos de teclado", "F6 abre Rodada, F7 alterna HUD e F8 pausa combate.")
    option(hub, "animateMenu", "Animação RGB", "Liga o ciclo de cor na moldura e no cabeçalho.", refreshMenuMotion)
    optionRefresh.rgbTheme = choiceRow(hub, "Paleta RGB", "Escolha a combinação de cores do V2.", {
        {"Aurora", "Aurora"}, {"Glacial", "Glacial"}, {"Neon", "Neon"},
    }, function() return state.rgbTheme end, function(value)
        state.rgbTheme = value
        refreshSpectrum()
    end)
    option(hub, "lockMenu", "Fixar menu na tela", "Trava a posição enquanto estiver ligado.", function()
        dragInput = nil
    end)
    optionRefresh.uiSize = choiceRow(hub, "Tamanho do menu", "Ajusta a janela conforme o espaço da tela.", {
        {"Compacto", "Compacto"}, {"Padrão", "Padrão"}, {"Amplo", "Amplo"},
    }, function() return state.uiSize end, function(value)
        state.uiSize = value
        resizeMenu()
    end)
    actionRow(hub, "Centralizar janela", "Retorna o menu para o centro da tela.", "MOVER", function()
        position = nil
        resizeMenu()
    end)
    actionRow(hub, "Pausar combate", "Desarma mira, Auto Kill All, busca e Fling.", "PAUSAR", roundTools.pauseCombat)

    local profileKeys = {
        "smoothAim", "torsoAim", "checkWalls", "aimRange", "aimSmoothRate", "aimWeapon", "aimLead",
        "espName", "espDistance", "espFill", "espThrough", "espHealth", "espTracers", "espTraceCenter",
        "espRange", "espOpacity", "roundHud", "radar", "radarRange", "performanceHud", "animateMenu", "uiSize", "rgbTheme",
    }
    local function copyTable(values)
        local result = {}
        for key, value in pairs(values) do result[key] = value end
        return result
    end
    local function captureProfile()
        local values = {}
        for _, key in ipairs(profileKeys) do values[key] = state[key] end
        return {
            values = values,
            esp = copyTable(state.esp),
            graphics = copyTable(state.graphics),
            graphicProfile = state.profile,
        }
    end
    local defaultProfile = captureProfile()

    local function applyProfile(profile, message)
        for _, key in ipairs(profileKeys) do
            state[key] = profile.values[key]
            local refresh = optionRefresh[key]
            if refresh then refresh() end
        end
        state.esp = copyTable(profile.esp)
        for _, refresh in pairs(espRefresh) do refresh() end
        state.profile = profile.graphicProfile
        state.graphics = copyTable(profile.graphics)
        graphicsTools.apply()
        graphicsTools.refresh()
        resizeMenu()
        refreshMenuMotion()
        refreshSpectrum()
        dashboard.updateVisibility()
        if isMM2 and (state.esp.Murderer or state.esp.Sheriff or state.esp.Innocent) then requestRoles() end
        syncPlayers()
        lastAimState = nil
        status(message)
    end

    local function preset(graphicName, values, roles)
        local result = {
            values = copyTable(defaultProfile.values),
            esp = copyTable(roles or defaultProfile.esp),
            graphics = copyTable(graphicsTools.profiles[graphicName]),
            graphicProfile = graphicName,
        }
        for key, value in pairs(values) do result.values[key] = value end
        return result
    end

    actionRow(hub, "Perfil de rodada", "ESP do Murder e Sheriff, vida, radar e HUD.", "APLICAR", function()
        applyProfile(preset("Original", {
            espHealth = true, espDistance = true, roundHud = true, radar = true,
        }, {Murderer = true, Sheriff = true, Innocent = false}), "Perfil de rodada aplicado.")
    end)
    actionRow(hub, "Perfil desempenho", "Gráfico baixo, HUD de FPS e fundo estático.", "APLICAR", function()
        applyProfile(preset("Baixo", {
            performanceHud = true, animateMenu = false, uiSize = "Compacto",
        }), "Perfil desempenho aplicado.")
    end)
    actionRow(hub, "Perfil original", "Restaura os ajustes iniciais de câmera, ESP e gráficos.", "APLICAR", function()
        applyProfile(defaultProfile, "Perfil original aplicado.")
    end)
    local savedHint
    local _, saveDescription = actionRow(hub, "Guardar meu perfil", "Guarda seus ajustes durante esta sessão.", "GUARDAR", function()
        storedProfile = captureProfile()
        savedHint.Text = "Perfil guardado nesta sessão."
        status("Seu perfil foi guardado.")
    end)
    savedHint = saveDescription
    actionRow(hub, "Carregar meu perfil", "Aplica o perfil guardado nesta sessão.", "CARREGAR", function()
        if storedProfile then
            applyProfile(storedProfile, "Seu perfil foi carregado.")
        else
            status("Guarde seu perfil primeiro.")
        end
    end)

    connect(UserInputService.InputBegan, function(input, handled)
        if handled or not state.unlocked or not state.keyboardShortcuts or UserInputService:GetFocusedTextBox() then
            return
        end
        if input.KeyCode == Enum.KeyCode.F6 then
            selectPage("Rodada")
            setMenu(true)
        elseif input.KeyCode == Enum.KeyCode.F7 then
            flipHud()
        elseif input.KeyCode == Enum.KeyCode.F8 then
            roundTools.pauseCombat()
        end
    end)
end

-- Fechamento limpo, inclusive quando o script é iniciado outra vez.
local function shutdown(destroyingGui)
    if not state.running then
        return
    end
    state.running = false
    stopKill(true)
    roundTools.shutdown()
    playerTools.shutdown()
    skinTools.shutdown()
    farm.stop()
    releaseTouchShift()
    RunService:UnbindFromRenderStep(renderName)
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    for _, animation in ipairs(animations) do
        animation:Cancel()
    end
    for other in pairs(espObjects) do
        removeEsp(other)
    end
    visuals:Destroy()
    graphicsTools.shutdown()
    if destroyingGui ~= true then
        ui.gui:Destroy()
    end
end

closeSignal.OnInvoke = shutdown
connect(exit.Activated, shutdown)
connect(ui.gui.Destroying, function()
    shutdown(true)
end)

selectPage("Combate")
refreshKillButton()
status(isMM2 and "Pronto • Murder Mystery 2" or "Mira e ESP disponíveis no Murder Mystery 2.")

local nextQuery = 0
task.spawn(function()
    while state.running do
        if state.unlocked then
            local now = os.clock()
            if isMM2 then
                local track = state.aim or activeKill or state.esp.Murderer or state.esp.Sheriff or state.esp.Innocent
                if (track or kill.auto or farm.active or roundTools.wantsRoles() or dashboard.wantsRoles()
                    or playerTool(player, "Knife")) and now >= nextQuery then
                    nextQuery = now + 1
                    requestRoles()
                end
                if track then
                    syncPlayers()
                end
                if not pcall(stepKill, now) then
                    stopKill(true, "Kill All interrompido.")
                end
                roundTools.tick(now)
                refreshKillButton()
                pcall(skinTools.tick, now)
            end
            playerTools.tick()
            pcall(dashboard.tick, now)
        end
        task.wait(0.2)
    end
end)

-- A senha é validada nesta sessão antes de abrir o hub.
local function showKeyScreen()
    local layer = make("Frame", screen, {
        Name = "KeyScreen",
        BackgroundColor3 = colors.ink,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 18,
        Active = true,
    })
    local wash = make("Frame", layer, {
        BackgroundColor3 = colors.white,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
    })
    local keyMotion = spectrum(wash, 7, -25)
    local panel = make("Frame", layer, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -24, 0, 256),
        BackgroundColor3 = colors.surface,
        BorderSizePixel = 0,
    })
    make("UISizeConstraint", panel, {MaxSize = Vector2.new(390, 256)})
    local scale = make("UIScale", panel, {Scale = 1})
    local function resize()
        if layer.Parent then
            scale.Scale = math.clamp(screen.AbsoluteSize.Y / 281, 0.70, 1)
        end
    end
    local resizeConnection = connect(screen:GetPropertyChangedSignal("AbsoluteSize"), resize)
    resize()
    round(panel, 16)
    stroke(panel, colors.violet, 0.15)
    local strip = make("Frame", panel, {
        BackgroundColor3 = colors.white,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 13, 1, -6),
        Size = UDim2.new(1, -26, 0, 2),
    })
    local stripMotion = spectrum(strip, 4.5, 0)

    local function centered(value, y, height, size, font, color)
        local text = label(panel, value, size, font, color)
        text.Position = UDim2.fromOffset(12, y)
        text.Size = UDim2.new(1, -24, 0, height)
        text.TextXAlignment = Enum.TextXAlignment.Center
        return text
    end
    centered("GHOST V2  /  ACESSO", 14, 16, 10, Enum.Font.GothamBold, colors.accent)
    centered("Ghost Soares Hub", 35, 33, 26, Enum.Font.GothamBlack)
    centered("By Soares And Ghost Hub", 69, 17, 11, nil, colors.muted)

    local closeKey = button(panel, "×", 16)
    closeKey.BackgroundColor3 = colors.raised
    closeKey.TextTransparency = 1
    closeKey.Position = UDim2.new(1, -35, 0, 11)
    closeKey.Size = UDim2.fromOffset(25, 25)
    glyph(closeKey, "close", UDim2.fromOffset(6, 6), 13, colors.accent)
    connect(closeKey.Activated, shutdown)

    local input = make("TextBox", panel, {
        Name = "KeyInput",
        BackgroundColor3 = colors.raised,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        MultiLine = false,
        PlaceholderColor3 = colors.muted,
        PlaceholderText = "Digite a senha do V2",
        Position = UDim2.fromOffset(20, 101),
        Size = UDim2.new(1, -40, 0, 36),
        Text = "",
        TextColor3 = colors.white,
        TextSize = 15,
    })
    round(input, 9)
    stroke(input, colors.line)

    local submit = button(panel, "ENTRAR NO HUB", 12)
    submit.Position = UDim2.fromOffset(20, 145)
    submit.Size = UDim2.new(1, -40, 0, 34)
    local feedback = centered("", 183, 17, 11, Enum.Font.GothamBold, colors.pink)
    centered("CONTATO NO DISCORD", 207, 14, 9, Enum.Font.GothamBold, colors.darkMuted)
    centered("loyalfriendp", 222, 18, 13, Enum.Font.GothamBold, colors.accent)

    local function submitKey()
        if not state.running or state.unlocked then return end
        if not input.Text:match("^%s*Pes20277%s*$") then
            feedback.Text = "Senha inválida. Tente novamente."
            return
        end
        state.unlocked = true
        input:ReleaseFocus()
        resizeConnection:Disconnect()
        keyMotion:Cancel()
        stripMotion:Cancel()
        layer:Destroy()
        setMenu(true)
    end
    connect(submit.Activated, submitKey)
    connect(input.FocusLost, function(enterPressed)
        if enterPressed then submitKey() end
    end)
end

-- Abertura V2 com gradiente e barra RGB.
local cover = make("CanvasGroup", screen, {
    BackgroundColor3 = colors.ink,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 20,
    Active = true,
})
local bootWash = make("Frame", cover, {
    BackgroundColor3 = colors.white,
    BackgroundTransparency = 0.84,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
})
local openingMotion = spectrum(bootWash, 4.8, -48)
local intro = make("Frame", cover, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, -26, 0, 212),
    BackgroundColor3 = colors.surface,
    BorderSizePixel = 0,
})
make("UISizeConstraint", intro, {MaxSize = Vector2.new(410, 212)})
round(intro, 17)
stroke(intro, colors.violet, 0.24)

local function introText(value, size, font, color, y, height)
    local object = label(intro, value, size, font, color)
    object.TextXAlignment = Enum.TextXAlignment.Center
    object.Position = UDim2.fromOffset(10, y)
    object.Size = UDim2.new(1, -20, 0, height)
    return object
end
local introLogo = glyph(intro, "logo", UDim2.new(0.5, -15, 0, 15), 30, colors.accent)
introLogo.Name = "GhostLogo"
introText("V2  /  MURDER MYSTERY 2", 10, Enum.Font.GothamBold, colors.accent, 48, 16)
local introTitle = introText("Ghost Soares Hub", 33, Enum.Font.GothamBlack, colors.white, 68, 38)
introTitle.TextScaled = true
make("UITextSizeConstraint", introTitle, {MinTextSize = 17, MaxTextSize = 33})
introText("By Soares And Ghost Hub", 12, Enum.Font.GothamBold, colors.muted, 108, 18)
local progressText = introText("Preparando V2   0%", 10, Enum.Font.GothamBold, colors.darkMuted, 168, 20)

local track = make("Frame", intro, {
    Position = UDim2.fromOffset(21, 149),
    Size = UDim2.new(1, -42, 0, 6),
    BorderSizePixel = 0,
    BackgroundColor3 = colors.raised,
})
round(track, 4)
local progress = make("Frame", track, {
    Size = UDim2.fromScale(0, 1),
    BorderSizePixel = 0,
    BackgroundColor3 = colors.white,
})
round(progress, 4)
local progressMotion = spectrum(progress, 2.5, 10)
animate(progress, TweenInfo.new(1.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.fromScale(1, 1),
})

task.spawn(function()
    local started = os.clock()
    while state.running do
        local ratio = math.clamp((os.clock() - started) / 1.45, 0, 1)
        local visualRatio = 1 - (1 - ratio) ^ 4
        progressText.Text = string.format("Preparando V2   %d%%", math.floor(visualRatio * 100))
        if ratio >= 1 then break end
        task.wait(0.035)
    end
    if not state.running then return end
    state.loading = false
    showKeyScreen()
    animate(cover, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        GroupTransparency = 1,
    }).Completed:Wait()
    if state.running then
        openingMotion:Cancel()
        progressMotion:Cancel()
        cover:Destroy()
    end
end)
