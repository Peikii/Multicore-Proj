using Mmap
using Base.Threads
using SIMD
using Distributed
using SharedArrays

const CHARSET = UInt8['a', 'b', 'c', 'd']

function load_balance(file_size, char_counts, nprocs)
    # Calculate total number of target characters
    total_chars = sum(values(char_counts))

    # Calculate target characters per thread
    chars_per_thread = ceil(Int, total_chars / nprocs)

    # Partition file into segments based on target character counts
    segment_starts = [1]
    segment_chars = 0
    for (char, count) in char_counts
        segment_chars += count
        if segment_chars > chars_per_thread
            # Split current segment at this character
            split_index = findnext(x -> x == char, CHARSET, segment_starts[end])
            push!(segment_starts, split_index)
            segment_chars -= count
        end
    end
    push!(segment_starts, file_size+1)

    # Calculate segment ranges for each thread
    segment_ranges = [(segment_starts[i], segment_starts[i+1]-1) for i in 1:length(segment_starts)-1]

    return segment_ranges
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
    count = SharedArray(Int, 256)

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