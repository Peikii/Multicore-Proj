using Distributed

@everywhere function count_chars(filename, file_size, start, stop)
    # Open the file and read its contents into a buffer
    f = open(filename)
    buffer = read(f, file_size)
    close(f)

    # Initialize an array to count the frequency of each character
    count = zeros(Int, 4)

    # Loop through characters in buffer for this process
    for j in start:stop
        c = buffer[j]
        if c == 'a'
            count[1] += 1
        elseif c == 'b'
            count[2] += 1
        elseif c == 'c'
            count[3] += 1
        elseif c == 'd'
            count[4] += 1
        end
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

    # Add worker processes
    addprocs(nprocs - 1)

    # Initialize global array to count the frequency of each character
    count_global = zeros(Int, 4)

    # Calculate start and end indices for each process
    starts = [div((pid - 1) * file_size, nprocs) + 1 for pid in 1:nprocs]
    stops = [div(pid * file_size, nprocs) for pid in 1:nprocs]
    stops[end] += rem(file_size, nprocs)  # Handle case when nprocs is not divisible by file_size

    # Distribute computation among worker processes
    counts = pmap((args...) -> count_chars(filename, file_size, args...), zip(starts, stops))

    # Combine counts from all processes into global array
    for i in 1:nprocs
        for j in 1:4
            count_global[j] += counts[i][j]
        end
    end

    # Loop through entries in array to find maximum frequency and corresponding character
    max_count = maximum(count_global)
    max_char = ['a', 'b', 'c', 'd'][argmax(count_global)]

    println("$max_char occurred the most $max_count times of a total of $file_size characters.")

    return 0
end

main()