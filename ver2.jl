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

    # Initialize array to count the frequency of each character
    count = zeros(Int, 4)

    # Split the buffer into chunks for each thread to operate on
    chunks = [(i-1)*file_size ÷ nprocs + 1 : i*file_size ÷ nprocs for i in 1:nprocs]

    # Start parallel region with nprocs threads
    @threads for tid in 1:nprocs
        # Get the chunk for this thread
        chunk = chunks[tid]

        # Loop through characters in chunk for this thread
        for j in chunk
            count[CHARSET[Char(buffer[j])]] += 1
        end
    end

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
