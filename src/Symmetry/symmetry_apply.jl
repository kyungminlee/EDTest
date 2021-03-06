export symmetry_apply
export isinvariant

import LatticeTools.AbstractSpaceSymmetryOperationEmbedding
import LatticeTools.SymmetryEmbedding

## AbstractSpaceSymmetryOperationEmbedding

### HilbertSpaceSector
function symmetry_apply(
    hss::HilbertSpaceSector{QN},
    symop::AbstractSymmetryOperationEmbedding,
    args...;
    kwargs...
) where {QN}
    return symmetry_apply(hss.parent, symop, args...; kwargs...)
end

function isinvariant(
    hss::HilbertSpaceSector{QN},
    symop::AbstractSymmetryOperationEmbedding,
    args...;
    kwargs...
) where {QN}
    return isinvariant(hss.parent, symop, args...; kwargs...)
end

function isinvariant(
    hss::HilbertSpaceSector{QN},
    symbed::SymmetryEmbedding,
    args...;
    kwargs...
) where {QN}
    return isinvariant(hss.parent, symbed, args...; kwargs...)
end

function isinvariant(
    hss::HilbertSpaceSector{QN},
    symbed::SymmorphicSymmetryEmbedding,
    args...;
    kwargs...
) where {QN}
    return isinvariant(hss.parent, symbed, args...; kwargs...)
end


### generic symmetry operations for NullOperator and SumOperator
function symmetry_apply(
    hs::HilbertSpace{QN},
    symop::AbstractSpaceSymmetryOperationEmbedding,
    op::NullOperator
) where {QN}
    return op
end

function symmetry_apply(
    hs::HilbertSpace{QN},
    symop::AbstractSpaceSymmetryOperationEmbedding,
    op::SumOperator{S, BR}
) where {QN, S<:Number, BR<:Unsigned}
    terms = collect(symmetry_apply(hs, symop, t) for t in op.terms)
    return SumOperator{S, BR}(terms)
end


## Permutation
### Binary Representation
function symmetry_apply(
    hs::HilbertSpace{QN},
    permutation::SitePermutation,
    bitrep::BR
) where {QN, BR<:Unsigned}
    out = zero(BR)
    for (i, j) in enumerate(permutation.permutation.map)
        out |= ( (bitrep >> hs.bitoffsets[i]) & make_bitmask(hs.bitwidths[i]) ) << hs.bitoffsets[j]
    end
    return out
end


### Operator
function symmetry_apply(
    hs::HilbertSpace{QN},
    permutation::SitePermutation,
    op::PureOperator{S, BR}
) where {QN, S<:Number, BR<:Unsigned}
    bm = symmetry_apply(hs, permutation, op.bitmask)
    br = symmetry_apply(hs, permutation, op.bitrow)
    bc = symmetry_apply(hs, permutation, op.bitcol)
    am = op.amplitude
    return PureOperator{S, BR}(bm, br, bc, am)
end


## isinvariant
function isinvariant(
    hs::HilbertSpace{QN},
    symop::AbstractSpaceSymmetryOperationEmbedding,
    op::AbstractOperator
) where {QN}
    return simplify(op - symmetry_apply(hs, symop, op)) == NullOperator()
end

function isinvariant(
    hs::HilbertSpace{QN},
    symbed::SymmetryEmbedding,
    op::AbstractOperator
) where {QN}
    return all(isinvariant(hs, g, op) for g in generator_elements(symbed))
end

function isinvariant(
    hs::HilbertSpace{QN},
    symbed::SymmorphicSymmetryEmbedding,
    op::AbstractOperator
) where {QN}
    return (
        all(isinvariant(hs, g, op) for g in generator_elements(symbed.normal)) &&
        all(isinvariant(hs, g, op) for g in generator_elements(symbed.rest))
    )
end
