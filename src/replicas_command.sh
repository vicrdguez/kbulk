# echo "# this file is located in 'src/replicas_command.sh'"
# echo "# code for 'kbulk replicas' goes here"
# echo "# you can edit it freely and regenerate (it will not be overwritten)"
# inspect_args

topic_list=$(cat ${args[topics]})
target=${args[target]}
bootstrap="--bootstrap-server ${args[--bootstrap]}"

config=${args[--config]}
if [[ $config ]]; then
	config="--command-config ${args[--config]}"
fi

num_brokers=$(kafka-broker-api-versions ${bootstrap} ${config} | awk '/id/{print $1}' | wc -l)

function get_replicas() {
	# ok=0
	# min=1
	# max=$1
	list=$1
	start=$2

	# We want to increase the replication factor. Generate random new replicas
	if [[ $start -lt $target ]]; then
		while [[ $start -ne $target ]]; do
			# getting a random number between 1 and num_brokers
			rnd=$(awk -v n=$num_brokers 'BEGIN{srand();print int(rand()*(n))+1 }')
			# Check if the replica is the same as the one passed as parameter. Don't include it then
			if [[ $(echo "$list" | grep -c "$rnd") -eq 0 ]]; then
				# new=$(random_replicas $max "${2},$rnd")
				list=$list,$rnd
				# new_count=$((new_count++))
				((start++))
			fi
		done
	else
		# We want to decrease the replication factor. Keep the first ones until target
		leader=$3
		if [[ $target -gt 1 ]]; then
			list=$(echo $list | cut -d, -f1-$target)
			# if the leader was removed, cut another replica and add it back
			if [[ $(echo "$list" | grep -c "$leader") -eq 0 ]]; then
				if [[ $target -gt 1 ]]; then
					list=$leader,$(echo $list | cut -d, -f1-$((target - 1)))
				fi
			fi
		else
			list=$leader
		fi
	fi

	echo "${list}"
}

no_color "Number of brokers: ${num_brokers}"
for topic in $topic_list; do
	out=$(kafka-topics ${bootstrap} ${config} --describe --topic ${topic} 2>/dev/null)
	partition_count=$(echo "{$out}" | grep -o "PartitionCount: [0-9.]" | awk '{print $2}')
	green "Changing replication factor for topic $(green_bold "${topic}") $(green "with PartitionCount: ${partition_count}")"

	json_delim=""
	# printf "{\"version\": 1,\"partitions\": [\n" >kbulk-replica-assignment.json
	json_header="{\"version\": 1,\"partitions\": [\n"
	# Empty the file for next iteration
	cat /dev/null >kbulk-replica-assignment.json

	echo "{$out}" | grep "Replicas:" | awk '{print $4,$6,$8}' | while read p l r; do
		curr_num_replicas=$(echo "$r" | awk -F '[,]' '{print NF}')

		no_color "Current number of replicas for partition ${p} (Leader: ${l}): ${curr_num_replicas}"
		# If the partition has already $target number of replicas, skip it
		if [[ $curr_num_replicas -eq $target ]]; then
			cyan "\tSkipping partition ${p}: current number of replicas already matches the target"
		else
			# if [[ $curr_num_replicas -gt $target ]]; then
			#     new_replicas=$(random_replicas "$r")
			# fi
			new_replicas=$(get_replicas "${r}" "${curr_num_replicas}" "${l}")
			yellow "\tPartition ${p} new replica assignment: ${r} ==> ${new_replicas}"
			printf "${json_header}" >>kbulk-replica-assignment.json
			printf "${json_delim}{\"topic\": \"${topic}\", \"partition\": ${p}, \"replicas\": [${new_replicas}]}" >>kbulk-replica-assignment.json
			json_delim=",\n"
			json_header=""
			# if ((p + 1 == partition_count)); then json_delim=""; fi
		fi

	done

	if grep -q . kbulk-replica-assignment.json; then
		printf "\n]}" >>kbulk-replica-assignment.json
		yellow "Executing the replica assignment for topic ${topic}.\nThis can take a while if your topic has a lot of data\n"

		kafka-reassign-partitions ${bootstrap} ${config} --reassignment-json-file kbulk-replica-assignment.json --execute &>/dev/null

		cond="kafka-reassign-partitions ${bootstrap} ${config} --reassignment-json-file replica-assignment.json --verify | grep -io \"complete\""
		wait_completion "$cond" "Waiting for reasignment to complete." "Reassignment complete for Topic: ${topic}     " 2
	else
		cyan "Skipping topic $(cyan_bold "${topic}")$(cyan ": All partitions have replicas matching the target")"
		cyan_bold "================\n"
	fi

done
