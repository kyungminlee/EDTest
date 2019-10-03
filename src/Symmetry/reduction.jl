export ReducedHilbertSpaceRealization
export symmetry_reduce, symmetry_reduce_parallel
export materialize, materialize_parallel

struct ReducedHilbertSpaceRealization{QN, BR, C<:Complex}
  parent_hilbert_space_realization ::HilbertSpaceRealization{QN, BR}
  translation_group ::TranslationGroup
  basis_list ::Vector{BR}
  basis_lookup ::Dict{BR, NamedTuple{(:index, :amplitude), Tuple{Int, C}}}
end

function symmetry_reduce(hsr ::HilbertSpaceRealization{QN, BR},
                trans_group ::TranslationGroup,
                fractional_momentum ::AbstractVector{Rational};
                ComplexType::DataType=ComplexF64) where {QN, BR}
  ik = findfirst(collect(
    trans_group.fractional_momenta[ik] == fractional_momentum
    for ik in 1:length(trans_group.fractional_momenta) ))
  
  isnothing(ik) && throw(ArgumentError("fractional momentum $(fractional_momentum) not an irrep of the translation group"))

  # check if fractional momentum is compatible with translation group ?
  #k = float.(fractional_momentum) .* 2π
  phases = trans_group.character_table[ik, :]
  #[ cis(dot(k, t)) for t in trans_group.translations]
  reduced_basis_list = Set{BR}()
  parent_amplitude = Dict()

  for bvec in hsr.basis_list
    if haskey(parent_amplitude, bvec)
      continue
    end

    ψ = SparseState{ComplexType, BR}(hsr.hilbert_space)
    identity_translations = Vector{Int}[]
    for i in 1:length(trans_group.elements)
      t = trans_group.translations[i]
      g = trans_group.elements[i]
      p = phases[i]

      bvec_prime = apply_symmetry(hsr.hilbert_space, g, bvec)
      ψ[bvec_prime] += p
      if bvec_prime == bvec
        push!(identity_translations, t)
      end
    end
    if !is_compatible(fractional_momentum, identity_translations)
      continue
    end
    clean!(ψ)
    @assert !isempty(ψ)

    normalize!(ψ)
    push!(reduced_basis_list, bvec)

    for (bvec_prime, amplitude) in ψ.components
      parent_amplitude[bvec_prime] = (parent=bvec, amplitude=amplitude)
    end
  end
  reduced_basis_list = sort(collect(reduced_basis_list))
  reduced_basis_lookup = Dict(bvec => (index=ivec, amplitude=parent_amplitude[bvec].amplitude)
                              for (ivec, bvec) in enumerate(reduced_basis_list))

  for (bvec_prime, (bvec, amplitude)) in parent_amplitude
    bvec_prime == bvec && continue
    reduced_basis_lookup[bvec_prime] = (index=reduced_basis_lookup[bvec].index, amplitude=amplitude)
  end
  return ReducedHilbertSpaceRealization{QN, BR, ComplexType}(hsr, trans_group, reduced_basis_list, reduced_basis_lookup)
end


