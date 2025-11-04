PersistentVars = {}

---checks if all entries of a vore data are correct and adds missing / removes extra fileds
---@param checkTable table table to check
---@param entryTable table entry example
---@param tableName string table name for logging
local function VO_CheckData(checkTable, entryTable, tableName)
    for k, v in pairs(checkTable) do
        for i, j in pairs(entryTable) do
            if v[i] == nil then
                _F('Character: ' .. k)
                _F('Missing value: ' .. i)
                if type(j) == "table" then
                    checkTable[k][i] = VO_Deepcopy(j)
                else
                    checkTable[k][i] = j
                end
            end
        end
        for i, _ in pairs(v) do
            if entryTable[i] == nil then
                _F('Character: ' .. k)
                _F('Unknown value: ' .. i)
                checkTable[k][i] = nil
            end
        end
    end
end

---sets up all vore datas and checks them
function VO_SetupData()
    if PersistentVars['PredData'] == nil then
        PersistentVars['PredData'] = {}
    end
    PredData = PersistentVars['PredData']
    VO_CheckData(PredData, PredEntry, "PredData")

    if PersistentVars['PreyData'] == nil then
        PersistentVars['PreyData'] = {}
    end
    PreyData = PersistentVars['PreyData']
    VO_CheckData(PreyData, PreyEntry, "PreyData")

    if PersistentVars['VoreLvlData'] == nil then
        PersistentVars['VoreLvlData'] = {}
    end
    VoreLvlData = PersistentVars['VoreLvlData']
    VO_CheckData(VoreLvlData, LevelEntry, "VoreLevelData")

    if PersistentVars['VorePerData'] == nil then
        PersistentVars['VorePerData'] = {}
    end
    VorePerData = PersistentVars['VorePerData']
    VO_CheckData(VorePerData, PersistentEntry, "VorePersistentData")
end
