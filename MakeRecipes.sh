#!/bin/bash
#
#
#  A utility helper script to make a new set of PatchBot recipes from templates
#
#  A click saver…
#  Takes an Application Name (with spaces)
#  Assumes the name for the package is the App name with no spaces, opportunity
#  to provide an alternative
#  Makes a new directory for the recipes
#  Inserts the App Name and AppName variants into the recipes' placeholders
#  names the files, and is done
#


# the recipe repo directory is the container for this script
# and any application recipes folders, which contain their recipes
recipe_container_dir=$(dirname "$0")


# the templates subdirectory is adjacent to this script, the following folder
patchbot_templates_dir="PatchBot_Templates"



## MAIN

# ask for the app name
read -p "Patch Software Title (Patch Definition and Patch Policy names): " patch_name

# often the package is also
# the app name w/o spaces
pkg_name=${patch_name// /}

# ask for the pkg name, w/ default
read -p "Package Name (no version, extension or spaces) [$pkg_name]: " this_input
if [ "$this_input" != "" ]
then
  pkg_name="$this_input"
fi

# lowercase string of pkg name
pkg_name_lc=$(awk '{print tolower($0)}' <<< "$pkg_name")


# ask for the parent recipe identifier
read -p "Parent Recipe Identifier: " parent_pkg_recipe_id



echo "Using..."
echo "App: $patch_name"
echo "Pkg: $pkg_name"
echo "pkg: $pkg_name_lc"
echo "Parent: $parent_pkg_recipe_id"
echo


## make a new directory to contain the application recipes?
echo "Application directory will be: $recipe_container_dir/$pkg_name"
# if it exists, we'll warn… and continue.
if [ -e "$recipe_container_dir/$pkg_name" ]
then
  echo "WARN: The directory exists!"
else
  echo "Making a new application directory"
  mkdir -v "$recipe_container_dir/$pkg_name"
  if [ $? -gt 0 ]
  then
    echo "mkdir failed, exiting"
    exit -13
  fi
fi
echo


## copy any templates into the new directory
echo "Copying templates..."
# 
while IFS=$'\n' read template_file
do
  # for each file, check if it exists, if not we'll make it
  # the new file name
  ## replaces the template text "PackageName" with the pkg_name string
  new_file_name="${template_file/PackageName/$pkg_name}"
  new_file_name_and_ext="${new_file_name/.templaterecipe/.recipe}"
  
  # some reporting
  echo "Template: $recipe_container_dir/$pkg_name/$new_file_name_and_ext"
  
  # does the new file exist?
  if [ -e "$recipe_container_dir/$pkg_name/$new_file_name_and_ext" ]
  then
    # file already there, skipping
    echo "WARN: file exists, skipping"
    #continue
  else
    # no file yet, let's make it
    cp "$recipe_container_dir/$patchbot_templates_dir/$template_file" "$recipe_container_dir/$pkg_name/$new_file_name_and_ext"
    
    # replace variable placeholders with strings
    # {Application Name} -> patch_name
    # {PackageName} -> pkg_name
    # {packagename} -> pkg_name_lc
    # edit in place, the new file/copy
    sed -e "s/{Application Name}/$patch_name/g" \
		-e "s/{PackageName}/$pkg_name/g" \
		-e "s/{packagename}/$pkg_name_lc/g" \
		-e "s/{Pkg Recipe Identifier}/$parent_pkg_recipe_id/g" \
		-i "" "$recipe_container_dir/$pkg_name/$new_file_name_and_ext"
        
  fi
done < <(
  ## list of files in the template directory
  ls -1 "$recipe_container_dir/$patchbot_templates_dir"
)

exit


