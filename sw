#!/bin/bash
#
# Script: sw
# Description:
# Version: 4.0.18
# Package Version: 4.0.18
# Date: 2017.01.03
# Author: Bob Chang
# Tested: CentOS 6.x, Cygwin NT 6.1
#

###!!!!! need to do
# modify other show function
# create get_pathes function
# modify -r function
# modify -u function
# nnnnnneed to tag version and delete make safe commit of Git
#!!!!

## don't modify here, because the $0 is /bin/bash for alias 
script_name=sw
script_full_name=sw
this_file=/usr/local/bin/$script_full_name
tag_folder=~
##

# variables #
# 1 for debug, 0 for no
debug=0

# functions #

# Meta
# Group: High level functions
	
#
# Function: main
# Description:
#	- high level function
# Usage: main
#
main() {				
	#
	# the function main is used for source (I can't use exit or return 
	# directly in script otherwise the shell will terminate). Recently 
	# it seems ok using if-else instead of it, but for future expansion 
	# I keep this main() way.
	#

	if [ $# -eq 0 ];then
		show_list
		return 0
	fi

	case $1 in
		.) check_path
		;;
		-c) clean_list
		;;
		-d) delete_tag $2
		;;
		-gf) get_tag_file
		;;
		-h) show_usage
		;;
		-r) show_list_by_path
		;;
		-tag) check_tag $2
		;;
		-u) show_list_under_tag $2
		;;
		-V) show_version
		;;
		*) save_path $1
		;;
	esac
}

#
# Function: save_path
# Description: 
#	- high level function
#	- perform any needed operations to add tag to system with its path
#	- not so reusable
#	- tag name format will be check
# Input: tag_name
# Return:
#	1 for invalid tag name format
# Usage: save_path tag_name
#
save_path() {
	local tag_name=$1

	#debug
	if [ $debug -eq 1 ];then
		echo "$FUNCNAME: tag_name=$tag_name"
		#read
	fi

	check_tag_format $tag_name
	local result=$?
	
	if [ $result -eq 1 ];then
		echo "invalid tag name format"
		return 1
	fi

	#if tag is already in tag list?
	check_tag_in_list $tag_name
	result=$?

	if [ $result -eq 0 ];then
		#tag is in list, update it with new path
		update_tag $tag_name
		result=$?
	else	
		#new tag, add it
		add_tag $tag_name
		result=$?
	fi

	if [ $result -eq 2 ];then	#not added
		:;	#do nothing
	else
		#after tag added I don't show all list
		#show_list

		#just the info of this new tag
		show_tag_info $tag_name
	fi
}
	
#
# Function: clean_list
# Description:
# Usage: clean_list
#	=> all tag information are removed from system
#
clean_list() {
	unset_shell_variables
	local list=`get_tag_file`
	>$list
}

#
# Function: check_tag
# Description:
# Input: tag_name
# Output:
# Return: N/A
# Usage: check_tag tag_name
# 	find => angl                 /var/www/html/angl
#	no find => N/A
# 
check_tag() {
	local tag_name=$1

	#debug
	if [ $debug -eq 1 ];then
		echo "$FUNCNAME: tag_name=$tag_name"
		#read
	fi

	check_tag_format $tag_name
	local result=$?
	
	if [ $result -eq 1 ];then
		echo "invalid tag name format"
		return 1
	fi

	#if tag is already in tag list?
	check_tag_in_list $tag_name
	result=$?

	if [ $result -eq 0 ];then
		#tag is in list
		show_tag_info $tag_name
	else
		:;	#do nothing :)
	fi
}
	
