#!/bin/bash
#
# Script: sw
# Description:
# Version: 4.1.4
# Package Version: 4.1.1
# Date: 2017.08.04
# Author: Bob Chang
# Tested: CentOS 6.x, Cygwin NT 6.1
# Note:
#	1. Every function may check error_msg in case for process termination.
#		#if there is error message, break this function
#		if [ ! -z "$error_msg" ];then
#			return 999
#		fi
#
#

## Don't modify here, because the $0 is /bin/bash for alias.
script_name=sw
script_full_name=sw
this_file=/usr/local/bin/$script_full_name
##

tag_folder=~
tmp_folder=/tmp

# variables #
# 1 for debug, 0 for no
debug=0

# global variables, need to be clean after script terminated
error_msg=''
tag_name=''
tag_path=''

#shell value conflict
sv_conflict=''

tag_shell_value=''
tag_file=''
roll_back_file=''

#true, clean up roll back file before termination
#false, don't clean up
#keep this default false
clean_roll_back_file='false'

#special tag
#.
sp_tag=''

# functions #

# Meta
# Group: High level functions
	
#
# Function: main
# Description:
#	1. Every function starts from here.
#	2. For source usage we need this main function. Otherwise the shell could accidentally
#	   terminated.
# Usage:
#	main
#
main() {				
	#
	# The function main is used for source (I can't use exit or return 
	# directly in script otherwise the shell will terminate). Recently 
	# it seems ok using if-else instead of it, but for future expansion 
	# I keep this main() way.
	#

	tag_file=`get_tag_file`
	roll_back_file=`get_roll_back_file`

	#no argument then shows tag list
	if [ $# -eq 0 ];then
		show_list
	else
		case $1 in
			.) check_path
			;;
			-c) clean_list
			;;
			-d) check_tag_name $2
			    delete_tag
			;;
			-gf) get_tag_file
			;;
			-h) show_usage
			;;
			-r) show_list_by_path
			;;
			-rb) roll_back
			;;
			-srb) show_roll_back_info
			;;
			-svo) save_shell_variables_only
			;;
			-tag) check_tag_name $2
			      check_tag
			;;
			-u) check_tag_name $2
			    show_list_under_tag
			;;
			-V) show_version
			;;
			*) check_tag_name $1
			   save_path
			;;
		esac
	fi

	if [ ! -z "$error_msg" ];then
		echo $error_msg
	fi

	#clean up
	#roll back file
	#If the operation is not update, we purge roll back file content.
	if [ "$clean_roll_back_file" == 'true' ];then
echo here
		>$roll_back_file
	fi

	#global variables
	error_msg=''
	tag_name=''
	tag_path=''
	sv_conflict=''
	tag_shell_value=''
	tag_file=''
	is_update=''
	clean_roll_back_file='false'

}

#
# Function: save_path
# Description: 
#	1. High level function.
#	2. Perform any needed operations to add tag to system with its path.
#	3. Not reusable.
#	4. Tag name format will not be checked.
#	5. Shell variable confliction (sv conflic) of tag name will not be checked.
# Input:
#	tag_name
#	sv_conflic
#		If this tag name is already used as shell variable.
#		0 for not beused
#		1 for used but have the same values
#		2 for used and have different values
# Output:
#	N/A
# Return:
#	999
#		error
#	0
#		ok
# Usage: save_path tag_name sv_conflic
#
save_path() {
	#if there is error message, break this function
	if [ ! -z "$error_msg" ];then
		return 999
	fi

	if [ ! -z "$tag_path" ];then	#tag is in list, update it with new path
		update_tag

	else	#new tag, add it
		tag_path=`pwd`
		add_new_tag 1
	fi

	#show info of this new tag
	show_tag_info
}
	
#
# Function: clean_list
# Description:
#	1. All tag information will be removed from system.
#	2. All tag shell variables will be unset.
#	3. All tag info will be purged from tag list.
# Usage:
#	clean_list
#
clean_list() {
	unset_shell_variables
	>$tag_file
}

#
# Function: check_tag
# Description:
#	1. Show info about given tag, output empty if there is no info.
# Input:
# Output:
# Return:
# Usage:
#	check_tag
# 	find => angl                 /var/www/html/angl
#	no find => (empty)
# 
check_tag() {
	#if there is error message, break this function
	if [ ! -z "$error_msg" ];then
		return 999
	fi

	if [ ! -z "$tag_path" ];then		#tag is in list
		show_tag_info
	else
		:;	#do nothing :)
	fi
}

