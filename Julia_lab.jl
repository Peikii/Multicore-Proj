using Distributed
addprocs(4) # Add 4 worker processes

@everywhere function count_chars(filename, start, stop)
    fp = open(filename, "r")
    seekstart(fp, start)
    str = read(fp, stop - start + 1)
    close(fp)
    count = zeros(Int, 26)
    for c in str
        if c in 'a':'z'
            count[c - 'a' + 1] += 1
        end
    end
    return count
end

function parallel_count_chars(nprocs, filename)
    num = filesize(filename)
    pids = workers()
    @sync @distributed for (i, pid) in enumerate(pids)
        start = Int64(((i - 1) * num) ÷ nprocs) + 1
        stop = Int64((i * num) ÷ nprocs)
        if i == nprocs
            stop = num
        end
        local_count = count_chars(filename, start, stop)
        remote_call_fetch(pid, ()->local_count)
    end
    counts = fetch(@spawnat :any, map(f->f(), fetch(@spawnat :any, nprocs)))
    count = reduce(+, counts)
    max_count, max_char = findmax(count)
    max_char = Char('a' + max_char - 1)
    println("$max_char occurred the most $max_count times of a total of $num characters.")
end

function main()
    if length(ARGS) != 2
        println("Usage: julia <program.jl> <nprocs> <filename>")
        return
    end

    nprocs = parse(Int, ARGS[1])
    filename = ARGS[2]
    @time parallel_count_chars(nprocs, filename)
end

main()
