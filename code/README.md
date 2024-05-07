# Course Project for EECS4824 Computer Architecture

# Introduction:

R10K is a high-performance microprocessor designed by MIPS and first introduced in the mid-1990s. It uses out-of-order execution technology, which allows the processor to execute instructions outside the original order of program instructions to improve execution efficiency and processor throughput. This out-of-order execution mechanism can effectively utilize processor resources and reduce idle cycles caused by instruction dependencies and execution waits, thereby significantly improving program execution speed.
The R10K processor enhances resource utilization by executing independent instructions while waiting for others, reducing dependencies between instructions to minimize pipeline stalls, and boosting parallel processing capabilities by allowing simultaneous instruction execution. It also incorporates dynamic scheduling and advanced branch prediction to optimize execution speed and accuracy. Our project is dedicated to building an out-of-order execution pipeline based on the R10K architecture. We chose the R10K for these significant advantages, which altogether elevate computing performance and efficiency.



# How to use

run single program:

```shell
make xxx.out
```

run visual debugger

```shell
make xxx.vis
```

run all
```shell
./auto_test.sh
```
