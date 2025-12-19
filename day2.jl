using DelimitedFiles
using Base.Iterators: partition

function extract_range(line::AbstractString)
    regex = r"(\d+)-(\d+)"
    m = match(regex, line)
    start = parse(Int, m.captures[1])
    stop = parse(Int, m.captures[2])
    return start:stop
end

function easy_factor(i::Int)
    possibilities = collect(1:i)
    remainders = mod.(i, possibilities)
    factors = Set(possibilities[remainders .== 0])
    useful_factors = setdiff(factors, Set((i,)))
    return useful_factors
end

function is_valid(id::Int, even_only::Bool = false)
    s = string(id)
    n_digits = length(s)
    if even_only
        if mod(n_digits, 2) == 0
            factors = Set((floor(Int, n_digits/2,)))
        else
            return 0
        end
    else
        factors = easy_factor(n_digits)
    end

    for f in factors
        substrings = collect(partition(s, f))
        all_same = foldl((x, y) -> x == y ? x : "", substrings)
        if all_same != ""
            return id
        end
    end
    return 0
end

function invalid_ids_sum_even(range::UnitRange)
    return sum(is_valid.(range, true))
end

function invalid_ids_sum(range::UnitRange)
    return sum(is_valid.(range, false))
end

text = readdlm("day2_input.txt", ',')
ranges = extract_range.(text)
println("First sum: ", sum(invalid_ids_sum_even.(ranges)))
println("Second sum: ", sum(invalid_ids_sum.(ranges)))