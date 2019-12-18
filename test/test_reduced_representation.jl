using Test
using ExactDiagonalization

using LinearAlgebra
using SparseArrays

using ExactDiagonalization.Toolkit: pauli_matrix

@testset "RedRep" begin
  tol = sqrt(eps(Float64))
  QN = Int

  # Test State and Site
  up = State("Up", 1)
  dn = State("Dn",-1)
  spin_site = Site([up, dn])
  n = 4
  hs = HilbertSpace(repeat([spin_site], n))
  σ = Dict( (isite, j) => pauli_matrix(hs, isite, j) for isite in 1:n, j in [:x, :y, :z, :+, :-])
  j1 = sum(σ[i, j] * σ[mod(i, n) + 1 , j] for i in 1:n, j in [:x, :y, :z])

  hsr = represent(HilbertSpaceSector(hs, 0))
  translation_group = TranslationGroup([Permutation([2,3,4,1])])
  @test is_invariant(hs, translation_group, j1)
  @test is_invariant(HilbertSpaceSector(hs, 0), translation_group, j1)

  @testset "RHSR" begin
    rhsr = symmetry_reduce(hsr, translation_group, [0//1])
    @test scalartype(rhsr) === ComplexF64
    @test scalartype(typeof(rhsr)) === ComplexF64
    @test bintype(rhsr) === UInt
    @test bintype(typeof(rhsr)) === UInt
  end

  j1_rep = represent(hsr, j1)
  j1_mat = Matrix(j1_rep)
  @test hsr.basis_list == [0b0011, 0b0101, 0b0110, 0b1001, 0b1010, 0b1100]

  @testset "ROR" begin
    rhsr = symmetry_reduce(hsr, translation_group, [0//1])
    @test dimension(rhsr) == 2
    @test rhsr.basis_list == UInt[0b0011, 0b0101]

    j1_redrep = represent(rhsr, j1)
    @testset "typetraits" begin
      @test scalartype(j1) === Complex{Int}

      @test scalartype(j1_redrep) === ComplexF64
      @test scalartype(typeof(j1_redrep)) === ComplexF64

      @test bintype(j1_redrep) === UInt
      @test bintype(typeof(j1_redrep)) === UInt

      @test spacetype(j1_redrep) === typeof(rhsr)
      @test operatortype(j1_redrep) === typeof(j1)
      @test spacetype(typeof(j1_redrep)) === typeof(rhsr)
      @test operatortype(typeof(j1_redrep)) === typeof(j1)
      @test get_space(j1_redrep) === rhsr
    end

    let
      psis = [normalize([1.0, 0.0, 1.0, 1.0, 0.0, 1.0]), normalize([0.0, 1.0, 0.0, 0.0, 1.0, 0.0])]
      H = zeros(ComplexF64, (2,2))
      for i in 1:2, j in 1:2
        H[i,j] = psis[i] ⋅ (j1_mat * psis[j])
      end
      @test isapprox(Matrix(j1_redrep), H; atol=tol)

      @testset "get_row_iterator" begin
        rowvec = zeros(ComplexF64, dimension(rhsr))
        for irow_r in 1:dimension(rhsr)
          rowvec[:] .= zero(ComplexF64)
          err = zero(ComplexF64)
          for (icol_r, ampl) in get_row_iterator(j1_redrep, irow_r)
            if 1 <= icol_r <= dimension(rhsr)
              rowvec[icol_r] += ampl
            else
              err += ampl
            end
          end
          @test isapprox(err, 0; atol=tol) # is this necessarily true?
          @test isapprox(rowvec, H[irow_r, :]; atol=tol)
        end
      end

      @testset "get_column_iterator" begin
        colvec = zeros(ComplexF64, dimension(rhsr))
        for icol_r in 1:dimension(rhsr)
          colvec[:] .= zero(ComplexF64)

          colvec[:] .= zero(ComplexF64)
          err = zero(ComplexF64)
          for (irow_r, ampl) in get_column_iterator(j1_redrep, icol_r)
            if 1 <= irow_r <= dimension(rhsr)
              colvec[irow_r] += ampl
            else
              err += ampl
            end
          end
          @test isapprox(err, 0; atol=tol) # is this necessarily true?
          @test isapprox(colvec, H[:, icol_r]; atol=tol)
        end
      end # testset get_column_iterator

      @testset "get exceptions" begin
        dim = dimension(rhsr)
        opr = j1_redrep
        @test_throws BoundsError get_row_iterator(opr, 0)
        @test_throws BoundsError get_row_iterator(opr, dim+1)
        @test_throws BoundsError get_column_iterator(opr, 0)
        @test_throws BoundsError get_column_iterator(opr, dim+1)
        @test_throws BoundsError get_row(opr, 0)
        @test_throws BoundsError get_row(opr, dim+1)
        @test_throws BoundsError get_column(opr, 0)
        @test_throws BoundsError get_column(opr, dim+1)
        @test_throws BoundsError get_element(opr, 0, 1)
        @test_throws BoundsError get_element(opr, dim+1, 1)
        @test_throws BoundsError get_element(opr, 1, 0)
        @test_throws BoundsError get_element(opr, 1, dim+1)
      end
    end
  end # testset ROR


  @testset "ROR-ALL" begin
    j1_mat = Matrix(represent(hsr, j1))
    @test isapprox(j1_mat, adjoint(j1_mat); atol=tol)
    eigenvalues1 = eigvals(Hermitian(j1_mat))
    eigenvalues2 = Float64[]
    for k in translation_group.fractional_momenta
      rhsr = symmetry_reduce(hsr, translation_group, k)
      j1_redrep = represent(rhsr, j1)
      j1_redmat = Matrix(j1_redrep)
      @test isapprox(j1_redmat, adjoint(j1_redmat); atol=tol)
      append!(eigenvalues2, eigvals(Hermitian(j1_redmat)))
    end
    sort!(eigenvalues2)
    @test length(eigenvalues1) == length(eigenvalues2)
    @test isapprox(eigenvalues1, eigenvalues2; atol=tol)
  end # testset iterator

end # testset RedOp

@testset "RedOp-nontriv" begin
# TODO: at an angle
end
