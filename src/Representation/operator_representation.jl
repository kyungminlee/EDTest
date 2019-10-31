export OperatorRepresentation
export represent
export apply!, apply_serial!, apply_parallel!

struct OperatorRepresentation{HSR <:HilbertSpaceRepresentation, S<:Number, O<:AbstractOperator} <: AbstractOperatorRepresentation{S}
  hilbert_space_representation ::HSR
  operator ::O

  function OperatorRepresentation(hsr ::HSR, op ::O) where {HSR<:HilbertSpaceRepresentation, O<:AbstractOperator}
    S = scalartype(op)
    new{HSR, S, O}(hsr, op)
  end
  # function OperatorRepresentation{HSR, O}(hsr ::HSR, op ::O) where {HSR<:HilbertSpaceRepresentation, O<:AbstractOperator}
  #   S = scalartype(op)
  #   new{HSR, S, O}(hsr, op)
  # end
end

function represent(hsr ::HSR, op ::O) where {HSR<:HilbertSpaceRepresentation, O<:AbstractOperator}
  return OperatorRepresentation(hsr, op)
end


@inline spacetype(lhs::Type{OperatorRepresentation{HSR, S, O}}) where {HSR, S, O} = HSR
@inline operatortype(lhs ::Type{OperatorRepresentation{HSR, S, O}}) where {HSR, S, O} = O
@inline get_space(lhs ::OperatorRepresentation{HSR, S, O}) where {HSR, S, O} = lhs.hilbert_space_representation ::HSR



import LinearAlgebra.issymmetric
function issymmetric(arg::OperatorRepresentation{HSR, S, O}) where {HSR, S, O}
  return issymmetric(arg.operator)
end


import LinearAlgebra.ishermitian
function ishermitian(arg::OperatorRepresentation{HSR, S, O}) where {HSR, S, O}
  return ishermitian(arg.operator)
end


## iterators

"""
May contain duplicates
"""
function get_row_iterator(opr ::OperatorRepresentation{HSR, S, O},
                          irow ::Integer) where {HSR, S, O}
  hsr = opr.hilbert_space_representation
  brow = hsr.basis_list[irow]
  basis_lookup = hsr.basis_lookup
  operator = opr.operator
  iter = (get(basis_lookup, bcol, -1) => amplitude
            for (bcol, amplitude) in get_row_iterator(operator, brow))
  return iter
end


function get_column_iterator(opr ::OperatorRepresentation{HSR, S, O}, icol ::Integer) where {HSR, S, O}
  hsr = opr.hilbert_space_representation
  bcol = hsr.basis_list[icol]
  basis_lookup = hsr.basis_lookup
  operator = opr.operator
  iter = (get(basis_lookup, brow, -1) => amplitude
            for (brow, amplitude) in get_column_iterator(operator, bcol))
  return iter
end


import Base.*
function (*)(opr ::OperatorRepresentation{HSR, SO, O}, state ::AbstractVector{SV}) where {HSR, O, SO, SV<:Number}
  hsr = opr.hilbert_space_representation
  n = dimension(hsr)
  T = promote_type(SO, SV)
  out = zeros(T, n)
  err = apply!(out, opr, state)
  return out
end


import Base.*
function (*)(state ::AbstractVector{SV}, opr ::OperatorRepresentation{HSR, SO, O}) where {HSR, SO, O, SV<:Number}
  hsr = opr.hilbert_space_representation
  n = dimension(hsr)
  T = promote_type(SO, SV)
  out = zeros(T, n)
  err = apply!(out, state, opr)
  out
end
