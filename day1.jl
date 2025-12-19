function update_dial(x::Int, dir::AbstractString, n::Int, count_moduli::Bool=false)
    if dir == "L"
        y = x - n
        traversed = x:-1:y
    else
        y = x + n
        traversed = x:1:y
    end
    
    r = mod(y, 100)
    
    if count_moduli
        crossings = sum(mod.(traversed[2:end-1], 100) .== 0)
        return (r, crossings)
    else
        return r
    end
end

function match_instructions(instructions::AbstractVector{<:AbstractString})
    regex = r"^([LR])(\d+)"
    matches = match.(regex, instructions)
    output = [(m.captures[1], parse(Int, m.captures[2])) for m in matches]
    return output
end

function get_password(instructions::AbstractVector{<:AbstractString}; start::Int=50, add_crossings::Bool=false)
    directions = match_instructions(instructions)
    update_fns = [x -> update_dial(x, d[1], d[2], true) for d in directions]
    positions = accumulate((x, f) -> f(x[1]), update_fns, init = (start, 0))
    n_zeros = sum(getindex.(positions,1) .== 0)
    n_crossings = sum(getindex.(positions,2))
    if add_crossings
        return n_zeros + n_crossings
    else
        return n_zeros
    end
end

lines = readlines("day1_input.txt")
println("Password: ", get_password(lines))
println("Password 0x434C49434B: ", get_password(lines, add_crossings=true))