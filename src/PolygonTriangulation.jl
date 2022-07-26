module PolygonTriangulation

import Base:length,+,-,*,/

include("Vertex.jl")
include("utils.jl")
include("Polygon.jl")
include("findEar.jl")

export triangulate, Vertex, Polygon, +,-,*,/,⋅,×,norm,Hand,handedNess,Left,Right

function triangulate(p::Polygon)::Vector{Vector{Vertex}}
    q = Polygon(p.vertices)
    triangles = Vector{Vector{Vertex}}([])
    while length(q)>3
        ear = findEar(p,1)
        v = Vector{Vertex}([])
        for i in 1:length(q)
            if i != ear
                push!(v,q.vertices[i])
            end
        end
        @show q.vertices[ear]
        push!(triangles,[consecutiveTriple(q,ear)...])
        q = Polygon(v)
    end
    push!(triangles,[q.vertices...])
    return triangles
end

end # module
