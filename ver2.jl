using Mmap
using Base.Threads

const CHARSET = Dict('a' => 1, 'b' => 2, 'c' => 3, 'd' => 4)

function count_chars(buffer, start, stop)
    count = zeros(Int, 4)
    for j in start:stop
        count[CHARSET[Char(buffer[j])]] += 1
    end
    return count
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

    # Start parallel region with N threads
    @threads for tid in 1:nprocs
        # Calculate start and end indices for this thread
        start = div((tid - 1) * file_size, nprocs) + 1
        stop = div(tid * file_size, nprocs)
        if tid == nprocs  # Handle case when nprocs is not divisible by file_size
            stop += rem(file_size, nprocs)
        end

        # Count characters in this thread's portion of the file
        count_local = count_chars(buffer, start, stop)

        # Use a mutex to update the global counts
        for i in 1:length(count_local)
            lock(CHARSET[i]) do
                CHARSET[i] += count_local[i]
            end
        end
    end

    # Find maximum frequency and corresponding character
    max_count = maximum(values(CHARSET))
    max_char = findfirst(x -> x == max_count, values(CHARSET))
    max_char = keys(CHARSET)[max_char]

    println("$max_char occurred the most $max_count times of a total of $file_size characters.")

    # Close the memory-mapped file and file handle
    flush(f)
    close(f)

    return 0
end

main()
