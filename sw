#!/bin/bash
#
# Script: sw
# Description:
# Version: 4.0.6
# Date: 2016.08.01
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
	local version=`grep '^# Package Version:' $this_file|cut -d ' ' -f 3`
	if [ -s $version ];then
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

	echo $tag_file
}

#
show_usage() {
	local tag_file=`get_tag_file`

        cat<<here
$script_full_name, v$version

Change and manage work directories

Usage: $script_full_name [-c|-d <tag>|-gf|-h|-V]

tag	    composed of [a-zA-Z0-9_]

Options
  N/A	    show tags info
  tag	    save tag with current work directory path
  -c        clean (delete) all tags in path list
  -d tag    delete tag in path list
  -gf	    get tag file name
  -h        show this help
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

	#naming rule, only [a-zA-Z0-9_]
	#
	# this don't work if tag name equals to perl argument e.g. -v
	#local name_ok=`perl -w -e '$name=shift;if($name =~ /^[a-zA-Z0-9_]+$/){print 0;}else{print 1}' $tag_name 2>/dev/null`
	# this works
	local cmd="perl -w -e '\$name=\"$tag_name\";if(\$name =~ /^[a-zA-Z0-9_]+\$/){print 0;}else{print 1}' 2>/dev/null"
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
		-V) show_version
		;;
		*) _save_path $1
		;;
	esac
}

## Main ##
main $@

## End of script ##
