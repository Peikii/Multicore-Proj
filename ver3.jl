using Base.Threads

function main()
    if length(ARGS) != 2
        println("Usage: julia <program.jl> <nprocs> <filename>")
        return
    end

    N = parse(Int, ARGS[1])  # number of threads
    num = parse(Int, ARGS[2])  # number of characters in file
    filename = ARGS[3]  # name of file
    fp = fopen(filename, "r")  # open file for reading
    if fp == C_NULL
        println("Error opening file!!!")
        return 1
    end

    # Read the file into the buffer
    buffer = Vector{UInt8}(undef, num)
    fread(fp, buffer)

    # Initialize arrays to count the frequency of each character
    count = zeros(Int, 4)

    # Start parallel region with N threads
    @threads for i in 1:N
        start = div((i - 1) * num, N) + 1  # calculate start index for this thread
        stop = div(i * num, N)  # calculate end index for this thread
        if i == N  # handle case when N is not divisible by num
            stop += rem(num, N)
        end

        # Private count array for each thread
        count_local = zeros(Int, 4)

        # Loop through characters in buffer for this thread
        for j in start:stop
            c = Char(buffer[j])  # read a character from buffer

            # Determine which entry of array to increment based on character read from buffer
            if c == 'a'
                count_local[1] += 1
            elseif c == 'b'
                count_local[2] += 1
            elseif c == 'c'
                count_local[3] += 1
            elseif c == 'd'
                count_local[4] += 1
            end
        end

        # Combine arrays for each thread in to one
        lock = Base.Threads.get_lock()
        Base.Threads.lock(lock)
        count .+= count_local
        Base.Threads.unlock(lock)
    end

    # Loop through entries in array to find maximum frequency and corresponding character
    max_count = maximum(count)
    max_char = ['a', 'b', 'c', 'd'][argmax(count)]

    println("$max_char occurred the most $max_count times of a total of $num characters.")

    fclose(fp)  # close the file
    return 0
end

main()
