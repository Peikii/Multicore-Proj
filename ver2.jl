using Mmap
using Base.Threads
using SIMD
using Distributed
using SharedArrays

const CHARSET = UInt8['a', 'b', 'c', 'd']

function load_balance(file_size::Int64, char_counts::Dict{UInt8, Int64}, nprocs::Int64)
    work_loads = Vector{Int64}[]
    remaining_counts = copy(char_counts)
    for i in 1:nprocs
        push!(work_loads, Int64[])
    end
    for (char, count) in char_counts
        proc = argmin([sum(work_load) for work_load in work_loads])
        if isempty(remaining_counts) # added this if statement
            break
        end
        if count > 0
            push!(work_loads[proc], char)
            remaining_counts[char] -= 1
        end
    end
    work_sizes = [sum([char_counts[char] for char in work_load]) for work_load in work_loads]
    return work_sizes
end

function main()
    if length(ARGS) != 3
        println("Usage: julia <program.jl> <nprocs> <filename>")
        return
    end

    nprocs = parse(Int, ARGS[1])
    filename = ARGS[3]
    file_size = parse(Int, ARGS[2])

    # Open the file and memory-map its contents
    f = open(filename)
    buffer = Mmap.mmap(f, Vector{UInt8}, file_size)

    # Initialize shared array to count the frequency of each character
    count = SharedArray{Int}(zeros(Int, 256))

    # Scan the buffer to get an estimate of the frequency of each target character
    char_counts = Dict(zip(CHARSET, zeros(Int, length(CHARSET))))
    for i in 1:file_size
        char = buffer[i]
        if char in CHARSET
            char_counts[char] += 1
        end
    end

    # Partition the file into segments based on target character counts
    segment_ranges = load_balance(file_size, char_counts, nprocs)

    # Start parallel region with N threads
    @sync @distributed for tid in 1:nprocs
        # Get segment range for this thread
        start, stop = segment_ranges[tid]

        # Initialize thread-local array to count the frequency of each character
        count_local = zeros(Int, 256)

        # Loop through characters in buffer for this thread
        for j in start:stop
            count_local[buffer[j]] += 1
        end

        # Accumulate thread-local frequency counts into shared array using SIMD
        for i in 1:4:length(count_local)-3
            s1 = vsum(reinterpret(SIMD.UInt32, count_local[i:i+3]))
            s2 = vsum(reinterpret(SIMD.UInt32, count[i:i+3]))
            s = reinterpret(Vector{Int}, s1+s2)
            count[i:i+3] = s
        end
    end

    # Loop through entries in array to find maximum frequency and corresponding character
    max_count = maximum(count[CHARSET])
    max_char = findfirst(x -> count[x] == max_count, CHARSET)

    println("$(Char(max_char)) occurred the most $max_count times of a total of $file_size characters.")

    # Close the memory-mapped file and file handle
    flush(f)
    close(f)

    return 0
end

main()