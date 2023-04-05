using Base.Threads
using SharedArrays

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

    # Initialize a shared array to count the frequency of each character
    count = @SVector zeros(Int, 4)

    # Parallel loop to count character frequencies
    @threads for tid in 1:nprocs
        # Calculate start and end indices for this thread
        start = div((tid - 1) * file_size, nprocs) + 1
        stop = div(tid * file_size, nprocs)
        if tid == nprocs  # Handle case when nprocs is not divisible by file_size
            stop += rem(file_size, nprocs)
        end

        # Loop through characters in buffer for this thread
        for j in start:stop
            c = buffer[j]
            if c == 'a'
                atomic_add!(count[1], 1)
            elseif c == 'b'
                atomic_add!(count[2], 1)
            elseif c == 'c'
                atomic_add!(count[3], 1)
            elseif c == 'd'
                atomic_add!(count[4], 1)
            end
        end
    end

    # Loop through entries in array to find maximum frequency and corresponding character
    max_count = maximum(count)
    max_char = ['a', 'b', 'c', 'd'][argmax(count)]

    println("$max_char occurred the most $max_count times of a total of $file_size characters.")

    return 0
end

main()