#
# Function: show_usage
#
show_usage() {
	local tag_file=`get_tag_file`
	local version=`get_script_version`
	local pkg_version=`get_pkg_version`

        cat<<here
$script_full_name, v$version
g2w package, $pkg_version

Change and manage work directories

Usage: $script_full_name [-c|-d <tag>|-gf|-h|-V]

tag	    composed of a-z, A-Z, 0-9 or _, can't start with digit,
            at lest 1 to max 20 characters

Options
  N/A	    show tags info sorted by tag name
  .	    check if recent work directory is recorded in list
  tag	    save tag with current work directory path
  -c        clean (delete) all tags in path list
  -d tag    delete tag in path list
  -gf	    get tag file name
  -h        show this help
  -r	    show tags info sorted by path
  -tag	    show tag info if it is in list
  -u tag    show tags which pathes under this tag path
  -V        show version

Tag List
  The tag list is $tag_file

EXAMPLE
  $script_full_name
  $script_full_name a
  $script_full_name -d b
  $script_full_name -c

here

}

# Meta
# Group: Script version
# Description: Handle script version
#

#
# Function: get_script_version
# Description:
#	- ouput this script version number only
#	  e.g. 1.0.2
#	- the version line must in form # Version: <version number>
# Input: N/A
# Output: version number or - for no version number
# Usage: get_script_version => 1.0.2
# 
get_script_version() {
	local version=`grep '^# Version:' $this_file|cut -d ' ' -f 3`
	if [ -z $version ];then
		echo '-'
	else
		echo $version
	fi
}

#
# Function: get_pkg_version
#
get_pkg_version() {
	local version=`grep '^# Package Version:' $this_file|cut -d ' ' -f 4`
	if [ -z $version ];then
		echo '-'
	else
		echo $version
	fi
}

#
# Function: show_version
# Description:
#	- ouput this script version in formate package version/script versiont
#	  e.g. 1.2.0/1.1.7
#	- the version line must in form # Version: <version number>
# Input: N/A
# Output: formated version information
# 
show_version() {
	local pkg_v=`get_pkg_version`
	local script_v=`get_script_version`

	echo "$pkg_v/$script_v"
}

# Meta
# Group: General operation

#
# Function: get_username
# Usage: get_username => root
#
get_username() {
	whoami
}

# Meta
# Group: Tag operation
# Description:

#
# Function: check_path
# Description: check if recent work path already exists in tag list
# Input: N/A
# Output: formated tag and path information
# Usage: check_path
#	=> angl                 /var/www/html/angl
#
check_path() {
	local list=`get_tag_file`
	local work_path=`pwd`
	grep ,$work_path$ $list |perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' -
}

# 
# Function: get_tag_file
# Description:
#	- return full path of user's tag file
# 	- if file doesn't exist, an empty file will be created
# Input: N/A
# Output: full path of user's tag file
#	  e.g /root/root.sw
# Usage: get_tag_file => /root/root.sw
#
get_tag_file() {
	local username=`get_username`
	tag_file_name=$username.$script_name
	tag_file=$tag_folder/$tag_file_name

	if [ ! -e $tag_file ];then
		>$tag_file
	fi

	echo $tag_file
}

#
# Function: get_tag_path
# Description: 
# Input: tag name
# Output: path of this tag, empty if tag doesn't exist
# Usage: get_tag_path tmp => /tmp
#
get_tag_path() {
	local tag=$1
	local list=`get_tag_file`
	local cmd="grep '^$tag\b' $list"
	local info=`eval $cmd`
	
	if [ ! -z $info ];then
		echo $info|cut -d , -f 2
	fi
}

#
# Function: get_tag_names
# Description:
#	- default in alphabetical order
# Input: N/A
# Output: sorted list of all tag names in tag list
# Usage: get_tag_names
#	=> output tag name list
#
get_tag_names() {
	local list=`get_tag_file`

	perl -ne 'chomp;@s=split(/,/);printf("%s\n",$s[0]);' $list|sort
}

#
# Function: delete_tag_from_list
# Description: 
#	- delete tag from tag list
#	- this function will not check if this tag has other value
#	  e.g. tag shell value
# Usage: delete_tag tag_name => remove tag record from tag list
#
delete_tag_from_list(){
	local tag_name=$1
	local list=`get_tag_file`
	local found=`grep ^$tag_name, $list >/dev/null 2>&1;echo $?`

	if [ $found -eq 0 ];then	#find tag in list
		cmd="sed -i '/^$tag_name,.\+/d' $list"
		eval $cmd
		return 0
	else
		return 1
	fi
}