#
# Function: roll_back
# Description:
# Return:
# Usage: roll_back
#
roll_back() {
	if [ ! -s "$roll_back_file" ];then	#emtpy, no roll back data
		:;		#do nothing
	else
		tag_name=`cat $roll_back_file|cut -d ',' -f 1`
		local old_path=`cat $roll_back_file|cut -d ',' -f 2`

		delete_tag
		tag_path=$old_path
		check_tag_conflict
		add_new_tag 0	#add tag in bypass
		show_tag_info
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
-rb	    roll back tag to last saved path
-srb	    show roll back info
-svo	    save tag info as shell variable only
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

#
# Function: show_list
# Description:
#	1. Show tag list sorted by tag name.
#	2. Update shell varialbes.
# Input: 
#	flag
#		0	default, do everything
#     		1	don't output list info, only update shell variable
# Usage:
#	show_list
#
show_list() {
	local flag=0

	if [ ! -z $1 ];then
		flag=$1
	fi

	#debug
	#cat -A $list

	# 2016.08.09
	# Note about show list
	# I have tried lots of way to implement this task, and
	# I found recent solution is the best.
	# The issues are
	# 1. sort -k doesn't work in Cygwin when there are multiple 
	# white spaces between columns, but it works on CentOS 
	# because it sees all white spaces as one.
	# 2. I tried to use only one function e.g. show_tag_info to print 
	# formated output (read output from other function then printf 
	# line by line), but the performance is terribly slow. So the 
	# functions are not reuseable, e.g. for output by sub-path it 
	# must be a new function to handle it.
	#
	# 2017.01.05
	# In order to refactor this part, I still tried to use call sub 
	# function in loop method. But there was a very heavy performance
	# issue on Cygwin. But finally I found a acceptable way (I thought) 
	# to solve this issue.
	#
	# perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' $list|sort
	# set_shell_variables
	#
	# while read loop performs very slowly on Cygwin.
	#
	# !DON'T USE THIS ON CYGWIN!
	# while read line
	# do
	# 	name=`echo $line |cut -d ',' -f 1`
	# 	path=`echo $line |cut -d ',' -f 2`
	# 	show_info $name $path
	# done<$list

	#
	# 2017.03.10
	# There is an issue here. When path contains whitespace, the $list will be parsed unexpacted
	# (more tokens). So I fixed this bug and note I must be careful with for loop.
	#

	#	
	# 2017.07.17
	# Ther is still performance issue on Cygwin and find the best way is not to involke sub shell
	# in and loop. I know I can't use it but perl solution can't satify set shell variable
	# requiremnet, it must be implement in shell so I found the way to avoid using sub shell, using 
	# array to get name and path.
	#
# start comment
#
#	IFS_ORG=$IFS
#	#set "breakline" as input file seperator
#	#!!! Don't modify here !!!
#	IFS="
#"
##!!! 
#
#	for line in `sort $tag_file`
#	do
#		tag_name=`echo $line|cut -d ',' -f 1`		<< this two cause performance slow down
#		tag_path=`echo $line|cut -d ',' -f 2`		<<
#		check_tag_conflict
#
#		#don't set shell variable in sub shell
#		#for performance reason
#		if [ ! $SHLVL -gt 1 ];then
#			if [ $sv_conflict -eq 0 ];then
#				set_tag_in_shell
#			fi
#		fi
#
#		case $flag in
#			1) :;;	#don't show tag info
#			*) show_info;;	#show tag info
#		esac
#	done
#
#	IFS=$IFS_ORG
#
# End of comment

	#
	# 2017.07.19
	# "Houston, we got a problem."
	# Just found these codes have an issue that set_tag_in_shell will not work.
	# Because seems piple (|) will involk sub-shell for while. In order to set variable
	# in parent shell and sort the output, I modified the code again.
# start comment
#
#	local IFS_ORG=$IFS
#	IFS=,
#
#	sort $tag_file|while read line
#	do
#		local tag_info=($line)
#		tag_name=${tag_info[0]}
#		tag_path=${tag_info[1]}
#
#		check_tag_conflict
#
#		#if [ ! $SHLVL -gt 1 ];then
#		if [ $SHLVL -gt -1 ];then
#			if [ $sv_conflict -eq 0 ];then
#				set_tag_in_shell
#			fi
#		fi
#
#		case $flag in
#			1) :;;	#don't show tag info
#			*) show_info;;	#show tag info
#		esac
#	done
#
#	IFS=$IFS_ORG
# End of comment

	IFS_ORG=$IFS
	#set "breakline" as input file seperator
	#!!! Don't modify here !!!
	IFS="
"
#!!! 

	for line in `sort $tag_file`
	do
		local IFS_LAST=$IFS
		IFS=,

		local tag_info=($line)
		tag_name=${tag_info[0]}
		tag_path=${tag_info[1]}

		check_tag_conflict

		if [ $SHLVL -gt 1 ];then	#we are in sub-shell
			:;			#do nothing
		else
			if [ $sv_conflict -eq 0 ];then
				set_tag_in_shell
			fi
		fi

		case $flag in
			1) :;;	#don't show tag info
			*) show_tag_info;;	#show tag info
		esac

		IFS=$IFS_LAST
	done

	IFS=$IFS_ORG
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

	# 2017.01.06
	# 
	#sort -t ',' -k 2,2 $list|perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);'
	#set_shell_variables

	# !DON'T MODIFY HERE!
	local name
	local path

	#0 for name
	#1 for path
	monitor=0


	for line in `sort -t ',' -k 2,2 $list|sed -s 's/,/ /g'`
	do
		if [ $monitor -eq 0 ];then
			name=$line
			monitor=1
			continue
		fi	

		if [ $monitor -eq 1 ];then
			path=$line
			monitor=0
			set_tag_in_shell $name "$path"
			show_info $name "$path"
		fi
	done
	#
}

