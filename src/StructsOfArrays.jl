module StructsOfArrays
export StructOfArrays

struct StructOfArrays{T,N,U<:Tuple} <: AbstractArray{T,N}
    arrays::U
end

@generated function StructOfArrays(::Type{T}, dims::Integer...) where T
    (!isleaftype(T) || T.mutable) && return :(throw(ArgumentError("can only create an StructOfArrays of leaf type immutables")))
    isempty(T.types) && return :(throw(ArgumentError("cannot create an StructOfArrays of an empty or bitstype")))
    N = length(dims)
    arrtuple = Tuple{[Array{T.types[i],N} for i = 1:length(T.types)]...}
    :(StructOfArrays{T,$N,$arrtuple}(($([:(Array{$(T.types[i])}(dims)) for i = 1:length(T.types)]...),)))
end
StructOfArrays(T::Type, dims::Tuple{Vararg{Integer}}) = StructOfArrays(T, dims...)

Base.IndexStyle(::Type{T}) where {T <: StructOfArrays} = IndexLinear()

@generated function Base.similar(A::StructOfArrays, ::Type{T}, dims::Dims) where {T}
    if isbits(T) && length(T.types) > 1
        :(StructOfArrays(T, dims))
    else
        :(Array(T, dims))
    end
end

Base.convert(::Type{StructOfArrays{T,N}}, A::AbstractArray{S,N}) where {T,S,N} =
    copy!(StructOfArrays(T, size(A)), A)
Base.convert(::Type{StructOfArrays{T}}, A::AbstractArray{S,N}) where {T,S,N} =
    convert(StructOfArrays{T,N}, A)
Base.convert(::Type{StructOfArrays}, A::AbstractArray{T,N}) where {T,N} =
    convert(StructOfArrays{T,N}, A)

Base.size(A::StructOfArrays) = size(A.arrays[1])
Base.size(A::StructOfArrays, d) = size(A.arrays[1], d)

@generated function Base.getindex(A::StructOfArrays{T}, i::Integer...) where {T}
    Expr(:block, Expr(:meta, :inline), Expr(:meta, :propagate_inbounds),
         Expr(:new, T, [:(A.arrays[$j][i...]) for j = 1:length(T.types)]...))
end
@generated function Base.setindex!(A::StructOfArrays{T}, x, i::Integer...) where {T}
    quote
        Base.@_inline_meta
        Base.@_propagate_inbounds_meta
        $(Expr(:meta, :inline))
        v = convert(T, x)
        $([:(A.arrays[$j][i...] = getfield(v, $j)) for j = 1:length(T.types)]...)
        x
    end
end
end # module
