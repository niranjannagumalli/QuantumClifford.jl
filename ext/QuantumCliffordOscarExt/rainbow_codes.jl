"""
Quantum Rainbow codes

Based on arXiv:2408.13130v3
"""
struct RainbowCode <: AbstractCSSCode
      Hx::AbstractMatrix{Bool}
      Hz::AbstractMatrix{Bool}  
end

parity_matrix_x(c::RainbowCode) = c.Hx
parity_matrix_z(c::RainbowCode) = c.Hz
code_n(c::RainbowCode) = size(c.Hx, 2)

# Helper function to convert a bipartite graph (represented by a parity check matrix) into a chain complex.
function _graph_to_chain_complex(H::AbstractMatrix)
    F = GF(2)
    H_oscar = matrix(F, H)
    nr, nc = size(H)
    V1 = free_module(F, nc)
    V0 = free_module(F, nr)
    ∂ = hom(V1, V0, H_oscar)
    return chain_complex([∂])
end

import Graphs

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


function RainbowCode(g1::Graphs.SimpleGraph, g2::Graphs.SimpleGraph, graphs:: Graphs.SimpleGraph...; code_type=:mixed)
    graphs = (g1, g2, graphs...)
    D = length(graphs)


    
    # Convert input graphs to Oscar.jl chain complexes
    foreach(_check_necessary_conditions_on_input_graphs, graphs)
    println("Input graphs provided: ", length(graphs))
    println(graphs)

    

    # Some dummy values for now to make it compile successfully
    # We will compute the actual Hx and Hz matrices later
    Hz = fill(false, 0, 0)
    Hx = fill(false, 0, 0)
    
    return RainbowCode(Hx, Hz)
end
