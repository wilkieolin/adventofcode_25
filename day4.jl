using DSP: conv

function make_2dmat(lines::AbstractVector{<:AbstractString})
    map_fn = x -> vcat([c == '@' for c in x])
    mat = stack(map_fn.(lines)) .* 1
end

function moore_kernel(r::Int)
    d = 2*r+1
    center = r+1
    k = ones(Int, (d,d))
    k[center, center] = 0
    return k
end

function get_accessible(inventory::AbstractMatrix; limit::Int=4)
    k = moore_kernel(1)
    neighbors = conv(inventory, k, algorithm = :direct)[2:end-1,2:end-1]
    return neighbors .< limit .* inventory
end

function get_paper(inventory::AbstractMatrix, total::Int)
    stock = get_accessible(inventory)
    if sum(stock) == 0
        return total
    else
        new_inventory = inventory .- stock
        total += sum(stock)
        return get_paper(new_inventory, total)
    end
end

m = make_2dmat(readlines("day4_input.txt"))
println("Accessible rolls: ", get_accessible(m) |> sum)
println("Total accessible rolls: ", get_paper(m, 0))