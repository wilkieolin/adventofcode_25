function split_input(input::AbstractVector{<:AbstractString})
    i = findfirst(input .== "")
    range_regex = r"(\d+)-(\d+)"
    ranges = match.(range_regex, input[1:i-1])
    str_2_int = x -> parse(Int, x)
    ranges = [str_2_int(r.captures[1]):str_2_int(r.captures[2]) for r in ranges]
    ids = str_2_int.(input[i+1:end])
    return (ranges, ids)
end

function is_fresh(id::Int, ranges::AbstractVector{<:UnitRange})
    return reduce(+, [id in r for r in ranges]) > 0
end

function overlap_ranges(range_a::UnitRange, range_b::UnitRange)
    if range_a[end] in range_b || range_a[1] in range_b
        new_range = min(range_a[1], range_b[1]):max(range_a[end], range_b[end])
        return (new_range, true)
    else
        return (range_a, false)
    end
end

function merge_ranges(ranges::AbstractVector{<:UnitRange}, init_ind::Int=1)
    merges = accumulate((x,y) -> overlap_ranges(x[1],y), ranges, init=(ranges[init_ind], true))
    new_range = merges[end][1]
    eaten = getindex.(merges, 2)
    remaining = ranges[map(!, eaten)]
    return vcat([new_range], remaining)
end

function squeeze_ranges(ranges::AbstractVector{<:UnitRange})
    last_n = length(ranges)
    for _ in 1:length(ranges)
        while true
            last_n = length(ranges)
            ranges = merge_ranges(ranges)
            new_n = length(ranges)
            if (last_n - new_n) == 0 break end
        end
        circshift!(ranges, 1)
    end
    return ranges
end

ranges, ids = split_input(readlines("day5_input.txt"));
println("Fresh ingredients: ", [is_fresh(id, ranges) for id in ids] |> sum)
println("Total fresh IDs (but at what cost...) ", squeeze_ranges(ranges) .|> length |> sum)