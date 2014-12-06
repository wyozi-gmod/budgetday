local points = {}

hook.Add("Think", "DBSCAN", function()
    if #points == 0 then return end

    local DB = bd.util.Map(points, function(p)
        return {pos = p}
    end)

    local clusters = {}

    local eps = 512
    local MinPts = 2

    local function RegionQuery(p, eps)
        local n = {}
        for _,sp in pairs(DB) do
            if p ~= sp and p.pos:Distance(sp.pos) < eps then
                n[#n+1] = sp
            end
        end
        return n
    end

    local function SetCluster(p, c)
        c.points[#c.points+1] = p
        p.cluster = c
    end

    local function ExpandCluster(p, NeighborPts, c, eps, MinPts)
        SetCluster(p, c)
        for _,p2 in pairs(NeighborPts) do
            if not p2.visited then
                p2.visited = true
                local NeighborPts2 = RegionQuery(p2, eps)
                if #NeighborPts2 >= MinPts then
                    table.Add(NeighborPts, NeighborPts2)
                end
            end
            if not p2.cluster then
                SetCluster(p2, c)
            end
        end
    end

    local function Iteratep(p)
        if p.visited then return end

        p.visited = true
        local NeighborPts = RegionQuery(p, eps)
        if #NeighborPts < MinPts then
            p.noise = true
        else
            local c = {points = {}}
            clusters[#clusters+1] = c

            ExpandCluster(p, NeighborPts, c, eps, MinPts)
        end

    end

    for _,p in pairs(DB) do
        Iteratep(p)
    end

    for _,p in pairs(DB) do
        local clr = Color(127, 127, 127)
        if not p.noise then
            clr = HSVToColor(table.KeyFromValue(clusters, p.cluster)*45, 1, 1)
        end
        debugoverlay.Sphere(p.pos, 16, 0.1, clr)
    end

    PrintTable(DB)

end)

concommand.Add("bd_debug_dbscan_point", function()
    local p = LocalPlayer():EyePos()
    table.insert(points, p)
end)