function symmetry_reduce_parallel(hsr ::HilbertSpaceRealization{QN, BR},
                trans_group ::TranslationGroup,
                fractional_momentum ::AbstractVector{Rational};
                ComplexType::DataType=ComplexF64) where {QN, BR}
  print_lock = Threads.SpinLock()
  prints_pending = Vector{String}()
  function tprintln(str)
    tid= Threads.threadid()
    str = "[Thread $tid]: " * string(str)
    lock(print_lock) do
      push!(prints_pending, str)
      if tid == 1 # Only first thread is allows to print
        println.(prints_pending)
        empty!(prints_pending)
      end
    end
  end

  ik = findfirst(collect(
    trans_group.fractional_momenta[ik] == fractional_momentum
    for ik in 1:length(trans_group.fractional_momenta) ))
  
  isnothing(ik) && throw(ArgumentError("fractional momentum $(fractional_momentum) not an irrep of the translation group"))

  # check if fractional momentum is compatible with translation group ?
  #k = float.(fractional_momentum) .* 2π
  phases = trans_group.character_table[ik, :]
  #[ cis(dot(k, t)) for t in trans_group.translations]

  n_basis = length(hsr.basis_list)

  mutex = Threads.Mutex()

  nthreads = Threads.nthreads()
  local_reduced_basis_list = [BR[] for i in 1:nthreads]
  ParentAmplitudeType = NamedTuple{(:parent,:amplitude), Tuple{Int,ComplexType}}
  parent_amplitude_list = ParentAmplitudeType[(parent=-1,amplitude=zero(ComplexType)) for i in 1:n_basis]

  size_estimate = let
    denom = max(1, length(trans_group.fractional_momenta) - 1)
    n_basis ÷ denom
  end
  for i in eachindex(local_reduced_basis_list)
    sizehint!(local_reduced_basis_list[i], size_estimate ÷ nthreads)
  end

  visited = falses(n_basis)
  reorder = Int[]
  nblocks = (n_basis + nthreads - 1) ÷ nthreads
  for i in 1:nthreads
    for j in 1:nblocks
      k = i + nthreads * (j-1)
      if 1 <= k <= n_basis
        push!(reorder, k)
      end
    end
  end

  @assert length(reorder) == n_basis
  @assert length(Set(reorder)) == n_basis

  Threads.@threads for itemp in 1:n_basis
    ivec = reorder[itemp]
    visited[ivec] && continue
    id = Threads.threadid()
    bvec = hsr.basis_list[ivec]
    #@show id, ivec, bvec

    #tprintln("ivec=$ivec")
    compatible = true
    ψ = SparseState{ComplexType, BR}(hsr.hilbert_space)
    for i in 1:length(trans_group.elements)
      t = trans_group.translations[i]
      g = trans_group.elements[i]

      bvec_prime = apply_symmetry(hsr.hilbert_space, g, bvec)

      if bvec_prime < bvec
        compatible = false
        break
      elseif bvec_prime == bvec && !is_compatible(fractional_momentum, t)
        compatible = false
        break
      end

      p = phases[i]
      ψ[bvec_prime] += p
    end
    (!compatible) && continue
    (bvec != minimum(keys(ψ.components))) && continue

    clean!(ψ)
    @assert !isempty(ψ)

    ivec_primes = [hsr.basis_lookup[bvec_prime] for bvec_prime in keys(ψ.components)]

    lock(mutex)
    if any(visited[ivec_primes])
      unlock(mutex)
      #Core.println("Avoiding collision $ivec $bvec"); flush(stdout)
      tprintln("Avoiding collision $ivec $bvec"); flush(stdout)
      continue
    else
      visited[ivec_primes] .= true
      unlock(mutex)
    end

    normalize!(ψ)
    push!(local_reduced_basis_list[id], bvec)
    for (bvec_prime, amplitude) in ψ.components
      # local_parent_amplitude[id][bvec_prime] = (parent=bvec, amplitude=amplitude)
      ivec_prime = hsr.basis_lookup[bvec_prime]
      parent_amplitude_list[ivec_prime] = (parent=ivec, amplitude=amplitude)
    end
    #Core.print("$(count(visited)) "); flush(stdout)
    #tprintln("$(count(visited)) "); flush(stdout)
  end
  println("Finished local reduction"); flush(stdout)

  #reduced_basis_list ::Vector{BR} = vcat(local_reduced_basis_list...)
  reduced_basis_list = BR[]
  while !isempty(local_reduced_basis_list)
    lbl = pop!(local_reduced_basis_list)
    append!(reduced_basis_list, lbl)
  end
  sort!(reduced_basis_list)

  # parent_amplitude = ParentAmplitudeDictType()
  #merge!(parent_amplitude, local_parent_amplitude...)
  # while !isempty(local_parent_amplitude)
  #  lpa = pop!(local_parent_amplitude)
  #  merge!(parent_amplitude, lpa)
  # end

  #reduced_basis_lookup = Dict(bvec => (index=ivec, amplitude=parent_amplitude[bvec].amplitude)
  #                            for (ivec, bvec) in enumerate(reduced_basis_list))
  ItemType = NamedTuple{(:index, :amplitude), Tuple{Int, ComplexType}}
  reduced_basis_lookup = Dict{BR, ItemType}(
                              let
                                ivec_parent = hsr.basis_lookup[bvec]
                                amplitude = parent_amplitude_list[ivec_parent].amplitude
                                bvec => (index=ivec, amplitude=amplitude)
                              end for (ivec, bvec) in enumerate(reduced_basis_list))
  sizehint!(reduced_basis_lookup, length(reduced_basis_list))

  for (ivec_prime_parent, (ivec_parent, amplitude)) in enumerate(parent_amplitude_list)
    if ivec_parent == -1
      continue
    end
    ivec_prime_parent == ivec_parent && continue
    bvec_prime = hsr.basis_list[ivec_prime_parent]
    bvec = hsr.basis_list[ivec_parent]
    ivec = reduced_basis_lookup[bvec].index
    reduced_basis_lookup[bvec_prime] = (index=ivec, amplitude=amplitude)
  end
  return ReducedHilbertSpaceRealization{QN, BR, ComplexType}(hsr, trans_group, reduced_basis_list, reduced_basis_lookup)
