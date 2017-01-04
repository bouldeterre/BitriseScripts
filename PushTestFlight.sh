#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ipa_path=$BITRISE_IPA_PATH
itunescon_user="XXX@xxx.com"
app_id="XXXXXX"
submit_for_beta="yes"
skip_metadata="yes"
skip_screenshots="yes"
team_id="XXXX"
team_name="XXXX"
password="XXXX"
pkg_path=$BITRISE_PKG_PATH
echo "Config:"
echo " * ipa_path: ${ipa_path}"
echo " * pkg_path: ${pkg_path}"
echo " * itunescon_user: ${itunescon_user}"
echo " * password: ***"
echo " * app_id: ${app_id}"
echo " * submit_for_beta: ${submit_for_beta}"
echo " * skip_metadata: ${skip_metadata}"
echo " * skip_screenshots: ${skip_screenshots}"
echo " * team_id: ${team_id}"
echo " * team_name: ${team_name}"

# ------------------------------
# --- Error Cleanup

function finalcleanup {
  echo "-> finalcleanup"
  local fail_msg="$1"

  echo "# Error"
  if [ ! -z "${fail_msg}" ] ; then
    echo "**Error Description**:"
    echo "${fail_msg}"
  fi
  echo "*See the logs for more information*"

  echo "**If this is the very first build**
of the app you try to deploy to iTunes Connect then you might want to upload the first
build manually to make sure it fulfills the initial iTunes Connect submission
verification process."

  if [[ "${submit_for_beta}" == "yes" ]] ; then
	echo "**Beta deploy note:** you
should try to disable the \`Submit for TestFlight Beta Testing\` option and try
the deploy again."
  fi
}

# ---------------------
# --- Required Inputs

if [ -z "${ipa_path}" ] && [ -z "${pkg_path}" ] ; then
	echo " [!] ipa/pkg path not provided!"
	exit 1
fi

if [ -z "${password}" ] ; then
	echo " [!] \`password\` not provided!"
	exit 1
fi

if [ -z "${itunescon_user}" ] ; then
	echo " [!] \`itunescon_user\` not provided!"
	exit 1
fi

if [ -z "${app_id}" ] ; then
	echo " [!] \`app_id\` not provided!"
	exit 1
fi


CONFIG_package_type=''
CONFIG_package_path=''
if [ -n "${ipa_path}" ] ; then
  CONFIG_package_type='--ipa'
  CONFIG_package_path="${ipa_path}"
elif [ -n "${pkg_path}" ] ; then
  CONFIG_package_type='--pkg'
  CONFIG_package_path="${pkg_path}"
fi

CONFIG_testflight_beta_deploy_type_flag=''
if [[ "${submit_for_beta}" == "yes" ]] ; then
	CONFIG_testflight_beta_deploy_type_flag='--submit_for_review'
fi

CONFIG_skip_metadata_type_flag=''
if [[ "${skip_metadata}" == "yes" ]] ; then
	CONFIG_skip_metadata_type_flag='--skip_metadata'
fi

CONFIG_skip_screenshots_type_flag=''
if [[ "${skip_screenshots}" == "yes" ]] ; then
	CONFIG_skip_screenshots_type_flag='--skip_screenshots'
fi

# ---------------------
# --- Main

echo "# Setup"
################################### DOWNLOAD PILOT
command_exists () {
	command -v "$1" >/dev/null 2>&1 ;
}

update_pilot="yes"
gem_name="pilot"

if command_exists $gem_name ; then
	echo " (i) $gem_name already installed"

  if [ "$update_pilot" == "no" ] ; then
    echo " (i) update  $gem_name disabled, setup finished..."
	  exit 0
  fi

  echo " (i) updating  $gem_name..."
else
	echo " (i) $gem_name NOT yet installed, attempting install..."
fi

STARTTIME=$(date +%s)

which_ruby="$(which ruby)"
osx_system_ruby_pth="/usr/bin/ruby"
brew_ruby_pth="/usr/local/bin/ruby"

echo
echo " (i) Which ruby: $which_ruby"
echo " (i) Ruby version: $(ruby --version)"
echo

set -e

if [[ "$which_ruby" == "$osx_system_ruby_pth" ]] ; then
	echo " -> using system ruby - requires sudo"
	echo '$' sudo gem install ${gem_name} --no-document
	sudo gem install ${gem_name} --no-document
elif [[ "$which_ruby" == "$brew_ruby_pth" ]] ; then
	echo " -> using brew ($brew_ruby_pth) ruby"
	echo '$' gem install ${gem_name} --no-document
	gem install ${gem_name} --no-document
elif command_exists rvm ; then
	echo " -> installing with RVM"
	echo '$' gem install ${gem_name} --no-document
	gem install ${gem_name} --no-document
elif command_exists rbenv ; then
	echo " -> installing with rbenv"
	echo '$' gem install ${gem_name} --no-document
	gem install ${gem_name} --no-document
	echo '$' rbenv rehash
	rbenv rehash
else
	echo " [!] Failed to install: no ruby is available!"
	exit 1
fi

ENDTIME=$(date +%s)
echo
echo " (i) Setup took $(($ENDTIME - $STARTTIME)) seconds to complete"
echo

################################### END DOWNLOAD PILOT


echo "# Deploy"

echo "**Note:** if your password
contains special characters
and you experience problems, please
consider changing your password
to something with only
alphanumeric characters."

echo "**Be advised** that this
step uses a well maintained, open source tool which
uses *undocumented and unsupported APIs* (because the current
iTunes Connect platform does not have a documented and supported API)
to perform the deployment.
This means that when the API changes
**this step might fail until the tool is updated**."

export FASTLANE_PASSWORD=XXXX
pilot --help

pilot upload -u "${itunescon_user}"  -i "${ipa_path}" -s -z -p "${app_id}" -q "XXXXXX"


#echo "CREATING EXPECT FILE"
#echo "#!/usr/bin/expect -f" > customscript
#echo "spawn pilot upload -u " ${itunescon_user} " -i " ${ipa_path} " -s -z -p " ${app_id} " -q " "XXXXX" >> customscript
#echo "expect" "\"password\"" >> customscript
#echo  "send" "\"XXXXXX\r\"" >> customscript
#echo "interact" >> customscript


#chmod +x customscript
#echo "EXPECT SCRIPT:"
#cat customscript
#./customscript
#sleep 2m
#echo "END BASH"
#exit 0

exit 0
