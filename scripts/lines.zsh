#!/bin/zsh

# cd ~/Source/Hyades
NOTIFY=true 
SHOULD_SAY=false

while [[ "$#" -gt 0 ]]
do case $1 in
  -n|--notify) NOTIFY=true
  shift;;
  -s|--say) SHOULD_SAY=true
  shift;;
  *) echo "Unknown parameter passed: $1\nOnly -n, --notify, -s, --say parameters are supported"
  shift;;
esac
# shift
done


BRANCH=$(git branch --show-current)

if [ -z ${1+x} ]; then
  # Parent
  # https://stackoverflow.com/questions/1527234/finding-a-branch-point-with-git
  # COMPARE_BRANCH=$(git log --pretty=format:'%D' HEAD^ | grep 'origin/' | head -n1 | sed 's@origin/@@' | sed 's@,.*@@') # This needs work
  COMPARE_BRANCH=sprint
  COMPARE_HEAD_COMMMIT=$(git show --format="%H" $(git show -s --format="%H" sprint..HEAD | tail -1)~1)
else
  COMPARE_BRANCH="$1"
  COMPARE_HEAD_COMMMIT=$(git rev-parse $COMPARE_BRANCH)
  echo "Comparing to $COMPARE_BRANCH"
fi

CURRENT_HEAD_COMMIT=$(git rev-parse $BRANCH)

ADDED_REMOVED=$(git diff --numstat --pretty="%H" $COMPARE_HEAD_COMMMIT..$CURRENT_HEAD_COMMIT | awk 'NF==3 {added+=$1; removed+=$2} END {printf("%d,%d", added, removed)}')
ADDED=$(echo $ADDED_REMOVED | awk -F',' '{print $1}')
REMOVED=$(echo $ADDED_REMOVED | awk -F',' '{print $2}')
CHANGES=$(($ADDED + $REMOVED))

OUTPUT_ANSI="Changes:   \e[0;91m$CHANGES\e[0m\t(+$ADDED, -$REMOVED)"
# echo $OUTPUT_ANSI

OSA_TITLE="Lines Difference: $CHANGES (+$ADDED, -$REMOVED)"
echo $OSA_TITLE

if $NOTIFY; then
osascript - "$OSA_TITLE" "$BRANCH" <<EOF
  on run argv
    display notification (item 1 of argv) with title (item 2 of argv)
  end run
EOF
fi # if $NOTIFY

if $SHOULD_SAY; then
SAY="TOTAL of $CHANGES Lines difference. Added $ADDED, removed $REMOVED"
osascript - $SAY <<EOF
  on run argv
    say (item 1 of argv)
  end run
EOF
fi # if $SHOULD_SAY
