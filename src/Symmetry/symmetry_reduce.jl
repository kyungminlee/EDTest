export symmetry_reduce, symmetry_reduce_parallel
export materialize, materialize_parallel

function symmetry_reduce(
    hsr ::HilbertSpaceRepresentation{QN, BR},
    trans_group ::TranslationGroup,
    fractional_momentum ::AbstractVector{<:Rational};
    ComplexType::DataType=ComplexF64,
    tol::Real=sqrt(eps(Float64))) where {QN, BR}

  ik = findfirst(collect(
    trans_group.fractional_momenta[ik] == fractional_momentum
    for ik in 1:length(trans_group.fractional_momenta) ))
  HSR = HilbertSpaceRepresentation{QN, BR}
  ik === nothing && throw(ArgumentError("fractional momentum $(fractional_momentum) not an irrep of the translation group"))

  phases = trans_group.character_table[ik, :]
  n_basis = length(hsr.basis_list)

  reduced_basis_list = BR[]
  RepresentativeAmplitudeType = NamedTuple{(:representative,:amplitude), Tuple{Int,ComplexType}}
  representative_amplitude_list = RepresentativeAmplitudeType[(representative=-1,amplitude=zero(ComplexType)) for i in 1:n_basis]

  size_estimate = let
    denom = max(1, length(trans_group.fractional_momenta) - 1)
    n_basis ÷ denom
  end
  sizehint!(reduced_basis_list, size_estimate)

  visited = falses(n_basis)
  for ivec_p in 1:n_basis
    visited[ivec_p] && continue
    bvec = hsr.basis_list[ivec_p]

    compatible = true
    ψ = Dict{BR, ComplexType}()
    #ψ = SparseState{ComplexType, BR}(hsr.hilbert_space)
    for i in 1:length(trans_group.elements)
      t = trans_group.translations[i]
      g = trans_group.elements[i]

      bvec_prime = symmetry_apply(hsr.hilbert_space, g, bvec)

      if bvec_prime < bvec
        compatible = false
        break
      elseif bvec_prime == bvec && !is_compatible(fractional_momentum, t)
        compatible = false
        break
      end

      p = phases[i]
      ψ[bvec_prime] = get(ψ, bvec_prime, zero(ComplexType)) + p
    end
    (!compatible) && continue

    choptol!(ψ, tol)
    @assert !isempty(ψ)

    ivec_p_primes = Int[hsr.basis_lookup[bvec_prime] for bvec_prime in keys(ψ)]

    if any(visited[ivec_p_primes])
      continue
    else
      visited[ivec_p_primes] .= true
    end

    norm = sqrt( sum( (abs.(values(ψ)).^2) ) )
    # normalize!(ψ)
    push!(reduced_basis_list, bvec)
    for (bvec_prime, amplitude) in ψ
      ivec_p_prime = hsr.basis_lookup[bvec_prime]
      representative_amplitude_list[ivec_p_prime] = (representative=ivec_p, amplitude=amplitude / norm)
    end
  end

  sort!(reduced_basis_list)

  ItemType = NamedTuple{(:index, :amplitude), Tuple{Int, ComplexType}}
  basis_mapping = ItemType[(index=-1, amplitude=zero(ComplexType)) for b in hsr.basis_list]
  for (ivec_r, bvec) in enumerate(reduced_basis_list)
    ivec_p = hsr.basis_lookup[bvec]
    amplitude = representative_amplitude_list[ivec_p].amplitude
    basis_mapping[ivec_p] = (index=ivec_r, amplitude=amplitude)
  end

  for (ivec_p_prime, (ivec_p, amplitude)) in enumerate(representative_amplitude_list)
    (ivec_p == -1) && continue  # not in this irrep
    (ivec_p_prime == ivec_p) && continue # already in the lookup
    ivec_r = basis_mapping[ivec_p].index
    basis_mapping[ivec_p_prime] = (index=ivec_r, amplitude=amplitude)
  end

  return ReducedHilbertSpaceRepresentation{HSR, BR, ComplexType}(hsr, trans_group, reduced_basis_list, basis_mapping)
end