#
# Function: delete_tag
# Description:
#	- check tag format
#	- remove tag record from tag list
#	- remove tag variable from shell if tag shell value equals
#	  tag path, otherwise tag variable will not be unset
# Input:
# Output:
# Return:
#	0
#	1 for 
#	
# Usage: delete_tag tag_name
#	=> remove tag from list
#	=> remove tag variable from shell if no conflict
#
delete_tag() {
	local tag_name=$1

	if [ -z $tag_name ];then
		show_usage
		return 1
	fi

	#check tag format
	check_tag_format $tag_name
	local result=$?

	#tag format not ok
	if [ $result -eq 1 ];then
		echo "invalid tag name format"
		return 1
	fi	

	#if tag shell value equals tag path
	local tag_path=`get_tag_path $tag_name`
	local tag_shell_value=`check_tag_in_shell $tag_name`
	
	#they are equal
	if [ "$tag_path" == "$tag_shell_value" ];then
		unset_tag_in_shell $tag_name
	fi

	delete_tag_from_list $tag_name

	#after delete tag don't need to show the tag list
	#especially when there are lots of tags
	#just keep output silent, if user wants he can use
	# sw or sw -tag <tag name> to check result
	#show_list
}

#
# Function: check_tag_format
# Description: 
#	- check tag name format
#	- rule: 
#		1. ^[a-zA-Z_][\w_]{0,19}\$
#		2. 1 to 20 letters
#		3. can't contain -
#		4. can't begin with number
# Input: tag_name
# Output: N/A
# Return:
#	- 0 for ok
#	- 1 for no ok
# Usage: check_tag_format tag_name
#	=> return 0 for ok
#	=> return 1 for no ok
#
check_tag_format() {
	local tag_name=$1

	#debug
	if [ $debug -eq 1 ];then
		echo "$FUNCNAME: tag_name=$tag_name"
	fi

	#
	# The naming rule is the same as shell environment variable 
	# naming rule, only [a-zA-Z0-9_], min 1, max 20, 
	# do not begin with a digit.
	# The reason why can't we use - in tag name because:
	# 1. It's invalid of shell variable naming rule.
	# 2. When tag name begins with -, it will be confused with flag.
	#
	local cmd="perl -w -e '\$name=\"$tag_name\";if(\$name =~ /^[a-zA-Z_][\w_]{0,19}\$/){print 0;}else{print 1}' 2>/dev/null"

	local result=`eval $cmd`

	if [ $result -eq 0 ];then	#name format is ok
		return 0		
	else				#not ok
		return 1
	fi
}

#
# Function: check_tag_in_list
# Description: check if tag exits in tag list
# Input: tag_name
# Output: N/A
# Return:
#	- 0 for in tag list
#	- 1 for not in tag list
# Usage: check_tag_in_list tag_name
#	=> return 0 for in list
#	=> return 1 for not in list
# 
check_tag_in_list() {
	local tag_name=$1
	local list=`get_tag_file`

	# 0 for find
	local found=`grep ^$tag_name, $list >/dev/null 2>&1;echo $?`

	if [ $found -eq 0 ];then	#found
		return 0
	else			#not found
		return 1
	fi
}

#
# Function: show_tag_info
# Description:
#	- show tag all information
#	- note if tag has shell variable conflict
# Input: tag_name
# Output: formated tag_info
# Usage: show_tag_info tag_name
#	=> work                 /opt/tools/g2w/work 
#
show_tag_info() {
	local tag_name=$1
	local list=`get_tag_file`
	local path=`get_tag_path $tag_name`

	#debug
	if [ $debug -eq 1 ];then
		echo "$FUNCNAME: tag_name=$tag_name"
	fi

	#
	# 2016.01.05
	# add conflict check
	#local tag_info=`grep "^$tag_name," $list`
	#echo $tag_info |perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' -

	check_tag_conflict $tag_name
	local result=$?

	#is conflict
	if [ $result -eq 0 ];then
		echo -n '*'
	fi

	printf "%-20s %-20s\n" $tag_name $path;
}

