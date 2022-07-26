#=
    An ear is a convex vertex such that the triangle
    formed by it and it's neighbours contains
    no other vertex

    A convex vertex is has an interior angle < \pi
    formed by the lines to it's neighbours
=#
function isEar(p::Polygon,i::Int)::Bool
    if angleSign(p,i) == Left
        return false
    end

    tri = consecutiveTriple(p,i)

    for v in p.vertices
        if (v != tri[1] && v != tri[2] && v != tri[3])
            if (pointInTriangle(v,tri...))
                return false
            end
        end
    end

    return true
end

function isEar(p::Polygon,v::Vertex)::Bool
    id = 0
    for i in 1:length(p)
        if p.vertices[i] == v
            id = i
            return isEar(p,i)
        end
    end
    return false
end

function findDiagonal(p::Polygon,i::Int,events::MaybeEvents)::Tuple{Int,Int}
    n = length(p)
    a,b,c = consecutiveTriple(p,i)
    bisector = angleBisector(p,i)
    ray = bisector

    if (angleSign(p,i)==Left)
        ray = -1.0*ray
    end

    ray = ray / norm(ray)

    if (events != nothing) push!(events,BisectorEvent(b,ray)) end

    E = edges(p)
    e = nextIndex(i,n) #mod((i-1)+1,n)+1
    seen = 0
    edge = E[e]
    intersection = lineLineSegmentIntersection(b,ray,edge[1],edge[2])

    if (intersection == NULL_VERTEX)
        seen += 1
        e+=1
        if (e > length(p)) e = 1 end
    end

    while (seen < length(E) && intersection == NULL_VERTEX)
        edge = E[e]
        intersection = lineLineSegmentIntersection(b,ray,edge[1],edge[2])
        if (intersection == NULL_VERTEX)
            e+=1
            seen += 1
            if (e > length(p)) e = 1 end
        else
            break
        end
    end

    for (v,j) in enumerate(p.vertices)
        if (v == intersection)
            return i,j
        end
    end

    if (events != nothing) push!(events,IntersectionEvent(intersection)) end


    pk = edge[1] # p_{k}
    pk1 = edge[2] # p_{k+1}

    if (events != nothing) push!(events,TestingTriangleEvent(b,intersection,pk1)) end
    R = Vector{Int}([])
    s = nextIndex(e+1,n) #mod((e-1)+2,n)+1
    while s != i
        if (pointInTriangleInterior(p.vertices[s],b,intersection,pk1))
            push!(R,s)
        end
        s += 1
        if (s > n)
            s = 1
        end
    end

    if (length(R)==0)

        if (pk1 != a)
            return i,nextIndex(e,n)#mod((e-1)+1,n)+1
        end

        #return i,mod((i-1)-1,n)+1

    else
        θs = zeros(length(R))
        for (j,r) in enumerate(R)
            θs[j] = angle(intersection,b,p.vertices[r])
        end

        z = R[argmin(θs)]

        if (z != previousIndex(i,n))
            return i,z
        end
    end

    z = a # p_{i-1}

    if (events != nothing) push!(events,TestingTriangleEvent(b,intersection,pk)) end

    S = Vector{Int}([])
    s = nextIndex(i,n) # mod((i-1)+1,n)+1
    while s != mod((e-1),n)+1
        if (pointInTriangleInterior(p.vertices[s],b,intersection,pk))
            push!(S,s)
        end
        s += 1
        if (s > n)
            s = 1
        end
    end

    if (length(S)==0)
        if (pk != c)
            return i,e
        end
    else

        w = c

        θs = zeros(length(S))
        for (j,s) in enumerate(s)
            θs[j] = angle(intersection,b,p.vertices[s])
        end

        w = S[argmin(θs)]

        return i,w

    end

    return i,i

end

function isGood(p::Polygon,q::Polygon)::Bool
    diff = 0
    pe = PolygonTriangulation.edges(p)
    for e in PolygonTriangulation.edges(q)
        if (e in pe)==false
            diff+=1
        end

        if (diff > 1)
            return false
        end
    end

    if diff <= 1
        return true
    else
        return false
    end
end

function goodSubPolygon(p::Polygon,q::Polygon,i::Int,j::Int)::Polygon
    v = []
    k = i
    while k != j
        push!(v,q.vertices[k])
        k+=1
        if (k > length(q))
            k = 1
        end
    end
    push!(v,q.vertices[j])

    gsp = Polygon(v)

    if isGood(p,gsp)
        return gsp
    end

    v = []
    k = j
    while k != i
        push!(v,q.vertices[k])
        k+=1
        if (k > length(q))
            k = 1
        end
    end
    push!(v,q.vertices[i])

    return Polygon(v)

end

function relabel(p::Polygon,q::Polygon,i::Int,j::Int)::Polygon
    v = []
    k = i
    for l in 1:length(p)
        push!(v,p.vertices[k])
        k += 1
        if (k > length(p))
            k = 1
        end
    end
    return Polygon(v)
end

function findEar(p::Polygon,q::Polygon,i::Int,events::MaybeEvents=nothing)::Vertex

    if (events != nothing) push!(events,TestingVertexEvent(q.vertices[i])) end

    if isEar(p,q.vertices[i])
        return q.vertices[i]
    end

    i,j = findDiagonal(q,i,events)

    if (events != nothing) push!(events,FoundDiagonalEvent(q.vertices[i],q.vertices[j])) end

    if (j == i)
        return q.vertices[i]
    end

    q = goodSubPolygon(p,q,i,j)

    if (events != nothing) push!(events,GoodSubPolygonEvent(q)) end

    return findEar(p,q,Int(1+floor(length(q)/2.0)),events)
end
