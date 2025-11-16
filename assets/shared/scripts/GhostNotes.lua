local boyfriendGhostData = {}
local dadGhostData = {}
local gfGhostData = {}

function goodNoteHit(id, direction, noteType, isSustainNote)
    local strumTime = getPropertyFromGroup('notes', id, 'strumTime')
    local noteType = getPropertyFromGroup('notes', id, 'noteType')

    local isGF = getPropertyFromGroup('notes', id, 'gfNote') or noteType == 'Gf Sing'

    -- BOYFRIEND or DAD
    if not isSustainNote and not isGF then
        if strumTime == boyfriendGhostData.strumTime then
            createGhost(getProperty('characterPlayingAsDad') and 'dad' or 'boyfriend')
        end

        boyfriendGhostData.strumTime = strumTime
        updateGData(getProperty('characterPlayingAsDad') and 'dad' or 'boyfriend')
    end

    -- GF
    if not isSustainNote and isGF then
        if strumTime == gfGhostData.strumTime then
            createGhost('gf')
        end

        gfGhostData.strumTime = strumTime
        updateGData('gf')
    end
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
    local strumTime = getPropertyFromGroup('notes', id, 'strumTime')
    local noteType = getPropertyFromGroup('notes', id, 'noteType')

    local isGF = getPropertyFromGroup('notes', id, 'gfNote') or noteType == 'Gf Sing'

    -- DAD or BOYFRIEND
    if not isSustainNote and not isGF then
        if strumTime == dadGhostData.strumTime then
            createGhost(getProperty('characterPlayingAsDad') and 'boyfriend' or 'dad')
        end

        dadGhostData.strumTime = strumTime
        updateGData(getProperty('characterPlayingAsDad') and 'boyfriend' or 'dad')
    end

    -- GF
    if not isSustainNote and isGF then
        if strumTime == gfGhostData.strumTime then
            createGhost('gf')
        end

        gfGhostData.strumTime = strumTime
        updateGData('gf')
    end
end

function createGhost(char)
    local songPos = math.floor(math.abs(getSongPosition()))
    local imageFile = getProperty(char .. '.imageFile')
    local animName = getProperty(char .. '.animation.curAnim.name')
    local isMultiAtlas = getProperty(char .. '.isMultiAtlas')
    local newPath = isMultiAtlas and (imageFile:match("(.+)/[^/]+$") or imageFile) .. '/' .. animName or imageFile

    local ghostTag = char .. 'Ghost' .. songPos
    makeAnimatedLuaSprite(ghostTag, newPath, getProperty(char .. '.x'), getProperty(char .. '.y'))
    addLuaSprite(ghostTag, false)

    setProperty(ghostTag .. '.scale.x', getProperty(char .. '.scale.x'))
    setProperty(ghostTag .. '.scale.y', getProperty(char .. '.scale.y'))
    setProperty(ghostTag .. '.flipX', getProperty(char .. '.flipX'))
	setProperty(ghostTag .. '.antialiasing', getProperty(char .. '.antialiasing'))
    if getProperty('inSilhouette') then
        setProperty(ghostTag .. '.color', 0x000000)
    end
    setProperty(ghostTag .. '.alpha', 1)
	setProperty(ghostTag .. '.blend', getProperty(char .. '.blend'))
	setProperty(ghostTag .. '.shader', getProperty(char .. '.shader'))
    doTweenAlpha(ghostTag .. 'delete', ghostTag, 0, 0.4)

    local data = getGhostData(char)
    setProperty(ghostTag .. '.animation.frameName', data.frameName)
    setProperty(ghostTag .. '.offset.x', data.offsetX)
    setProperty(ghostTag .. '.offset.y', data.offsetY)
    setObjectOrder(ghostTag, getObjectOrder(char .. 'Group') - 1)
end

function onTweenCompleted(tag)
    if tag:sub(-6) == 'delete' then
        removeLuaSprite(tag:sub(1, -7), true)
    end
end

function updateGData(char)
    local data = getGhostData(char)
    data.frameName = getProperty(char .. '.animation.frameName')
    data.offsetX = getProperty(char .. '.offset.x')
    data.offsetY = getProperty(char .. '.offset.y')
end

function getGhostData(char)
    if char == 'boyfriend' then
        return boyfriendGhostData
    elseif char == 'dad' then
        return dadGhostData
    elseif char == 'gf' then
        return gfGhostData
    end
end