function symmetry_reduce_parallel(
    hsr ::HilbertSpaceRepresentation{QN, BR},
    trans_group ::TranslationGroup,
    fractional_momentum ::AbstractVector{<:Rational};
    ComplexType::DataType=ComplexF64,
    tol::Real=sqrt(eps(Float64))) where {QN, BR}

  HSR = HilbertSpaceRepresentation{QN, BR}
  debug(LOGGER, "BEGIN symmetry_reduce_parallel")
  ik = findfirst(collect(
    trans_group.fractional_momenta[ik] == fractional_momentum
    for ik in 1:length(trans_group.fractional_momenta) ))

  if ik === nothing
    throw(ArgumentError("fractional momentum $(fractional_momentum)" *
                        " not an irrep of the translation group"))
  end
  phases = trans_group.character_table[ik, :]
  n_basis = length(hsr.basis_list)
  debug(LOGGER, "Original Hilbert space dimension: $n_basis")

  visit_lock = Threads.SpinLock()
  nthreads = Threads.nthreads()
  local_reduced_basis_list = [BR[] for i in 1:nthreads]
  RepresentativeAmplitudeList = NamedTuple{(:representative,:amplitude), Tuple{Int,ComplexType}}
  representative_amplitude_list = RepresentativeAmplitudeList[(representative=-1,amplitude=zero(ComplexType)) for i in 1:n_basis]

  size_estimate = let
    denom = max(1, length(trans_group.fractional_momenta) - 1)
    n_basis ÷ denom
  end
  debug(LOGGER, "Estimate for the reduced Hilbert space dimension (local): $size_estimate")
  for i in eachindex(local_reduced_basis_list)
    sizehint!(local_reduced_basis_list[i], size_estimate ÷ nthreads + 1)
  end

  # Load balancing (the representatives are the smaller binary numbers)
  reorder = Int[]
  sizehint!(reorder, n_basis)
  nblocks = (n_basis + nthreads - 1) ÷ nthreads
  for i in 1:nthreads, j in 1:nblocks
    k = i + nthreads * (j-1)
    if 1 <= k <= n_basis
      push!(reorder, k)
    end
  end
  @assert sort(reorder) == 1:n_basis

  visited = falses(n_basis)
  debug(LOGGER, "Starting reduction (parallel)")
  Threads.@threads for itemp in 1:n_basis
    ivec_p = reorder[itemp]
    visited[ivec_p] && continue
    id = Threads.threadid()
    bvec = hsr.basis_list[ivec_p]

    compatible = true
    ψ = Dict{BR, ComplexType}()
    #ψ = SparseState{ComplexType, BR}(hsr.hilbert_space)
    for i in 1:length(trans_group.elements)
      t = trans_group.translations[i]
      g = trans_group.elements[i]

      bvec_prime = symmetry_apply(hsr.hilbert_space, g, bvec)

      if bvec_prime < bvec
        compatible = false
        break
      elseif bvec_prime == bvec && !is_compatible(fractional_momentum, t)
        compatible = false
        break
      end

      p = phases[i]
      ψ[bvec_prime] = get(ψ, bvec_prime, zero(ComplexType)) + p
    end
    (!compatible) && continue

    choptol!(ψ, tol)
    @assert !isempty(ψ)

    ivec_p_primes = Int[hsr.basis_lookup[bvec_prime] for bvec_prime in keys(ψ)]

    lock(visit_lock)
    if any(visited[ivec_p_primes])
      unlock(visit_lock)
      continue
    else
      visited[ivec_p_primes] .= true
      unlock(visit_lock)
    end

    push!(local_reduced_basis_list[id], bvec)

    norm = sqrt( sum( (abs.(values(ψ)).^2) ) )
    for (bvec_prime, amplitude) in ψ
      ivec_p_prime = hsr.basis_lookup[bvec_prime]
      representative_amplitude_list[ivec_p_prime] = (representative=ivec_p, amplitude=amplitude / norm)
    end
  end
  debug(LOGGER, "Finished reduction (parallel)")

  debug(LOGGER, "Collecting basis list")
  reduced_basis_list = BR[]
  while !isempty(local_reduced_basis_list)
    lbl = pop!(local_reduced_basis_list)
    append!(reduced_basis_list, lbl)
  end
  sort!(reduced_basis_list)

  ItemType = NamedTuple{(:index, :amplitude), Tuple{Int, ComplexType}}
  basis_mapping = ItemType[(index=-1, amplitude=zero(ComplexType)) for i in hsr.basis_list]
  debug(LOGGER, "Collecting basis lookup (diagonal)")
  Threads.@threads for ivec_r in eachindex(reduced_basis_list)
    bvec = reduced_basis_list[ivec_r]
    ivec_p = hsr.basis_lookup[bvec]
    amplitude = representative_amplitude_list[ivec_p].amplitude
    basis_mapping[ivec_p] = (index=ivec_r, amplitude=amplitude)
  end

  debug(LOGGER, "Collecting basis lookup (offdiagonal)")
  Threads.@threads for ivec_p_prime in eachindex(representative_amplitude_list)
    ivec_p, amplitude = representative_amplitude_list[ivec_p_prime]
    (ivec_p == -1) && continue  # not in this irrep
    (ivec_p_prime == ivec_p) && continue # already in the lookup
    bvec = hsr.basis_list[ivec_p]
    ivec_r = basis_mapping[ivec_p].index
    @assert ivec_r > 0 "ivec_r $ivec_r <= 0"
    basis_mapping[ivec_p_prime] = (index=ivec_r, amplitude=amplitude)
  end
  debug(LOGGER, "END symmetry_reduce_parallel")
  return ReducedHilbertSpaceRepresentation{HSR, BR, ComplexType}(hsr, trans_group, reduced_basis_list, basis_mapping)
end