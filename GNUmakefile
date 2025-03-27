# SPDX-License-Identifier: BlueOak-1.0.0
# SPDX-FileCopyrightText: 2024 Saulius Krasuckas <saulius2_at_ar-fi_point_lt> | sskras

A = An introductory description of this Makefile (a TODO).


sample_iso = `cygpath -m /C/Users/Renato/Downloads/18362*.iso`


all:
	@echo "${A}"
	@echo
	@echo "Available targets:"
	@
	@# Via: https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile/26340367#26340367
	@$(MAKE) -pRrqn -f $(firstword $(MAKEFILE_LIST)) : 2> /dev/null \
	| awk                                                           \
	'                                           \
	      BEGIN                                 \
	      {                                     \
	          RS=""         # Set separators    \
	          FS=":"                            \
	      }                                     \
	                                            \
	      /^# Files$$/                          \
	      {                                     \
	          GO=1          # Start processing  \
	      }                                     \
	                                            \
	      /^# Finished Make data base/          \
	      {                                     \
	          GO=0          # Stop processing   \
	      }                                     \
	                                            \
	      GO && ! /^(#|\.|$@:)/                 \
	      {                                     \
	          printf "    " # Indent            \
	          print $$1     # Print target name \
	      }                                     \
	'                                           \
	| sort

desc:
	@echo "${A}"

sample:
	@sh -c "time                                        \
	    ./iso2winre.ps1                                 \
	    $$(                                             \
	      cygpath -m                                    \
	        /C/Users/Renato/Downloads/18362*.iso        \
	      )                                             \
	    " 2>&1                                          \
	    | sed 's/\r//'                                  \
	    | tee iso2winre-sample.output                   \

clean:
	./iso-image.ps1 ${sample_iso} -cleanup              \

