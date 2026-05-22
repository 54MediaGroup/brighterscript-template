sub main(args as dynamic)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.setMessagePort(port)
    memoryMonitor = CreateObject("roAppMemoryMonitor")
    deviceInfo = invalid
    memoryLimitPercent = invalid
    channelMemoryLimit = invalid
    channelAvailableMemory = invalid
    if memoryMonitor <> invalid
        memoryMonitor.setMessagePort(port)
        memoryWarningsEnabled = memoryMonitor.EnableMemoryWarningEvent(true)
        memoryLimitPercent = memoryMonitor.GetMemoryLimitPercent()
        channelMemoryLimit = memoryMonitor.GetChannelMemoryLimit()
        channelAvailableMemory = memoryMonitor.GetChannelAvailableMemory()
        if memoryWarningsEnabled <> true
            deviceInfo = CreateObject("roDeviceInfo")
            deviceInfo.setMessagePort(port)
            deviceInfo.EnableLowGeneralMemoryEvent(true)
        end if
    else
        deviceInfo = CreateObject("roDeviceInfo")
        deviceInfo.setMessagePort(port)
        deviceInfo.EnableLowGeneralMemoryEvent(true)
    end if
    scene = screen.CreateScene("MainScene")
    if args <> invalid then
        scene.launchArgs = args
    end if
    screen.show()
    scene.signalBeacon("AppLaunchComplete")
    while true
        msg = wait(0, port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then
                return
            end if
        else if msgType = "roAppMemoryNotificationEvent"
            if memoryMonitor <> invalid
                memoryLimitPercent = memoryMonitor.GetMemoryLimitPercent()
                channelMemoryLimit = memoryMonitor.GetChannelMemoryLimit()
                channelAvailableMemory = memoryMonitor.GetChannelAvailableMemory()
            end if
        else if msgType = "roDeviceInfoEvent"
            info = msg.GetInfo()
            if info <> invalid
                if memoryMonitor <> invalid
                    memoryLimitPercent = memoryMonitor.GetMemoryLimitPercent()
                    channelMemoryLimit = memoryMonitor.GetChannelMemoryLimit()
                    channelAvailableMemory = memoryMonitor.GetChannelAvailableMemory()
                end if
            end if
        else if msgType = "roInputEvent"
            info = msg.GetInfo()
            if info <> invalid then
                scene.launchArgs = info
            end if
        end if
    end while
end sub'//# sourceMappingURL=./main.bs.map