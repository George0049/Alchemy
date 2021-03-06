#include <device_launch_parameters.h>
#include <math/math_op.h>
#include "accuracy_layer.h"

namespace alchemy {

template <typename T>
__global__ void max_index_kernel(const int count, const T * ptr, int * index){
    T max_value = 0;
    for(auto j = 0; j < count; ++j) {
        if(max_value < ptr[j]) {
            max_value = ptr[j];
            *index = j;
        };
    }
}

template<typename T>
void AccuracyLayer<T>::ForwardGPU(const vector<Blob<T> *> &input,
                                  const vector<Blob<T> *> &output)
{
    auto size = input[0]->shape(2) * input[0]->shape(3);
    auto o_ptr = input[0]->data_gptr();
    auto g_ptr = input[1]->data_gptr();
    int result_ = 0;
    Tensor<int> index_1({1}), index_2({1});

    for(auto i = 0; i < input[0]->shape(0); ++i) {

        max_index_kernel<<<1, 1>>>(size, o_ptr, index_1.mutable_gptr());
        max_index_kernel<<<1, 1>>>(size, g_ptr, index_2.mutable_gptr());

        auto _1 = index_1.cptr()[0];
        auto _2 = index_2.cptr()[0];
//        cudaDeviceSynchronize();
        if(_1 == _2)
            result_++;

        o_ptr += size;
        g_ptr += size;
    }

    /// cpu
    output[0]->mutable_data_cptr()[1] += result_;
    output[0]->mutable_data_cptr()[2] += input[0]->shape(0);
    output[0]->mutable_data_cptr()[0] = output[0]->data_cptr()[1] / output[0]->data_cptr()[2];
}

template void AccuracyLayer<float>::ForwardGPU(const vector<Blob<float> *> &input, const vector<Blob<float> *> &output);
template void AccuracyLayer<double>::ForwardGPU(const vector<Blob<double> *> &input, const vector<Blob<double> *> &output);
}