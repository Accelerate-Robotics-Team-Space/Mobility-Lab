#!/bin/sh


# https://gist.github.com/yan-foto/c1f57bf1fe4f63d4f674d98e96e23730
# Make sure date is given
# if [ $# -eq 0 ]
# then
# 	printf "Usage:\n bash git-del-tag.sh 2018-04-23"
# 	exit 1
# fi
#
# date command has different syntax for Linux and Mac
uname=$(uname)
case "$uname" in
	(*Linux*) dateCmd='date +%s -d' ;;
	(*Darwin*) dateCmd='date -jf "%Y-%m-%d" +%s' ;;
esac

delLocal='git tag -d'
delRemoteCmd='git push --delete origin'
delLocalCmd='git fetch --prune origin "+refs/tags/*:refs/tags/*"'


# Get Date for 2 months ago in format "YYYY-MM-dd"
userDate=$(date -v -2m +%F)

# User given date to epoch timestamp
userTS=`eval "$dateCmd $userDate"`

currentVersion="1.0.117.0"

echo "Prune QA tags from before $userDate, that aren't the current version ($currentVersion)"
echo ""

git for-each-ref --sort=taggerdate --format 'tag="%(refname:short)"; DATE="%(taggerdate:short)"' refs/tags |
{
	# Array of matching tags
	tags=()

	echo "Finding matching tags..."
	while read entry; do
		eval "$entry"
		# echo "$entry"
		if [ -z "$DATE" ]; then
			DATE=$(date -v -3m +%F)
			# echo "Date is Empty: $DATE"
		fi
		# echo "$DATE"
		tagTS=`eval "$dateCmd $DATE"`
		
		if [[ $userTS -ge $tagTS && "$tag" == *"QA"* && "$tag" != *"$currentVersion"* ]]; then
			#echo "Adding Tag for $DATE: $tag"
			tags[${#tags[*]}]="$tag"
		fi
	done
	
	# If no tags has been found just exit!
	if [ ${#tags[@]} -eq 0 ]
	then
		echo "No matching tags found. Quitting!"
		exit 0
	fi

	# echo "Found ${tags[@]} tags..."
	echo "Following tags will be removed"
	for tag in "${tags[@]}"; do
	  echo "$tag"
	done
	echo ""
	# echo "${tags[@]}"
	read -p "Are you sure you want to continue? [N/y]" docontinue < /dev/tty
	if [ "$docontinue" = "y" ]; then
		echo "Removing Local tags..."
        eval '$delLocal "${tags[@]}"'
		echo "Removing remote tags..."
		eval '$delRemoteCmd "${tags[@]}"'
		# for tag in "${tags[@]}"; do
	  	# 	eval '$delRemoteCmd "$tag"'
		# done
		echo "Purging local tags..."
		# eval "$delLocalCmd"
	fi
}

exit 0
