export SparseState

mutable struct SparseState{Scalar<:Number, BR}
  hilbert_space ::AbstractHilbertSpace
  components ::DefaultDict{BR, Scalar, Scalar}
  function SparseState{Scalar, BR}(hs ::AbstractHilbertSpace) where {Scalar, BR}
    return new{Scalar, BR}(hs, DefaultDict{BR, Scalar, Scalar}(zero(Scalar)))
  end

  function SparseState{Scalar, BR}(hs ::AbstractHilbertSpace, binrep ::BR) where {Scalar, BR}
    components = DefaultDict{BR, Scalar, Scalar}(zero(Scalar))
    components[binrep] = one(Scalar)
    return new{Scalar, BR}(hs, components)
  end
end

import Base.getindex, Base.setindex!

function Base.getindex(state ::SparseState{Scalar, BR}, basis ::BR) where {Scalar, BR}
  # TODO: check hilbert space
  return state.components[basis]
end

function Base.setindex!(state ::SparseState{Scalar, BR}, value ::Scalar, basis ::BR) where {Scalar, BR}
  # TODO: check hilbert space
  Base.setindex!(state.components, value, basis)
end

import Base.-, Base.+, Base.*, Base./

function (-)(arg ::SparseState{S, BR}) where {S, BR}
  out = SparseState{S, BR}(arg.hilbert_space, )
  for (b, v) in arg.components
    out[b] -= v
  end
end

function (+)(lhs ::SparseState{S1, BR}, rhs ::SparseState{S2, BR}) where {S1, S2, BR}
  S3 = promote_type(S1, S2)
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces of lhs and rhs of + should match"))
  end
  out = SparseState{S3, BR}(lhs.hilbert_space)
  for (b, v) in lhs.components
    out[b] += v
  end
  for (b, v) in rhs.components
    out[b] += v
  end
  return out 
end

function (-)(lhs ::SparseState{S1, BR}, rhs ::SparseState{S2, BR}) where {S1, S2, BR}
  S3 = promote_type(S1, S2)
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces of lhs and rhs of + should match"))
  end
  out = SparseState{S3, BR}(lhs.hilbert_space)
  for (b, v) in lhs.components
    out[b] += v
  end
  for (b, v) in rhs.components
    out[b] -= v
  end
  return out 
end

function (*)(lhs ::SparseState{S1, BR}, rhs ::S2) where {S1, S2<:Number, BR}
  S3 = promote_type(S1, S2)
  out = SparseState{S3, BR}(lhs.hilbert_space)
  for (b, v) in lhs.components
    out[b] += v * rhs
  end
  return out
end

function (*)(lhs ::S1, rhs ::SparseState{S2, BR}) where {S1<:Number, S2<:Number, BR}
  S3 = promote_type(S1, S2)
  out = SparseState{S3, BR}(rhs.hilbert_space)
  for (b, v) in rhs.components
    out[b] += lhs * v
  end
  return out
end


function (/)(lhs ::SparseState{S1, BR}, rhs ::S2) where {S1, S2<:Number, BR}
  S3 = promote_type(S1, S2)
  out = SparseState{S3, BR}(lhs.hilbert_space)
  for (b, v) in lhs.components
    out[b] += v / rhs
  end
  return out
end


function prettyprintln(psi::SparseState{S, BR}; prefix::AbstractString="") where {S, BR}
  println(prefix, "SparseState")
  bs = sort(collect(keys(psi.components)))
  for b in bs
    println(prefix, "  ", string(b, base=2, pad=psi.hilbert_space.bitoffsets[end]), " : ", psi.components[b])
  end
end