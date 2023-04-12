## Add any function here that is needed in more than one parts of your
## application, or that you otherwise wish to extract from the main function
## scripts.
##
## Note that code here should be wrapped inside bash functions, and it is
## recommended to have a separate file for each function.
##
## Subdirectories will also be scanned for *.sh, so you have no reason not
## to organize your code neatly.
##

# $1: condition to wait for
# $2: Waiting message
# $3: Completion message
# $4: Wait interval in secs
wait_completion() {
	sp='/-\|'
	time=$SECONDS
	while
		# a small trick to execute the commands in the background based on the interval passed
		res=""
		if (((SECONDS - time) == $4)); then
			exec 3< <(eval "$1" 2>/dev/null)
			res=$(cat <&3 2>/dev/null)
			time=$SECONDS
		fi

		## if [[ -n $res ]]; then
		## 	green "This would have been success!!!\n"
		## 	green "$res \n"
		## fi
		##       true
		[[ -z $res ]]
	do
		# a spinner to not clutter the screen.
		printf "\b\e[33m$2 [%.1s]\e[0m\r" "$sp"
		sleep 0.1
		sp=${sp#?}${sp%???}

	done

	green_bold "$3"
	green_bold "================\n"
}
