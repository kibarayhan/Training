package training.sort;
/*

The sorting algorithms characteristics:
1. Time complexity: This is what the concept of asymptotic runtime, or big O time, means. Big O notations in increasing
time complexity order:
O(1) - Constant Time Algorithms
O(log n) - Logarithmic Time Algorithms
O(n) - Linear Time Algorithms
O(n log n) - N Log N Time Algorithms
O(n^p) - Polynomial Time Algorithms such as: quadratic (n2), cubic (n3), quartic (n4)
O(k^n) - Exponential Time Algorithms
O(n!) - Factorial Time Algorithms


 - O (big 0) (worst case): In academia, big O describes an upper bound on the time. An algorithm that prints all the
values in an array could be described as O(N), but it could also be described as O(N2), O(N3), or 0(2N)
(or many other big O times). The algorithm is at least as fast as each of these; therefore they are upper
bounds on the runtime.
 - Ω (big omega) (best case): In academia, Ω is the equivalent concept but for lower bound.Printing the values in
an array is Ω(N) as well as Ω(log N) and Ω(1). After all, you know that it won't be faster than those runtimes.
 - Θ (big theta) (average case): In academia, Θ means both O and Ω. That is, an algorithm is Θ(N) if it is both O(N) and
Ω(N). Θ gives a tight bound on runtime.

2. Space complexity: In place or not. It is related with memory allocation during the execution of algo.
in-place algorithms are insertion sort, bubble sort, heap sort, quicksort, and shell sort.

3. Stability (Stable or not): The stability of a sorting algorithm is concerned with how the algorithm treats equal
(or repeated) elements. Stable sorting algorithms preserve the relative order of equal elements,
Several common sorting algorithms are stable by nature,
such as Merge Sort, Timsort, Counting Sort, Insertion Sort, and Bubble Sort.
Others such as Quicksort, Heapsort and Selection Sort are unstable.
We can modify unstable sorting algorithms to be stable. For instance, we can use extra space to maintain stability in Quicksort.

4. Recursive or imperative:

5. Internal or External sort:


Algorithm		Time Complexity								Space Complexity
				Best		Average			Worst			Worst
Quicksort		Ω(n log(n))	Θ(n log(n))		O(n^2)			O(log(n))
Mergesort		Ω(n log(n))	Θ(n log(n))		O(n log(n))		O(n)
Timsort			Ω(n)		Θ(n log(n))		O(n log(n))		O(n)
Heapsort		Ω(n log(n))	Θ(n log(n))		O(n log(n))		O(1)
Bubble Sort		Ω(n)		Θ(n^2)			O(n^2)			O(1)
Insertion Sort	Ω(n)		Θ(n^2)			O(n^2)			O(1)
Selection Sort	Ω(n^2)		Θ(n^2)			O(n^2)			O(1)
Tree Sort		Ω(n log(n))	Θ(n log(n))		O(n^2)			O(n)
Shell Sort		Ω(n log(n))	Θ(n(log(n))^2)	O(n(log(n))^2)	O(1)
Bucket Sort		Ω(n+k)		Θ(n+k)			O(n^2)			O(n)
Radix Sort		Ω(nk)		Θ(nk)			O(nk)			O(n+k)
Counting Sort	Ω(n+k)		Θ(n+k)			O(n+k)			O(k)
Cubesort		Ω(n)		Θ(n log(n))		O(n log(n))		O(n)
 */