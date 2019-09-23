export ConcreteHilbertSpace
export dimension, concretize, materialize

struct ConcreteHilbertSpace{QN, BR}
  hilbert_space :: AbstractHilbertSpace{QN}
  basis_list ::Vector{BR}
  basis_lookup ::Dict{BR, Int}
end

import Base.==
function (==)(lhs ::ConcreteHilbertSpace{H1, B1}, rhs ::ConcreteHilbertSpace{H2, B2}) where {H1, B1, H2, B2}
  return (H1 == H2) && (B1 == B2) && (lhs.hilbert_space == rhs.hilbert_space) && (lhs.basis_list == rhs.basis_list)
end

"""
    dimension

Dimension of the Concrete Hilbert space, i.e. number of basis vectors.
"""
dimension(chs ::ConcreteHilbertSpace) = length(chs.basis_list)

"""
    concretize(hs; BR ::DataType=UInt)

Make a ConcreteHilbertSpace with all the basis vectors of the specified AbstractHilbertSpace.

# Arguments
- `hs ::AbstractHilbertSpace{QN}`: Abstract Hilbert space
- `BR ::DataType=UInt`: Binary representation type
"""
function concretize(hs ::AbstractHilbertSpace{QN}; BR ::DataType=UInt) where {QN}
  basis_list = BR[]
  for indexarray in Iterators.product((1:length(site.states) for site in hs.sites)...)
    indexarray = Int[indexarray...]
    push!(basis_list, compress(hs, indexarray))
  end
  basis_lookup = Dict{BR, Int}()
  sizehint!(basis_lookup, length(basis_list))
  for (ibasis, basis) in enumerate(basis_list)
    basis_lookup[basis] = ibasis
  end
  return ConcreteHilbertSpace{QN, BR}(hs, basis_list, basis_lookup)
end

# function concretize_naive(
#     hs ::AbstractHilbertSpace{QN},
#     qn ::QN;
#     BR ::DataType=UInt) where {QN}
#   sectors = quantum_number_sectors(hs)
#   if ! (qn in sectors)
#     return ConcreteHilbertSpace{QN, BR}(hs, [], Dict())
#   end
#   basis_list = BR[]
#   for indexarray in Iterators.product((1:length(site.states) for site in hs.sites)...)
#     indexarray = Int[indexarray...]
#     q = get_quantum_number(hs, indexarray)
#     if q == qn
#       push!(basis_list, compress(hs, indexarray))
#     end
#   end
#   basis_lookup = Dict{BR, Int}()
#   for (ibasis, basis) in enumerate(basis_list)
#     basis_lookup[basis] = ibasis
#   end
#   return ConcreteHilbertSpace{QN, BR}(hs, basis_list, basis_lookup)
# end

function concretize(
    hs::AbstractHilbertSpace{QN},
    qn::QN;
    BR::DataType=UInt) where {QN}
  return concretize(hs, [qn]; BR=BR)
end

"""
    concretize(hs; BR ::DataType=UInt)

Make a ConcreteHilbertSpace with all the basis vectors of the specified AbstractHilbertSpace.

# Arguments
- `hs ::AbstractHilbertSpace{QN}`: Abstract Hilbert space
- `allowed`: Allowed quantum numbers
- `BR ::DataType=UInt`: Binary representation type
"""
function concretize(
    hs::AbstractHilbertSpace{QN},
    allowed::Union{AbstractSet{QN}, AbstractVector{QN}};
    BR::DataType=UInt) where {QN}
  allowed = Set(allowed)
  sectors = Set(quantum_number_sectors(hs))
  if isempty(intersect(allowed, sectors))
    return ConcreteHilbertSpace{QN, BR}(hs, [], Dict())
  end

  quantum_numbers = [[state.quantum_number for state in site.states] for site in hs.sites]
  possible_quantum_numbers = [Set([zero(QN)])]  # PQN[i]: possible QN left of i

  n_sites = length(hs.sites)
  for i in 1:n_sites
    pq = Set{QN}()
    for q1 in possible_quantum_numbers[i], q2 in quantum_numbers[i]
      push!(pq, q1 .+ q2)
    end
    push!(possible_quantum_numbers, pq)
  end

  function generate(i ::Int, allowed ::AbstractSet{QN})
    if i == 0
      return (zero(QN) in allowed) ? Dict(zero(QN) => [BR(0x0)]) : Dict()
    end
    allowed_prev = Set{QN}()
    for q1 in quantum_numbers[i], q2 in allowed
      q = q2 - q1
      if q in possible_quantum_numbers[i]
        push!(allowed_prev, q)
      end
    end
    result_prev = generate(i-1, allowed_prev)

    result = DefaultDict{QN, Vector{BR}}(Vector{BR})
    for (i_state, q_curr) in enumerate(quantum_numbers[i])
      for (q_prev, states_prev) in result_prev
        q = q_prev + q_curr
        if q in allowed
          append!(result[q], (s | (BR(i_state-1) << hs.bitoffsets[i])) for s in states_prev)
        end
      end
    end
    return result
  end

  basis_list = BR[]
  result = generate(n_sites, allowed)
  for (q, states) in result
    basis_list = merge_vec(basis_list, states)
  end
  result = nothing

  basis_lookup = Dict{BR, Int}()
  sizehint!(basis_lookup, length(basis_list))
  for (ibasis, basis) in enumerate(basis_list)
    basis_lookup[basis] = ibasis
  end
  return ConcreteHilbertSpace{QN, BR}(hs, basis_list, basis_lookup)
end


function concretize(hs ::AbstractHilbertSpace{QN},
                    basis_list ::AbstractArray{BR}) where {QN, BR<:Unsigned}
  basis_lookup = Dict{BR, Int}()
  sizehint!(basis_lookup, length(basis_list))
  for (ibasis, basis) in enumerate(basis_list)
    basis_lookup[basis] = ibasis
  end
  return ConcreteHilbertSpace{QN, BR}(hs, basis_list, basis_lookup)
end