#
# Function: add_tag
# Description:
#	- this function will not check tag name format
#	- this function checks if tag is in shell
#	- if everything ok, tag will add to tag list and shell
# Input: tag_name
# Output: N/A
# Return:
#	0 for added to list and shell
#	1 for added to list only
#	2 no added
# Usage: add_tag tag_name
#	=> add tag_name and path to tag list
#	   set tag_name as variable in shell
#	   return 0
#	=> add tag_name and path to tag list (add note c as conflict)
#	   return 1
#	=> do nothing
#	   return 2
# 
add_tag() {
	local tag_name=$1
	local path=`pwd`
	local data=$tag_name,$path
	local list=`get_tag_file`
		
	#set tag as shell variable
	set_tag_in_shell $tag_name $path
	local result=$?	

	#1 for conflict:
	#tag name is already used by shell
	#and shell values is not equal to path
	if [ $result -eq 1 ];then
		local answer=n
		local tag_shell_value=`check_tag_in_shell $tag_name`

		echo "tag name already exists in shell: $tag_name=$tag_shell_value"
		echo -n "add to list only? [y/n] "
		read answer

		#need to refine here
		if [ "$answer" == y ];then	#user want's add tag to list only
			#add tag data to tag list
			echo "$data">>$list
			return 1
		else
			return 2	#do nothing
		fi
	else
		#add tag data to tag list
		echo $data>>$list
		return 0
	fi
}

#
# Function: update_tag
# Description:
#	- tag will be deleted than added
#	- this function will not check if tag exists in tag list
#	- this function will not check tag format
# Input: tag_name
# Output: N/A
# Return:
#	0 for update to list and shell
#	1 for update to list only
#	2 no update
# Usage: update_tag tag_name
#	=> tag_name has new path in list
#	=> shell variable tag_name have new path value if not conflict
#
update_tag() {
	local result
	local tag_name=$1

	delete_tag $tag_name

	add_tag $tag_name
	result=$?

	case $result in
		0) return 0;;
		1) return 1;;
		*) return 2;;
	esac
}

# Meta
# Group: Tag operation on shell
# Description:

#
# Function: check_tag_in_shell
# Description: 
#	- check if tag already exits as variable in shell
#	
# Input: tag_name
# Output: shell value if it's found, otherwise empty
# Return:
#	0 for not found
#	1 for found and no conflict
#	2 for found and conflict
# Usage: check_tag_in_shell tag_name
#	=> <value of shell variable>
#	=> <empty> for not found
#
check_tag_in_shell() {
	local tag_name=$1
	local cmd="echo \$${tag_name}"
	local result=`eval $cmd`
	echo "$result"
}

#
# Function: check_tag_conflict
# Description:
# Input: tag_name
# Output:
# Return:
#	0 for conflict
#	1 for no conflict
# Usage: check_tag_conflict tag_name
#	=> return 0 for conflict
#	=> return 1 for no conflict
#
check_tag_conflict() {
	local tag_name=$1
	local tag_shell_value=`check_tag_in_shell $tag_name`
	local tag_path=`get_tag_path $tag_name`

	#if tag_name is set in shell and 
	#its value is not equal to path
	#=> conflict
	if [ ! -z "$tag_shell_value" ] && [ ! "$tag_shell_value" == "$path" ];then
		return 0
	else		
		#no conflict
		return 1
	fi	
}

#
# Function: set_tag_in_shell
# Description: 
#	- set shell variable as tag vs path
#	  e.g. set_tag_in_shell tmp /tmp
#	  will result shell variable tmp with value /tmp
#	- export this variable to sub shell too
#	- if shell variable exists and equals path, the function
#	  will do nothing i.e. the shell value will not be overwritten
# Input: tag_name, path
# Output: N/A
# Return:
#	0 for added
#	1 for not added/conflict
# Usage: set_tag_in_shell tmp /tmp
#	=> in shell tmp=/tmp
#	=> return 0
#
set_tag_in_shell() {
	local tag_name=$1
	local path=$2

	check_tag_conflict $tag_name
	local result=$?

	#0 for conflict
	if [ $result -eq 0 ];then
		#don't set it
		return 1
	else				#otherwise set it
		export $tag_name=$path
		return 0
	fi	
}

