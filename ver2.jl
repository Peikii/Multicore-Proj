using Base.Threads

function main(args)
    N = parse(Int, args[1]) # number of threads
    num = parse(Int, args[2]) # number of characters in file
    filename = args[3] # name of file
    fp = open(filename, "r") # open file for reading
    buffer = read(fp, String)[1] # read the file into a string
    close(fp) # close the file

    count = zeros(Int, 4) # the final combined array of 4 arrays to store frequency of each character for each thread
    max_count = 0 # maximum frequency of the character
    max_char = 'a' # character with maximum frequency

    # Pure sequential version
    if N == 0
        for c in buffer
            # increment corresponding occurrence
            global count[findfirst(isequal(c), ['a', 'b', 'c', 'd'])] += 1
        end

        for i in 1:4
            if count[i] > max_count
                max_count = count[i]
                max_char = 'a' + i - 1 # converting index 'i' into char value
            end
        end
        println("$(max_char) occurred the most $(max_count) times of a total of $num characters.")

        return 0
    end

    # OpenMP parallel version
    threads = nthreads() # get number of threads available
    if N > threads
        println("Warning: $N requested threads exceeds the available $threads threads.")
        N = threads
    end

    @threads for id = 1:N
        start = 1 + (id-1) * (num ÷ N) # calculate start index for this thread
        finish = id == N ? num : id * (num ÷ N) # calculate end index for this thread

        # Private count array for each thread
        count_local = zeros(Int, 4)

        # loop through characters in buffer for this thread
        for c in buffer[start:finish]
            # determine which entry of array to increment based on character read from buffer
            count_local[findfirst(isequal(c), ['a', 'b', 'c', 'd'])] += 1
        end

        # Combine arrays for each thread in to one
        @atomic for i in 1:4
            count[i] += count_local[i]
        end
    end

    # loop through entries in array to find maximum frequency and corresponding
    for i in 1:4
        if count[i] > max_count
            max_count = count[i]
            max_char = 'a' + i - 1 # converting index 'i' into char value
        end
    end

    println("$(max_char) occurred the most $(max_count) times of a total of $num characters.")

    return 0
end


main()
