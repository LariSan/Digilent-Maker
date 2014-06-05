################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/color_space.c \
../src/helloworld.c \
../src/linear_filter.c \
../src/platform.c 

LD_SRCS += \
../src/lscript.ld 

OBJS += \
./src/color_space.o \
./src/helloworld.o \
./src/linear_filter.o \
./src/platform.o 

C_DEPS += \
./src/color_space.d \
./src/helloworld.d \
./src/linear_filter.d \
./src/platform.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM gcc compiler'
	arm-xilinx-eabi-gcc -Wall -O0 -g3 -c -fmessage-length=0 -I../../video_demo_bsp/ps7_cortexa9_0/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


