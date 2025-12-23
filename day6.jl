using DelimitedFiles

function read_input(filename::String)
    vals = readdlm(filename)
    numbers = Int.(vals[1:end-1, 1:end-1])
    ops = vals[end, 1:end-1]
    return numbers, ops
end

function read_cephalopod(filename::String)
    vals_mat = stack(readlines(filename)[1:end-1])
    n_rows = size(vals_mat,2)
    vals = [filter(x -> x != ' ', c) for c in eachslice(vals_mat, dims=1)]
    nums = [sum(parse.(Int, x) .* 10 .^ ((length(x)-1):-1:0)) for x in vals]
    idx = vcat([0,], findall(nums .== 0))
    rngs = [(idx[i]+1):(idx[i+1]-1) for i in 1:length(idx)-1]
    cnums = [nums[rng] for rng in rngs]
    return cnums
end

function do_column(numbers::AbstractArray, op::AbstractString)
    if op == "*"
        return reduce(*, numbers)
    elseif op == "+"
        return reduce(+, numbers)
    elseif op == "/"
        return reduce(/, numbers)
    elseif op == "-"
        return reduce(-, numbers)
    else
        error("Unrecognized cephalopod math op!!")
    end
end

function do_homework(numbers::AbstractMatrix{<:Real}, ops::AbstractVector)
    return sum([do_column(numbers[:,i], ops[i]) for i in 1:length(ops)])
end

nums, ops = read_input("day6_input.txt")
nums_2 = read_cephalopod("day6_input.txt")
println("Human homework: ", do_homework(nums, ops))
println("Cephalopod homework: ", [do_column(nums_2[i], ops[i]) for i in 1:length(ops)] |> sum)