#
# Function: unset_tag_in_shell
# Description: 
#	- unset tag in shell
#	- this function will not check if this tag exists in tag list
#	- user must check tag list manually before invoke this function
# Input: tag_name
# Usage: unset_tag_in_shell tag_name
#	=> unset <tag name> in shell
#
unset_tag_in_shell() {
	local tag_name=$1
	unset $tag_name
}

#
# Function: set_shell_variables
# Description:
#	- set all tags in tag list to shell variables
# Input: N/A
# Output: N/A
# Usage: set_shell_variable => in shell <tag1>=<path1>...
#
set_shell_variables() {
	local file=`get_tag_file`
	local list=`cat $file`
	local IFS_org=$IFS

	for data in $list
	do
		IFS=','
		local data_arr=($data)
		IFS=$IFS_org
		local tag=${data_arr[0]}
		local path=${data_arr[1]}
		
		set_tag_in_shell $tag $path
	done
}

#
# Function: unset_shell_variables
# Description:
# Usage: unset_shell_variables
#	=> all tag shell variables are unset
#
unset_shell_variables() {
	local file=`get_tag_file`
	local list=`cat $file`
	local IFS_org=$IFS

	for data in $list
	do
		IFS=','
		local data_arr=($data)
		IFS=$IFS_org
		local tag=${data_arr[0]}
		
		unset_tag_in_shell $tag
	done

}

# Meta
# Group: Show List
# Description:

#
# Function: show_list
# Description: show tag list sorted by tag name
# Usage: show_list
#	=> <tag1>                 <path1>	<note>
#	   ...
#	=> in shell <tag1>=<path1>
#	   ...
#
show_list() {
	local list=`get_tag_file`

	#debug
	#cat -A $list

	#
	# 2016.08.09
	# Note about show list
	# I have tried lots of way to implement this task, and
	# I found recent solution is the best.
	# The issues are
	# 1. sort -k doesn't work in Cygwin when there are multiple 
	# white spaces between columns, but it works on CentOS 
	# because it sees all white spaces as one.
	# 2. I tried to use only one function e.g. _show_list to print 
	# formated output (read output from other function then printf 
	# line by line), but the performance is terribly slow. So the 
	# functions are not reuseable, e.g. for output by sub-path it 
	# must be a new function to handle it.
	#
	#perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' $list|sort

	#
	# 2017.01.05
	# change to use show_tag_info
	#perl -ne 'chomp;@s=split(/,/);printf("%-20s %-40s %s\n",$s[0],$s[1],$s[2]);' $list|sort

	local tag_names=`get_tag_names`

	local name
	for name in $tag_names
	do
		show_tag_info $name
	done
	
	set_shell_variables
}

#
# Function: show_list_by_path
# Description: show tag list but sorted by path
# Usage: show_list_by_path
#	=> <tag1>                 <path1>...
#	=> in shell <tag1>=<path1>...
#
show_list_by_path() {
	local list=`get_tag_file`

	#debug
	#cat -A $list

	sort -t ',' -k 2,2 $list|perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);'

	set_shell_variables
}

#
# Function: show_list_under_tag
# Description: 
#	- show tag which path is under dedicated tag
# Usage: show_list_under_tag tag_name
#	=> <tag1>                 <path1>...
#	=> in shell <tag1>=<path1>...
#
show_list_under_tag(){
	local tag_name=$1
	local list=`get_tag_file`

	#check tag format
	check_tag_format $tag_name
	local result=$?
	
	if [ $result -eq 1 ];then
		echo "invalid tag name format"
		return 1
	fi

	#get tag path
	local path=`get_tag_path $tag_name`

	if [ ! -z "$path" ];then
	
	#compare path with other pathes
	grep ",$path" $list|sort -t ',' -k 2,2|perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);'

	fi

	set_shell_variables
}

# main #
main $@

# end of script #