#
# Function: show_list_under_tag
# Description: 
#	1. Shows tags which pathes is under dedicated tag.
#	2. If special tag is set to ., this function will show tags under current folder.
# Usage:
#	show_list_under_tag
#	=> <tag1>                 <path1>...
#	=> in shell <tag1>=<path1>...
#
show_list_under_tag(){
	#if there is error message, break this function
	if [ ! -z "$error_msg" ];then
		return 999
	fi

	#handle special tag if exists
	case $sp_tag in
		.)	#search under current folder
		   tag_path=`pwd`
		   echo "($tag_path)"
		;;
		*) :;	#do nothing
		;;
	esac

	#tag path exists
	if [ ! -z "$tag_path" ];then
	
		# 2017.01.06
		#
		#grep ",$path" $list|sort -t ',' -k 2,2|perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);'
		#set_shell_variables
		#

		# 2017.08.02
		#for line in `grep ",$tag_path" $tag_file|sort -t ',' -k 2,2|sed -s 's/,/ /g'`
		#

		local tag_file_temp=/tmp/$script_name-tag_file_temp

		grep ",$tag_path" $tag_file|sort -t ',' -k 2,2>>$tag_file_temp

		#debug
		#cat $tag_file_temp

		while read line
		do
			local IFS_ORG=$IFS
			IFS=,

			local tag_info=($line)
			tag_name=${tag_info[0]}
			tag_path=${tag_info[1]}

			check_tag_conflict

			if [ $SHLVL -gt 1 ];then	#we are in sub-shell
				:;			#do nothing
			else
				if [ $sv_conflict -eq 0 ];then
					set_tag_in_shell
				fi
			fi

			show_tag_info;	#show tag info

			IFS=$IFS_ORG
		done<$tag_file_temp

		rm -f $tag_file_temp
	fi
}

