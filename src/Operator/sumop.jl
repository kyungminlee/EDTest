
export SumOperator

struct SumOperator{Scalar<:Number, BR <:Unsigned} <:AbstractOperator
  hilbert_space ::AbstractHilbertSpace
  terms ::Vector{OptionalPureOperator{Scalar, BR}} # SumOperator{Scalar, BR}, 

  function SumOperator{S, BR}(hs ::AbstractHilbertSpace, terms) where {S, BR}
    if any(!isa(t,  NullOperator) && t.hilbert_space !== hs for t in terms)
      throw(ArgumentError("Hilbert spaces don't match"))
    end
    return new{S, BR}(hs, terms)
  end
end

import Base.real, Base.imag

real(arg ::SumOperator{S, BR}) where {S<:Real, BR} = arg
imag(arg ::SumOperator{S, BR}) where {S<:Real, BR} = SumOperator{S, BR}(arg.hilbert_space, [])

real(arg ::SumOperator{Complex{S}, BR}) where {S<:Real, BR} = SumOperator{S, BR}(arg.hilbert_space, real.(arg.terms))
imag(arg ::SumOperator{Complex{S}, BR}) where {S<:Real, BR} = SumOperator{S, BR}(arg.hilbert_space, imag.(arg.terms))

(-)(arg ::SumOperator{S, BR}) where {S, BR} = SumOperator{S, BR}(arg.hilbert_space, -arg.terms)

function (*)(lhs ::S1, rhs ::SumOperator{S2, BR}) where {S1<:Number, S2<:Number, BR}
  S = promote_type(S1, S2)
  SumOperator{S, BR}(rhs.hilbert_space, lhs .* rhs.terms)
end

function (*)(lhs ::SumOperator{S1, BR}, rhs ::S2) where {S1<:Number, S2<:Number, BR}
  S = promote_type(S1, S2)
  SumOperator{S, BR}(lhs.hilbert_space, lhs.terms .* rhs)
end


function (*)(lhs::SumOperator{S1, BR}, rhs::PureOperator{S2, BR}) where {S1, S2, BR}
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces don't match"))
  end

  S3 = promote_type(S1, S2)
  return SumOperator{S3, BR}(lhs.hilbert_space, lhs.terms .* rhs)
end


function (*)(lhs::PureOperator{S1, BR}, rhs::SumOperator{S2, BR}) where {S1, S2, BR}
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces don't match"))
  end
  S3 = promote_type(S1, S2)
  return SumOperator{S3, BR}(rhs.hilbert_space, lhs .* rhs.terms)
end


function (*)(lhs::SumOperator{S1, BR}, rhs::SumOperator{S2, BR}) where {S1, S2, BR}
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces don't match"))
  end

  S3 = promote_type(S1, S2)
  return SumOperator{S3, BR}(lhs.hilbert_space, vec([tl * tr for tl in lhs.terms, tr in rhs.terms]))
end




function (+)(lhs::PureOperator{S1, BR}, rhs::PureOperator{S2, BR}) where {S1, S2, BR}
  S = promote_type(S1, S2)
  return SumOperator{S, BR}(lhs.hilbert_space, [lhs, rhs])
end


function (+)(lhs::SumOperator{S1, BR}, rhs::PureOperator{S2, BR}) where {S1, S2, BR}
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces don't match"))
  end

  S3 = promote_type(S1, S2)
  return SumOperator{S3, BR}(lhs.hilbert_space, PureOperator{S3, BR}[lhs.terms..., rhs])
end


function (+)(lhs::PureOperator{S1, BR}, rhs::SumOperator{S2, BR}) where {S1, S2, BR}
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces don't match"))
  end

  S3 = promote_type(S1, S2)
  return SumOperator{S3, BR}(lhs.hilbert_space, PureOperator{S3, BR}[lhs, rhs.terms...])
end


function (+)(lhs::SumOperator{S1, BR}, rhs::SumOperator{S2, BR}) where {S1, S2, BR}
  if lhs.hilbert_space !== rhs.hilbert_space
    throw(ArgumentError("Hilbert spaces don't match"))
  end

  S3 = promote_type(S1, S2)
  return SumOperator{S3, BR}(lhs.hilbert_space, PureOperator{S3, BR}[lhs.terms..., rhs.terms...])
end











function prettyprintln(op::SumOperator{S, BR}; prefix::AbstractString="") where {S, BR}
  println(prefix, "SumOperator")
  for t in op.terms
    prettyprintln(t; prefix=string(prefix, "  "))
  end
end
