using Base.Threads

function main()
    if length(ARGS) != 3
        println("Usage: julia <program.jl> <nprocs> <filename>")
        return
    end

    nprocs = parse(Int, ARGS[1])
    filename = ARGS[3]
    file_size = parse(Int, ARGS[2])

    # Open the file and read its contents into a buffer
    f = open(filename)
    buffer = read(f, file_size)
    close(f)

    # Initialize thread-local arrays to count the frequency of each character
    count_global = zeros(Int, 4)
    count_local = [zeros(Int, 4) for _ in 1:nprocs]

    @threads for tid in 1:nprocs
        # Calculate start and end indices for this thread
        start = (tid - 1) * div(file_size, nprocs) + 1
        stop = tid * div(file_size, nprocs)
        if tid == nprocs  # Handle case when nprocs is not divisible by file_size
            stop += rem(file_size, nprocs)
        end
    
        # Loop through characters in buffer for this thread
        for j in start:stop
            c = buffer[j]
            if c == 'a'
                count_local[tid][1] += 1
            elseif c == 'b'
                count_local[tid][2] += 1
            elseif c == 'c'
                count_local[tid][3] += 1
            elseif c == 'd'
                count_local[tid][4] += 1
            end
        end
    end

    # Combine thread-local arrays into global array
    for i in 1:nprocs
        for j in 1:4
            count_global[j] += count_local[i][j]
        end
    end

    # Loop through entries in array to find maximum frequency and corresponding character
    max_count = maximum(count_global)
    max_char = ['a', 'b', 'c', 'd'][argmax(count_global)]

    println("$max_char occurred the most $max_count times of a total of $file_size characters.")

    return 0
end

main()