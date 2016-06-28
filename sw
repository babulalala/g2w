#!/bin/bash
#
# Script: sw
# Description:
# Version: 4.0.2
# Date: 2016.06.23
# Author: Bob Chang
# Tested: CentOS 6.x, Cygwin NT 6.1
#

script_name=sw
script_full_name=sw
this_file=/usr/local/bin/$script_full_name

get_version() {
        local version=`grep '^# Version:' $this_file|cut -d ' ' -f 3`
        echo $version
}

version=`get_version`

tag_folder=/tmp

#
show_usage() {
        cat<<here
$script_full_name, v$version

Change and manage work directories

Usage: $script_full_name [-c|-d <tag>|-gf|-h|-V]

tag	    composed of [a-zA-Z0-9_-]

Options
  N/A	    show tags info
  tag	    save tag with current work directory path
  -c        clean (delete) all tags in path list
  -d tag    delete tag in path list
  -gf	    get tag file name
  -h        show this help
  -V        show version

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

# return tag file of user
get_tag_file() {
	local username=`get_username`
	tag_file_name=$username.$script_name
	tag_file=$tag_folder/$tag_file_name

	echo $tag_file
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
show_list() {
	local list=`get_tag_file`

	if [ ! -e $list ];then
		>$list
		return 0
	fi

	#debug
	#cat $list

	perl -pe 's/,/\t/' $list|sort

	set_shell_variables
	
}

unset_tag_in_shell() {
	local tag_name=$1
	unset $tag_name
}

delete_tag() {
	local tag_name=$1
	local list=`get_tag_file`

	if [ -z $tag_name ];then
		show_usage
		return 1
	fi

	local found=`grep ^$tag_name, $list >/dev/null 2>&1;echo $?`

	if [ $found -eq 0 ];then	#found
		cmd="sed -i '/^$tag_name,.\+/d' $list"
		eval $cmd
		unset_tag_in_shell $tag_name
	fi

	show_list
}

check_tag_format() {
	local tag_name=$1
	#naming rule, only [a-zA-Z0-9_-]
	local name_ok=`perl -w -e '$name=shift;if($name =~ /^[a-zA-Z0-9_-]+$/){print 0;}else{print 1}' $tag_name 2>/dev/null`

	return $name_ok
}

check_tag_in_shell() {
	local tag_name=$1
	local cmd="echo \$${tag_name}"
	local result=`eval $cmd`

	if [ -z $result ];then
		return 0
	else
		return 1
	fi
}

check_tag() {
	local tag_name=$1

	#check tag format
	check_tag_format $tag_name
	local result=$?

	if [ $result -eq 1 ];then
		echo "invalid tag name"
		return 1
	fi

	#sheck tag existance in shell
	check_tag_in_shell $tag_name
	local result=$?

	if [ $result -eq 1 ];then
		echo "tag name already exists in shell"
		return 1
	fi
}

save_path() {
	local tag_name=$1
	check_tag $tag_name
	local result=$?
	
	if [ $result -eq 1 ];then
		return 1
	fi

	local path=`pwd`
	local data=$tag_name,$path
	local list=`get_tag_file`

	local found=`grep ^$tag_name, $list >/dev/null 2>&1;echo $?`

	if [ $found -eq 0 ];then	#found
		delete_tag $tag_name
	fi
		
	echo $data>>$list

	#shell variable
	set_tag_in_shell $tag_name $path

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

show_version() {
	echo $version
}

main() {
	if [ $# -eq 0 ];then
		show_list
		return 0
	fi

	case $1 in
		-c) clean_list
		;;
		-d) delete_tag $2
		;;
		-gf) get_tag_file
		;;
		-h) show_usage
		;;
		-V) show_version
		;;
		*) save_path $1
		;;
	esac
}

## Main ##
main $@

## End of script ##
