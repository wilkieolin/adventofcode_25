using Graphs
using Random: AbstractRNG

map_initcond(str::AbstractString) = [c == 'S' ? 1 : 0 for c in str]
map_splitter(str::AbstractString) = [c == '^' ? 1 : 0 for c in str]

function advance_state(tachyons::AbstractVector{<:Int}, splitters::AbstractVector{<:Int})
    p = tachyons .* splitters
    new_state = deepcopy(tachyons)

    idx = findall(p .> 0)
    new_state[idx] .= 0
    idx = collect(union(Set(idx .+ 1), Set(idx .- 1)))
    idx = filter(x -> x >= 1 && x <= length(tachyons), idx)
    new_state[idx] .+= 1
    return new_state
end

function advance_state_quantum(tachyons::AbstractVector{<:Int}, splitters::AbstractVector{<:Int}, rng::AbstractRNG)
    p = tachyons .* splitters
    new_state = deepcopy(tachyons)

    idx = findall(p .> 0)
    new_state[idx] .= 0
    idx = idx .+ rand(rng, (-1,1), length(idx))
    idx = filter(x -> x >= 1 && x <= length(tachyons), idx)
    new_state[idx] .+= 1
    return new_state
end

function run_sim(splitters::AbstractVector{<:AbstractVector{<:Int}}, init_tachyons::AbstractVector{<:Int})
    tachyons = [init_tachyons,]
    for splitter in splitters
        new_tachyons = advance_state(tachyons[end], splitter)
        push!(tachyons, new_tachyons)
    end
    return tachyons
end

function load_file(input::String)
    lines = readlines(input)
    t0 = map_initcond(lines[1])
    ms = map_splitter.(lines[2:end])
    return t0, ms
end

function propagate(input::String)
    t0, ms = load_file(input)
    tachyons = run_sim(ms, t0) |> stack
    return (tachyons, stack(ms))
end

count_overlaps(tachyons::AbstractMatrix, splitters::AbstractMatrix) = sum((tachyons[:, 1:end-1] .* splitters) .> 0)

function count_splitters(input::String)
    return count_overlaps(propagate(input)...)
end

println("Number of splits or whatever: ", count_splitters("day7_input.txt"))

function get_active_nodes(tachyons::AbstractMatrix{<:Int}, splitters::AbstractMatrix{<:Int})
    return findall(tachyons[:,1:end-1] .* splitters .> 0)
end

function get_end_nodes(tachyons::AbstractMatrix{<:Int})
    rows = findall(tachyons[:,end] .> 0)
    n_cols = size(tachyons,2)
    return [CartesianIndex(r, n_cols) for r in rows]
end

function get_all_nodes(tachyons::AbstractMatrix{<:Int}, splitters::AbstractMatrix{<:Int})
    return vcat(get_active_nodes(tachyons, splitters), get_end_nodes(tachyons))
end

function find_sources(tachyons::AbstractMatrix{<:Int}, active_nodes::AbstractVector{<:CartesianIndex})
    function find_path(node)
        row = node[1]
        column = node[2]
        stop = findlast((tachyons[row,:] .== 0) .* (1:size(tachyons,2) .< column))
        if stop === nothing stop = 1 end
        return (stop, column)
    end
    
    return (active_nodes, find_path.(active_nodes))
end

function get_edge_map(nodes::AbstractVector{<:CartesianIndex})
    mapper = Dict()
    for (i,n) in enumerate(nodes)
        mapper[n] = i
    end
    return mapper
end

function match_source(nodes::AbstractVector{<:CartesianIndex}, sources::AbstractVector{<:Tuple{<:Int,<:Int}})
    mapper = get_edge_map(nodes)

    edges = []
    function match_individual(node::CartesianIndex, source::Tuple{<:Int, <:Int})
        row = node[1]
        start_col = source[1]
        end_col = node[2] - 1
        
        if start_col == 1 #source node
            push!(edges, Edge(length(nodes)+1, mapper[node]))
            return
        end 

        found = 0
        for col in start_col:end_col
            left_origin = CartesianIndex(row-1, col)
            right_origin = CartesianIndex(row+1, col)
            if left_origin in nodes 
                found += 1
                push!(edges, Edge(mapper[left_origin], mapper[node]))
            end
            if right_origin in nodes
                found += 1
                push!(edges, Edge(mapper[right_origin], mapper[node]))
            end
        end

        if found == 0
            println("Node: ", node)
            println("Source: ", source)
            error("No origin node found!!! :'(")
        else
            #print("Found ", found)
        end
    end

    for i in 1:length(nodes)
        match_individual(nodes[i], sources[i])
    end
    return edges

end

function predecessors(graph::SimpleDiGraph, node::Int)
    pred = []
    for e in edges(graph)
        if e.dst == node
            append!(pred, e.src)
        end
    end
    return pred
end

function label_edge(graph::SimpleDiGraph, node::Int, labeled_nodes::Dict{Tuple, Int})
    n_paths = sum([k[2] == node ? v : 0 for (k,v) in labeled_nodes])
    children = neighbors(graph, node)
    my_edges = Dict(((node, c) => n_paths) for c in children)
    new_dict = merge(labeled_nodes, my_edges)
    return new_dict, children
end

function apply_labels(graph::SimpleDiGraph)
    root_node = nv(graph)
    dfs = dfs_tree(graph, root_node)
    dists = gdistances(graph, root_node)
    labels = Dict{Tuple, Int}((root_node, 1) => 1,)
    println("Starting labeling... ")

    while true
        for node in vertices(graph)
            pred_nodes = predecessors(graph, node)
            if length(pred_nodes) > 0
                all_in = reduce(*, [(p, node) in keys(labels) for p in pred_nodes])
                if all_in
                    labels, _ = label_edge(graph, node, labels)
                end
            end
        end

        print(length(keys(labels)), " ")
        
        if length(keys(labels)) == ne(graph)
            break
        end
    end
    print("\n")
    return labels
end 

function analyze_tree_paths(input::AbstractString)
    ts, ms = propagate(input)
    msm = stack(ms)

    nodes = get_all_nodes(ts, msm)
    nodes, srcs = find_sources(ts, nodes)
    edges = match_source(nodes, srcs)
    graph = SimpleDiGraphFromIterator(edges)
    println("Constructed graph: ", nv(graph), " nodes and ", ne(graph), " edges.")
    
    mapper = get_edge_map(nodes)
    end_nodes = [mapper[i] for i in get_end_nodes(ts)]
    label_dict = apply_labels(graph)
    
    ps = []
    for (k,v) in label_dict
        if k[2] in end_nodes
            append!(ps, v)
        end
    end

    return sum(ps)
end
    
println("UUUUUHHHHHGHHH ", analyze_tree_paths("day7_input.txt"))