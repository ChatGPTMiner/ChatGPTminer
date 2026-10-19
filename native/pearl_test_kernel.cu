#include "pearl/test_cuda.h"

#include <cuda_runtime.h>
#include <stdint.h>

namespace {

__device__ __forceinline__ uint64_t mix64(uint64_t value) {
    value ^= value >> 30;
    value *= 0xbf58476d1ce4e5b9ULL;
    value ^= value >> 27;
    value *= 0x94d049bb133111ebULL;
    return value ^ (value >> 31);
}

__device__ __forceinline__ int dot_int8(
    const int8_t* a,
    const int8_t* b,
    uint32_t k) {
    int sum = 0;
#if __CUDA_ARCH__ >= 610
    if ((k & 3U) == 0U) {
        const uint32_t packed = k / 4;
        const int* a4 = reinterpret_cast<const int*>(a);
        const int* b4 = reinterpret_cast<const int*>(b);
        for (uint32_t i = 0; i < packed; ++i) sum = __dp4a(a4[i], b4[i], sum);
    } else {
        for (uint32_t i = 0; i < k; ++i)
            sum += static_cast<int>(a[i]) * static_cast<int>(b[i]);
    }
#else
    for (uint32_t i = 0; i < k; ++i)
        sum += static_cast<int>(a[i]) * static_cast<int>(b[i]);
#endif
    return sum;
}

__global__ void pearl_test_gemm(
    const int8_t* __restrict__ a,
    const int8_t* __restrict__ b,
    uint32_t m,
    uint32_t n,
    uint32_t k,
    uint64_t nonce,
    uint64_t target,
    PearlTestResult* result) {
    const uint32_t column = blockIdx.x * blockDim.x + threadIdx.x;
    const uint32_t row = blockIdx.y * blockDim.y + threadIdx.y;
    if (row >= m || column >= n || atomicAdd(&result->found, 0U) != 0U) return;

    const int dot = dot_int8(a + static_cast<uint64_t>(row) * k,
                             b + static_cast<uint64_t>(column) * k, k);
    uint64_t transcript = nonce;
    transcript ^= static_cast<uint64_t>(row) << 32;
    transcript ^= column;
    transcript = mix64(transcript ^ static_cast<uint32_t>(dot));
    transcript = mix64(transcript ^ (static_cast<uint64_t>(m) << 32 | n));
    transcript = mix64(transcript ^ k);

    if (transcript <= target && atomicCAS(&result->found, 0U, 1U) == 0U) {
        result->row = row;
        result->column = column;
        result->digest = transcript;
        __threadfence_system();
        atomicExch(&result->found, 2U);
    }
}

int cuda_error(cudaError_t error) {
    return error == cudaSuccess ? 0 : -1000 - static_cast<int>(error);
}

} // namespace

extern "C" int pearl_test_launch(
    int device,
    const int8_t* a_device,
    const int8_t* b_device,
    uint32_t m,
    uint32_t n,
    uint32_t k,
    uint64_t nonce,
    uint64_t target,
    PearlTestResult* result_device,
    void* stream_pointer) {
    if (!a_device || !b_device || !result_device || !m || !n || !k) return -1;
    if ((reinterpret_cast<uintptr_t>(a_device) & 3U) ||
        (reinterpret_cast<uintptr_t>(b_device) & 3U)) return -2;
    if (const auto error = cudaSetDevice(device); error != cudaSuccess) return cuda_error(error);

    const dim3 threads(16, 16);
    const dim3 blocks((n + threads.x - 1) / threads.x,
                      (m + threads.y - 1) / threads.y);
    pearl_test_gemm<<<blocks, threads, 0, static_cast<cudaStream_t>(stream_pointer)>>>(
        a_device, b_device, m, n, k, nonce, target, result_device);
    return cuda_error(cudaPeekAtLastError());
}

extern "C" int pearl_test_supports_device(int device) {
    cudaDeviceProp properties{};
    if (cudaGetDeviceProperties(&properties, device) != cudaSuccess) return 0;
    return (properties.major == 8 &&
            (properties.minor == 6 || properties.minor == 7 || properties.minor == 9)) ||
           properties.major >= 12;
}

extern "C" const char* pearl_test_kernel_name() {
    return "pearlhash-test-dp4a-v1";
}