#
# Function: save_shell_variables_only
#
save_shell_variables_only() {
	show_list 1
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
# Description: Check if recent work path already exists in tag list.
# Input:
# Output:
#	Formated tag and path information.
# Usage:
#	check_path
#	=> angl                 /var/www/html/angl
#	or
#	=> empty if not in tag list
#
check_path() {
	tag_path=`pwd`

	#
	# 2017.01.06
	# Change to use show_tag_info, although for loop is slowly.
	#
	#grep ,$work_path$ $list |perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' -
	#

	local tag_names=`get_tag_names_by_path`

	if [ ! -z "$tag_names" ];then
		for tag_name in $tag_names
		do
			check_tag_conflict
			show_tag_info
		done
	fi
}

# 
# Function: get_roll_back_file
# Description:
#	1. Return full path of user's roll back file.
# 	2. If file doesn't exist, an empty file will be created.
# Input: N/A
# Output: full path of user's roll back file
#	  e.g /tmp/root.sw.rb
# Usage: get_roll_back_file
#	 => /tmp/root.sw.rb
#
get_roll_back_file() {
	local username=`get_username`
	local roll_back_file_name=$username.$script_name.rb
	local roll_back_file=$tmp_folder/$roll_back_file_name

	if [ ! -e $roll_back_file ];then
		>$roll_back_file
	fi

	echo $roll_back_file
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
	local tag_file_name=$username.$script_name
	local tag_file=$tag_folder/$tag_file_name

	if [ ! -e $tag_file ];then
		>$tag_file
	fi

	echo $tag_file
}

#
# Function: get_tag_path
# Description: 
# Input:
# Output:
#	Set path to tag_path of this tag if it is found in tags list.
#	Keep tag_path empty if tag doesn't exist.
# Usage:
#	get_tag_path tmp
#
get_tag_path() {
	local cmd="grep '^$tag_name\b' $tag_file"
	local info=`eval $cmd`
	
	if [ ! -z "$info" ];then
		tag_path=`echo "$info"|cut -d , -f 2`
	fi
}

#
# Function: get_tag_pathes
# Description:
# Input: N/A
# Usage: get_tag_pathes
#	=> output path list
#
get_tag_pathes() {
	local list=`get_tag_file`

	perl -ne 'chomp;@s=split(/,/);printf("%s\n",$s[1]);' $list|sort
}

#
# Function: get_tag_names_by_path
# Description:
#	Return tag names of given tag path
# Usage:
#	get_tag_name path
#	=> tag names
#	or
#	=> emtpy for not found
#
get_tag_names_by_path() {
	grep ",$tag_path$" $tag_file |cut -d ',' -f 1
}

#
# Function: get_tag_names
# Description:
#	- default in alphabetical order
# Input: N/A # Output: sorted list of all tag names in tag list # Usage: get_tag_names
#	=> output tag name list
#
get_tag_names() {
	local list=`get_tag_file`

	perl -ne 'chomp;@s=split(/,/);printf("%s\n",$s[0]);' $list|sort
}

#
# Function: delete_tag_from_list
# Description: 
#	1. Delete tag from tags list.
#	2. This function will not check if this tag has tag shell value.
# Return:
#	0	ok
#	1	no ok
# Usage:
#	delete_tag
#
delete_tag_from_list(){
	if [ ! -z "$tag_name" ];then	#find tag in list
		cmd="sed -i '/^$tag_name,.\+/d' $tag_file"
		eval $cmd
		return 0
	else
		return 1
	fi
}

#
# Function: delete_tag
# Description:
#	1. Remove tag record from tag list
#	2. remove tag variable from shell if tag shell value equals
#	  recent work directory or path is in tag list, otherwise tag 
#	  variable will not be unset.
# Input:
# Output:
# Return:
#	0
#		ok
#	999
#		break
# Usage: delete_tag
#
delete_tag() {
	if [ -z $tag_name ];then
		return 999
	fi

	#if tag shell value equals tag path
	if [ "$tag_path" == "$tag_shell_value" ];then #they are equal
		unset_tag_in_shell
	fi

	delete_tag_from_list

	#clean up roll back file if tag name exists
	sed -i "/^$tag_name,/d" $roll_back_file

	#after delete tag don't need to show the tag list
	#especially when there are lots of tags
	#just keep output silent, if user wants he can use
	# sw or sw -tag <tag name> to check result
	#show_list

	return 0	#delete ok
}

#
# Function: check_tag_name_format
# Description: 
#	1. This function checks tag name format.
#	2. Tag name format rule: 
#		1. ^[a-zA-Z_][\w_]{0,19}\$
#		2. 1 to 20 letters
#		3. can't contain -
#		4. can't begin with number
#	3. Failed if tag name is empty.
# Input:
#	tag_name
# Output:
#	N/A
# Return:
#	0
#		ok
#	1
#		invalid tag name format
# Usage:
#	check_tag_name_format tag_name
# Example:
#	check_tag_name_format abc
#
check_tag_name_format() {
	local tag_name=$1

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
# Function: check_tag_name
# Description: 
#	1. Check tag name format. If it is invalid, set error_msg with error message.
#	2. Otherwise set tag_name with input value
#	3. Check if tag_name has path in tag list, if not set current path to tag_path.
#	4. Check sv conflict and set sv_conflict:
#		0 for not be used
#		1 for used but have the same values
#		2 for used and have different values
#	5. Check if tag name is special tag then set sp_tag, e.g. sp_tag='.'.
# Input:
#	tag_name
# Output:
#	N/A
# Return:
#	0
#		ok
#	999
#		break
# Usage:
#	check_tag_name tag_name
# Example:
#	check_tag_name abc
#
check_tag_name() {
	#check if tag name is special tag
	#
	case $1 in
		.) sp_tag='.';return 0
		;;
		*) :;	#do nothing
	esac

	check_tag_name_format $1
	local result=$?
	
	if [ $result -eq 1 ];then	#invalid format
		error_msg="invalid tag name format"
		return 999
	fi

	#valid format
	tag_name=$1

	#check its path
	get_tag_path

	#check sv conflict
	check_tag_conflict
}

