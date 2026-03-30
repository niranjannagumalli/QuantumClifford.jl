abstract type RainbowCode <: AbstractCSSCode end

"""
Quantum Rainbow codes

Based on arXiv:2408.13130v3
"""


struct HGPRainbow <: RainbowCode
    Hx::AbstractMatrix{Bool}
    Hz::AbstractMatrix{Bool}
end


struct GradedGraph
    graph::SimpleGraph{Int}
    levels::Vector{Int} # 0 or 1 for bipartite input graphs
    
    function GradedGraph(g::SimpleGraph)
        # Automatically find the bipartite partition since input is bipartite
        part = bipartite_map(g)
        # bipartite_map returns a vector of 1s and 2s; we'll shift to 0 and 1
        return new(g, [p - 1 for p in part])
    end
    
    # Internal constructor for products
    GradedGraph(g, l) = new(g, l)
end

function product_with_levels(gg1::GradedGraph, gg2::GradedGraph)
    # 1. Standard Graphs.jl Cartesian product
    g_prod = cartesian_product(gg1.graph, gg2.graph)
    
    n1 = nv(gg1.graph)
    n2 = nv(gg2.graph)
    new_levels = zeros(Int, n1 * n2)
    
    # 2. Assign labels: L = l1 + l2
    for v2 in 1:n2
        for v1 in 1:n1
            # Graphs.jl indexing logic for products
            new_idx = (v2 - 1) * n1 + v1
            new_levels[new_idx] = gg1.levels[v1] + gg2.levels[v2]
        end
    end
    
    return GradedGraph(g_prod, new_levels)
end


function _check_necessary_conditions_on_input_graphs(g::Graphs.SimpleGraph)
    if !Graphs.is_bipartite(g)
        throw(ArgumentError("Input graph is not bipartite. Rainbow codes require bipartite graphs."))
    end
    if !Graphs.is_connected(g)
        throw(ArgumentError("Input graph is not connected. Rainbow codes require connected graphs."))
    end
    if !all(iseven, Graphs.degree(g))
        throw(ArgumentError("Input graph does not have all even degrees. Rainbow codes require even-degree graphs."))
    end
    
end

function find_all_flags(gg::GradedGraph, D::Int)
    all_flags = Vector{Vector{Int}}()
    
    # Start DFS from every node at Level 0
    start_nodes = findall(x -> x == 0, gg.levels)
    # println("Starting DFS from nodes at Level 0: ", start_nodes)
    
    for start in start_nodes
        # Recursive helper to find paths
        _dfs_flags!(all_flags, [start], gg, D)
    end
    println("Total Flags Found: ", length(all_flags))
    println("all flags: ", all_flags)
    return all_flags
end

function _dfs_flags!(all_flags, current_path, gg, D)
    curr_node = current_path[end]
    curr_level = gg.levels[curr_node]
    
    if curr_level == D
        push!(all_flags, copy(current_path))
        return
    end
    
    # Only move to neighbors that are exactly one level higher
    for neighbor in neighbors(gg.graph, curr_node)
        if gg.levels[neighbor] == curr_level + 1
            push!(current_path, neighbor)
            _dfs_flags!(all_flags, current_path, gg, D)
            pop!(current_path) # Backtrack
        end
    end
end

"""
Constructs the Simplex Graph where nodes are flags.
Edges are added if flags differ at exactly one level.
"""
function build_simplex_graph(flags::Vector{Vector{Int}}, D::Int)
    num_flags = length(flags)
    simplex_g = SimpleGraph(num_flags)
    
    # Store edge colors: (edge_index) -> color_index
    # Or more simply: (u, v) -> level_where_they_differ
    edge_colors = Dict{Edge, Int}()
    
    # Compare paths (O(N^2) - fine for small/medium complexes)
    for i in 1:num_flags
        for j in (i+1):num_flags
            diff_indices = findall(k -> flags[i][k] != flags[j][k], 1:(D+1))
            
            if length(diff_indices) == 1
                level_idx = diff_indices[1] - 1 # 0-indexed level
                add_edge!(simplex_g, i, j)
                println("Adding edge between Flag $i and Flag $j at level $level_idx")
                edge_colors[Edge(i, j)] = level_idx
            end
        end
    end
    
    return simplex_g, edge_colors
end

#helper function to which returns all s-maximal subgraphs of the simplex graph for a given s
function maximal_subgraphs(simplex_g::SimpleGraph, edge_colors::Dict{Edge, Int}, s::Int)

    # We want to find all maximal subgraphs that only contain edges of
end

function rainbow_subgraphs(simplex_g::SimpleGraph, edge_colors::Dict{Edge, Int}, s::Int)
    # We want to find all subgraphs that contain at least one edge of each color from 0 to s-1
end



function HGPRainbow(g1::Graphs.SimpleGraph, g2::Graphs.SimpleGraph, graphs:: Graphs.SimpleGraph...; code_type=:mixed)
    graphs = (g1, g2, graphs...)
    D = length(graphs)


    
    #check if the input graphs satisfy the necessary conditions for constructing a Rainbow code
    foreach(_check_necessary_conditions_on_input_graphs, graphs)

    graded_graphs = [GradedGraph(g) for g in graphs]

    g_prod = graded_graphs[1]
    for i in 2:D
        g_prod = product_with_levels(g_prod, graded_graphs[i])
    end
    
    flags = find_all_flags(g_prod, D) # Max level is 3 (2 from g1 + 1 from g2)
    println("Total Flags (Nodes in Simplex Graph): ", flags)

    # 2. Build the Simplex Graph
    simplex_g, edge_colors = build_simplex_graph(flags, D)

    # 3. Prepare the labels and colors
    # We use a Dictionary mapping (src, dst) -> value to avoid DimensionMismatch
    labels_dict = Dict()
    

    for e in edges(simplex_g)
        level_idx = edge_colors[e]
        # We want the actual level number displayed on the edge
        labels_dict[(src(e), dst(e))] = string(level_idx)
        
    end


    # if code_type= :pin, then all the X stabilizers are x-maximal subgraphs of the simplex graph and the Z stabilizers are z-maximal subgraphs of the simplex graph. If code type is mixed, then we take the union of the x-maximal and z-maximal subgraphs as the X and Z stabilizers respectively.
    # else if code_type =: generic, X stabilizers are the x-maximal subgraphs of the simplex graph and Z stabilizers are the z-rainbow subgraphs of the simplex graph.
    # else if code_type =: anti_generic, X stabilizers are the x-rainbow subgraphs of the simplex graph and Z stabilizers are the z-maximal subgraphs of the simplex graph.
    # else if code_type =: mixed, X stabilizers are some x-maximal and some x-rainbow subgraphs. Z stabilizers are some z-maximal and some z-rainbow subgraphs of the simplex graph.
    # else, throw an error that the code type is not supported.


    # Some dummy values for now to make it compile successfully
    # We will compute the actual Hx and Hz matrices later
    Hz = fill(false, 0, 0)
    Hx = fill(false, 0, 0)
    
    return HGPRainbow(Hx, Hz)
end


parity_matrix_x(c::HGPRainbow) = c.Hx
parity_matrix_z(c::HGPRainbow) = c.Hz
code_n(c::HGPRainbow) = size(c.Hx, 2)

