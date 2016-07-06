# g2w - go to work directory

g2w is one of the most useful tool for my daily task. It is just like Linux command pushd/popd but pushd and popd don't meet my requirement. g2w is a package contains some small programs and after installation you can save your recent work directory path as tag (and also as shell environment variable) and later you can switch work directories by these tags.

## About coding
At the beginning I want this program like any Linux command, e.g. cd or pushd, but I don't have the knowledge to develope it. So I decide to use what I can, perl and shell scripting, to achieve my goal. And later I know it could be a kind of kernel space programming (very far from me), because the most programs running in sub-shell and have no effect to their parent, especially its work directory path. But luckly I found an work around to solve this issue. Now I can say it works! And if anyone knows the right way/language to develope this problem, please tell me, thank you very much!

## OS
Tested on CentOS 6.x and Cygwin.

## Installation
1. Log in as root.
2. in g2w folder, run `./install`

## Usage
### Save path as tag
1. In /etc run `sw etc`

2. In /opt run `sw opt`

### Go to tag's path
1. Run `gw etc` anywhere to go to /etc

2. Run `gw opt` anywhere to go to /opt

### Show tags info
`sw` or `gw`


## Use cases
(I will write more use cases when I have time.)

Case 1.....



