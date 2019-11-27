var documenterSearchIndex = {"docs":
[{"location":"api/#API-1","page":"API","title":"API","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Modules = [ExactDiagonalization]","category":"page"},{"location":"api/#ExactDiagonalization.HilbertSpace","page":"API","title":"ExactDiagonalization.HilbertSpace","text":"HilbertSpace{QN}\n\nAbstract Hilbert space with quantum number type QN.\n\nExamples\n\njulia> using ExactDiagonalization\n\njulia> spin_site = Site{Int64}([State{Int64}(\"Up\", +1), State{Int64}(\"Dn\", -1)])\nSite{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)])\n\njulia> hs = HilbertSpace{Int64}([spin_site, spin_site])\nHilbertSpace{Int64}(Site{Int64}[Site{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)]), Site{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)])], [1, 1], [0, 1, 2])\n\n\n\n\n\n","category":"type"},{"location":"api/#ExactDiagonalization.Site","page":"API","title":"ExactDiagonalization.Site","text":"Site{QN}\n\nA site with quantum number type QN.\n\nExamples\n\njulia> using ExactDiagonalization\n\njulia> up = State{Int}(\"Up\", 1); dn = State(\"Dn\", -1);\n\njulia> Site([up, dn])\nSite{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)])\n\n\n\n\n\n","category":"type"},{"location":"api/#ExactDiagonalization.SparseState","page":"API","title":"ExactDiagonalization.SparseState","text":"struct SparseState{Scalar<:Number, BR}\n\nRepresents a row vector. Free.\n\n\n\n\n\n","category":"type"},{"location":"api/#ExactDiagonalization.State","page":"API","title":"ExactDiagonalization.State","text":"State{QN}\n\nState with quantum number type QN.\n\nExamples\n\njulia> using ExactDiagonalization, StaticArrays\n\njulia> up = State{Int}(\"Up\", 1)\nState{Int64}(\"Up\", 1)\n\njulia> State(\"Dn\", SVector{2, Int}([-1, 1]))\nState{SArray{Tuple{2},Int64,1,2}}(\"Dn\", [-1, 1])\n\n\n\n\n\n","category":"type"},{"location":"api/#ExactDiagonalization.apply!-Union{Tuple{BR}, Tuple{S2}, Tuple{S1}, Tuple{SparseState{S1,BR},NullOperator,SparseState{S2,BR}}} where BR where S2 where S1","page":"API","title":"ExactDiagonalization.apply!","text":"apply!\n\nApply operator to psi and add it to out.\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.apply!-Union{Tuple{S2}, Tuple{S1}, Tuple{O}, Tuple{S}, Tuple{HSR}, Tuple{AbstractArray{S1,1},AbstractArray{S2,1},AbstractOperatorRepresentation{S}}} where S2<:Number where S1<:Number where O where S where HSR","page":"API","title":"ExactDiagonalization.apply!","text":"apply!(out, opr, state)\n\nPerform out += opr * state. Apply the operator representation opr to the row vector state and add it to the row vector out. Return sum of errors and sum of error-squared. Call apply_serial! if Threads.nthreads() == 1, and apply_parallel! if greater.\n\nArguments\n\nout ::Vector{S1}\nstate ::AbstractVector{S2}\nopr ::AbstractOperatorRepresentation{S}\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.apply!-Union{Tuple{S2}, Tuple{S1}, Tuple{S}, Tuple{AbstractArray{S1,1},AbstractOperatorRepresentation{S},AbstractArray{S2,1}}} where S2<:Number where S1<:Number where S","page":"API","title":"ExactDiagonalization.apply!","text":"apply!(out, opr, state)\n\nPerform out += opr * state. Apply the operator representation opr to the column vector state and add it to the column vector out. Return sum of errors and sum of error-squared. Call apply_serial! if Threads.nthreads() == 1, and apply_parallel! if greater.\n\nArguments\n\nout ::Vector{S1}\nopr ::OperatorRepresentation{HSR, O}\nstate ::AbstractVector{S2}\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.apply_parallel!-Union{Tuple{S2}, Tuple{S1}, Tuple{S}, Tuple{AbstractArray{S1,1},AbstractArray{S2,1},AbstractOperatorRepresentation{S}}} where S2<:Number where S1<:Number where S","page":"API","title":"ExactDiagonalization.apply_parallel!","text":"apply_parallel!(out, state, opr; range=1:size(opr, 1))\n\nPerform out += state * opr. Apply the operator representation opr to the row vector state and add it to the row vector out. Return sum of errors and sum of error-squared. Multi-threaded version.\n\nArguments\n\nout ::Vector{S1}\nstate ::AbstractVector{S2}\nopr ::OperatorRepresentation{HSR, O}\nrange ::AbstractVector{<:Integer}=1:dimension(opr.hilbert_space_representation)\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.apply_parallel!-Union{Tuple{S2}, Tuple{S1}, Tuple{S}, Tuple{AbstractArray{S1,1},AbstractOperatorRepresentation{S},AbstractArray{S2,1}}} where S2<:Number where S1<:Number where S","page":"API","title":"ExactDiagonalization.apply_parallel!","text":"apply_parallel!(out, opr, state; range=1:size(opr, 2))\n\nPerform out += opr * state. Apply the operator representation opr to the column vector state and add it to the column vector out. Return sum of errors and sum of error-squared. Multi-threaded version.\n\nArguments\n\nout ::Vector{S1}\nopr ::AbstractOperatorRepresentation{S}\nstate ::AbstractVector{S2}\nrange ::AbstractVector{<:Integer}=1:size(opr, 2)\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.apply_serial!-Union{Tuple{S2}, Tuple{S1}, Tuple{S}, Tuple{AbstractArray{S1,1},AbstractArray{S2,1},AbstractOperatorRepresentation{S}}} where S2<:Number where S1<:Number where S","page":"API","title":"ExactDiagonalization.apply_serial!","text":"apply_serial!(out, state, opr; range=1:size(opr, 1))\n\nPerform out += state * opr. Apply the operator representation opr to the row vector state and add it to the row vector out. Return sum of errors and sum of error-squared. Single-threaded version.\n\nArguments\n\nout ::Vector{S1}\nstate ::AbstractVector{S2}\nopr ::AbstractOperatorRepresentation{S}\nrange ::AbstractVector{<:Integer}=1:size(opr, 1)\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.apply_serial!-Union{Tuple{S2}, Tuple{S1}, Tuple{S}, Tuple{AbstractArray{S1,1},AbstractOperatorRepresentation{S},AbstractArray{S2,1}}} where S2<:Number where S1<:Number where S","page":"API","title":"ExactDiagonalization.apply_serial!","text":"apply_serial!(out, opr, state; range=1:size(opr, 2))\n\nPerform out += opr * state. Apply the operator representation opr to the column vector state and add it to the column vector out. Return sum of errors and sum of error-squared. Single-threaded version.\n\nArguments\n\nout ::Vector{S1}\nopr ::AbstractOperatorRepresentation{S}\nstate ::AbstractVector{S2}\nrange ::AbstractVector{<:Integer}=1:size(opr, 1)\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.bitwidth-Tuple{HilbertSpace}","page":"API","title":"ExactDiagonalization.bitwidth","text":"Total number of bits\n\njulia> using ExactDiagonalization\n\njulia> spin_site = Site{Int64}([State{Int64}(\"Up\", +1), State{Int64}(\"Dn\", -1)])\nSite{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)])\n\njulia> hs = HilbertSpace{Int64}([spin_site, spin_site, spin_site,])\nHilbertSpace{Int64}(Site{Int64}[Site{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)]), Site{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)]), Site{Int64}(State{Int64}[State{Int64}(\"Up\", 1), State{Int64}(\"Dn\", -1)])], [1, 1, 1], [0, 1, 2, 3])\n\njulia> bitwidth(hs)\n3\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.bitwidth-Tuple{Site}","page":"API","title":"ExactDiagonalization.bitwidth","text":"bitwidth(site ::Site)\n\nNumber of bits necessary to represent the states of the given site.\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.compress-Union{Tuple{BR}, Tuple{QN}, Tuple{HilbertSpace{QN},CartesianIndex}, Tuple{HilbertSpace{QN},CartesianIndex,Type{BR}}} where BR<:Unsigned where QN","page":"API","title":"ExactDiagonalization.compress","text":"Convert an array of indices (of states) to binary representation\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.extract-Union{Tuple{BR}, Tuple{QN}, Tuple{HilbertSpace{QN},BR}} where BR<:Unsigned where QN","page":"API","title":"ExactDiagonalization.extract","text":"Convert binary representation to an array of indices (of states)\n\nExamples ≡≡≡≡≡≡≡≡≡≡\n\n\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.get_quantum_number-Union{Tuple{BR}, Tuple{QN}, Tuple{HilbertSpace{QN},BR}} where BR where QN","page":"API","title":"ExactDiagonalization.get_quantum_number","text":"get_quantum_number\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.get_row_iterator-Union{Tuple{O}, Tuple{S}, Tuple{HSR}, Tuple{OperatorRepresentation{HSR,S,O},Integer}} where O where S where HSR","page":"API","title":"ExactDiagonalization.get_row_iterator","text":"May contain duplicates\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.get_state-Union{Tuple{U}, Tuple{Site,U}} where U<:Unsigned","page":"API","title":"ExactDiagonalization.get_state","text":"get_state(site ::Site{QN}, binrep ::BR) where {QN, BR<:Unsigned}\n\nReturns the state of site represented by the bits binrep.\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.qntype-Union{Tuple{HilbertSpace{QN}}, Tuple{QN}} where QN","page":"API","title":"ExactDiagonalization.qntype","text":"qntype\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.quantum_number_sectors-Union{Tuple{HilbertSpace{QN}}, Tuple{QN}} where QN","page":"API","title":"ExactDiagonalization.quantum_number_sectors","text":"quantum_number_sectors\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.represent-Union{Tuple{AbstractHilbertSpace}, Tuple{BR}, Tuple{AbstractHilbertSpace,Type{BR}}} where BR<:Unsigned","page":"API","title":"ExactDiagonalization.represent","text":"represent(hs; BR=UInt)\n\nMake a HilbertSpaceRepresentation with all the basis vectors of the specified HilbertSpaceSector.\n\nArguments\n\nhs ::AbstractHilbertSpace\nBR ::DataType=UInt: Binary representation type\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.represent-Union{Tuple{BR}, Tuple{AbstractHilbertSpace,AbstractArray{BR,1}}} where BR<:Unsigned","page":"API","title":"ExactDiagonalization.represent","text":"represent(hs, basis_list)\n\nMake a HilbertSpaceRepresentation with the provided list of basis vectors\n\nArguments\n\nhs ::AbstractHilbertSpace\nbasis_list ::AbstractVector{BR}\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.represent_dict-Union{Tuple{AbstractHilbertSpace}, Tuple{BR}, Tuple{AbstractHilbertSpace,Type{BR}}} where BR<:Unsigned","page":"API","title":"ExactDiagonalization.represent_dict","text":"represent_dict(hs; BR=UInt)\n\nMake a HilbertSpaceRepresentation with all the basis vectors of the specified HilbertSpace.\n\nArguments\n\nhs ::AbstractHilbertSpace\nBR ::DataType=UInt: Binary representation type\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.represent_dict-Union{Tuple{BR}, Tuple{AbstractHilbertSpace,AbstractArray{BR,1}}} where BR<:Unsigned","page":"API","title":"ExactDiagonalization.represent_dict","text":"represent_dict(hs, basis_list)\n\nMake a HilbertSpaceRepresentation with the provided list of basis vectors using Dict\n\nArguments\n\nhs ::HilbertSpace{QN}: Abstract Hilbert space\nbasis_list ::AbstractVector{BR}\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.symmetry_reduce-Union{Tuple{ComplexType}, Tuple{DT}, Tuple{BR}, Tuple{QN}, Tuple{HilbertSpaceRepresentation{QN,BR,DT},TightBindingLattice.TranslationGroup,AbstractArray{#s37,1} where #s37<:Rational}, Tuple{HilbertSpaceRepresentation{QN,BR,DT},TightBindingLattice.TranslationGroup,AbstractArray{#s36,1} where #s36<:Rational,Type{ComplexType}}} where ComplexType<:Complex where DT where BR where QN","page":"API","title":"ExactDiagonalization.symmetry_reduce","text":"symmetry_reduce(hsr, trans_group, frac_momentum, complex_type=ComplexF64, tol=sqrt(eps(Float64)))\n\nSymmetry-reduce the HilbertSpaceRepresentation using translation group.\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.symmetry_reduce-Union{Tuple{Si}, Tuple{C}, Tuple{BR}, Tuple{HSR}, Tuple{ReducedHilbertSpaceRepresentation{HSR,BR,C},AbstractArray{Si,1}}} where Si<:Number where C where BR where HSR","page":"API","title":"ExactDiagonalization.symmetry_reduce","text":"\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.symmetry_reduce_parallel-Union{Tuple{ComplexType}, Tuple{DT}, Tuple{BR}, Tuple{QN}, Tuple{HilbertSpaceRepresentation{QN,BR,DT},TightBindingLattice.TranslationGroup,AbstractArray{#s282,1} where #s282<:Rational}, Tuple{HilbertSpaceRepresentation{QN,BR,DT},TightBindingLattice.TranslationGroup,AbstractArray{#s283,1} where #s283<:Rational,Type{ComplexType}}} where ComplexType<:Complex where DT where BR where QN","page":"API","title":"ExactDiagonalization.symmetry_reduce_parallel","text":"symmetry_reduce_parallel(hsr, trans_group, frac_momentum, complex_type=ComplexF64, tol=sqrt(eps(Float64)))\n\nSymmetry-reduce the HilbertSpaceRepresentation using translation group (multi-threaded).\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.symmetry_reduce_serial-Union{Tuple{FloatType}, Tuple{ComplexType}, Tuple{DT}, Tuple{BR}, Tuple{QN}, Tuple{HilbertSpaceRepresentation{QN,BR,DT},TightBindingLattice.TranslationGroup,AbstractArray{#s15,1} where #s15<:Rational}, Tuple{HilbertSpaceRepresentation{QN,BR,DT},TightBindingLattice.TranslationGroup,AbstractArray{#s14,1} where #s14<:Rational,Type{ComplexType}}} where FloatType<:Real where ComplexType<:Complex where DT where BR where QN","page":"API","title":"ExactDiagonalization.symmetry_reduce_serial","text":"symmetry_reduce_serial(hsr, trans_group, frac_momentum, complex_type=ComplexF64, tol=sqrt(eps(Float64)))\n\nSymmetry-reduce the HilbertSpaceRepresentation using translation group (single threaded).\n\n\n\n\n\n","category":"method"},{"location":"api/#TightBindingLattice.dimension-Tuple{HilbertSpaceRepresentation}","page":"API","title":"TightBindingLattice.dimension","text":"dimension\n\nDimension of the Concrete Hilbert space, i.e. number of basis vectors.\n\n\n\n\n\n","category":"method"},{"location":"api/#TightBindingLattice.dimension-Tuple{Site}","page":"API","title":"TightBindingLattice.dimension","text":"dimension(site ::Site)\n\nHilbert space dimension of a given site ( = number of states).\n\n\n\n\n\n","category":"method"},{"location":"api/#ExactDiagonalization.splitblock-Tuple{Integer,Integer}","page":"API","title":"ExactDiagonalization.splitblock","text":"splitblock\n\nSplit n into b blocks.\n\nArguments\n\nn ::Integer: the number of elements to split.\nb ::Integer: the number of blocks.\n\n\n\n\n\n","category":"method"},{"location":"hilbertspace/#Hilbert-space-1","page":"Hilbert space","title":"Hilbert space","text":"","category":"section"},{"location":"representation/#Representation-1","page":"Representation","title":"Representation","text":"","category":"section"},{"location":"symmetry/#Symmetry-1","page":"Symmetry","title":"Symmetry","text":"","category":"section"},{"location":"operator/#Operator-1","page":"Operator","title":"Operator","text":"","category":"section"},{"location":"#ExactDiagonalization-1","page":"Home","title":"ExactDiagonalization","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Implements exact diagonalization.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Schematics for the structure of the package","category":"page"},{"location":"#","page":"Home","title":"Home","text":"                State\n                  ↓\n                Site\n                  ↓\n                HilbertSpace → HilbertSpaceSector    Operator\n                  ↓              ↓                     ↓\n                HilbertSpaceRepresentation         → OperatorRepresentation\n                  ↓                                    ↓\nSymmetryGroup → ReducedHilbertSpaceRepresentation  → ReducedOperatorRepresentation","category":"page"}]
}
