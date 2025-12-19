using DelimitedFiles
using Base.Iterators: partition

function extract_range(line::AbstractString)
    regex = r"(\d+)-(\d+)"
    m = match(regex, line)
    start = parse(Int, m.captures[1])
    stop = parse(Int, m.captures[2])
    return start:stop
end

function is_valid(id::Int)
    s = string(id)
    n_digits = length(s)
    if mod(n_digits, 2) != 0
        return 0
    end

    halfway = floor(Int, n_digits / 2)
    front = s[1:halfway]
    back = s[halfway+1:end]
    if front == back
        return id
    end
    return 0
end

function invalid_ids_sum(range::UnitRange)
    return sum(is_valid.(range))
end

function easy_factor(i::Int)
    possibilities = collect(1:i)
    remainders = mod.(i, possibilities)
    factors = Set(possibilities[remainders .== 0])
    useful_factors = setdiff(factors, Set((i,)))
    return useful_factors
end

function is_valid_2(id::Int)
    s = string(id)
    n_digits = length(s)
    factors = easy_factor(n_digits)
    for f in factors
        substrings = collect(partition(s, f))
        all_same = foldl((x, y) -> x == y ? x : "", substrings)
        if all_same != ""
            return id
        end
    end
    return 0
end

function invalid_ids_sum_2(range::UnitRange)
    return sum(is_valid_2.(range))
end

text = readdlm("day2_input.txt", ',')
ranges = extract_range.(text)
println("First sum: ", sum(invalid_ids_sum.(ranges)))
println("Second sum: ", sum(invalid_ids_sum_2.(ranges)))