end


function materialize(rhsr :: ReducedHilbertSpaceRealization{QN, BR, C},
                     operator ::AbstractOperator;
                     tol::Real=sqrt(eps(Float64))) where {QN, BR, C}
  # TODO CHECK IF THe OPERATOR HAS TRANSLATION SYMMETRY
  rows = Int[]
  cols = Int[]
  vals = ComplexF64[]
  
  hs = rhsr.parent_hilbert_space_realization.hilbert_space
  err = 0.0

  for (irow, brow) in enumerate(rhsr.basis_list)
    ampl_row = rhsr.basis_lookup[brow].amplitude
    ψrow = SparseState{C, BR}(hs, brow=>1/ampl_row)
    ψcol = SparseState{C, BR}(hs)
    apply!(ψcol, ψrow, operator)
    clean!(ψcol)

    for (bcol, ampl) in ψcol.components
      if ! haskey(rhsr.basis_lookup, bcol)
        err += abs(ampl.^2)
        continue
      end

      (icol, ampl_col) = rhsr.basis_lookup[bcol]
      push!(rows, irow)
      push!(cols, icol)
      push!(vals, ampl * ampl_col)
    end
  end

  if !isempty(vals) && maximum(imag.(vals)) < tol
    vals = real.(vals)
  end

  n = length(rhsr.basis_list)
  return (sparse(rows, cols, vals, n, n), err)
end



function materialize_parallel(rhsr :: ReducedHilbertSpaceRealization{QN, BR, C},
                     operator ::AbstractOperator;
                     tol::Real=sqrt(eps(Float64))) where {QN, BR, C}
  # TODO CHECK IF THe OPERATOR HAS TRANSLATION SYMMETRY
  hs = rhsr.parent_hilbert_space_realization.hilbert_space

  nthreads = Threads.nthreads()
  local_rows = [ Int[] for i in 1:nthreads]
  local_cols = [ Int[] for i in 1:nthreads]
  local_vals = [ C[] for i in 1:nthreads]
  local_err =  Float64[0.0 for i in 1:nthreads]

  n_basis = length(rhsr.basis_list)
  
  Threads.@threads for irow in 1:n_basis
    id = Threads.threadid()
    brow = rhsr.basis_list[irow]

    ampl_row = rhsr.basis_lookup[brow].amplitude
    ψrow = SparseState{C, BR}(hs, brow=>1/ampl_row)
    ψcol = SparseState{C, BR}(hs)
    apply_unsafe!(ψcol, ψrow, operator)
    clean!(ψcol)

    for (bcol, ampl) in ψcol.components
      if ! haskey(rhsr.basis_lookup, bcol)
        local_err[id] += abs(ampl.^2)
        continue
      end

      (icol, ampl_col) = rhsr.basis_lookup[bcol]
      push!(local_rows[id], irow)
      push!(local_cols[id], icol)
      push!(local_vals[id], ampl * ampl_col)
    end
  end

  rows ::Vector{Int} = vcat(local_rows...) 
  cols ::Vector{Int} = vcat(local_cols...) 
  vals ::Vector{C} = vcat(local_vals...) 
  err ::Float64 = sum(local_err) 

  n = length(rhsr.basis_list)
  if isempty(vals)
    vals = Float64[]
  elseif isapprox( maximum(abs.(imag.(vals))), 0)
    vals = real.(vals)
  end
  return (sparse(rows, cols, vals, n, n), err)
end

