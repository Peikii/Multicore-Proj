using Base.Threads

const CHARSET = Dict('a' => 1, 'b' => 2, 'c' => 3, 'd' => 4)

function main()
    if length(ARGS) != 3
        println("Usage: julia <program.jl> <nprocs> <filename>")
        return
    end

    nprocs = parse(Int, ARGS[1])
    filename = ARGS[3]
    file_size = min(parse(Int, ARGS[2]), filesize(filename))

    # Open the file and read its contents
    f = open(filename, "r")
    fileinfo = stat(filename)
    file_size = fileinfo.size
    buffer = Array{UInt32}(undef, file_size)
    read!(f, buffer)

    # Initialize thread-local arrays to count the frequency of each character
    count_local = [zeros(Int, 4) for i in 1:nprocs]

    # Start parallel region with N threads
    @threads for tid in 1:nprocs
        # Calculate start and end indices for this thread
        start = div((tid - 1) * file_size, nprocs) + 1
        stop = div(tid * file_size, nprocs)
        if tid == nprocs  # Handle case when nprocs is not divisible by file_size
            stop += rem(file_size, nprocs)
        end

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

    return 0
end

main()
