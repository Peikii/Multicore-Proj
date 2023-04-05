using Mmap
using Base.Threads

const CHARSET = Dict('a' => 1, 'b' => 2, 'c' => 3, 'd' => 4)

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

    # Initialize thread-local arrays to count the frequency of each character
    count_local = [zeros(Int, 4) for i in 1:nprocs]

    # Calculate length of buffer per thread
    chunk_size = div(length(buffer), nprocs)

    # Start parallel region with nprocs threads
    @threads for tid in 1:nprocs
        # Calculate start and end indices for this thread
        start = (tid - 1) * chunk_size + 1
        stop = min(tid * chunk_size, length(buffer))

        # Loop through characters in buffer for this thread
        for j in start:stop
            count_local[tid][CHARSET[Char(buffer[j])]] += 1
        end
    end

    # Combine thread-local arrays into one
    count = sum(count_local)

    # Loop through entries in array to find maximum frequency and corresponding character
    max_count = maximum(count)
    max_char = ['a', 'b', 'c', 'd'][argmax(count)]

    println("$max_char occurred the most $max_count times of a total of $file_size characters.")

    # Close the memory-mapped file and file handle
    flush(f)
    close(f)

    return 0
end

main()
