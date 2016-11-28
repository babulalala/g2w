#!/bin/bash
#
# Script: sw
# Description:
# Version: 4.0.16
# Package Version: 4.0.16
# Date: 2016.11.24
# Author: Bob Chang
# Tested: CentOS 6.x, Cygwin NT 6.1
#

#don't modify here, because the $0 is /bin/bash for alias 
script_name=sw
script_full_name=sw
this_file=/usr/local/bin/$script_full_name
tag_folder=~

# variables #
# 1 for debug, 0 for no
debug=0

# functions #
#function: get_script_version
get_script_version() {
	local version=`grep '^# Version:' $this_file|cut -d ' ' -f 3`
	if [ -z $version ];then
		echo '-'
	else
		echo $version
	fi
}

#function: get_pkg_version
get_pkg_version() {
	local version=`grep '^# Package Version:' $this_file|cut -d ' ' -f 4`
	if [ -z $version ];then
		echo '-'
	else
		echo $version
	fi
}

show_version() {
	local pkg_v=`get_pkg_version`
	local script_v=`get_script_version`

	echo "$pkg_v/$script_v"
}

# return tag file of user
get_tag_file() {
	local username=`get_username`
	tag_file_name=$username.$script_name
	tag_file=$tag_folder/$tag_file_name

	if [ ! -e $list ];then
		>$list
		exit 0
	fi

	echo $tag_file
}

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

get_username() {
	whoami
}

set_tag_in_shell() {
	local tag_name=$1
	local path=$2

	export $tag_name=$path
}

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

get_tag_path() {
	local tag=$1
	local list=`get_tag_file`
	local cmd="grep '^$tag\b' $list"
	local info=`eval $cmd`
	
	if [ ! -z $info ];then
		echo $info|cut -d , -f 2
	else
		exit
	fi
}

# Show list
#Note about show list - 2016.08.09
#I have tried lots of way to implement this task, and
#I found recent solution is the best.
#The issues are
#1. sort -k doesn't work in Cygwin when there are multiple white spaces
#between columns, but it works on CentOS because it sees all white
#spaces as one.
#2. I tried to use only one function e.g. _show_list to print formated 
#output (read output from other function then printf line by line), but
#the performance is terribly slow.
#So the functions are not reuseable, e.g. for output by sub-path it must
#be a new function to handle it.
#
show_list() {
	local list=`get_tag_file`

	#debug
	#cat -A $list

	perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' $list|sort

	set_shell_variables
}

show_list_by_path() {
	local list=`get_tag_file`

	#debug
	#cat -A $list

	sort -t ',' -k 2,2 $list|perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);'

	set_shell_variables
}

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
	
	#compare path with other pathes
	grep ",$path" $list|sort -t ',' -k 2,2|perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);'

}
#

unset_tag_in_shell() {
	local tag_name=$1
	unset $tag_name
}

delete_tag(){
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

_delete_tag() {
	local tag_name=$1

	if [ -z $tag_name ];then
		show_usage
		return 1
	fi

	delete_tag $tag_name
	unset_tag_in_shell $tag_name

	#after delete tag don't new to show the tag list
	#especially when there are lots of tags
	#just keep output silent, if user wants he can use
	# sw or sw -ct <tag name> to check result
	#show_list
}

check_tag_format() {
	local tag_name=$1

	#debug
	if [ $debug -eq 1 ];then
		echo "$FUNCNAME: tag_name=$tag_name"
	fi

	#The naming rule is the same as shell environment variable 
	#naming rule, only [a-zA-Z0-9_], min 1, max 20, 
	#do not begin with a digit.
	#The reason why can't we use - in tag name because:
	#1. It's invalid of shell variable naming rule.
	#2. When tag name begins with -, it will be confused with flag.
	local cmd="perl -w -e '\$name=\"$tag_name\";if(\$name =~ /^[a-zA-Z_][\w_]{0,19}\$/){print 0;}else{print 1}' 2>/dev/null"

	local result=`eval $cmd`

	if [ $result -eq 0 ];then	#name format is ok
		return 0		
	else				#not ok
		return 1
	fi
}

check_tag_in_shell() {
	local tag_name=$1
	local cmd="echo \$${tag_name}"
	local result=`eval $cmd`

	if [ -z $result ];then		#not in shell
		return 1
	else
		return 0		#in shell
	fi
}

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

# input: tag_name
# output: formated tag_info
show_tag_info() {
	local tag_name=$1
	local list=`get_tag_file`

	#debug
	if [ $debug -eq 1 ];then
		echo "$FUNCNAME: tag_name=$tag_name"
	fi

	local tag_info=`grep "^$tag_name," $list`
	echo $tag_info |perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' -
}

add_tag() {
	local tag_name=$1
	local path=`pwd`
	local data=$tag_name,$path
	local list=`get_tag_file`
		
	echo $data>>$list

	#shell variable
	set_tag_in_shell $tag_name $path
}

update_tag() {
	local tag_name=$1
	delete_tag $tag_name
	add_tag $tag_name
	
}

_save_path() {
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
	else
		#if tag is used by shell?
		check_tag_in_shell $tag_name
		result=$?

		if [ $result -eq 1 ];then
			#add tag with path
			add_tag $tag_name
		else
			echo "tag name already exists in shell"
			return 1
		fi
		
	fi

	#after tag added I don't show all list
	#just the info of this new tag
	#show_list
	show_tag_info $tag_name
}
	
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

clean_list() {
	unset_shell_variables
	local list=`get_tag_file`
	>$list
}

check_path() {
	local list=`get_tag_file`
	local work_path=`pwd`
	grep ,$work_path$ $list |perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' -
}

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
	
	
#the function main is used for source (I can't use exit or return 
#directly in script otherwise the shell will terminate). Recently 
#it seems ok using if-else instead of it, but for future expansion 
#I keep this main() way.
main() {				
	if [ $# -eq 0 ];then
		show_list
		return 0
	fi

	case $1 in
		.) check_path
		;;
		-c) clean_list
		;;
		-d) _delete_tag $2
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
		*) _save_path $1
		;;
	esac
}

# main #
main $@

# end of script #
