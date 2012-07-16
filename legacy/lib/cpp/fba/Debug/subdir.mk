################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
$(ROOT)/FbaSetup.cpp \
$(ROOT)/fba.cpp 

OBJS += \
./FbaSetup.o \
./fba.o 

DEPS += \
${addprefix ./, \
FbaSetup.d \
fba.d \
}


# Each subdirectory must supply rules for building sources it contributes
%.o: $(ROOT)/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	@echo g++ -DCOIN_USE_CLP -I/usr/local/include -I/usr/local/include/mysql -I/usr/local/include/COIN -O0 -g3 -Wall -c -fmessage-length=0 -o$@ $<
	@g++ -DCOIN_USE_CLP -I/usr/local/include -I/usr/local/include/mysql -I/usr/local/include/COIN -O0 -g3 -Wall -c -fmessage-length=0 -o$@ $< && \
	echo -n $(@:%.o=%.d) $(dir $@) > $(@:%.o=%.d) && \
	g++ -MM -MG -P -w -DCOIN_USE_CLP -I/usr/local/include -I/usr/local/include/mysql -I/usr/local/include/COIN -O0 -g3 -Wall -c -fmessage-length=0  $< >> $(@:%.o=%.d)
	@echo 'Finished building: $<'
	@echo ' '


