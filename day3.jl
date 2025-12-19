function select_reduce(bank::String, n::Int)
    selection = bank[1:end-n]
    values = [parse(Int, char) for char in selection]
    ind = argmax(values)
    val = values[ind]
    substr = bank[ind+1:end]
    return (val, (substr, n-1))
end

function select_topn_digits(bank::String, n::Int)
    init = (0, (bank, n-1))
    range = collect(n-2:-1:-1)
    selection = accumulate((x,y) -> select_reduce(x[2][1], x[2][2]), range, init=init)
    values = [s[1] for s in selection]
    return values
end

function get_voltage(line::AbstractString, n::Int)
    selection = select_topn_digits(line, n)
    powers = 10 .^ (n-1:-1:0)
    value = sum([(p * v) for (p,v) in zip(powers, selection)])
    return value
end

lines = readlines("day3_input.txt");
println("Joltage: ", sum(get_voltage.(lines, 2)))
println("HIGH Joltage (danger): ", sum(get_voltage.(lines, 12)))