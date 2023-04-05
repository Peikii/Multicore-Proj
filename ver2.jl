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
    count = zeros(Int, 4)
    count_global = zeros(Int, 4)
    @threads for tid in 1:nprocs
        count_local = zeros(Int, 4)
        # Calculate start and end indices for this thread
        start = div((tid - 1) * file_size, nprocs) + 1
        stop = div(tid * file_size, nprocs)
        if tid == nprocs  # Handle case when nprocs is not divisible by file_size
            stop += rem(file_size, nprocs)
        end

        # Loop through characters in buffer for this thread
        for j in start:stop
            count_local[CHARSET[Char(buffer[j])]] += 1
        end

        # Atomically update the shared count array
        for j in 1:4
            @atomic count_global[j] += count_local[j] : count_global[j]
        end
    end

    # Loop through entries in array to find maximum frequency and corresponding character
    max_count = maximum(count_global)
    max_char = ['a', 'b', 'c', 'd'][argmax(count_global)]

    println("$max_char occurred the most $max_count times of a total of $file_size characters.")

    # Close the memory-mapped file and file handle
    flush(f)
    close(f)

    return 0
end

main()
