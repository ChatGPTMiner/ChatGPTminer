#pragma once

#include <stdint.h>

#if defined(_WIN32)
#define PEARL_TEST_API __declspec(dllexport)
#else
#define PEARL_TEST_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PearlTestResult {
    /* 0 = empty, 1 = writer owns the slot, 2 = result ready for host. */
    uint32_t found;
    uint32_t row;
    uint32_t column;
    uint64_t digest;
} PearlTestResult;

/*
 * Launch the non-consensus test kernel.
 *
 * a_device: signed int8 matrix [m, k], row-major
 * b_device: signed int8 matrix [n, k], row-major (logically B-transposed)
 * result_device: one zero-initialized PearlTestResult in device memory
 * target: a match is reported when digest <= target
 * stream: cudaStream_t cast to void*
 */
PEARL_TEST_API int pearl_test_launch(
    int device,
    const int8_t* a_device,
    const int8_t* b_device,
    uint32_t m,
    uint32_t n,
    uint32_t k,
    uint64_t nonce,
    uint64_t target,
    PearlTestResult* result_device,
    void* stream);

PEARL_TEST_API int pearl_test_supports_device(int device);
PEARL_TEST_API const char* pearl_test_kernel_name(void);

#ifdef __cplusplus
}
#endif

