#!/bin/bash
#
# Script: sw
# Description:
# Version: 4.0.9
# Package Version: 4.0.11
# Date: 2016.08.09
# Author: Bob Chang
# Tested: CentOS 6.x, Cygwin NT 6.1
#

#don't modify here, because of alias the $0 is /bin/bash
script_name=sw
script_full_name=sw
this_file=/usr/local/bin/$script_full_name
tag_folder=~

# functions #
get_script_version() {
	local version=`grep '^# Version:' $this_file|cut -d ' ' -f 3`
	if [ -z $version ];then
		echo '-'
	else
		echo $version
	fi
}

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
  tag	    save tag with current work directory path
  -c        clean (delete) all tags in path list
  -d tag    delete tag in path list
  -gf	    get tag file name
  -h        show this help
  -r	    show tags info sorted by path
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

#
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

	sort $list|_show_list

	#debug
	#cat -A $list

	perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);' $list|sort

	set_shell_variables
}

show_list_by_path() {
	local list=`get_tag_file`

	if [ ! -e $list ];then
		>$list
		return 0
	fi

	#debug
	#cat -A $list

	sort -t ',' -k 2,2 $list|perl -ne 'chomp;@s=split(/,/);printf("%-20s %-20s\n",$s[0],$s[1]);'

	set_shell_variables
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
	show_list
}

check_tag_format() {
	local tag_name=$1

	#The naming rule is the same as shell environment variable 
	#naming rule, only [a-zA-Z0-9_], min 1, max 20, 
	#do not begin with a digit.
	#The reason why can't we use - in tag name because:
	#1. It's invalid of shell variable naming rule.
	#2. When tag name begins with -, it will be confused with flag.
	local cmd="perl -w -e '\$name=\"$tag_name\";if(\$name =~ /^[a-zA-Z_][\w_]{1,19}\$/){print 0;}else{print 1}' 2>/dev/null"

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
echo $cmd
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

	check_tag_format $tag_name
	local result=$?
	
	if [ $result -eq 1 ];then
		echo "invalid tag name format"
		return 1
	fi

	check_tag_in_list $tag_name
	result=$?

	if [ $result -eq 0 ];then
		update_tag $tag_name
	else
		check_tag_in_shell $tag_name
		result=$?

		if [ $result -eq 1 ];then
			add_tag $tag_name
		else
			echo "tag name already exists in shell"
			return 1
		fi
		
	fi

	show_list
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

main() {
	if [ $# -eq 0 ];then
		show_list
		return 0
	fi

	case $1 in
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
		-V) show_version
		;;
		*) _save_path $1
		;;
	esac
}

## Main ##
main $@

## End of script ##
