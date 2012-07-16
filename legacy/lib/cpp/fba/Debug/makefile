################################################################################
# Automatically-generated file. Do not edit!
################################################################################

ROOT := ..

-include $(ROOT)/makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include $(SUBDIRS:%=%/subdir.mk)
-include objects.mk
ifneq ($(strip $(DEPS)),)
-include $(DEPS)
endif

-include $(ROOT)/makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 

# All Target
all: fba3

# Tool invocations
fba3: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: GCC C++ Linker'
	@echo g++ -L/usr/local/lib/COIN -L/usr/local/lib/mysql -ofba3 $(OBJS) $(USER_OBJS) $(LIBS)
	@g++ -L/usr/local/lib/COIN -L/usr/local/lib/mysql -ofba3 $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(DEPS)$(EXECUTABLES) fba3
	-@echo ' '

.PHONY: all clean dependents
.SECONDARY:

-include $(ROOT)/makefile.targets