#
# Function: show_tag_info
# Description:
#	1. Show tag all information.
#	2. Note if tag has shell variable conflict.
#	3. This function is suitable for single display.
# Input:
# Output:
#	formated tag_info
# Usage:
#	show_tag_info tag_name path
#	=> work                 /opt/tools/g2w/work 
#	or
#	=> *work                 /opt/tools/g2w/work 
#
show_tag_info() {
	#check conflict
	if [ $sv_conflict -eq 2 ];then
		echo -n '*'
	fi

	printf "%-20s %-20s\n" $tag_name "$tag_path";
}

#
# Function: show_roll_back_info
# Description:
#	1. Show roll back file information.
# Usage: show_roll_back_info
#
show_roll_back_info() {
	if [ ! -s $roll_back_file ];then	#roll back file is empty
		:;		#do nothing
	else
		local tag_name=`cat $roll_back_file|cut -d ',' -f 1`
		local tag_path=`cat $roll_back_file|cut -d ',' -f 2`
	
		#we don't need to handle sv_conflict
		sv_conflict=0
		show_tag_info
	fi
}

#
# Function: add_tag
# Description:
#	- this function will not check tag name format
#	- this function checks if tag is in shell
#	- if conflict, the function will ask user y/n
#	- if conflict, bypass mode keeps process silent
#	- if everything ok, tag will add to tag list and shell
#	- if parameter path exists, path value will replace recent work directory
#	- if path must be used with mode parameter
# Input: 
#	tag_name
#	bypass
#		0 - for bypass mode
#		1 - for interactive mode (default)
#	path 
#		path of tag_name
# Output: N/A
# Return:
#	0 for added to list and shell
#	1 for added to list only
#	2 no added
# Usage: 
#	add_tag tag_name
#	=> add tag_name and path to tag list
#	   set tag_name as variable in shell
#	   return 0
#	=> add tag_name and path to tag list
#	   return 1
#	=> do nothing
#	   return 2
#	or
#	add_tag tag_name 0
#	=> enable bypass mode
#	or
#	add_tag tag_name 0 path
#	=> add tag_name with path in bypass mode
# 
add_tag() {
	local tag_name=$1
	local bypass=$2
	local path=$3

	if [ -z "$path" ];then
		path=`pwd`
	fi
		
	local data=$tag_name,$path
	local list=`get_tag_file`
	local answer=n

	if [ -z $bypass ];then
		bypass=1
	fi

	#set tag as shell variable
	set_tag_in_shell $tag_name "$path"
	local result=$?	

	#1 for conflict:
	#tag name is already used by shell
	#and shell values is not equal to path
	if [ $result -eq 1 ];then
		if [ ! $bypass -eq 0 ];then	#no bypass

			#don't use this command, it doesn't work
			#local tag_shell_value=`echo \$$tag_name`
			#use this instead
			local cmd="echo \$$tag_name"
			local tag_shell_value=`eval $cmd`

			echo "tag name already exists in shell: $tag_name=$tag_shell_value"
			echo -n "add to list only? [y/n] "
			read answer
		else
			answer=y
		fi

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
# Function: add_new_tag
# Description:
# Input:
#	0	for bypass mode
#	1	for interactive mode (default)
# Usage:
#	add_new_tag [mode]
# Examples:
#	add_new_tag 0	=> add new tag in bypass mode
#
add_new_tag() {
	local bypass=$1
	local data=$tag_name,$tag_path

	if [ -z $bypass ];then
		bypass=1
	fi

	#set tag as shell variable
	if [ $sv_conflict -eq 0 ];then		#not used
		echo $data>>$tag_file
		set_tag_in_shell
		return 0
	fi

	if [ $sv_conflict -eq 1 ];then		#the same values
		#add to tag list only
		echo $data>>$tag_file	
		return 0
	fi

	if [ $sv_conflict -eq 2 ];then		#conflict (different values)
		local answer=n

		if [ ! $bypass -eq 0 ];then	#no bypass
			echo "tag name already exists in shell: $tag_name=$tag_shell_value"
			echo -n "add to list only? [y/n] "
			read answer
		else
			answer=y
		fi

		#need to refine here, for Y,y,yes....
		if [ "$answer" == y ];then	#user wants to add tag to tag list only
			#add tag data to tag list
			echo "$data">>$tag_file
			return 0
		else
			return 2	#do nothing
		fi
	fi
}

#
# Function: update_tag
# Description:
#	1. Tag will be deleted and then added.
#	2. This function will not check if tag exists in tag list
#	3. This function will not check tag format or cv confilict.
#	4. Prepare roll back info.
# Input: 
# Output:
# Return:
# Usage:
#	update_tag
#
update_tag() {
	delete_tag

	#for roll back
	#add old path to roll back file
	echo -n "$tag_name,$tag_path" > $roll_back_file
	#

	#set pwd to tag path
	tag_path=`pwd`
	add_new_tag 1
}

# Meta
# Group: Tag operation on shell
# Description:

#
# -Function: check_tag_in_shell
# Description: 
# 	- this function is useless and obsolate
#	- check if tag already exits as variable in shell
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
#check_tag_in_shell() {
#	local tag_name=$1
#	local cmd="echo \$${tag_name}"
#	local result=`eval $cmd`
#	echo "$result"
#}

#
# Function: check_tag_conflict
# Description:
# Input:
# Global Variable:
#	tag_name
#	tag_path
# Output:
# Return:
#	0
#		ok
#	1
#		used but have the same values
#	2
#		used and have different values
# Usage: check_tag_conflict
#
check_tag_conflict() {
	
	# 2017.01.05
	# 1. Don't use check_tag_in_shell because it consumes lots of time.
	#   I have disabled it.
	#
	#   old code:
	#   local tag_shell_value=`check_tag_in_shell $tag_name`
	#
	#   In stead of:
	#   a. Use cmd and eval method to get shell variable value, 
	#      the value could be emtpy.
	#   b. Compare value with path.
	#
	# 2. Don't use tag_shell_value=`\$$tag_name, becaues:
	#   a. It works only in shell script on CentOS.
	#   b. It doesn't work on CentOS terminal (echo \$$tag_name =>
	#      $work).
	#   c. It doesn't work on Cygwin both terminal and script (echo 
	#      \$$tag_name => $work).
	#   I don't know why but with cmd and eval it works.
	#
	# DON'T MODIFY HERE!
	local cmd="echo \$$tag_name"
	tag_shell_value=`eval $cmd`
	#

	# tag name is not set as shell variable
	if [ -z "$tag_shell_value" ];then
		sv_conflict=0
		return 0
	fi

	# tag name is set and has the same value of shell variable
	if [ "$tag_shell_value" == "$tag_path" ];then
		sv_conflict=1
		return 0
	else	# they have different values
		sv_conflict=2
		return 0
	fi	
}

#
# Function: set_tag_in_shell
# Description: 
#	1. Set shell variable as tag vs path and export this variable to sub shell.
# Input:
# Output:
# Return:
# Usage: set_tag_in_shell
#
set_tag_in_shell() {
	export $tag_name="$tag_path"
}

#
# Function: unset_tag_in_shell
# Description: 
#	1. Unset tag shell varialbe.
#	2. This function will not check if this tag exists in tag list.
#	3. User must check tag list manually before invoke this function
# Input:
# Usage:
#	unset_tag_in_shell tag_name
#
unset_tag_in_shell() {
	unset $tag_name
}

#
# Function: set_shell_variables
# Description:
#	- set all tags in tag list to shell variables
# Input: N/A
# Output: N/A
# Usage: set_shell_variable
#	=> in shell <tag1>=<path1>
#	...
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
		
		set_tag_in_shell $tag "$path"
	done
}

#
# Function: unset_shell_variables
# Description: All tag shell variables will be unset.
# Usage: unset_shell_variables
#
unset_shell_variables() {
#	local list=`cat $tag_file`
#	local IFS_org=$IFS
#
#	for data in $list
#	do
#		IFS=','
#		local data_arr=($data)
#		IFS=$IFS_org
#		local tag=${data_arr[0]}
#		
#		unset_tag_in_shell $tag
#	done

	local IFS_ORG=$IFS
	IFS=,

	while read line
	do
		local tag_info=($line)
		tag_name=${tag_info[0]}
		
		unset_tag_in_shell
	done<$tag_file

	IFS=$IFS_ORG
}

# main #
main $@

# end of script #
