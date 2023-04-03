using Distributed
addprocs(4) # Add 4 worker processes

@everywhere function count_chars(filename, start, stop)
    fp = open(filename, "r")
    seek(fp, start)
    str = read(fp, stop - start + 1)
    close(fp)
    count = zeros(Int, 4)
    for c in str
        count[c - 'a' + 1] += 1
    end
    return count
end

function parallel_count_chars(filename, nprocs)
    num = filesize(filename)
    pids = workers()
    @sync begin
        @distributed for (i, pid) in enumerate(pids)
            start = Int64(((i - 1) * num) ÷ nprocs) + 1
            stop = Int64((i * num) ÷ nprocs)
            if i == nprocs
                stop = num
            end
            local_count = count_chars(filename, start, stop)
            remote_call_fetch(:(@spawnat), pid, (main, local_count))
        end
    end
    counts = fetch(Any[fetch(x) for x in results()])
    count = reduce(+, counts)
    max_count, max_char = findmax(count)
    max_char = Char('a' + max_char - 1)
    println("$max_char occurred the most $max_count times of a total of $num characters.")
end

function main()
    if length(ARGS) < 3
        println("Usage: julia <program.jl> <nprocs> <filename>")
        return
    end

    nprocs = parse(Int, ARGS[1])
    filename = ARGS[2]
    println("$nprocs and $filename")
    @time parallel_count_chars(filename, nprocs)
end

main()