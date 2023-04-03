using Distributed

# Define a function that reads a file, counts the frequency of each character, and returns the maximum frequency and corresponding character
function count_chars(filename::String)
    count = zeros(Int, 4)
    max_count = 0
    max_char = 'a'

    # Read the file
    f = open(filename, "r")
    text = read(f, String)
    close(f)

    # Count the characters in parallel
    @sync @distributed for i = 1:length(text)
        c = text[i]
        if c == 'a'
            @atomic count[1] += 1
        elseif c == 'b'
            @atomic count[2] += 1
        elseif c == 'c'
            @atomic count[3] += 1
        elseif c == 'd'
            @atomic count[4] += 1
        end
    end

    # Find the maximum frequency and corresponding character
    for i = 1:4
        if count[i] > max_count
            max_count = count[i]
            max_char = Char(UInt8('a') + i - 1)
        end
    end

    return max_count, max_char
end

# Get the number of workers
nworkers()

# Parse command line arguments
N = parse(Int, ARGS[1]) # number of workers
filename = ARGS[2] # name of file

# Set the number of workers
addprocs(N-1)

# Call the function to count the characters
@time max_count, max_char = count_chars(filename)

# Print the result
println("$max_char occurred the most $max_count times.")
